<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('permisos', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100)->unique()->comment('Ej: productos.leer, pedidos.actualizar');
            $table->string('modulo', 50)->comment('Ej: productos, pedidos, usuarios');
            $table->enum('accion', ['leer', 'crear', 'actualizar', 'eliminar']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('permisos');
    }
};
