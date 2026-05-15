<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class YoutubeApiService
{
    private const SEARCH_URL = 'https://www.googleapis.com/youtube/v3/search';

    public function __construct(private readonly string $apiKey = '')
    {
    }

    public static function make(): self
    {
        return new self(env('YOUTUBE_API_KEY', ''));
    }

    /**
     * Busca videos en YouTube y retorna hasta $limit resultados filtrados a
     * la categoría Music (10). Devuelve solo los campos necesarios para la app.
     *
     * @throws \RuntimeException si la API Key no está configurada o la cuota se agotó.
     */
    public function searchVideos(string $query, int $limit = 5): array
    {
        if (empty($this->apiKey)) {
            throw new \RuntimeException('YOUTUBE_API_KEY no configurada en .env');
        }

        $response = Http::timeout(10)->get(self::SEARCH_URL, [
            'part'            => 'snippet',
            'q'               => $query,
            'type'            => 'video',
            'videoCategoryId' => '10',   // Music
            'maxResults'      => $limit,
            'key'             => $this->apiKey,
        ]);

        if ($response->failed()) {
            $status = $response->status();
            $reason = $response->json('error.message', "HTTP {$status}");

            if ($status === 403) {
                throw new \RuntimeException("Cuota de YouTube API excedida o API Key inválida: {$reason}");
            }

            throw new \RuntimeException("YouTube API error: {$reason}");
        }

        $items = $response->json('items', []);

        return array_values(
            array_map(
                fn ($item) => [
                    'video_id'  => $item['id']['videoId'],
                    'title'     => html_entity_decode($item['snippet']['title'] ?? '', ENT_QUOTES, 'UTF-8'),
                    'channel'   => $item['snippet']['channelTitle'] ?? '',
                    'thumbnail' => $item['snippet']['thumbnails']['medium']['url']
                                   ?? $item['snippet']['thumbnails']['default']['url']
                                   ?? null,
                ],
                array_filter($items, fn ($i) => ! empty($i['id']['videoId']))
            )
        );
    }
}
