<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabla pivot productos ↔ etiquetas.
 * Referencia en Tag::products():
 *   belongsToMany(Product::class, 'producto_etiqueta', 'id_etiqueta', 'id_producto')
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('producto_etiqueta', function (Blueprint $table) {
            $table->unsignedInteger('id_etiqueta');
            $table->uuid('id_producto');

            $table->primary(['id_etiqueta', 'id_producto']);

            $table->foreign('id_etiqueta')
                  ->references('id')->on('etiquetas')
                  ->onDelete('cascade');

            $table->foreign('id_producto')
                  ->references('id')->on('productos')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('producto_etiqueta');
    }
};
