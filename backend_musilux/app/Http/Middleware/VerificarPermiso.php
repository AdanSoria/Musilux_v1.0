<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class VerificarPermiso
{
    /**
     * Verifica que el usuario autenticado tenga al menos uno de los permisos
     * requeridos. El superadmin siempre pasa.
     *
     * Uso en rutas:  ->middleware('permiso:productos.crear,productos.actualizar')
     */
    public function handle(Request $request, Closure $next, string ...$permisos): mixed
    {
        $usuario = $request->user();

        if (! $usuario) {
            return response()->json(['message' => 'No autenticado.'], 401);
        }

        $usuario->loadMissing('rol.permisos');

        // Superadmin: acceso total
        if ($usuario->rol->nombre === 'superadmin') {
            return $next($request);
        }

        // Verificar si tiene al menos uno de los permisos requeridos
        foreach ($permisos as $permiso) {
            if ($usuario->tienePermiso($permiso)) {
                return $next($request);
            }
        }

        return response()->json([
            'message'  => 'No tienes permiso para realizar esta acción.',
            'required' => $permisos,
        ], 403);
    }
}
