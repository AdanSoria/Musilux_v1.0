<?php

namespace App\Http\Controllers;

use App\Models\Rol;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Listado de roles (provisional — útil durante el registro).
     * GET /api/auth/roles
     */
    public function roles(): JsonResponse
    {
        $roles = Rol::select('id', 'nombre')->get();

        return response()->json(['roles' => $roles]);
    }

    /**
     * Registro de nuevo usuario.
     * POST /api/auth/register
     */
    public function register(Request $request): JsonResponse
    {
        $data = $request->validate([
            'nombres'   => 'required|string|max:100',
            'apellidos' => 'required|string|max:100',
            'correo'    => 'required|email|max:255|unique:usuarios,correo',
            'contrasena'            => [
                'required',
                'string',
                'min:8',
                'confirmed',          // requiere el campo contrasena_confirmation
                'regex:/[A-Z]/',      // al menos una mayúscula
                'regex:/[0-9]/',      // al menos un número
            ],
        ], [
            'nombres.required'   => 'Los nombres son obligatorios.',
            'nombres.max'        => 'Los nombres no pueden superar 100 caracteres.',
            'apellidos.required' => 'Los apellidos son obligatorios.',
            'apellidos.max'      => 'Los apellidos no pueden superar 100 caracteres.',
            'correo.required'    => 'El correo es obligatorio.',
            'correo.email'       => 'El correo no tiene un formato válido.',
            'correo.unique'      => 'El correo ya está registrado.',
            'contrasena.required'  => 'La contraseña es obligatoria.',
            'contrasena.min'       => 'La contraseña debe tener al menos 8 caracteres.',
            'contrasena.confirmed' => 'La confirmación de contraseña no coincide.',
            'contrasena.regex'     => 'La contraseña debe contener al menos una mayúscula y un número.',
        ]);

        $user = User::create([
            'id_rol'          => 2,
            'nombres'         => $data['nombres'],
            'apellidos'       => $data['apellidos'],
            'correo'          => $data['correo'],
            'contrasena_hash' => Hash::make($data['contrasena']),
            'esta_activo'     => true,
        ]);

        // Cargar el rol y sus permisos para incluirlos en la respuesta
        $user->load('rol.permisos');

        $token = $user->createToken('musilux-token')->plainTextToken;

        return response()->json([
            'message' => 'Usuario registrado correctamente.',
            'user'    => $this->formatUser($user),
            'token'   => $token,
        ], 201);
    }

    /**
     * Inicio de sesión.
     * POST /api/auth/login
     */
    public function login(Request $request): JsonResponse
    {
        $request->validate([
            'correo'     => 'required|email',
            'contrasena' => 'required|string',
        ], [
            'correo.required'     => 'El correo es obligatorio.',
            'correo.email'        => 'El correo no tiene un formato válido.',
            'contrasena.required' => 'La contraseña es obligatoria.',
        ]);

        $user = User::where('correo', $request->correo)->first();

        if (! $user || ! Hash::check($request->contrasena, $user->contrasena_hash)) {
            throw ValidationException::withMessages([
                'correo' => ['Las credenciales son incorrectas.'],
            ]);
        }

        if (! $user->esta_activo) {
            return response()->json([
                'message' => 'La cuenta está desactivada. Contacta al administrador.',
            ], 403);
        }

        // Revocar tokens anteriores — una sesión activa por usuario
        $user->tokens()->delete();

        $user->load('rol.permisos');

        $token = $user->createToken('musilux-token')->plainTextToken;

        return response()->json([
            'user'  => $this->formatUser($user),
            'token' => $token,
        ]);
    }

    /**
     * Cierre de sesión (revoca el token actual).
     * POST /api/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Sesión cerrada correctamente.']);
    }

    /**
     * Retorna el usuario autenticado.
     * GET /api/auth/me
     */
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('rol.permisos');

        return response()->json($this->formatUser($user));
    }

    /**
     * Formatea los datos del usuario para la respuesta JSON.
     */
    private function formatUser(User $user): array
    {
        return [
            'id'          => $user->id,
            'id_rol'      => $user->id_rol,
            'rol'         => $user->rol ? $user->rol->nombre : null,
            'permisos'    => $user->rol ? $user->rol->permisos->pluck('nombre') : [],
            'nombres'     => $user->nombres,
            'apellidos'   => $user->apellidos,
            'correo'      => $user->correo,
            'esta_activo' => $user->esta_activo,
            'creado_en'   => $user->creado_en,
        ];
    }
}
