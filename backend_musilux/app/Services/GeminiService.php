<?php

namespace App\Services;

use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class GeminiService
{
    /**
     * Base URL de la API de Gemini. El modelo se selecciona dinámicamente
     * con fallback automático si uno agota su cuota.
     */
    private const API_BASE = 'https://generativelanguage.googleapis.com/v1beta/models';

    /**
     * Modelos en orden de preferencia. Si uno falla (cuota, 404, 503),
     * se intenta el siguiente automáticamente.
     */
    private const MODELS = [
        'gemini-flash-latest',    // Alias siempre actualizado — primer intento
        'gemini-2.0-flash',       // Flash más reciente con nombre explícito
        'gemini-1.5-flash-8b',    // Más ligero, cuota independiente
    ];

    /**
     * Instrucción de sistema base que define la personalidad del bot.
     */
    private const SYSTEM_BASE = 'Eres el asistente virtual de Musilux. Tu objetivo es ayudar '
        . 'a los clientes con dudas sobre productos musicales y el estado de sus pedidos '
        . 'o tickets de soporte. Responde siempre en español, de forma amable, concisa y '
        . 'profesional. Usa únicamente la información del inventario y pedidos que se te '
        . 'proporciona — no inventes datos. Si no tienes información suficiente, indícalo '
        . 'con cortesía y ofrece contactar al equipo de soporte.';

    /**
     * Genera una respuesta a partir del historial de conversación y el contexto
     * del usuario autenticado (inventario, pedidos, tickets).
     *
     * @param  array<int, array{rol: string, contenido: string}>  $historial
     */
    public function generateResponse(array $historial, string $mensajeUsuario, User $usuario): string
    {
        $apiKey = config('services.gemini.api_key');

        if (empty($apiKey)) {
            throw new \RuntimeException('La clave GEMINI_API_KEY no está configurada en el servidor.');
        }

        // ── Construir instrucción de sistema con contexto dinámico ─────────────
        $systemInstruction = self::SYSTEM_BASE . "\n\n" . $this->buildContexto($usuario);

        // ── Transformar historial al formato de Gemini ──────────────────────────
        // Tomamos los últimos 10 turnos para no agotar tokens.
        $contents = [];

        foreach (array_slice($historial, -10) as $msg) {
            $contents[] = [
                'role'  => $msg['rol'] === 'usuario' ? 'user' : 'model',
                'parts' => [['text' => $msg['contenido']]],
            ];
        }

        // Agregar el mensaje nuevo del usuario
        $contents[] = [
            'role'  => 'user',
            'parts' => [['text' => $mensajeUsuario]],
        ];

        // ── Payload para la API de Gemini ───────────────────────────────────────
        $payload = [
            'system_instruction' => [
                'parts' => [['text' => $systemInstruction]],
            ],
            'contents'         => $contents,
            'generationConfig' => [
                'temperature'     => 0.7,
                'maxOutputTokens' => 1024,
                'topP'            => 0.9,
            ],
            'safetySettings' => [
                ['category' => 'HARM_CATEGORY_HARASSMENT',        'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'],
                ['category' => 'HARM_CATEGORY_HATE_SPEECH',       'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'],
                ['category' => 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'],
                ['category' => 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold' => 'BLOCK_MEDIUM_AND_ABOVE'],
            ],
        ];

        // ── Llamada HTTP con fallback entre modelos ─────────────────────────────
        $lastError  = null;
        $lastStatus = null;

        foreach (self::MODELS as $model) {
            $url = self::API_BASE . "/{$model}:generateContent?key={$apiKey}";

            $response = Http::timeout(30)
                ->withHeaders(['Content-Type' => 'application/json'])
                ->post($url, $payload);

            if ($response->successful()) {
                $data = $response->json();
                return $data['candidates'][0]['content']['parts'][0]['text']
                    ?? 'No pude generar una respuesta. Por favor, intenta de nuevo.';
            }

            $lastStatus = $response->status();
            $lastError  = $response->body();

            // Detener inmediatamente en errores de autenticación — ningún modelo ayudará.
            if (in_array($lastStatus, [400, 401, 403])) {
                break;
            }

            // Para cuota agotada (429), modelo no encontrado (404) o servidor caído (500/503),
            // intentar el siguiente modelo de la lista.
            Log::warning("GeminiService: modelo {$model} falló ({$lastStatus}), probando siguiente.", [
                'status' => $lastStatus,
            ]);
        }

        Log::error('GeminiService: todos los modelos fallaron', [
            'status' => $lastStatus,
            'body'   => $lastError,
        ]);

        throw new \RuntimeException(
            'El servicio de IA no está disponible en este momento. Intente de nuevo en unos minutos.'
        );
    }

    // ── Contexto dinámico ───────────────────────────────────────────────────────

    /**
     * Construye un bloque de texto con el inventario activo y los pedidos/tickets
     * del usuario, para inyectarlo en la instrucción de sistema.
     */
    private function buildContexto(User $usuario): string
    {
        $bloques = [];

        // ── Inventario ──────────────────────────────────────────────────────────
        $productos = Product::where('esta_activo', true)
            ->with('category:id,nombre')
            ->select('nombre', 'precio', 'inventario', 'descripcion', 'tipo_producto', 'id_categoria')
            ->get();

        if ($productos->isNotEmpty()) {
            $lineas = ['=== INVENTARIO ACTUAL ==='];
            foreach ($productos as $p) {
                $cat = $p->category->nombre ?? 'Sin categoría';
                $lineas[] = sprintf(
                    '• %s | Categoría: %s | Precio: $%.2f MXN | Stock: %d | Tipo: %s',
                    $p->nombre,
                    $cat,
                    $p->precio,
                    $p->inventario,
                    $p->tipo_producto
                );
            }
            $bloques[] = implode("\n", $lineas);
        }

        // ── Pedidos del usuario ─────────────────────────────────────────────────
        $pedidos = DB::table('pedidos')
            ->where('id_usuario', $usuario->id)
            ->orderByDesc('creado_en')
            ->limit(5)
            ->select('id', 'estado', 'total', 'creado_en', 'guia_envio', 'direccion_envio')
            ->get();

        if ($pedidos->isNotEmpty()) {
            $lineas = [sprintf('=== PEDIDOS DE %s ===', mb_strtoupper($usuario->nombres))];
            foreach ($pedidos as $pedido) {
                $guia       = $pedido->guia_envio    ? " | Guía: {$pedido->guia_envio}"            : '';
                $direccion  = $pedido->direccion_envio ? " | Dirección: {$pedido->direccion_envio}" : '';
                $lineas[] = sprintf(
                    '• Pedido #%s | Estado: %s | Total: $%.2f | Fecha: %s%s%s',
                    substr($pedido->id, 0, 8),
                    $pedido->estado,
                    (float) $pedido->total,
                    substr($pedido->creado_en, 0, 10),
                    $guia,
                    $direccion
                );
            }
            $bloques[] = implode("\n", $lineas);
        }

        // ── Tickets abiertos ────────────────────────────────────────────────────
        $tickets = DB::table('tickets')
            ->where('id_usuario', $usuario->id)
            ->whereIn('estado', ['abierto', 'en_proceso'])
            ->orderByDesc('creado_en')
            ->limit(3)
            ->select('id', 'asunto', 'estado', 'creado_en')
            ->get();

        if ($tickets->isNotEmpty()) {
            $lineas = ['=== TICKETS DE SOPORTE ACTIVOS ==='];
            foreach ($tickets as $ticket) {
                $lineas[] = sprintf(
                    '• Ticket #%s | Asunto: %s | Estado: %s | Fecha: %s',
                    substr($ticket->id, 0, 8),
                    $ticket->asunto,
                    $ticket->estado,
                    substr($ticket->creado_en, 0, 10)
                );
            }
            $bloques[] = implode("\n", $lineas);
        }

        return implode("\n\n", $bloques);
    }
}
