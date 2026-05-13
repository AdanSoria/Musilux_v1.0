<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('roles', function (Blueprint $table) {
            $table->unsignedInteger('id')->autoIncrement()->primary();
            $table->string('nombre', 50)->unique()->comment('Ej: superadmin, cliente, admin_pedidos');
            // Sin timestamps — tabla de catálogo estática
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('roles');
    }
};
