<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Elimina todos los triggers de la tabla multimedia_producto.
 *
 * El trigger de es_principal provoca un SQLSTATE HY000 (error 1442):
 * "Can't update table 'multimedia_producto' in stored function/trigger
 *  because it is already used by statement which invoked this stored
 *  function/trigger."
 *
 * MySQL no permite que un trigger haga UPDATE sobre la misma tabla
 * que disparó el INSERT. La lógica de es_principal se maneja en PHP
 * (ProductController) y por eso el trigger es innecesario.
 */
return new class extends Migration
{
    public function up(): void
    {
        $triggers = DB::select(
            "SHOW TRIGGERS WHERE `Table` = 'multimedia_producto'"
        );

        foreach ($triggers as $trigger) {
            DB::unprepared("DROP TRIGGER IF EXISTS `{$trigger->Trigger}`");
        }
    }

    public function down(): void
    {
        // No recreamos el trigger: la lógica vive ahora en ProductController.
    }
};
