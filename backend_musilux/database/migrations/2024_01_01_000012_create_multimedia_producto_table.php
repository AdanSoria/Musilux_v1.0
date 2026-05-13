<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Tabla activa de multimedia por producto (ProductMedia model).
 * Reemplaza a imagenes_producto (tabla legacy).
 *
 * NOTA: los triggers originales sobre esta tabla fueron eliminados
 * en la migración 2026_04_13_000001. La lógica de es_principal
 * se maneja en ProductController (PHP).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('multimedia_producto', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('id_producto');

            $table->enum('tipo_multimedia', ['imagen', 'audio', 'video'])
                  ->default('imagen');
            $table->string('url_archivo', 500);
            $table->boolean('es_principal')->default(false);

            // Solo creado_en (UPDATED_AT = null en el modelo)
            $table->timestamp('creado_en')->useCurrent();

            $table->foreign('id_producto')
                  ->references('id')->on('productos')
                  ->onDelete('cascade');

            $table->index('id_producto');
            $table->index(['id_producto', 'es_principal'], 'idx_prod_principal');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('multimedia_producto');
    }
};
