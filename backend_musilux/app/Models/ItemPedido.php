<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ItemPedido extends Model
{
    use HasFactory;

    protected $table = 'items_pedido';
    protected $primaryKey = 'id';

    protected $fillable = [
        'id_pedido',
        'id_producto',
        'cantidad',
        'precio_unitario',
        'nombre_producto',
        'imagen_producto',
    ];

    protected $casts = [
        'cantidad'       => 'integer',
        'precio_unitario' => 'float',
        'created_at'     => 'datetime',
        'updated_at'     => 'datetime',
    ];

    public function pedido(): BelongsTo
    {
        return $this->belongsTo(Pedido::class, 'id_pedido');
    }
}
