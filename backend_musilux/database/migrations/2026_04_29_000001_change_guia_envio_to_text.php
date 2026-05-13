<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     * Cambia la columna guia_envio a TEXT para evitar truncamientos cuando se
     * construye la guía concatenada con nombre, dirección y teléfono.
     */
    public function up(): void
    {
        Schema::table('pedidos', function (Blueprint $table) {
            // Si la columna existe y es string, la modificamos a text
            // Nota: algunos drivers requieren doctrine/dbal para modificar columnas.
            // Si no está disponible, se puede crear una columna temporal, copiar y renombrar.
            if (Schema::hasColumn('pedidos', 'guia_envio')) {
                $table->text('guia_envio')->nullable()->change();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('pedidos', function (Blueprint $table) {
            if (Schema::hasColumn('pedidos', 'guia_envio')) {
                $table->string('guia_envio', 100)->nullable()->change();
            }
        });
    }
};
