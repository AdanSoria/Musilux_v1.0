<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Rol extends Model
{
    protected $table = 'roles';

    // La tabla roles usa id INT autoincremental (sin UUID)
    protected $primaryKey = 'id';
    public $incrementing = true;
    protected $keyType = 'int';
    public $timestamps = false;

    protected $fillable = ['nombre'];

    public function usuarios()
    {
        return $this->hasMany(User::class, 'id_rol');
    }

    public function permisos()
    {
        return $this->belongsToMany(
            Permiso::class,
            'rol_permiso',
            'id_rol',
            'id_permiso'
        );
    }
}
