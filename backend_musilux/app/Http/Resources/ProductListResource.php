<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class ProductListResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'id_categoria' => $this->id_categoria,
            'nombre' => $this->nombre,
            'slug' => $this->slug,
            'precio' => (float) $this->precio,
            'inventario' => (int) $this->inventario,
            'tipo_producto' => $this->tipo_producto,
            'esta_activo' => (bool) $this->esta_activo,
            'bpm' => $this->bpm,
            'descripcion' => $this->descripcion,
            'youtube_video_id' => $this->youtube_video_id,
            'youtube_title' => $this->youtube_title,
            'youtube_channel' => $this->youtube_channel,
            'youtube_thumbnail' => $this->youtube_thumbnail,
            'multimedia' => $this->whenLoaded('multimedia', function () {
                return $this->multimedia->map(function ($media) {
                    return [
                        'id' => $media->id,
                        'tipo_multimedia' => $media->tipo_multimedia,
                        'url_archivo' => $this->resolveMediaUrl($media->url_archivo),
                        'es_principal' => (bool) $media->es_principal,
                    ];
                });
            }),
        ];
    }

    /**
     * Builds the full public URL for a media file.
     * If the value is already a full URL (external/Spotify images), returns as-is.
     * Otherwise builds the URL using Laravel Storage.
     */
    private function resolveMediaUrl(?string $path): ?string
    {
        if (empty($path)) return null;
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        return url(Storage::url($path));
    }
}