<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        DB::table('categorias')->insert([
            ['id' => 1, 'nombre' => 'Instrumentos', 'slug' => 'instrumentos'],
            ['id' => 2, 'nombre' => 'Iluminación', 'slug' => 'iluminacion'],
            ['id' => 3, 'nombre' => 'Vinilos', 'slug' => 'vinilos'],
        ]);
    }
}
