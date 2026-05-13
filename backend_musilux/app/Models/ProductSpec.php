<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductSpec extends Model
{
    use HasFactory;

    protected $table = 'especificaciones_producto';

    protected $fillable = [
        'id_producto',
        'clave',
        'valor',
    ];

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'id_producto');
    }
}
