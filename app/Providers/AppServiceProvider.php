<?php

namespace App\Providers;

use App\Models\Admin;
use App\Services\Admin\AdminUpdateMetadataService;
use App\Services\Admin\AdminWelcomeModalService;
use App\Services\GeoFlow\ArticleGeoFlowService;
use App\Services\GeoFlow\HorizonMetricsAdapter;
use App\Services\GeoFlow\JobQueueService;
use App\Services\GeoFlow\TaskLifecycleService;
use App\Services\GeoFlow\TaskMonitoringQueryService;
use App\Support\GeoFlow\OutboundHttpProxy;
use App\View\Composers\SiteLayoutComposer;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(JobQueueService::class);
        $this->app->singleton(HorizonMetricsAdapter::class);
        $this->app->singleton(TaskMonitoringQueryService::class);
        $this->app->singleton(TaskLifecycleService::class);
        $this->app->singleton(ArticleGeoFlowService::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $appUrl = rtrim((string) config('app.url'), '/');

        if (app()->environment('production') && $appUrl !== '' && str_starts_with($appUrl, 'https://')) {
            URL::forceRootUrl($appUrl);
            URL::forceScheme('https');
        }

        Http::globalMiddleware(OutboundHttpProxy::middleware());

        View::composer(['site.layout', 'theme.*.layout'], SiteLayoutComposer::class);

        View::composer('admin.layouts.app', function ($view): void {
            try {
                $admin = auth('admin')->user();
                $welcomePayload = null;
                $updatePayload = null;

                if ($admin instanceof Admin) {
                    try {
                        $welcomePayload = app(AdminWelcomeModalService::class)->buildModalPayload($admin);
                    } catch (\Throwable) {
                        $welcomePayload = null;
                    }

                    try {
                        $updatePayload = app(AdminUpdateMetadataService::class)->buildNotificationPayload();
                    } catch (\Throwable) {
                        $updatePayload = null;
                    }
                }

                $view->with('adminWelcomeModalPayload', $welcomePayload);
                $view->with('adminUpdateNotificationPayload', $updatePayload);
            } catch (\Throwable) {
                $view->with('adminWelcomeModalPayload', null);
                $view->with('adminUpdateNotificationPayload', null);
            }
        });
    }
}
