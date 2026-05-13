<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class MensajeChatIa extends Model
{
    use HasUuids;

    protected $table      = 'mensajes_chat_ia';
    protected $primaryKey = 'id';
    protected $keyType    = 'string';
    public    $incrementing = false;

    // Solo tiene creado_en, no actualizado_en
    public    $timestamps = false;
    const     CREATED_AT  = 'creado_en';

    protected $fillable = [
        'id_chat',
        'rol',
        'contenido',
    ];

    protected function casts(): array
    {
        return [
            'creado_en' => 'datetime',
        ];
    }

    public function chat(): BelongsTo
    {
        return $this->belongsTo(ChatIa::class, 'id_chat');
    }
}
