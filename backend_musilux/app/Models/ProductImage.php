<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Concerns\HasUuids;

class ProductImage extends Model
{
    use HasUuids;

    protected $primaryKey = 'id';
    protected $keyType = 'string';
    public $incrementing = false;

    // Especificamos el nombre de la tabla, ya que no sigue la convención de Laravel (está en español).
    // El error "Table 'musilux_db.product_images' doesn't exist" ocurre porque Laravel busca 'product_images' por defecto.
    protected $table = 'imagenes_producto';

    // Tu tabla solo tiene creado_en, no tiene actualizado_en
    const CREATED_AT = 'creado_en';
    const UPDATED_AT = null;

    protected $fillable = [
        'id_producto', 'tipo_multimedia', 'url_archivo', 'es_principal'
    ];
}