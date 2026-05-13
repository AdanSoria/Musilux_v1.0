<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pedido extends Model
{
    use HasFactory, HasUuids;

    protected $table = 'pedidos';
    protected $primaryKey = 'id';
    protected $keyType = 'string';
    public $incrementing = false;

    const CREATED_AT = 'creado_en';
    const UPDATED_AT = 'actualizado_en';

    protected $fillable = [
        'id_usuario',
        'id_cupon',
        'estado',
        'subtotal',
        'descuento',
        'total',
        'guia_envio',
        'direccion_envio',
    ];

    protected $casts = [
        'subtotal'       => 'float',
        'descuento'      => 'float',
        'total'          => 'float',
        'creado_en'      => 'datetime',
        'actualizado_en' => 'datetime',
    ];

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_usuario');
    }

    public function items(): HasMany
    {
        return $this->hasMany(ItemPedido::class, 'id_pedido');
    }
}
