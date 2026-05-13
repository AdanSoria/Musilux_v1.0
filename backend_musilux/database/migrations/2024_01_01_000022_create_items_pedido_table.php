<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Líneas de detalle de cada pedido.
 * Se guarda precio_unitario al momento de la compra para que
 * los cambios futuros de precio no afecten el historial.
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('items_pedido', function (Blueprint $table) {
            $table->increments('id');
            $table->uuid('id_pedido');
            $table->uuid('id_producto');

            $table->unsignedSmallInteger('cantidad')->default(1);
            $table->decimal('precio_unitario', 10, 2)->unsigned()
                  ->comment('Precio fijo al momento de la compra');

            // Nombre e imagen del producto al momento de la compra (historial inmutable)
            $table->string('nombre_producto', 200);
            $table->string('imagen_producto', 500)->nullable();

            $table->timestamps();

            $table->foreign('id_pedido')
                  ->references('id')->on('pedidos')
                  ->onDelete('cascade');

            $table->foreign('id_producto')
                  ->references('id')->on('productos')
                  ->onDelete('restrict');

            $table->index('id_pedido');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('items_pedido');
    }
};
