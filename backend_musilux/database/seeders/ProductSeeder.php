<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $ahora = now();

        $productos = [

            // ── Instrumentos (id_categoria = 1) ─────────────────────────────
            [
                'id_categoria'   => 1,
                'nombre'         => 'Guitarra Acústica Taylor 214ce',
                'descripcion'    => 'Guitarra electroacústica de lujo con tapa de abeto sólido y cuerpos de palisandro. Perfecta para conciertos y estudio.',
                'precio'         => 1850.00,
                'inventario'     => 8,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 1,
                'nombre'         => 'Teclado Korg Kross 2 61 Teclas',
                'descripcion'    => 'Sintetizador de escenario con 61 teclas semipesadas, 305 timbres y secuenciador de 16 pistas.',
                'precio'         => 620.00,
                'inventario'     => 5,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 1,
                'nombre'         => 'Batería Acústica Yamaha Stage Custom',
                'descripcion'    => 'Kit completo de 5 piezas con cáscaras de Birch, incluye platos y pedal de bombo.',
                'precio'         => 2100.00,
                'inventario'     => 3,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 1,
                'nombre'         => 'Bajo Eléctrico Fender Precision MX',
                'descripcion'    => 'Bajo clásico de 4 cuerdas con cuerpo de aliso y mástil de arce. Ideal para rock y jazz.',
                'precio'         => 980.00,
                'inventario'     => 6,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 1,
                'nombre'         => 'Controlador DJ Pioneer DDJ-400',
                'descripcion'    => 'Controlador de 2 canales compatible con Rekordbox, con jog wheels de alto torque y mezclador integrado.',
                'precio'         => 430.00,
                'inventario'     => 10,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 1,
                'nombre'         => 'Micrófono Condensador Rode NT1-A',
                'descripcion'    => 'Micrófono de estudio de diafragma grande con muy bajo nivel de ruido propio. Incluye araña y filtro antipop.',
                'precio'         => 290.00,
                'inventario'     => 12,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],

            // ── Iluminación (id_categoria = 2) ──────────────────────────────
            [
                'id_categoria'   => 2,
                'nombre'         => 'Cabeza Móvil Beam 230W Sharpy',
                'descripcion'    => 'Moving head profesional con lámpara de 230 W, 14 colores y 17 gobos rotativos. Ideal para conciertos y discotecas.',
                'precio'         => 750.00,
                'inventario'     => 15,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 2,
                'nombre'         => 'Par LED 54x3W RGBW DMX',
                'descripcion'    => 'Foco PAR LED de 54 LEDs tricolor con control DMX-512 y modo automático. Cobertura de 180°.',
                'precio'         => 95.00,
                'inventario'     => 40,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 2,
                'nombre'         => 'Máquina de Humo 1500W Antari Z-1500',
                'descripcion'    => 'Máquina de humo de alta densidad con tiempo de calentamiento de 6 minutos y tanque de 3.5 L.',
                'precio'         => 280.00,
                'inventario'     => 7,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 2,
                'nombre'         => 'Controlador DMX 512 Canales',
                'descripcion'    => 'Consola de iluminación con 512 canales DMX, 240 escenas programables y salida USB.',
                'precio'         => 180.00,
                'inventario'     => 9,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],
            [
                'id_categoria'   => 2,
                'nombre'         => 'Barra LED UV Ultravioleta 1m',
                'descripcion'    => 'Barra de LEDs ultravioleta de 1 metro con 72 diodos UV. Perfecta para efectos de neón en eventos.',
                'precio'         => 65.00,
                'inventario'     => 25,
                'tipo_producto'  => 'fisico',
                'esta_activo'    => true,
            ],

            // ── Vinilos (id_categoria = 3) ───────────────────────────────────
            [
                'id_categoria'      => 3,
                'nombre'            => 'Nevermind — Nirvana (Vinilo LP)',
                'descripcion'       => 'Edición remasterizada del álbum icónico de 1991. Vinilo de 180 gramos, incluye poster.',
                'precio'            => 38.00,
                'inventario'        => 20,
                'tipo_producto'     => 'fisico',
                'esta_activo'       => true,
                'youtube_video_id'  => null,
                'youtube_title'     => 'Smells Like Teen Spirit',
                'youtube_channel'   => 'Nirvana',
                'youtube_thumbnail' => null,
                'bpm'               => 117,
            ],
            [
                'id_categoria'      => 3,
                'nombre'            => 'Thriller — Michael Jackson (Vinilo LP)',
                'descripcion'       => 'El álbum más vendido de la historia en edición conmemorativa de 40 aniversario. 180 g.',
                'precio'            => 45.00,
                'inventario'        => 15,
                'tipo_producto'     => 'fisico',
                'esta_activo'       => true,
                'youtube_video_id'  => null,
                'youtube_title'     => 'Thriller',
                'youtube_channel'   => 'Michael Jackson',
                'youtube_thumbnail' => null,
                'bpm'               => 118,
            ],
            [
                'id_categoria'      => 3,
                'nombre'            => 'Dark Side of the Moon — Pink Floyd',
                'descripcion'       => 'Edición de colección con portada holográfica. Una de las grabaciones más precisas en vinilo.',
                'precio'            => 52.00,
                'inventario'        => 10,
                'tipo_producto'     => 'fisico',
                'esta_activo'       => true,
                'youtube_video_id'  => null,
                'youtube_title'     => 'Money',
                'youtube_channel'   => 'Pink Floyd',
                'youtube_thumbnail' => null,
                'bpm'               => 122,
            ],
            [
                'id_categoria'      => 3,
                'nombre'            => 'Back in Black — AC/DC (Vinilo LP)',
                'descripcion'       => 'Clásico del hard rock en prensado de alta fidelidad. Incluye funda interior anti-estática.',
                'precio'            => 36.00,
                'inventario'        => 18,
                'tipo_producto'     => 'fisico',
                'esta_activo'       => true,
                'youtube_video_id'  => null,
                'youtube_title'     => 'Back in Black',
                'youtube_channel'   => 'AC/DC',
                'youtube_thumbnail' => null,
                'bpm'               => 92,
            ],
            [
                'id_categoria'      => 3,
                'nombre'            => 'Rumours — Fleetwood Mac (Vinilo LP)',
                'descripcion'       => 'Reedición 2024 del álbum más icónico de Fleetwood Mac. Vinilo transparente de colección.',
                'precio'            => 48.00,
                'inventario'        => 12,
                'tipo_producto'     => 'fisico',
                'esta_activo'       => true,
                'youtube_video_id'  => null,
                'youtube_title'     => 'Go Your Own Way',
                'youtube_channel'   => 'Fleetwood Mac',
                'youtube_thumbnail' => null,
                'bpm'               => 158,
            ],
        ];

        foreach ($productos as $producto) {
            // Generar slug único
            $producto['slug']       = Str::slug($producto['nombre']) . '-' . uniqid();
            $producto['creado_en']  = $ahora;
            $producto['actualizado_en'] = $ahora;

            // Usar UUID generado manualmente
            $id = (string) Str::uuid();
            DB::table('productos')->insert(array_merge(['id' => $id], $producto));
        }

        $this->command->info('✔  ' . count($productos) . ' productos insertados correctamente.');
    }
}
