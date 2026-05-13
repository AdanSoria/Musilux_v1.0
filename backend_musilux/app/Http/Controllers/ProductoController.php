<?php

namespace App\Http\Controllers;

use App\Models\Product; // Corregido: El modelo se llama Product, no Producto
use App\Http\Resources\ProductResource; // Importamos el Resource
use Illuminate\Http\Request;
use Illuminate\Support\Str; // Para generar el slug

class ProductoController extends Controller
{
    public function index(Request $request)
    {
        // Eager loading para evitar N+1 queries y mejorar rendimiento
        $query = Product::with(['tags', 'multimedia'])->where('esta_activo', true);

        // Filtrado por categoría si se provee el slug en la URL (?category=guitarras)
        if ($request->has('category')) {
            $query->whereHas('category', function ($q) use ($request) {
                $q->where('slug', $request->category);
            });
        }

        $productos = $query->get();

        // Usamos el API Resource para una respuesta estandarizada (con wrapper 'data')
        // que la app Flutter espera.
        return ProductResource::collection($productos);
    }

    public function store(Request $request)
    {
        // Validaciones según tu esquema SQL
        // NOTA: El frontend no está enviando 'id_categoria', lo que causará un error.
        // Se debe agregar un selector de categoría en el formulario de admin en Flutter.
        $request->validate([
            'id_categoria' => 'required|exists:categorias,id',
            'nombre' => 'required|string|max:200',
            'tipo_producto' => 'required|in:fisico,digital,servicio',
            'precio' => 'required|numeric|min:0',
            'inventario' => 'integer|min:0',
        ]);

        $data = $request->all();

        // Generar Slug automáticamente basado en el nombre
        $data['slug'] = Str::slug($request->nombre) . '-' . uniqid();

        // Asignar valor por defecto si es digital (inventario 0 según tu comentario SQL)
        if ($data['tipo_producto'] === 'digital') {
            $data['inventario'] = 0;
        }

        $producto = Product::create($data);

        // TODO: Aquí se debería manejar la lógica para guardar imágenes, tags, etc.

        // Retornamos el nuevo producto usando el Resource para una respuesta consistente
        return (new ProductResource($producto->load(['tags', 'multimedia'])))
            ->response()
            ->setStatusCode(201);
    }

    public function show($id)
    {
        // Eager loading para todas las relaciones necesarias en la vista de detalle
        $producto = Product::with(['tags', 'especificaciones', 'multimedia', 'category'])->find($id);

        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }
        // Usamos el API Resource para una respuesta detallada y estandarizada
        return new ProductResource($producto);
    }

    public function update(Request $request, $id)
    {
        $producto = Product::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        // Si actualizan el nombre, actualizamos el slug
        $data = $request->all();
        if ($request->filled('nombre')) {
            $data['slug'] = Str::slug($request->nombre) . '-' . uniqid();
        }

        $producto->update($data);
        // Devolvemos el recurso actualizado, cargando las relaciones
        return new ProductResource($producto->fresh()->load(['tags', 'especificaciones', 'multimedia', 'category']));
    }

    public function destroy($id)
    {
        $producto = Product::find($id);
        if (!$producto) {
            return response()->json(['message' => 'Producto no encontrado'], 404);
        }

        // Opción A: Borrado físico (DELETE FROM...)
        $producto->delete();

        // Opción B: Borrado lógico (RECOMENDADO para mantener integridad de datos)
        // Esto simplemente lo "oculta" de las vistas públicas.
        // $producto->update(['esta_activo' => false]);

        return response()->json(null, 204); // 204 No Content es una respuesta estándar para un DELETE exitoso.
    }
}
