<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TicketController extends Controller
{
    /**
     * Lista todos los tickets con paginación.
     * GET /api/admin/tickets
     * Middleware: permiso:tickets.leer
     */
    public function index(Request $request): JsonResponse
    {
        $tickets = DB::table('tickets')
            ->join('usuarios', 'tickets.id_usuario', '=', 'usuarios.id')
            ->select(
                'tickets.id',
                'tickets.asunto',
                'tickets.estado',
                'tickets.creado_en',
                'tickets.actualizado_en',
                'usuarios.nombres',
                'usuarios.apellidos',
                'usuarios.correo'
            )
            ->orderBy('tickets.creado_en', 'desc')
            ->paginate(20);

        return response()->json($tickets);
    }

    /**
     * Muestra el detalle de un ticket con sus respuestas.
     * GET /api/admin/tickets/{id}
     * Middleware: permiso:tickets.leer
     */
    public function show(string $id): JsonResponse
    {
        $ticket = DB::table('tickets')->where('id', $id)->first();

        if (! $ticket) {
            return response()->json(['message' => 'Ticket no encontrado.'], 404);
        }

        $respuestas = DB::table('respuestas_ticket')
            ->join('usuarios', 'respuestas_ticket.id_usuario', '=', 'usuarios.id')
            ->select(
                'respuestas_ticket.id',
                'respuestas_ticket.mensaje',
                'respuestas_ticket.creado_en',
                'usuarios.nombres',
                'usuarios.apellidos'
            )
            ->where('respuestas_ticket.id_ticket', $id)
            ->orderBy('respuestas_ticket.creado_en')
            ->get();

        return response()->json([
            'ticket'     => $ticket,
            'respuestas' => $respuestas,
        ]);
    }

    /**
     * Agrega una respuesta a un ticket.
     * POST /api/admin/tickets/{id}/respuestas
     * Middleware: permiso:tickets.crear,tickets.actualizar
     */
    public function responder(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'mensaje' => 'required|string|max:2000',
        ]);

        $ticket = DB::table('tickets')->where('id', $id)->first();

        if (! $ticket) {
            return response()->json(['message' => 'Ticket no encontrado.'], 404);
        }

        DB::table('respuestas_ticket')->insert([
            'id'          => \Illuminate\Support\Str::uuid(),
            'id_ticket'   => $id,
            'id_usuario'  => $request->user()->id,
            'mensaje'     => $request->mensaje,
        ]);

        // Si estaba abierto, pasar a en_proceso automáticamente
        if ($ticket->estado === 'abierto') {
            DB::table('tickets')->where('id', $id)->update(['estado' => 'en_proceso']);
        }

        return response()->json(['message' => 'Respuesta agregada correctamente.'], 201);
    }

    /**
     * Actualiza el estado de un ticket.
     * PUT /api/admin/tickets/{id}/estado
     * Middleware: permiso:tickets.crear,tickets.actualizar
     */
    public function actualizarEstado(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'estado' => 'required|in:abierto,en_proceso,resuelto,cerrado',
        ]);

        $affected = DB::table('tickets')
            ->where('id', $id)
            ->update(['estado' => $request->estado]);

        if (! $affected) {
            return response()->json(['message' => 'Ticket no encontrado.'], 404);
        }

        return response()->json(['message' => 'Estado actualizado correctamente.']);
    }
}
