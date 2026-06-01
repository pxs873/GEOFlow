<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Models\Category;
use App\Models\DistributionChannel;
use App\Models\Task;
use App\Services\Admin\Analytics\AnalyticsFilter;
use App\Services\Admin\Analytics\AnalyticsLogQueryService;
use App\Services\Admin\Analytics\AnalyticsOverviewService;
use App\Support\AdminWeb;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Schema;
use Illuminate\View\View;
use Throwable;

class AnalyticsController extends Controller
{
    public function __construct(
        private readonly AnalyticsOverviewService $overviewService,
        private readonly AnalyticsLogQueryService $logQueryService,
    ) {}

    public function index(Request $request): View
    {
        $filter = AnalyticsFilter::fromRequest($request->query());

        $pageData = [
            'pageTitle' => __('admin.analytics.page_title'),
            'activeMenu' => 'analytics',
            'adminSiteName' => AdminWeb::siteName(),
            'filters' => $filter,
            'filterOptions' => $this->filterOptions(),
        ];

        try {
            $pageData += [
                'globalOverview' => $this->overviewService->globalOverview(),
                'kpis' => $this->overviewService->kpis($filter),
                'publicationTrend' => $this->overviewService->publicationTrend($filter),
                'taskTrend' => $this->overviewService->taskTrend($filter),
                'contentFunnel' => $this->overviewService->contentFunnel($filter),
                'distributionSummary' => $this->overviewService->distributionSummary($filter),
                'topContent' => $this->overviewService->topContent($filter),
                'aiUsageSummary' => $this->overviewService->aiUsageSummary($filter),
                'categoryDistribution' => $this->overviewService->categoryDistribution($filter),
                'performanceStats' => $this->overviewService->performanceStats($filter),
                'latestArticles' => $this->overviewService->latestArticles($filter),
                'taskHealth' => $this->overviewService->taskHealth($filter),
                'materialHealth' => $this->overviewService->materialHealth(),
                'aiHealth' => $this->overviewService->aiHealth(),
                'urlImportHealth' => $this->overviewService->urlImportHealth($filter),
                'logSummary' => $this->logQueryService->summary($filter),
            ];
        } catch (Throwable $exception) {
            report($exception);
            $pageData += $this->emptyAnalyticsData();
        }

        return view('admin.analytics.index', $pageData);
    }

    /**
     * @return array<string, mixed>
     */
    private function filterOptions(): array
    {
        return [
            'channels' => Schema::hasTable('distribution_channels')
                ? DistributionChannel::query()->orderBy('name')->select('id', 'name')->get()
                : collect(),
            'tasks' => Task::query()
                ->orderByDesc('created_at')
                ->select('id', 'name')
                ->limit(100)
                ->get(),
            'categories' => Category::query()
                ->orderBy('name')
                ->select('id', 'name')
                ->get(),
            'articles' => Article::query()
                ->whereNull('deleted_at')
                ->orderByDesc('created_at')
                ->select('id', 'title')
                ->limit(100)
                ->get(),
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function emptyAnalyticsData(): array
    {
        return [
            'globalOverview' => [
                'total_articles' => 0,
                'today_articles' => 0,
                'published_articles' => 0,
                'publish_rate' => 0,
                'ai_generated_articles' => 0,
                'ai_generated_ratio' => 0,
                'total_views' => 0,
                'today_views' => 0,
                'running_jobs' => 0,
                'pending_jobs' => 0,
                'total_tasks' => 0,
                'active_ai_models' => 0,
                'material_total' => 0,
                'pending_review' => 0,
            ],
            'kpis' => [
                'articles' => 0,
                'published' => 0,
                'running_tasks' => 0,
                'failed_tasks' => 0,
                'ai_calls' => 0,
                'distribution_failed' => 0,
                'distribution_pending' => 0,
                'total_views' => 0,
            ],
            'publicationTrend' => [],
            'taskTrend' => [],
            'contentFunnel' => [
                'max' => 1,
                'stages' => [],
            ],
            'distributionSummary' => [
                'total' => 0,
                'synced' => 0,
                'failed' => 0,
                'pending' => 0,
                'rows' => [],
            ],
            'topContent' => [],
            'aiUsageSummary' => [
                'used_today' => 0,
                'total_used' => 0,
                'active_models' => 0,
                'model_rows' => [],
            ],
            'categoryDistribution' => [],
            'performanceStats' => [
                'avg_generation_time' => 0,
                'success_rate' => 0,
                'daily_quota_used' => 0,
            ],
            'latestArticles' => [],
            'taskHealth' => [
                'active_tasks' => 0,
                'paused_tasks' => 0,
                'running_jobs' => 0,
                'pending_jobs' => 0,
                'failed_jobs' => 0,
                'recent_failures' => [],
            ],
            'materialHealth' => [
                'keyword_libraries' => 0,
                'title_libraries' => 0,
                'knowledge_bases' => 0,
                'image_libraries' => 0,
                'authors' => 0,
                'knowledge_chunks' => 0,
                'vectorized_chunks' => 0,
                'unvectorized_chunks' => 0,
            ],
            'aiHealth' => [
                'chat_models' => 0,
                'embedding_models' => 0,
                'used_today' => 0,
                'total_used' => 0,
                'active_models' => [],
            ],
            'urlImportHealth' => [
                'total' => 0,
                'running' => 0,
                'completed' => 0,
                'failed' => 0,
                'waiting_import' => 0,
                'recent_jobs' => [],
            ],
            'logSummary' => [
                'has_data' => false,
                'kpis' => [
                    'pv' => 0,
                    'unique_ip' => 0,
                    'ai_bot_pv' => 0,
                    'errors' => 0,
                ],
                'traffic_trend' => [],
                'bot_breakdown' => [],
                'top_paths' => [],
                'top_articles' => [],
            ],
        ];
    }
}
