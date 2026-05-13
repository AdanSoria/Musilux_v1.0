<?php

namespace App\Http\Controllers;

use App\Models\Rol;
use Illuminate\Http\JsonResponse;

class RolController extends Controller
{
    /**
     * Lista todos los roles disponibles.
     * GET /api/roles
     */
    public function index(): JsonResponse
    {
        $roles = Rol::select('id', 'nombre')->get();

        return response()->json(['roles' => $roles]);
    }
}
