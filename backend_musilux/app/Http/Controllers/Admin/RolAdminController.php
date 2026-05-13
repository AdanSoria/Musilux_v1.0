<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Permiso;
use App\Models\Rol;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RolAdminController extends Controller
{
    /**
     * Lista todos los roles con sus permisos.
     * GET /api/admin/roles
     * Middleware: permiso:roles.leer,roles.crear,roles.actualizar,roles.eliminar
     */
    public function index(): JsonResponse
    {
        $roles = Rol::with('permisos')->get();

        return response()->json(['roles' => $roles]);
    }

    /**
     * Crea un nuevo rol.
     * POST /api/admin/roles
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nombre' => 'required|string|max:50|unique:roles,nombre',
        ]);

        $rol = Rol::create($data);

        return response()->json([
            'message' => 'Rol creado correctamente.',
            'rol'     => $rol,
        ], 201);
    }

    /**
     * Actualiza el nombre de un rol.
     * PUT /api/admin/roles/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $rol = Rol::findOrFail($id);

        // Proteger roles del sistema
        if ($id <= 8) {
            return response()->json([
                'message' => 'Los roles del sistema no pueden modificarse.',
            ], 403);
        }

        $data = $request->validate([
            'nombre' => "required|string|max:50|unique:roles,nombre,{$id}",
        ]);

        $rol->update($data);

        return response()->json([
            'message' => 'Rol actualizado correctamente.',
            'rol'     => $rol,
        ]);
    }

    /**
     * Elimina un rol (solo roles custom, no del sistema).
     * DELETE /api/admin/roles/{id}
     */
    public function destroy(int $id): JsonResponse
    {
        if ($id <= 8) {
            return response()->json([
                'message' => 'Los roles del sistema no pueden eliminarse.',
            ], 403);
        }

        Rol::findOrFail($id)->delete();

        return response()->json(['message' => 'Rol eliminado correctamente.']);
    }

    /**
     * Asigna permisos a un rol (reemplaza los existentes).
     * POST /api/admin/roles/{id}/permisos
     */
    public function asignarPermisos(Request $request, int $id): JsonResponse
    {
        $rol = Rol::findOrFail($id);

        $request->validate([
            'permisos'   => 'required|array',
            'permisos.*' => 'integer|exists:permisos,id',
        ]);

        $rol->permisos()->sync(
            collect($request->permisos)->mapWithKeys(fn($pid) => [$pid => []])
        );

        return response()->json([
            'message'  => 'Permisos asignados correctamente.',
            'permisos' => $rol->permisos()->pluck('nombre'),
        ]);
    }
}
