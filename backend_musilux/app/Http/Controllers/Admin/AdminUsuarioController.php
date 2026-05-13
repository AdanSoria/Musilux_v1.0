<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminUsuarioController extends Controller
{
    /**
     * Lista todos los usuarios (clientes) con paginación.
     * GET /api/admin/usuarios
     * Middleware: permiso:usuarios.leer
     */
    public function index(Request $request): JsonResponse
    {
        $usuarios = User::with('rol')
            ->orderBy('creado_en', 'desc')
            ->paginate(20);

        return response()->json($usuarios);
    }

    /**
     * Muestra el detalle de un usuario.
     * GET /api/admin/usuarios/{id}
     * Middleware: permiso:usuarios.leer
     */
    public function show(string $id): JsonResponse
    {
        $usuario = User::with('rol')->findOrFail($id);

        return response()->json($usuario);
    }

    /**
     * Actualiza datos de un usuario (nombres, apellidos, rol, etc.).
     * PUT /api/admin/usuarios/{id}
     * Middleware: permiso:usuarios.actualizar
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $usuario = User::findOrFail($id);

        $data = $request->validate([
            'nombres'   => 'sometimes|string|max:100',
            'apellidos' => 'sometimes|string|max:100',
            'id_rol'    => 'sometimes|integer|exists:roles,id',
        ]);

        $usuario->update($data);

        return response()->json([
            'message' => 'Usuario actualizado correctamente.',
            'usuario' => $usuario->fresh('rol'),
        ]);
    }

    /**
     * Suspende (desactiva) la cuenta de un usuario.
     * DELETE /api/admin/usuarios/{id}
     * Middleware: permiso:usuarios.eliminar
     */
    public function suspender(string $id): JsonResponse
    {
        $usuario = User::findOrFail($id);

        if ($usuario->rol->nombre === 'superadmin') {
            return response()->json([
                'message' => 'No se puede suspender una cuenta de superadmin.',
            ], 403);
        }

        $usuario->update(['esta_activo' => false]);

        // Revocar todos sus tokens activos
        $usuario->tokens()->delete();

        return response()->json([
            'message' => 'Cuenta suspendida correctamente.',
        ]);
    }
}
