<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'productos';
    protected $primaryKey = 'id';
    protected $keyType = 'string';
    public $incrementing = false;

    // Desactivamos los timestamps. MySQL se encargará con DEFAULT CURRENT_TIMESTAMP y ON UPDATE CURRENT_TIMESTAMP
    public $timestamps = false;

    protected $fillable = [
        'id_categoria',
        'nombre',
        'slug',
        'descripcion',
        'precio',
        'inventario',
        'esta_activo',
        'tipo_producto',
        'bpm',
        'youtube_video_id',
        'youtube_title',
        'youtube_channel',
        'youtube_thumbnail',
    ];

    protected $casts = [
        'precio' => 'float',
        'esta_activo' => 'boolean',
        'inventario' => 'integer',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class, 'id_categoria');
    }

    public function multimedia(): HasMany
    {
        // Apuntamos al nuevo modelo que representa la tabla multimedia_producto
        return $this->hasMany(ProductMedia::class, 'id_producto');
    }

    public function tags(): BelongsToMany
    {
        return $this->belongsToMany(Tag::class, 'producto_etiqueta', 'id_producto', 'id_etiqueta');
    }
}
