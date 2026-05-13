<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CuponController extends Controller
{
    /**
     * Lista todos los cupones.
     * GET /api/admin/cupones
     * Middleware: permiso:cupones.leer,cupones.crear,cupones.actualizar
     */
    public function index(): JsonResponse
    {
        // TODO: implementar cuando exista el modelo Cupon
        return response()->json([
            'data'    => [],
            'message' => 'Módulo de cupones en construcción.',
        ]);
    }

    /**
     * Crea un nuevo cupón.
     * POST /api/admin/cupones
     * Middleware: permiso:cupones.crear,cupones.actualizar
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'codigo'    => 'required|string|max:50|unique:cupones,codigo',
            'descuento' => 'required|numeric|min:0|max:100',
            'tipo'      => 'required|in:porcentaje,fijo',
        ]);

        // TODO: crear el modelo Cupon y la tabla
        return response()->json([
            'message' => 'Cupón creado (módulo en construcción).',
        ], 201);
    }

    /**
     * Actualiza un cupón existente.
     * PUT /api/admin/cupones/{id}
     * Middleware: permiso:cupones.crear,cupones.actualizar
     */
    public function update(Request $request, int $id): JsonResponse
    {
        return response()->json([
            'message' => 'Cupón actualizado (módulo en construcción).',
        ]);
    }
}
