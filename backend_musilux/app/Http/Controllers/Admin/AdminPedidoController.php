<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pedido;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminPedidoController extends Controller
{
    /**
     * Lista todos los pedidos con paginación.
     * GET /api/admin/pedidos
     * Middleware: permiso:pedidos.leer
     */
    public function index(Request $request): JsonResponse
    {
        $pedidos = Pedido::with(['usuario', 'items'])
            ->orderBy('creado_en', 'desc')
            ->paginate(20);

        return response()->json($pedidos);
    }

    /**
     * Muestra el detalle de un pedido.
     * GET /api/admin/pedidos/{id}
     * Middleware: permiso:pedidos.leer
     */
    public function show(string $id): JsonResponse
    {
        $pedido = Pedido::with(['usuario', 'items'])
            ->find($id);

        if (! $pedido) {
            return response()->json(['message' => 'Pedido no encontrado.'], 404);
        }

        return response()->json($pedido);
    }

    /**
     * Actualiza el estado o la guía de envío de un pedido.
     * PUT /api/admin/pedidos/{id}/estado
     * Middleware: permiso:pedidos.actualizar
     */
    public function actualizarEstado(Request $request, string $id): JsonResponse
    {
        $request->validate([
            'estado'     => ['sometimes', 'string', Rule::in([
                'pendiente',
                'confirmado',
                'en_preparacion',
                'enviado',
                'entregado',
                'cancelado',
            ])],
            'guia_envio' => 'sometimes|nullable|string|max:100',
        ]);

        $pedido = Pedido::find($id);

        if (! $pedido) {
            return response()->json(['message' => 'Pedido no encontrado.'], 404);
        }

        $pedido->fill($request->only(['estado', 'guia_envio']));
        $pedido->save();

        return response()->json([
            'message' => 'Pedido actualizado correctamente.',
            'pedido'  => $pedido->fresh(['usuario', 'items']),
        ]);
    }
}
