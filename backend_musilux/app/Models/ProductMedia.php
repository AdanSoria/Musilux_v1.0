<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductMedia extends Model
{
    use HasFactory, HasUuids;

    // Apuntamos a la tabla de tu nuevo esquema DB First
    protected $table = 'multimedia_producto';
    protected $primaryKey = 'id';
    protected $keyType = 'string';
    public $incrementing = false;

    // Tu tabla solo tiene creado_en, no tiene actualizado_en
    const CREATED_AT = 'creado_en';
    const UPDATED_AT = null;

    protected $fillable = [
        'id_producto',
        'tipo_multimedia',
        'url_archivo',
        'es_principal',
    ];

    protected $casts = [
        'es_principal' => 'boolean',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_producto');
    }
}