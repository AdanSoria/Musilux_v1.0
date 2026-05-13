<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChatIa extends Model
{
    use HasUuids;

    protected $table      = 'chats_ia';
    protected $primaryKey = 'id';
    protected $keyType    = 'string';
    public    $incrementing = false;

    const CREATED_AT = 'creado_en';
    const UPDATED_AT = 'actualizado_en';

    protected $fillable = [
        'id_usuario',
        'titulo',
    ];

    protected function casts(): array
    {
        return [
            'creado_en'      => 'datetime',
            'actualizado_en' => 'datetime',
        ];
    }

    public function usuario(): BelongsTo
    {
        return $this->belongsTo(User::class, 'id_usuario');
    }

    public function mensajes(): HasMany
    {
        return $this->hasMany(MensajeChatIa::class, 'id_chat')->orderBy('creado_en');
    }
}
