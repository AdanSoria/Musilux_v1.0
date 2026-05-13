<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('productos', function (Blueprint $table) {
            // UUID generado por Laravel (HasUuids)
            $table->uuid('id')->primary();

            $table->unsignedInteger('id_categoria');

            $table->string('nombre', 200);
            $table->string('slug', 220)->unique()->comment('nombre + uniqid()');
            $table->text('descripcion')->nullable();

            $table->decimal('precio', 10, 2)->unsigned();
            $table->unsignedInteger('inventario')->default(0)
                  ->comment('0 para productos digitales');
            $table->boolean('esta_activo')->default(true);

            $table->enum('tipo_producto', ['fisico', 'digital', 'servicio']);

            // BPM opcional (ej. pistas de música)
            $table->unsignedSmallInteger('bpm')->nullable();

            // Integración Spotify
            $table->string('spotify_track_id', 100)->nullable();
            $table->string('spotify_track_name', 255)->nullable();
            $table->string('spotify_artist_name', 255)->nullable();
            $table->string('spotify_preview_url', 500)->nullable();
            $table->string('spotify_album_image_url', 500)->nullable();

            // Timestamps manejados por MySQL (el modelo los excluye de Eloquent)
            $table->timestamp('creado_en')->useCurrent();
            $table->timestamp('actualizado_en')->nullable()->useCurrent()->useCurrentOnUpdate();

            $table->foreign('id_categoria')
                  ->references('id')->on('categorias')
                  ->onDelete('restrict');

            $table->index('id_categoria');
            $table->index('esta_activo');
            $table->index('tipo_producto');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('productos');
    }
};
