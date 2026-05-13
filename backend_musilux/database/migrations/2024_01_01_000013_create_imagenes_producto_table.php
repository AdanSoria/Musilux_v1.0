<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabla LEGACY de imágenes de producto (ProductImage model).
 * Se mantiene por compatibilidad histórica.
 * Para nuevos registros usar multimedia_producto.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('imagenes_producto', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('id_producto');

            $table->string('tipo_multimedia', 50)->default('imagen');
            $table->string('url_archivo', 500);
            $table->boolean('es_principal')->default(false);

            // Solo creado_en (UPDATED_AT = null en el modelo)
            $table->timestamp('creado_en')->useCurrent();

            $table->foreign('id_producto')
                  ->references('id')->on('productos')
                  ->onDelete('cascade');

            $table->index('id_producto');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('imagenes_producto');
    }
};
