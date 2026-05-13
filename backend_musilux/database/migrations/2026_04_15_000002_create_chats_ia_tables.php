<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Sesiones de chat con la IA ─────────────────────────────────────────
        Schema::create('chats_ia', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('id_usuario');
            $table->string('titulo', 255)->nullable()->comment('Primeros 80 chars del primer mensaje');
            $table->timestamp('creado_en')->useCurrent();
            $table->timestamp('actualizado_en')->useCurrent()->useCurrentOnUpdate();

            $table->foreign('id_usuario')
                  ->references('id')
                  ->on('usuarios')
                  ->onDelete('cascade');

            $table->index('id_usuario');
        });

        // ── Mensajes individuales de cada sesión ───────────────────────────────
        Schema::create('mensajes_chat_ia', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('id_chat');
            $table->enum('rol', ['usuario', 'asistente']);
            $table->text('contenido');
            $table->timestamp('creado_en')->useCurrent();

            $table->foreign('id_chat')
                  ->references('id')
                  ->on('chats_ia')
                  ->onDelete('cascade');

            $table->index(['id_chat', 'creado_en']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('mensajes_chat_ia');
        Schema::dropIfExists('chats_ia');
    }
};
