<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categorias', function (Blueprint $table) {
            $table->increments('id');
            $table->string('nombre', 100);
            $table->string('slug', 100)->unique();
            $table->text('descripcion')->nullable();
            $table->timestamps();                    // created_at + updated_at (nullable para seeders manuales)
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('categorias');
    }
};
