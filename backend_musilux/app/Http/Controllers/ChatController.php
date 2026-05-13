<?php

namespace App\Http\Controllers;

use App\Models\ChatIa;
use App\Models\MensajeChatIa;
use App\Services\GeminiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ChatController extends Controller
{
    public function __construct(private readonly GeminiService $gemini) {}

    // ──────────────────────────────────────────────────────────────────────────
    // POST /api/chat
    // Recibe el mensaje del usuario, genera respuesta con la IA y persiste ambos.
    // ──────────────────────────────────────────────────────────────────────────
    public function enviarMensaje(Request $request): JsonResponse
    {
        $request->validate([
            'mensaje'   => ['required', 'string', 'min:1', 'max:2000'],
            'id_sesion' => ['nullable', 'uuid'],
        ]);

        $usuario = $request->user();

        // ── Buscar o crear sesión de chat ────────────────────────────────────
        if ($request->filled('id_sesion')) {
            // La sesión DEBE pertenecer al usuario autenticado
            $chat = ChatIa::where('id', $request->id_sesion)
                ->where('id_usuario', $usuario->id)
                ->firstOrFail();
        } else {
            $chat = ChatIa::create([
                'id_usuario' => $usuario->id,
                'titulo'     => mb_substr($request->mensaje, 0, 80),
            ]);
        }

        // ── Cargar historial previo (últimos 20 mensajes para contexto) ───────
        $historial = MensajeChatIa::where('id_chat', $chat->id)
            ->orderBy('creado_en')
            ->limit(20)
            ->get(['rol', 'contenido'])
            ->toArray();

        DB::beginTransaction();

        try {
            // Persistir mensaje del usuario
            MensajeChatIa::create([
                'id_chat'   => $chat->id,
                'rol'       => 'usuario',
                'contenido' => $request->mensaje,
            ]);

            // Generar respuesta de la IA
            $respuesta = $this->gemini->generateResponse($historial, $request->mensaje, $usuario);

            // Persistir respuesta del asistente
            MensajeChatIa::create([
                'id_chat'   => $chat->id,
                'rol'       => 'asistente',
                'contenido' => $respuesta,
            ]);

            // Actualizar timestamp de la sesión para ordenamiento
            $chat->touch();

            DB::commit();

            return response()->json([
                'id_sesion' => $chat->id,
                'respuesta' => $respuesta,
            ]);
        } catch (\Throwable $e) {
            DB::rollBack();

            return response()->json([
                'message' => $e->getMessage(),
            ], 503);
        }
    }

    // ──────────────────────────────────────────────────────────────────────────
    // GET /api/chat/history?id_sesion={uuid}
    // Con id_sesion: devuelve los mensajes de esa sesión.
    // Sin id_sesion: devuelve la lista de sesiones del usuario (últimas 20).
    // ──────────────────────────────────────────────────────────────────────────
    public function historial(Request $request): JsonResponse
    {
        $request->validate([
            'id_sesion' => ['nullable', 'uuid'],
        ]);

        $usuario = $request->user();

        if ($request->filled('id_sesion')) {
            $chat = ChatIa::where('id', $request->id_sesion)
                ->where('id_usuario', $usuario->id)
                ->with(['mensajes' => fn ($q) => $q->orderBy('creado_en')])
                ->firstOrFail();

            return response()->json([
                'id_sesion' => $chat->id,
                'titulo'    => $chat->titulo,
                'mensajes'  => $chat->mensajes,
            ]);
        }

        // Lista de sesiones del usuario — más reciente primero
        $sesiones = ChatIa::where('id_usuario', $usuario->id)
            ->orderByDesc('actualizado_en')
            ->limit(20)
            ->get(['id', 'titulo', 'actualizado_en']);

        return response()->json(['sesiones' => $sesiones]);
    }
}
