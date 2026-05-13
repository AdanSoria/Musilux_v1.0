<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('usuarios', function (Blueprint $table) {
            // UUID generado por Laravel (HasUuids)
            $table->uuid('id')->primary();

            $table->unsignedInteger('id_rol');

            $table->string('nombres', 100);
            $table->string('apellidos', 100);
            $table->string('correo', 255)->unique();
            $table->string('contrasena_hash', 255);
            $table->boolean('esta_activo')->default(true);

            // Timestamps personalizados (User::CREATED_AT / UPDATED_AT)
            $table->timestamp('creado_en')->useCurrent();
            $table->timestamp('actualizado_en')->nullable()->useCurrent()->useCurrentOnUpdate();

            $table->foreign('id_rol')
                  ->references('id')->on('roles')
                  ->onDelete('restrict');

            $table->index('id_rol');
            $table->index('esta_activo');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('usuarios');
    }
};
