<?php

namespace App\Providers;

use App\Services\YoutubeApiService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(YoutubeApiService::class, fn () => YoutubeApiService::make());
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
