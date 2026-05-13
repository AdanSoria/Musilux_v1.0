<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class ReporteController extends Controller
{
    /**
     * Reporte de ingresos.
     * GET /api/admin/reportes/ingresos
     * Middleware: permiso:reportes.leer
     */
    public function ingresos(): JsonResponse
    {
        // TODO: implementar cuando exista el modelo Pedido/Venta
        return response()->json([
            'data'    => [],
            'message' => 'Módulo de reportes en construcción.',
        ]);
    }

    /**
     * Métricas generales del sistema.
     * GET /api/admin/reportes/metricas
     * Middleware: permiso:reportes.leer
     */
    public function metricas(): JsonResponse
    {
        return response()->json([
            'data'    => [],
            'message' => 'Módulo de métricas en construcción.',
        ]);
    }
}
