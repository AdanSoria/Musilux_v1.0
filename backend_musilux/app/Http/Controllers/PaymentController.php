<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Validator;
use Stripe\Stripe;
use Stripe\PaymentIntent;
use Stripe\Checkout\Session;

class PaymentController extends Controller
{
    public function __construct()
    {
        $secret = config('services.stripe.secret');
        if ($secret) {
            Stripe::setApiKey($secret);
        }
    }

    private function stripeConfigured(): bool
    {
        return !empty(config('services.stripe.secret'));
    }

    /**
     * Crea un PaymentIntent para el flujo móvil (PaymentSheet).
     * Registra la orden en BD antes de cobrar y vincula el id_pedido como metadata.
     * Request JSON: { amount, items[], nombre, apellido, calle, ciudad, codigo_postal, pais, ... }
     * Devuelve: { client_secret, publishableKey }
     */
    public function createPaymentIntent(Request $request)
    {
        if (!$this->stripeConfigured()) {
            Log::error('Stripe not configured: STRIPE_SECRET env var is missing.');
            return response()->json(['message' => 'Payment service not configured. Contact support.'], 500);
        }

        $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'items'  => ['required', 'array'],
            'calle'  => ['required', 'string', 'min:3', 'max:255'],
            'ciudad' => ['required', 'string', 'min:2', 'max:100'],
            'codigo_postal' => ['required', 'string', 'min:3', 'max:12'],
            'pais'   => ['required', 'string', 'min:2', 'max:100'],
            'nombre' => ['required', 'string', 'min:2', 'max:100'],
            'apellido' => ['required', 'string', 'min:2', 'max:100'],
            'apto'   => ['nullable', 'string', 'max:100'],
            'estado' => ['nullable', 'string', 'max:100'],
            'telefono' => ['nullable', 'string', 'min:7', 'max:20'],
        ]);

        $amountFloat = (float) $request->input('amount');
        $amountCents = (int) round($amountFloat * 100);

        $items    = $request->input('items', []);
        $nombre   = trim($request->input('nombre', ''));
        $apellido = trim($request->input('apellido', ''));
        $calle    = trim($request->input('calle', ''));
        $apto     = trim($request->input('apto', '')) ?: null;
        $ciudad   = trim($request->input('ciudad', ''));
        $estado   = trim($request->input('estado', '')) ?: null;
        $cp       = trim($request->input('codigo_postal', ''));
        $pais     = trim($request->input('pais', ''));
        $telefono = trim($request->input('telefono', '')) ?: null;

        $discount  = (float) $request->input('discount', 0);
        $ivaRate   = 0.16;
        $total     = $amountFloat - $discount;
        $subtotal  = $total / (1 + $ivaRate);

        // Construir línea de dirección de envío (sin datos de contacto)
        $direccionParts = array_filter([$calle, $apto]);
        $localParts     = array_filter([$ciudad, $estado, $cp, $pais]);
        if (!empty($localParts)) {
            $direccionParts[] = implode(', ', $localParts);
        }
        $direccionEnvio = implode(' • ', $direccionParts);

        // direccion_envio almacena toda la info de contacto+dirección (campo TEXT)
        // guia_envio queda null — se usa para el número de guía de paquetería (admin lo llena al enviar)
        $contactParts = array_filter([
            trim("$nombre $apellido"),
            $direccionEnvio,
            $telefono ? "Tel: $telefono" : null,
        ]);
        $fullShippingInfo = implode(' • ', $contactParts);

        $userId   = $request->user()?->id;
        $pedidoId = null;

        $step = 'init';
        DB::beginTransaction();
        try {
            $step     = 'insert_pedido';
            $pedidoId = (string) Str::uuid();

            DB::table('pedidos')->insert([
                'id'              => $pedidoId,
                'id_usuario'      => $userId,
                'id_cupon'        => null,
                'estado'          => 'pendiente',
                'subtotal'        => round($subtotal, 2),
                'descuento'       => $discount,
                'total'           => round($total, 2),
                'direccion_envio' => $fullShippingInfo,
                'guia_envio'      => null,
                'creado_en'       => now(),
            ]);

            foreach ($items as $it) {
                $idProducto    = $it['id_producto'] ?? null;
                $cantidad      = (int) ($it['cantidad'] ?? 1);
                $precioUnitario = (float) ($it['precio_unitario'] ?? 0.0);
                $nomProd       = $it['nombre_producto'] ?? null;
                $imgProd       = $it['imagen_producto'] ?? null;

                if ($idProducto) {
                    $dbNombre = DB::table('productos')->where('id', $idProducto)->value('nombre');
                    if ($dbNombre) $nomProd = $dbNombre;

                    $img = DB::table('multimedia_producto')
                        ->where('id_producto', $idProducto)
                        ->where('es_principal', true)
                        ->value('url_archivo');
                    if (!$img) {
                        $img = DB::table('multimedia_producto')
                            ->where('id_producto', $idProducto)
                            ->value('url_archivo');
                    }
                    if ($img) $imgProd = $img;
                }

                $step = 'insert_items';
                DB::table('items_pedido')->insert([
                    'id_pedido'       => $pedidoId,
                    'id_producto'     => $idProducto,
                    'cantidad'        => $cantidad,
                    'precio_unitario' => $precioUnitario,
                    'nombre_producto' => $nomProd ?? 'Producto',
                    'imagen_producto' => $imgProd,
                    'created_at'      => now(),
                    'updated_at'      => now(),
                ]);
            }

            // allow_redirects:'never' asegura que Stripe solo devuelva métodos
            // compatibles con PaymentSheet nativo (sin redirecciones a browser).
            $step = 'stripe_pi';
            $pi = PaymentIntent::create([
                'amount'   => $amountCents,
                'currency' => 'mxn',
                'automatic_payment_methods' => [
                    'enabled'         => true,
                    'allow_redirects' => 'never',
                ],
                'metadata' => [
                    'platform'   => 'musilux',
                    'id_pedido'  => $pedidoId,
                    'id_usuario' => (string) $userId,
                ],
            ]);

            DB::commit();

            return response()->json([
                'client_secret'  => $pi->client_secret,
                'publishableKey' => config('services.stripe.key'),
            ]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("createPaymentIntent error at [$step]: " . $e->getMessage(), [
                'amount'   => $amountFloat,
                'userId'   => $userId,
                'pedidoId' => $pedidoId,
            ]);
            // Detalle visible temporalmente para diagnóstico — quitar en producción final
            return response()->json([
                'message' => 'Error al crear el pago',
                'step'    => $step,
                'detail'  => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Crea una sesión de Stripe Checkout (útil para web)
     * Request JSON esperado: { "amount": 123.45 }
     * Devuelve: { url }
     */
    public function createCheckoutSession(Request $request)
    {
        if (!$this->stripeConfigured()) {
            Log::error('Stripe not configured: STRIPE_SECRET env var is missing.');
            return response()->json(['message' => 'Payment service not configured. Contact support.'], 500);
        }

        $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'items' => ['required', 'array',],
        ]);

        $amountFloat = $request->input('amount');
        $amount = (int) round($amountFloat * 100);

        $items = $request->input('items', []);
        $discount = $request->input('discount', 0);

        // calcular totales: los precios enviados en 'precio_unitario' ya incluyen IVA.
        // Sumamos para obtener el total con IVA, aplicamos descuento y luego
        // extraemos la porción sin IVA (subtotal) y la porción de impuestos.
        $rawTotal = 0.0;
        foreach ($items as $it) {
            $p = isset($it['precio_unitario']) ? floatval($it['precio_unitario']) : 0.0;
            $q = isset($it['cantidad']) ? intval($it['cantidad']) : 1;
            $rawTotal += $p * $q;
        }

        // Aplicar descuento (si existe) sobre el total con IVA
        $discountVal = floatval($discount);
        $totalWithIva = $rawTotal - $discountVal;

        $ivaRate = 0.16;
        // Subtotal sin IVA (base)
        $subtotal = $totalWithIva / (1 + $ivaRate);
        // Importe de impuestos
        $impuestos = $totalWithIva - $subtotal;
        // Total final (con IVA)
        $total = $totalWithIva;

        $userId = $request->user()?->id;

        DB::beginTransaction();
        try {
            $pedidoId = (string) Str::uuid();

            // Capturar datos de dirección enviados por el frontend (pueden venir por partes)
            $direccionEnvio = $request->input('direccion_envio', null);
            $calle = trim($request->input('calle', '')) ?: null;
            $apto = trim($request->input('apto', '')) ?: null;
            $ciudad = trim($request->input('ciudad', '')) ?: null;
            $estado = trim($request->input('estado', '')) ?: null;
            $codigoPostal = trim($request->input('codigo_postal', '')) ?: null;
            $pais = trim($request->input('pais', '')) ?: null;

            $nombre = trim($request->input('nombre', '')) ?: null;
            $apellido = trim($request->input('apellido', '')) ?: null;
            $telefono = trim($request->input('telefono', '')) ?: null;

            // Si el frontend envía las partes de la dirección, validarlas y construir direccion_envio
            $addressPartsProvided = $calle !== null || $ciudad !== null || $codigoPostal !== null || $pais !== null;

            if ($addressPartsProvided) {
                $validator = Validator::make($request->all(), [
                    'calle' => ['required', 'string', 'min:3', 'max:255'],
                    'ciudad' => ['required', 'string', 'min:2', 'max:100'],
                    'codigo_postal' => ['required', 'string', 'min:3', 'max:12'],
                    'pais' => ['required', 'string', 'min:2', 'max:100'],
                    'apto' => ['nullable', 'string', 'max:100'],
                    'estado' => ['nullable', 'string', 'max:100'],
                    'nombre' => ['nullable', 'string', 'min:2', 'max:100'],
                    'apellido' => ['nullable', 'string', 'min:2', 'max:100'],
                    'telefono' => ['nullable', 'string', 'min:7', 'max:20'],
                ]);

                if ($validator->fails()) {
                    return response()->json(['message' => 'Invalid address data', 'errors' => $validator->errors()->all()], 422);
                }

                // Construir direccion_envio solo con las partes de dirección (sin nombre ni teléfono)
                $direccionParts = [];
                $direccionParts[] = $calle;
                if ($apto !== null) $direccionParts[] = $apto;
                $localParts = array_filter([$ciudad, $estado, $codigoPostal, $pais]);
                if (!empty($localParts)) $direccionParts[] = implode(', ', $localParts);
                $direccionEnvio = implode(' • ', $direccionParts);
            } else {
                // Validación mínima si solo se envió direccion_envio concatenada
                $errors = [];
                if ($direccionEnvio === null || strlen(trim($direccionEnvio)) < 5) {
                    $errors[] = 'direccion_envio inválida';
                }
                if ($nombre !== null && strlen($nombre) < 2) $errors[] = 'nombre inválido';
                if ($telefono !== null && strlen($telefono) < 7) $errors[] = 'telefono inválido';
                if (!empty($errors)) {
                    return response()->json(['message' => 'Invalid address data', 'errors' => $errors], 422);
                }
            }

            // direccion_envio almacena toda la info de contacto+dirección (campo TEXT)
            // guia_envio queda null — se usa para número de guía de paquetería (admin lo llena al enviar)
            $contactParts = array_filter([
                ($nombre !== null || $apellido !== null)
                    ? trim(($nombre ?? '') . ' ' . ($apellido ?? ''))
                    : null,
                $direccionEnvio,
                $telefono !== null ? 'Tel: ' . $telefono : null,
            ]);
            $fullShippingInfo = !empty($contactParts)
                ? implode(' • ', $contactParts)
                : $direccionEnvio;

            DB::table('pedidos')->insert([
                'id'              => $pedidoId,
                'id_usuario'      => $userId,
                'id_cupon'        => null,
                'estado'          => 'pendiente',
                'subtotal'        => round($subtotal, 2),
                'descuento'       => $discountVal,
                'total'           => round($total, 2),
                'direccion_envio' => $fullShippingInfo,
                'guia_envio'      => null,
                'creado_en'       => now(),
            ]);

            $stripeLineItems = [];
            foreach ($items as $it) {
                $idProducto = $it['id_producto'] ?? null;
                $cantidad = isset($it['cantidad']) ? intval($it['cantidad']) : 1;
                $precioUnitario = isset($it['precio_unitario']) ? floatval($it['precio_unitario']) : 0.0;

                // Intentar obtener nombre e imagen desde la BD usando id_producto
                $nombre = $it['nombre_producto'] ?? null;
                $imagen = $it['imagen_producto'] ?? null;

                if ($idProducto) {
                    // Nombre desde productos.nombre
                    $prodNombre = DB::table('productos')->where('id', $idProducto)->value('nombre');
                    if ($prodNombre) {
                        $nombre = $prodNombre;
                    }

                    // Imagen principal desde multimedia_producto.url_archivo (si existe es_principal)
                    $img = DB::table('multimedia_producto')
                             ->where('id_producto', $idProducto)
                             ->where('es_principal', true)
                             ->value('url_archivo');
                    if (!$img) {
                        // Fallback: cualquier multimedia para el producto
                        $img = DB::table('multimedia_producto')
                                 ->where('id_producto', $idProducto)
                                 ->value('url_archivo');
                    }
                    if ($img) {
                        $imagen = $img;
                    }
                }

                // Valores por defecto si aún no existen
                $nombre = $nombre ?? ($it['description'] ?? 'Producto');

                DB::table('items_pedido')->insert([
                    'id_pedido' => $pedidoId,
                    'id_producto' => $idProducto,
                    'cantidad' => $cantidad,
                    'precio_unitario' => $precioUnitario,
                    'nombre_producto' => $nombre,
                    'imagen_producto' => $imagen,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);

                // Construir línea para Stripe
                $stripeLineItems[] = [
                    'price_data' => [
                        'currency' => 'mxn',
                        'product_data' => ['name' => $nombre],
                        'unit_amount' => (int) round($precioUnitario * 100),
                    ],
                    'quantity' => $cantidad,
                ];
            }

            // Permitir que el frontend envíe su origin (scheme://host:port) para
            // que la URL de éxito incluya el puerto dinámico usado por Flutter dev server.
            $frontendFromPayload = trim($request->input('frontend', '')) ?: null;
            $frontend = $frontendFromPayload ?? env('FRONTEND_URL', env('APP_URL'));

            $session = Session::create([
                'payment_method_types' => ['card'],
                'line_items' => $stripeLineItems,
                'mode' => 'payment',
                // Usar hash routing para evitar 404 en servidores que no devuelven index.html
                // El fragmento no se envía al servidor, pero el frontend puede leerlo y obtener session_id.
                'success_url' => rtrim($frontend, '/') . '/#/checkout/success?session_id={CHECKOUT_SESSION_ID}',
                'cancel_url' => rtrim($frontend, '/') . '/#/checkout/cancel',
                'metadata' => ['id_pedido' => $pedidoId],
            ]);

            DB::commit();
            return response()->json(['url' => $session->url]);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Stripe Checkout error / DB error: ' . $e->getMessage());
            return response()->json(['message' => 'Error creating checkout session'], 500);
        }
    }

    /**
     * Recupera información de una sesión de Checkout por id.
     * GET /checkout/session/{id}
     */
    public function getCheckoutSession(Request $request, $id)
    {
        try {
            // Intentar expandir payment_intent y line_items
            $session = Session::retrieve($id, ['expand' => ['payment_intent', 'line_items']]);

            $result = [
                'id' => $session->id ?? null,
                'payment_status' => $session->payment_status ?? null,
                'amount_total' => $session->amount_total ?? null,
                'currency' => $session->currency ?? null,
                'payment_intent' => $session->payment_intent ?? null,
                'line_items' => [],
            ];

            // Si la propiedad line_items está disponible y es iterables
            if (isset($session->line_items) && is_iterable($session->line_items->data)) {
                foreach ($session->line_items->data as $li) {
                    $result['line_items'][] = [
                        'description' => $li->description ?? null,
                        'quantity' => $li->quantity ?? 1,
                        'price' => $li->price->unit_amount ?? null,
                        'currency' => $li->price->currency ?? null,
                        'product_name' => $li->price->product ?? null,
                    ];
                }
            }

            return response()->json($result);
        } catch (\Exception $e) {
            Log::error('Stripe retrieve session error: ' . $e->getMessage());
            return response()->json(['message' => 'Error retrieving session: ' . $e->getMessage()], 500);
        }
    }

    /**
     * Diagnóstico de configuración — GET /api/checkout/diagnose
     * Eliminar antes de producción final.
     */
    public function diagnose()
    {
        $result = [];

        // 1. Claves Stripe
        $secret      = config('services.stripe.secret');
        $publishable  = config('services.stripe.key');
        $webhookSec  = config('services.stripe.webhook_secret');
        $result['stripe_secret_set']         = !empty($secret);
        $result['stripe_secret_prefix']      = $secret ? substr($secret, 0, 7) . '...' : null;
        $result['stripe_publishable_set']    = !empty($publishable);
        $result['stripe_publishable_prefix'] = $publishable ? substr($publishable, 0, 7) . '...' : null;
        $result['stripe_webhook_secret_set'] = !empty($webhookSec);

        // 2. Conexión a BD
        try {
            $count = DB::table('pedidos')->count();
            $result['db_connected']    = true;
            $result['pedidos_count']   = $count;
        } catch (\Exception $e) {
            $result['db_connected'] = false;
            $result['db_error']     = $e->getMessage();
        }

        // 3. Llamada real a Stripe
        if (!empty($secret)) {
            try {
                // Listar 1 PaymentIntent para verificar autenticación
                $list = PaymentIntent::all(['limit' => 1]);
                $result['stripe_api_ok'] = true;
            } catch (\Stripe\Exception\AuthenticationException $e) {
                $result['stripe_api_ok']    = false;
                $result['stripe_api_error'] = 'Auth failed: ' . $e->getMessage();
            } catch (\Exception $e) {
                $result['stripe_api_ok']    = false;
                $result['stripe_api_error'] = $e->getMessage();
            }
        } else {
            $result['stripe_api_ok'] = false;
            $result['stripe_api_error'] = 'STRIPE_SECRET not set';
        }

        // 4. Columnas de la tabla pedidos
        try {
            $cols = DB::select("SHOW COLUMNS FROM pedidos");
            $result['pedidos_columns'] = array_column($cols, 'Field');
        } catch (\Exception $e) {
            $result['pedidos_columns_error'] = $e->getMessage();
        }

        return response()->json($result);
    }

    /**
     * Webhook de Stripe — verifica firma si STRIPE_WEBHOOK_SECRET está configurado.
     * Registrar en Stripe Dashboard → Developers → Webhooks:
     *   URL: https://<tu-app>.railway.app/api/stripe/webhook
     *   Eventos: payment_intent.succeeded, checkout.session.completed
     */
    public function webhook(Request $request)
    {
        $payload    = $request->getContent();
        $sigHeader  = $request->header('Stripe-Signature');
        $secret     = config('services.stripe.webhook_secret');

        if ($secret) {
            try {
                $event = \Stripe\Webhook::constructEvent($payload, $sigHeader, $secret);
            } catch (\Stripe\Exception\SignatureVerificationException $e) {
                Log::warning('Stripe webhook: firma inválida — ' . $e->getMessage());
                return response()->json(['error' => 'Invalid signature'], 400);
            } catch (\UnexpectedValueException $e) {
                Log::warning('Stripe webhook: payload inválido — ' . $e->getMessage());
                return response()->json(['error' => 'Invalid payload'], 400);
            }
            // constructEvent devuelve un objeto Stripe\Event; normalizar a array
            $event = $event->toArray();
        } else {
            // Sin secret configurado (desarrollo local) — procesar directamente
            $event = json_decode($payload, true);
            if (!$event) {
                return response()->json(['error' => 'Invalid payload'], 400);
            }
        }

        $type = $event['type'] ?? 'unknown';
        Log::info("Stripe webhook: $type");

        switch ($type) {
            case 'checkout.session.completed':
                $obj      = $event['data']['object'] ?? [];
                $pedidoId = $obj['metadata']['id_pedido'] ?? null;
                if ($pedidoId) {
                    DB::table('pedidos')
                        ->where('id', $pedidoId)
                        ->update(['estado' => 'confirmado']);
                    Log::info("Pedido web confirmado: $pedidoId");
                } else {
                    Log::warning('checkout.session.completed sin metadata.id_pedido');
                }
                break;

            case 'payment_intent.succeeded':
                $obj      = $event['data']['object'] ?? [];
                $pedidoId = $obj['metadata']['id_pedido'] ?? null;
                if ($pedidoId) {
                    DB::table('pedidos')
                        ->where('id', $pedidoId)
                        ->update(['estado' => 'confirmado']);
                    Log::info("Pedido móvil confirmado: $pedidoId");
                } else {
                    Log::info('payment_intent.succeeded sin id_pedido: ' . ($obj['id'] ?? ''));
                }
                break;
        }

        return response()->json(['received' => true]);
    }

    /**
     * Devuelve el número de pedidos del usuario autenticado.
     * GET /pedidos/mis/count
     */
    public function myOrdersCount(Request $request)
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        try {
            $count = DB::table('pedidos')->where('id_usuario', $user->id)->count();
            return response()->json(['count' => $count]);
        } catch (\Exception $e) {
            Log::error('Error counting pedidos for user ' . $user->id . ': ' . $e->getMessage());
            return response()->json(['message' => 'Error retrieving pedidos count'], 500);
        }
    }

    /**
     * GET /pedidos/mis
     * Devuelve la lista de pedidos del usuario autenticado (resumen paginado simple).
     */
    public function myOrdersList(Request $request)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        $page = max(1, intval($request->query('page', 1)));
        $perPage = min(50, max(5, intval($request->query('per_page', 20))));

        try {
            $query = DB::table('pedidos')
                        ->where('id_usuario', $user->id)
                        ->orderBy('creado_en', 'desc');

            $total = $query->count();
            $items = $query->forPage($page, $perPage)->get();

            // Mapear un resumen por pedido incluyendo número de items y primera imagen
            $data = [];
            foreach ($items as $p) {
                $itemsCount = DB::table('items_pedido')->where('id_pedido', $p->id)->count();
                // Obtener hasta 4 imágenes distintas desde items_pedido
                $imagenes = DB::table('items_pedido')
                                ->where('id_pedido', $p->id)
                                ->whereNotNull('imagen_producto')
                                ->pluck('imagen_producto')
                                ->filter()
                                ->unique()
                                ->take(4)
                                ->values()
                                ->all();

                $data[] = [
                    'id' => $p->id,
                    'estado' => $p->estado,
                    'subtotal' => (float) $p->subtotal,
                    'total' => (float) $p->total,
                    'creado_en' => $p->creado_en,
                    'items_count' => $itemsCount,
                    'imagenes' => $imagenes,
                ];
            }

            return response()->json([
                'data' => $data,
                'meta' => ['page' => $page, 'per_page' => $perPage, 'total' => $total],
            ]);
        } catch (\Exception $e) {
            Log::error('Error listing my orders for user ' . $user->id . ': ' . $e->getMessage());
            return response()->json(['message' => 'Error retrieving orders'], 500);
        }
    }

    /**
     * GET /pedidos/mis/{id}
     * Devuelve detalle de un pedido (items, totales, direccion, estado)
     */
    public function myOrderShow(Request $request, $id)
    {
        $user = $request->user();
        if (!$user) return response()->json(['message' => 'Unauthorized'], 401);

        try {
            $pedido = DB::table('pedidos')->where('id', $id)->where('id_usuario', $user->id)->first();
            if (!$pedido) return response()->json(['message' => 'Not found'], 404);

            $items = DB::table('items_pedido')->where('id_pedido', $id)->get();

            $itemsArr = [];
            foreach ($items as $it) {
                // intentar obtener stock actual desde tabla productos
                $stock = DB::table('productos')->where('id', $it->id_producto)->value('inventario');
                $itemsArr[] = [
                    'id_producto' => $it->id_producto,
                    'nombre_producto' => $it->nombre_producto,
                    'imagen_producto' => $it->imagen_producto,
                    'cantidad' => $it->cantidad,
                    'precio_unitario' => (float) $it->precio_unitario,
                    'stock' => is_null($stock) ? null : intval($stock),
                ];
            }

            $impuestos = ((float)$pedido->total) - ((float)$pedido->subtotal);
            return response()->json([
                'id' => $pedido->id,
                'estado' => $pedido->estado,
                'subtotal' => (float) $pedido->subtotal,
                'impuestos' => $impuestos,
                'descuento' => (float) $pedido->descuento,
                'total' => (float) $pedido->total,
                'direccion_envio' => $pedido->direccion_envio,
                'creado_en' => $pedido->creado_en,
                'items' => $itemsArr,
            ]);
        } catch (\Exception $e) {
            Log::error('Error retrieving order ' . $id . ' for user ' . $user->id . ': ' . $e->getMessage());
            return response()->json(['message' => 'Error retrieving order'], 500);
        }
    }
}
