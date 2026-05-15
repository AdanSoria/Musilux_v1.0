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
     * Crea un PaymentIntent a partir del total enviado desde el frontend.
     * Request JSON esperado: { "amount": 123.45 }
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
        ]);

    // Stripe espera el monto en centavos (integer)
    $amountFloat = $request->input('amount');
    $amount = (int) round($amountFloat * 100);

        try {
            $pi = PaymentIntent::create([
                'amount' => $amount,
                // Usar MXN (pesos mexicanos). Cambia si necesitas otra moneda.
                'currency' => 'mxn',
                'automatic_payment_methods' => ['enabled' => true],
                // metadata opcional: puedes incluir user id, orden id, etc.
                'metadata' => [
                    'platform' => 'musilux',
                ],
            ]);

            return response()->json([
                'client_secret' => $pi->client_secret,
                'publishableKey' => config('services.stripe.key'),
            ]);
        } catch (\Exception $e) {
            Log::error('Stripe createPaymentIntent error: ' . $e->getMessage());
            return response()->json(['message' => 'Error creating payment intent'], 500);
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

            // Construir guia_envio: "Nombre Apellido • Dirección • Tel: ..." (si hay nombre/telefono)
            $guiaParts = [];
            if ($nombre !== null || $apellido !== null) {
                $fullName = trim(($nombre ?? '') . ' ' . ($apellido ?? ''));
                if ($fullName !== '') $guiaParts[] = $fullName;
            }
            if ($direccionEnvio !== null) $guiaParts[] = $direccionEnvio;
            if ($telefono !== null) $guiaParts[] = 'Tel: ' . $telefono;
            $guiaEnvio = !empty($guiaParts) ? implode(' • ', $guiaParts) : null;

            DB::table('pedidos')->insert([
                'id' => $pedidoId,
                'id_usuario' => $userId,
                'id_cupon' => null,
                'estado' => 'pendiente',
                'subtotal' => round($subtotal, 2),
                'descuento' => $discountVal,
                'total' => round($total, 2),
                'direccion_envio' => $direccionEnvio,
                'guia_envio' => $guiaEnvio,
                'creado_en' => now(),
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
     * Webhook básico para recibir eventos de Stripe (opcional)
     */
    public function webhook(Request $request)
    {
        // Por simplicidad procesamos el payload directamente. En producción usar Stripe\Webhook y verificar signature.
        $payload = $request->getContent();
        $event = json_decode($payload, true);
        Log::info('Stripe webhook received', $event ?? []);

        // Manejar eventos relevantes
        if (isset($event['type'])) {
            switch ($event['type']) {
                case 'checkout.session.completed':
                    // Cuando Checkout completa, buscar metadata.id_pedido y marcar confirmado
                    $session = $event['data']['object'] ?? null;
                    $pedidoId = $session['metadata']['id_pedido'] ?? null;
                    if ($pedidoId) {
                        DB::table('pedidos')->where('id', $pedidoId)->update(['estado' => 'confirmado', 'actualizado_en' => now()]);
                        Log::info('Pedido marcado como confirmado: ' . $pedidoId);
                    } else {
                        Log::warning('checkout.session.completed sin metadata.id_pedido');
                    }
                    break;
                case 'payment_intent.succeeded':
                    Log::info('PaymentIntent succeeded: ' . ($event['data']['object']['id'] ?? ''));
                    break;
            }
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
