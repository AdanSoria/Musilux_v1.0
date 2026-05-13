<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\ProductMedia;
use Illuminate\Http\Request;
use App\Http\Resources\ProductListResource;
use App\Http\Resources\ProductDetailResource;
use Illuminate\Validation\Rule;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::with(['multimedia']);

        if ($request->has('category')) {
            $query->whereHas('category', function ($q) use ($request) {
                $q->where('slug', $request->category);
            });
        }

        return ProductListResource::collection($query->get());
    }

    public function show(string $id)
    {
        $product = Product::with(['multimedia', 'category', 'tags'])->findOrFail($id);
        return new ProductDetailResource($product);
    }

    /**
     * Returns up to 4 products related to $id, ranked by:
     *   +3 same category, +2 per shared tag, +1 similar price (±30%).
     */
    public function related(string $id)
    {
        $product = Product::with(['tags'])->findOrFail($id);

        $tagIds   = $product->tags->pluck('id')->toArray();
        $priceMin = $product->precio * 0.70;
        $priceMax = $product->precio * 1.30;

        $ranked = Product::with(['multimedia', 'tags'])
            ->where('id', '!=', $id)
            ->where('esta_activo', true)
            ->get()
            ->map(function ($c) use ($product, $tagIds, $priceMin, $priceMax) {
                $score = 0;
                if ($c->id_categoria === $product->id_categoria) $score += 3;
                $score += $c->tags->whereIn('id', $tagIds)->count() * 2;
                if ($c->precio >= $priceMin && $c->precio <= $priceMax) $score += 1;
                return ['model' => $c, 'score' => $score];
            })
            ->filter(fn($item) => $item['score'] > 0)
            ->sortByDesc('score')
            ->take(4)
            ->pluck('model')
            ->values();

        return ProductListResource::collection($ranked);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'id_categoria'         => 'nullable|integer|exists:categorias,id',
            'nombre'               => 'required|string|max:255',
            'descripcion'          => 'nullable|string',
            'tipo_producto'        => ['required', 'string', Rule::in(['fisico', 'digital', 'servicio'])],
            'precio'               => 'required|numeric|min:0',
            'inventario'           => 'required|integer|min:0',
            'bpm'                  => 'nullable|integer',
            'esta_activo'          => 'boolean',
            'youtube_video_id'  => 'nullable|string|max:20',
            'youtube_title'     => 'nullable|string|max:255',
            'youtube_channel'   => 'nullable|string|max:255',
            'youtube_thumbnail' => 'nullable|string|max:500',
            // Imagen principal (retrocompatibilidad)
            'imagen_url'           => 'nullable|string|max:2048',
            // Soporte para múltiples imágenes adicionales
            'imagenes_urls'        => 'nullable|array|max:8',
            'imagenes_urls.*'      => 'string|max:2048',
        ]);

        $data['slug'] = Str::slug($data['nombre']) . '-' . uniqid();

        if (empty($data['id_categoria'])) {
            $data['id_categoria'] = 1;
        }

        if (($data['tipo_producto'] ?? '') === 'digital') {
            $data['inventario'] = 0;
        }

        $imagenUrl    = $data['imagen_url'] ?? null;
        $imagenesUrls = $data['imagenes_urls'] ?? [];
        unset($data['imagen_url'], $data['imagenes_urls']);

        $product = Product::create($data);

        // Imagen principal
        if ($imagenUrl) {
            ProductMedia::create([
                'id_producto'     => $product->id,
                'tipo_multimedia' => 'imagen',
                'url_archivo'     => $imagenUrl,
                'es_principal'    => true,
            ]);
        }

        // Imágenes adicionales (ninguna es principal)
        foreach ($imagenesUrls as $url) {
            if ($url && $url !== $imagenUrl) {
                ProductMedia::create([
                    'id_producto'     => $product->id,
                    'tipo_multimedia' => 'imagen',
                    'url_archivo'     => $url,
                    'es_principal'    => false,
                ]);
            }
        }

        return (new ProductDetailResource($product->load(['multimedia', 'category', 'tags'])))
            ->response()
            ->setStatusCode(201);
    }

    public function update(Request $request, string $id)
    {
        $product = Product::findOrFail($id);

        $data = $request->validate([
            'id_categoria'         => 'nullable|exists:categorias,id',
            'nombre'               => 'required|string|max:255',
            'descripcion'          => 'nullable|string',
            'tipo_producto'        => ['required', 'string', Rule::in(['fisico', 'digital', 'servicio'])],
            'precio'               => 'required|numeric|min:0',
            'inventario'           => 'required|integer|min:0',
            'bpm'                  => 'nullable|integer',
            'esta_activo'          => 'boolean',
            'youtube_video_id'  => 'nullable|string|max:20',
            'youtube_title'     => 'nullable|string|max:255',
            'youtube_channel'   => 'nullable|string|max:255',
            'youtube_thumbnail' => 'nullable|string|max:500',
            'imagen_url'        => 'nullable|string|max:2048',
            'imagenes_urls'        => 'nullable|array|max:8',
            'imagenes_urls.*'      => 'string|max:2048',
        ]);

        if (isset($data['nombre'])) {
            $data['slug'] = Str::slug($data['nombre']) . '-' . uniqid();
        }

        $imagenUrl    = $data['imagen_url'] ?? null;
        $imagenesUrls = $data['imagenes_urls'] ?? [];
        unset($data['imagen_url'], $data['imagenes_urls']);

        $product->update($data);

        if ($imagenUrl) {
            $product->multimedia()->where('es_principal', true)->delete();
            ProductMedia::create([
                'id_producto'     => $product->id,
                'tipo_multimedia' => 'imagen',
                'url_archivo'     => $imagenUrl,
                'es_principal'    => true,
            ]);
        }

        // Añade imágenes adicionales sin borrar las existentes no-principales
        foreach ($imagenesUrls as $url) {
            if ($url && $url !== $imagenUrl) {
                $exists = $product->multimedia()
                    ->where('url_archivo', $url)
                    ->exists();
                if (!$exists) {
                    ProductMedia::create([
                        'id_producto'     => $product->id,
                        'tipo_multimedia' => 'imagen',
                        'url_archivo'     => $url,
                        'es_principal'    => false,
                    ]);
                }
            }
        }

        return new ProductDetailResource($product->fresh()->load(['multimedia', 'category', 'tags']));
    }

    public function destroy(string $id)
    {
        Product::findOrFail($id)->delete();
        return response()->json(null, 204);
    }
}
