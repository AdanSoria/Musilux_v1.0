<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Pedidos de clientes.
 * Referenciado en AdminPedidoController (módulo en construcción).
 * El campo guia_envio se menciona en actualizarEstado().
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pedidos', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('id_usuario');
            $table->string('id_cupon', 50)->nullable()
                  ->comment('Código del cupón aplicado (desnormalizado para historial)');

            $table->enum('estado', [
                'pendiente',
                'confirmado',
                'en_preparacion',
                'enviado',
                'entregado',
                'cancelado',
            ])->default('pendiente');

            $table->decimal('subtotal', 10, 2)->unsigned();
            $table->decimal('descuento', 10, 2)->unsigned()->default(0);
            $table->decimal('total', 10, 2)->unsigned();

            $table->string('guia_envio', 100)->nullable()
                  ->comment('Número de guía de rastreo del paquete');

            // Dirección de envío (desnormalizada para historial inmutable)
            $table->text('direccion_envio')->nullable();

            $table->timestamp('creado_en')->useCurrent();
            $table->timestamp('actualizado_en')->nullable()->useCurrent()->useCurrentOnUpdate();

            $table->foreign('id_usuario')
                  ->references('id')->on('usuarios')
                  ->onDelete('restrict');

            $table->index('id_usuario');
            $table->index('estado');
            $table->index('creado_en');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pedidos');
    }
};
