<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Orden de ejecución respeta las dependencias de FK:
     *   roles → usuarios → (permisos ya en su propio seeder) → categorias → …
     */
    public function run(): void
    {
        $this->call([
            RolesPermisosSeeder::class,  // roles + permisos + rol_permiso
            CategorySeeder::class,       // categorias base (Instrumentos, Iluminación, Vinilos)
            ProductSeeder::class,        // 16 productos de muestra (6 instr. + 5 ilum. + 5 vinilos)
        ]);
    }
}
