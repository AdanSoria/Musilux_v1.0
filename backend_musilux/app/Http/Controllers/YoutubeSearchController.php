<?php

namespace App\Http\Controllers;

use App\Services\YoutubeApiService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class YoutubeSearchController extends Controller
{
    public function __construct(private readonly YoutubeApiService $youtube)
    {
    }

    /**
     * GET /api/youtube/search?q={query}
     *
     * Retorna hasta 5 videos de YouTube filtrados a música.
     * El backend actúa como proxy para proteger la API Key.
     */
    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'q' => 'required|string|min:2|max:200',
        ]);

        try {
            $videos = $this->youtube->searchVideos(trim($request->query('q')));
            return response()->json(['videos' => $videos]);
        } catch (\RuntimeException $e) {
            return response()->json(['error' => $e->getMessage()], 503);
        }
    }
}
