<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tickets', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('(UUID())'));
            $table->uuid('id_usuario');
            $table->string('asunto', 255);
            $table->text('descripcion');
            $table->enum('estado', ['abierto', 'en_proceso', 'resuelto', 'cerrado'])->default('abierto');
            $table->timestamp('creado_en')->nullable()->useCurrent();
            $table->timestamp('actualizado_en')->nullable()->useCurrent()->useCurrentOnUpdate();

            $table->index('id_usuario');
            $table->index('estado', 'idx_estado');

            $table->foreign('id_usuario')
                  ->references('id')->on('usuarios')
                  ->onDelete('cascade');
        });

        Schema::create('respuestas_ticket', function (Blueprint $table) {
            $table->uuid('id')->primary()->default(DB::raw('(UUID())'));
            $table->uuid('id_ticket');
            $table->uuid('id_usuario');
            $table->text('mensaje');
            $table->timestamp('creado_en')->nullable()->useCurrent();

            $table->index('id_ticket');

            $table->foreign('id_ticket')
                  ->references('id')->on('tickets')
                  ->onDelete('cascade');

            $table->foreign('id_usuario')
                  ->references('id')->on('usuarios')
                  ->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('respuestas_ticket');
        Schema::dropIfExists('tickets');
    }
};
