<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class SpotifyService
{
    private string $clientId;
    private string $clientSecret;

    public function __construct()
    {
        $this->clientId     = config('services.spotify.client_id');
        $this->clientSecret = config('services.spotify.client_secret');
    }

    private function getAccessToken(): string
    {
        $response = Http::asForm()
            ->withBasicAuth($this->clientId, $this->clientSecret)
            ->post('https://accounts.spotify.com/api/token', [
                'grant_type' => 'client_credentials',
            ]);

        return $response->json('access_token');
    }

    public function searchTracks(string $query, int $limit = 10): array
    {
        $token = $this->getAccessToken();

        $response = Http::withToken($token)
            ->get('https://api.spotify.com/v1/search', [
                'q'      => $query,
                'type'   => 'track',
                'limit'  => $limit,
                'market' => 'MX',
            ]);

        $tracks = $response->json('tracks.items', []);

        return array_map(fn($track) => [
            'id'              => $track['id'],
            'name'            => $track['name'],
            'artist_name'     => $track['artists'][0]['name'] ?? '',
            'album_name'      => $track['album']['name'] ?? '',
            'preview_url' => $track['preview_url'] ?? null,
            'album_image_url' => $track['album']['images'][0]['url'] ?? null,
        ], $tracks);
    }
}