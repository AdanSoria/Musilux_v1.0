<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class RolesPermisosSeeder extends Seeder
{
    public function run(): void
    {
        // ── 1. Roles (INSERT IGNORE: no sobreescribe si ya existen) ──────────
        DB::statement("
            INSERT IGNORE INTO `roles` (`id`, `nombre`) VALUES
            (1, 'superadmin'),
            (2, 'cliente'),
            (3, 'admin_pedidos'),
            (4, 'admin_usuarios'),
            (5, 'admin_inventario'),
            (6, 'admin_ventas'),
            (7, 'admin_soporte'),
            (8, 'visitante')
        ");

        // ── 2. Permisos por módulo ───────────────────────────────────────────
        $modulos = [
            'productos'     => ['leer', 'crear', 'actualizar', 'eliminar'],
            'pedidos'       => ['leer', 'crear', 'actualizar', 'eliminar'],
            'usuarios'      => ['leer', 'crear', 'actualizar', 'eliminar'],
            'descargas'     => ['leer', 'crear', 'actualizar', 'eliminar'],
            'resenas'       => ['leer', 'crear', 'actualizar', 'eliminar'],
            'reportes'      => ['leer', 'crear', 'actualizar', 'eliminar'],
            'cupones'       => ['leer', 'crear', 'actualizar', 'eliminar'],
            'tickets'       => ['leer', 'crear', 'actualizar', 'eliminar'],
            'roles'         => ['leer', 'crear', 'actualizar', 'eliminar'],
            'configuracion' => ['leer', 'crear', 'actualizar', 'eliminar'],
        ];

        foreach ($modulos as $modulo => $acciones) {
            foreach ($acciones as $accion) {
                DB::table('permisos')->insertOrIgnore([
                    'nombre' => "{$modulo}.{$accion}",
                    'modulo' => $modulo,
                    'accion' => $accion,
                ]);
            }
        }

        // ── 3. Helper: obtener id de permiso por nombre ──────────────────────
        $pid = fn(string $nombre): int =>
            DB::table('permisos')->where('nombre', $nombre)->value('id');

        // ── 4. Asignaciones rol → permisos ───────────────────────────────────

        // visitante (id=8): solo productos.leer
        $this->asignar(8, [$pid('productos.leer')]);

        // cliente (id=2)
        $this->asignar(2, [
            $pid('productos.leer'),
            $pid('pedidos.crear'),
            $pid('pedidos.leer'),
            $pid('descargas.leer'),
            $pid('resenas.crear'),
            $pid('resenas.actualizar'),
            $pid('usuarios.actualizar'),  // propio perfil
        ]);

        // admin_pedidos (id=3)
        $this->asignar(3, [
            $pid('pedidos.leer'),
            $pid('pedidos.actualizar'),
        ]);

        // admin_usuarios (id=4)
        $this->asignar(4, [
            $pid('usuarios.leer'),
            $pid('usuarios.actualizar'),
            $pid('usuarios.eliminar'),
        ]);

        // admin_inventario (id=5)
        $this->asignar(5, [
            $pid('productos.leer'),
            $pid('productos.crear'),
            $pid('productos.actualizar'),
            $pid('productos.eliminar'),
        ]);

        // admin_ventas (id=6)
        $this->asignar(6, [
            $pid('reportes.leer'),
            $pid('cupones.leer'),
            $pid('cupones.crear'),
            $pid('cupones.actualizar'),
        ]);

        // admin_soporte (id=7)
        $this->asignar(7, [
            $pid('tickets.leer'),
            $pid('tickets.crear'),
            $pid('tickets.actualizar'),
        ]);

        // superadmin (id=1): TODOS los permisos
        $todosLosIds = DB::table('permisos')->pluck('id')->toArray();
        $this->asignar(1, $todosLosIds);
    }

    private function asignar(int $idRol, array $idPermisos): void
    {
        foreach ($idPermisos as $idPermiso) {
            if ($idPermiso === null) continue;
            DB::table('rol_permiso')->insertOrIgnore([
                'id_rol'     => $idRol,
                'id_permiso' => $idPermiso,
            ]);
        }
    }
}
