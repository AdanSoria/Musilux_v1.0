<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Permiso extends Model
{
    protected $table = 'permisos';

    public $timestamps = false;

    protected $fillable = ['nombre', 'modulo', 'accion'];

    public function roles()
    {
        return $this->belongsToMany(Rol::class, 'rol_permiso', 'id_permiso', 'id_rol');
    }
}
