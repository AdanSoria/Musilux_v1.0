<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Especificaciones técnicas clave-valor por producto.
 * Ej: { clave: "Material", valor: "Abeto macizo" }
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('especificaciones_producto', function (Blueprint $table) {
            $table->increments('id');
            $table->uuid('id_producto');

            $table->string('clave', 100)
                  ->comment('Nombre de la especificación. Ej: Material, Peso, BPM');
            $table->string('valor', 255)
                  ->comment('Valor de la especificación. Ej: Abeto macizo, 2.5 kg');

            $table->timestamps();

            $table->foreign('id_producto')
                  ->references('id')->on('productos')
                  ->onDelete('cascade');

            $table->index('id_producto');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('especificaciones_producto');
    }
};
