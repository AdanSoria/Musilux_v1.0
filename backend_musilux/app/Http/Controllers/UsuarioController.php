<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class UsuarioController extends Controller
{
    /**
     * Cambiar contraseña del usuario autenticado.
     * POST /api/usuario/cambiar-contrasena
     */
    public function cambiarContrasena(Request $request): JsonResponse
    {
        $user = auth()->user();

        if (!$user) {
            return response()->json([
                'message' => 'No autorizado.',
            ], 401);
        }

        try {
            $request->validate([
                'contrasena_actual' => 'required|string',
                'contrasena_nueva' => [
                    'required',
                    'string',
                    'min:6',
                    'different:contrasena_actual',
                ],
                'contrasena_confirmacion' => 'required|string|same:contrasena_nueva',
            ], [
                'contrasena_actual.required' => 'La contraseña actual es obligatoria.',
                'contrasena_nueva.required' => 'La nueva contraseña es obligatoria.',
                'contrasena_nueva.min' => 'La nueva contraseña debe tener al menos 6 caracteres.',
                'contrasena_nueva.different' => 'La nueva contraseña debe ser diferente a la actual.',
                'contrasena_confirmacion.required' => 'La confirmación de contraseña es obligatoria.',
                'contrasena_confirmacion.same' => 'Las contraseñas no coinciden.',
            ]);

            // Verificar que la contraseña actual sea correcta
            if (!Hash::check($request->contrasena_actual, $user->contrasena_hash)) {
                return response()->json([
                    'message' => 'La contraseña actual es incorrecta.',
                ], 422);
            }

            // Actualizar la contraseña
            $user->update([
                'contrasena_hash' => Hash::make($request->contrasena_nueva),
            ]);

            return response()->json([
                'message' => 'Contraseña actualizada correctamente.',
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Errores de validación.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al cambiar la contraseña.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Actualizar información de dirección del usuario autenticado.
     * PUT /api/usuario/direccion
     */
    public function actualizarDireccion(Request $request): JsonResponse
    {
        $user = auth()->user();

        if (!$user) {
            return response()->json([
                'message' => 'No autorizado.',
            ], 401);
        }

        try {
            $request->validate([
                'direccion' => 'required|string|max:255',
                'departamento' => 'required|string|max:100',
                'municipio' => 'required|string|max:100',
                'codigo_postal' => 'nullable|string|max:20',
            ], [
                'direccion.required' => 'La dirección es obligatoria.',
                'direccion.max' => 'La dirección no puede superar 255 caracteres.',
                'departamento.required' => 'El departamento es obligatorio.',
                'departamento.max' => 'El departamento no puede superar 100 caracteres.',
                'municipio.required' => 'El municipio es obligatorio.',
                'municipio.max' => 'El municipio no puede superar 100 caracteres.',
                'codigo_postal.max' => 'El código postal no puede superar 20 caracteres.',
            ]);

            // Actualizar la información de dirección
            $user->update([
                'direccion' => $request->direccion,
                'departamento' => $request->departamento,
                'municipio' => $request->municipio,
                'codigo_postal' => $request->codigo_postal,
            ]);

            return response()->json([
                'message' => 'Dirección actualizada correctamente.',
                'user' => [
                    'direccion' => $user->direccion,
                    'departamento' => $user->departamento,
                    'municipio' => $user->municipio,
                    'codigo_postal' => $user->codigo_postal,
                ],
            ], 200);
        } catch (ValidationException $e) {
            return response()->json([
                'message' => 'Errores de validación.',
                'errors' => $e->errors(),
            ], 422);
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Error al actualizar la dirección.',
                'error' => $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Obtener información del usuario autenticado.
     * GET /api/usuario/perfil
     */
    public function perfil(): JsonResponse
    {
        $user = auth()->user();

        if (!$user) {
            return response()->json([
                'message' => 'No autorizado.',
            ], 401);
        }

        return response()->json([
            'user' => [
                'id' => $user->id,
                'nombres' => $user->nombres,
                'apellidos' => $user->apellidos,
                'correo' => $user->correo,
                'direccion' => $user->direccion,
                'departamento' => $user->departamento,
                'municipio' => $user->municipio,
                'codigo_postal' => $user->codigo_postal,
                'esta_activo' => $user->esta_activo,
            ],
        ], 200);
    }
}
