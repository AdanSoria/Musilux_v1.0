<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Cupones de descuento.
 * Referenciado en CuponController::store() con validación:
 *   codigo: unique:cupones,codigo
 *   descuento: numeric 0-100
 *   tipo: porcentaje|fijo
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cupones', function (Blueprint $table) {
            $table->increments('id');
            $table->string('codigo', 50)->unique();
            $table->decimal('descuento', 5, 2)->unsigned()
                  ->comment('Valor del descuento (0-100 para porcentaje, monto para fijo)');
            $table->enum('tipo', ['porcentaje', 'fijo']);
            $table->boolean('esta_activo')->default(true);

            // Vigencia opcional
            $table->date('fecha_inicio')->nullable();
            $table->date('fecha_fin')->nullable();

            // Límite de usos opcional
            $table->unsignedInteger('usos_maximos')->nullable();
            $table->unsignedInteger('usos_actuales')->default(0);

            $table->timestamps();

            $table->index('codigo');
            $table->index('esta_activo');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cupones');
    }
};
