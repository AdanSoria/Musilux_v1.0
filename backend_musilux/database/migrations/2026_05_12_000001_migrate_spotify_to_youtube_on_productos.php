<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            // Eliminar columnas de Spotify
            $table->dropColumn([
                'spotify_track_id',
                'spotify_track_name',
                'spotify_artist_name',
                'spotify_preview_url',
                'spotify_album_image_url',
            ]);

            // Agregar columnas de YouTube
            $table->string('youtube_video_id', 20)->nullable()->after('bpm');
            $table->string('youtube_title', 255)->nullable()->after('youtube_video_id');
            $table->string('youtube_channel', 255)->nullable()->after('youtube_title');
            $table->string('youtube_thumbnail', 500)->nullable()->after('youtube_channel');
        });
    }

    public function down(): void
    {
        Schema::table('productos', function (Blueprint $table) {
            $table->dropColumn([
                'youtube_video_id',
                'youtube_title',
                'youtube_channel',
                'youtube_thumbnail',
            ]);

            $table->string('spotify_track_id', 255)->nullable()->after('bpm');
            $table->string('spotify_track_name', 255)->nullable()->after('spotify_track_id');
            $table->string('spotify_artist_name', 255)->nullable()->after('spotify_track_name');
            $table->string('spotify_preview_url', 500)->nullable()->after('spotify_artist_name');
            $table->string('spotify_album_image_url', 500)->nullable()->after('spotify_preview_url');
        });
    }
};
