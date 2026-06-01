#!/usr/bin/env bash
set -euo pipefail
sudo -v
cd /opt/geoflow
echo '[1/4] Writing dashboard-related files...'
sudo mkdir -p 'app/Http/Controllers/Admin'
sudo tee 'app/Http/Controllers/Admin/DashboardController.php' >/dev/null <<'EOF_DASHBOARD_CONTROLLER_PHP'
<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AiModel;
use App\Models\Article;
use App\Models\Author;
use App\Models\Category;
use App\Models\Image;
use App\Models\ImageLibrary;
use App\Models\Keyword;
use App\Models\KeywordLibrary;
use App\Models\KnowledgeBase;
use App\Models\KnowledgeChunk;
use App\Models\Prompt;
use App\Models\Task;
use App\Models\TaskRun;
use App\Models\Title;
use App\Models\TitleLibrary;
use App\Models\UrlImportJob;
use App\Support\AdminWeb;
use Illuminate\Http\Response;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * 管理首页仪表盘：汇总文章、任务队列（task_runs）、素材与性能指标，并输出趋势图数据。
 */
class DashboardController extends Controller
{
    public function index(): Response
    {
        try {
            $stats = $this->buildStats();
            $todayStats = $this->buildTodayStats();
            $weekStats = $this->buildWeekStats();
            $categoryDistribution = $this->buildCategoryDistribution();
            $latestArticles = $this->buildLatestArticles();
            $articleTrend = $this->buildArticleTrendSeries();
            $trendChart = $this->buildArticleTrendChartPaths($articleTrend);
            $performanceStats = $this->buildPerformanceStats(
                (int) ($stats['completed_tasks'] ?? 0),
                (int) ($stats['failed_jobs'] ?? 0)
            );
            $contentFunnel = $this->buildContentFunnel($stats);
            $taskHealth = $this->buildTaskHealth();
            $materialHealth = $this->buildMaterialHealth();
            $aiHealth = $this->buildAiHealth();
            $urlImportHealth = $this->buildUrlImportHealth();
            $popularArticles = $this->buildPopularArticles();
            $todoItems = $this->buildTodoItems($stats, $materialHealth, $aiHealth, $urlImportHealth);

            return response(
                view('admin.dashboard', [
                    'pageTitle' => __('admin.dashboard.page_title'),
                    'activeMenu' => 'dashboard',
                    'adminSiteName' => AdminWeb::siteName(),
                    'stats' => $stats,
                    'today_stats' => $todayStats,
                    'week_stats' => $weekStats,
                    'category_distribution' => $categoryDistribution,
                    'latest_articles' => $latestArticles,
                    'article_trend' => $articleTrend,
                    'trend_chart' => $trendChart,
                    'performance_stats' => $performanceStats,
                    'content_funnel' => $contentFunnel,
                    'task_health' => $taskHealth,
                    'material_health' => $materialHealth,
                    'ai_health' => $aiHealth,
                    'url_import_health' => $urlImportHealth,
                    'popular_articles' => $popularArticles,
                    'todo_items' => $todoItems,
                ])->render(),
                200,
                ['Content-Type' => 'text/html; charset=UTF-8']
            );
        } catch (\Throwable $exception) {
            report($exception);

            return $this->renderFallbackResponse();
        }
    }

    private function renderFallbackResponse(): Response
    {
        $adminBase = '/'.trim((string) config('geoflow.admin_base_path', '/geo_admin'), '/');
        $links = [
            ['label' => '任务管理', 'href' => $adminBase.'/tasks'],
            ['label' => '文章管理', 'href' => $adminBase.'/articles'],
            ['label' => 'AI 模型', 'href' => $adminBase.'/ai-models'],
            ['label' => '素材中心', 'href' => $adminBase.'/materials'],
        ];

        $linkHtml = collect($links)->map(function (array $link): string {
            return sprintf(
                '<a href="%s" style="%s">%s</a>',
                e($link['href']),
                'display:inline-flex;align-items:center;justify-content:center;padding:12px 18px;border-radius:12px;background:#111827;color:#fff;text-decoration:none;font-weight:600;',
                e($link['label'])
            );
        })->implode('');

        $html = <<<HTML
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>GEOFlow 后台</title>
</head>
<body style="margin:0;background:#f8fafc;color:#0f172a;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;">
    <main style="max-width:860px;margin:0 auto;padding:48px 24px;">
        <section style="background:#fff;border:1px solid #e2e8f0;border-radius:20px;padding:32px;box-shadow:0 12px 40px rgba(15,23,42,.08);">
            <div style="display:inline-flex;padding:6px 12px;border-radius:999px;background:#dbeafe;color:#1d4ed8;font-size:13px;font-weight:700;">后台保底页</div>
            <h1 style="margin:18px 0 12px;font-size:32px;line-height:1.2;">仪表盘统计暂时打不开，但系统还能继续用</h1>
            <p style="margin:0 0 24px;font-size:16px;line-height:1.8;color:#475569;">我已经把 500 拦住了。你可以先继续进任务、文章、AI 模型和素材页面，不耽误运营；后面再根据日志把仪表盘的具体报错点修掉。</p>
            <div style="display:flex;flex-wrap:wrap;gap:12px;">{$linkHtml}</div>
        </section>
    </main>
</body>
</html>
HTML;

        return response($html, 200, ['Content-Type' => 'text/html; charset=UTF-8']);
    }

    /**
     * @return array<string, int|float>
     */
    private function buildStats(): array
    {
        $defaults = [
            'total_articles' => 0,
            'published_articles' => 0,
            'draft_articles' => 0,
            'ai_generated_articles' => 0,
            'total_tasks' => 0,
            'active_tasks' => 0,
            'completed_tasks' => 0,
            'running_jobs' => 0,
            'pending_jobs' => 0,
            'failed_jobs' => 0,
            'total_keywords' => 0,
            'total_titles' => 0,
            'total_images' => 0,
            'total_categories' => 0,
            'active_ai_models' => 0,
            'total_prompts' => 0,
            'pending_review' => 0,
            'approved_articles' => 0,
            'total_views' => 0,
            'total_likes' => 0,
        ];

        try {
            $jobStatusCounts = TaskRun::query()
                ->selectRaw('status, COUNT(*) as c')
                ->groupBy('status')
                ->pluck('c', 'status')
                ->all();
            $defaults['running_jobs'] = (int) ($jobStatusCounts['running'] ?? 0);
            $defaults['pending_jobs'] = (int) ($jobStatusCounts['pending'] ?? 0);
            $defaults['failed_jobs'] = (int) ($jobStatusCounts['failed'] ?? 0);
            $defaults['completed_tasks'] = (int) ($jobStatusCounts['completed'] ?? 0);

            $defaults['total_articles'] = (int) Article::query()->whereNull('deleted_at')->count();
            $defaults['published_articles'] = (int) Article::query()->where('status', 'published')->whereNull('deleted_at')->count();
            $defaults['draft_articles'] = (int) Article::query()->where('status', 'draft')->whereNull('deleted_at')->count();
            $defaults['ai_generated_articles'] = (int) Article::query()->where('is_ai_generated', 1)->whereNull('deleted_at')->count();
            $defaults['pending_review'] = (int) Article::query()->where('review_status', 'pending')->whereNull('deleted_at')->count();
            $defaults['approved_articles'] = (int) Article::query()->where('review_status', 'approved')->whereNull('deleted_at')->count();
            $defaults['total_views'] = (int) (Article::query()->whereNull('deleted_at')->sum('view_count') ?? 0);
            if (Schema::hasColumn('articles', 'like_count')) {
                $defaults['total_likes'] = (int) (Article::query()->whereNull('deleted_at')->sum('like_count') ?? 0);
            }

            $defaults['total_tasks'] = (int) Task::query()->count();
            $defaults['active_tasks'] = (int) Task::query()->where('status', 'active')->count();
            $defaults['total_keywords'] = (int) Keyword::query()->count();
            $defaults['total_titles'] = (int) Title::query()->count();
            $defaults['total_images'] = (int) Image::query()->count();
            $defaults['total_categories'] = (int) Category::query()->count();
            $defaults['active_ai_models'] = (int) AiModel::query()->where('status', 'active')->count();
            $defaults['total_prompts'] = (int) Prompt::query()->count();
        } catch (\Throwable) {
            return $defaults;
        }

        return $defaults;
    }

    /**
     * @return array<string, int>
     */
    private function buildTodayStats(): array
    {
        $out = ['today_articles' => 0, 'today_tasks' => 0, 'today_views' => 0];
        try {
            $today = Carbon::today();
            $out['today_articles'] = (int) Article::query()
                ->whereNull('deleted_at')
                ->whereDate('created_at', $today)
                ->count();
            $out['today_tasks'] = (int) Task::query()
                ->whereDate('created_at', $today)
                ->count();
            $out['today_views'] = (int) DB::table('view_logs')
                ->whereDate('created_at', $today)
                ->count();
        } catch (\Throwable) {
            // ignore
        }

        return $out;
    }

    /**
     * @return array<string, int>
     */
    private function buildWeekStats(): array
    {
        $out = ['week_articles' => 0, 'week_tasks' => 0];
        try {
            $since = now()->subDays(7);
            $out['week_articles'] = (int) Article::query()
                ->whereNull('deleted_at')
                ->where('created_at', '>=', $since)
                ->count();
            $out['week_tasks'] = (int) Task::query()->where('created_at', '>=', $since)->count();
        } catch (\Throwable) {
            // ignore
        }

        return $out;
    }

    /**
     * 分类维度文章分布：分类左连未软删文章，按篇数降序取前 10。
     *
     * @return list<array{name: string, count: int}>
     */
    private function buildCategoryDistribution(): array
    {
        try {
            return DB::table('categories as c')
                ->leftJoin('articles as a', function ($join): void {
                    $join->on('c.id', '=', 'a.category_id')
                        ->whereNull('a.deleted_at');
                })
                ->select('c.name', DB::raw('COUNT(a.id) as count'))
                ->groupBy('c.id', 'c.name')
                ->orderByDesc('count')
                ->limit(10)
                ->get()
                ->map(fn ($r) => ['name' => (string) $r->name, 'count' => (int) $r->count])
                ->all();
        } catch (\Throwable) {
            return [];
        }
    }

    /**
     * 最新文章列表：按创建时间降序 5 条，分类左连（无分类亦可）。
     *
     * @return list<object>
     */
    private function buildLatestArticles(): array
    {
        try {
            return DB::table('articles as a')
                ->leftJoin('categories as c', 'a.category_id', '=', 'c.id')
                ->whereNull('a.deleted_at')
                ->orderByDesc('a.created_at')
                ->select('a.*', 'c.name as category_name')
                ->limit(5)
                ->get()
                ->all();
        } catch (\Throwable) {
            return [];
        }
    }

    /**
     * 内容生产漏斗：从素材供给到草稿、审核、发布和产生浏览的转化概览。
     *
     * @param  array<string, int|float>  $stats
     * @return array{max: int, stages: list<array{key: string, label: string, count: int, tone: string}>}
     */
    private function buildContentFunnel(array $stats): array
    {
        $viewedArticles = 0;
        try {
            $viewedArticles = (int) Article::query()
                ->whereNull('deleted_at')
                ->where('view_count', '>', 0)
                ->count();
        } catch (\Throwable) {
            // ignore
        }

        $stages = [
            [
                'key' => 'titles',
                'label' => __('admin.dashboard.funnel_titles'),
                'count' => (int) ($stats['total_titles'] ?? 0),
                'tone' => 'blue',
            ],
            [
                'key' => 'drafts',
                'label' => __('admin.dashboard.funnel_drafts'),
                'count' => (int) ($stats['draft_articles'] ?? 0),
                'tone' => 'amber',
            ],
            [
                'key' => 'pending_review',
                'label' => __('admin.dashboard.funnel_pending_review'),
                'count' => (int) ($stats['pending_review'] ?? 0),
                'tone' => 'purple',
            ],
            [
                'key' => 'published',
                'label' => __('admin.dashboard.funnel_published'),
                'count' => (int) ($stats['published_articles'] ?? 0),
                'tone' => 'green',
            ],
            [
                'key' => 'viewed',
                'label' => __('admin.dashboard.funnel_viewed'),
                'count' => $viewedArticles,
                'tone' => 'slate',
            ],
        ];

        return [
            'max' => max(1, ...array_column($stages, 'count')),
            'stages' => $stages,
        ];
    }

    /**
     * @return array{
     *   active_tasks: int,
     *   paused_tasks: int,
     *   running_jobs: int,
     *   pending_jobs: int,
     *   failed_jobs: int,
     *   recent_failures: list<object>
     * }
     */
    private function buildTaskHealth(): array
    {
        $out = [
            'active_tasks' => 0,
            'paused_tasks' => 0,
            'running_jobs' => 0,
            'pending_jobs' => 0,
            'failed_jobs' => 0,
            'recent_failures' => [],
        ];

        try {
            $taskStatusCounts = Task::query()
                ->selectRaw('status, COUNT(*) as c')
                ->groupBy('status')
                ->pluck('c', 'status')
                ->all();
            $out['active_tasks'] = (int) ($taskStatusCounts['active'] ?? 0);
            $out['paused_tasks'] = (int) (($taskStatusCounts['paused'] ?? 0) + ($taskStatusCounts['inactive'] ?? 0));

            $jobStatusCounts = TaskRun::query()
                ->selectRaw('status, COUNT(*) as c')
                ->groupBy('status')
                ->pluck('c', 'status')
                ->all();
            $out['running_jobs'] = (int) ($jobStatusCounts['running'] ?? 0);
            $out['pending_jobs'] = (int) ($jobStatusCounts['pending'] ?? 0);
            $out['failed_jobs'] = (int) ($jobStatusCounts['failed'] ?? 0);

            $out['recent_failures'] = DB::table('task_runs as tr')
                ->leftJoin('tasks as t', 'tr.task_id', '=', 't.id')
                ->where('tr.status', 'failed')
                ->orderByDesc('tr.created_at')
                ->select('tr.id', 'tr.error_message', 'tr.created_at', 't.name as task_name')
                ->limit(4)
                ->get()
                ->all();
        } catch (\Throwable) {
            // ignore
        }

        return $out;
    }

    /**
     * @return array<string, int>
     */
    private function buildMaterialHealth(): array
    {
        $out = [
            'keyword_libraries' => 0,
            'title_libraries' => 0,
            'knowledge_bases' => 0,
            'image_libraries' => 0,
            'authors' => 0,
            'knowledge_chunks' => 0,
            'vectorized_chunks' => 0,
            'unvectorized_chunks' => 0,
        ];

        try {
            $out['keyword_libraries'] = (int) KeywordLibrary::query()->count();
            $out['title_libraries'] = (int) TitleLibrary::query()->count();
            $out['knowledge_bases'] = (int) KnowledgeBase::query()->count();
            $out['image_libraries'] = (int) ImageLibrary::query()->count();
            $out['authors'] = (int) Author::query()->count();
            $out['knowledge_chunks'] = (int) KnowledgeChunk::query()->count();
            $out['vectorized_chunks'] = (int) KnowledgeChunk::query()
                ->where(function ($query): void {
                    $query->whereNotNull('embedding_json')
                        ->orWhereNotNull('embedding_model_id')
                        ->orWhereNotNull('embedding_vector');
                })
                ->count();
            $out['unvectorized_chunks'] = max(0, $out['knowledge_chunks'] - $out['vectorized_chunks']);
        } catch (\Throwable) {
            // ignore
        }

        return $out;
    }

    /**
     * @return array{chat_models: int, embedding_models: int, used_today: int, total_used: int, active_models: list<object>}
     */
    private function buildAiHealth(): array
    {
        $out = [
            'chat_models' => 0,
            'embedding_models' => 0,
            'used_today' => 0,
            'total_used' => 0,
            'active_models' => [],
        ];

        try {
            $activeModels = AiModel::query()->where('status', 'active');
            $out['chat_models'] = (int) (clone $activeModels)
                ->where(function ($query): void {
                    $query->whereNull('model_type')
                        ->orWhere('model_type', '')
                        ->orWhere('model_type', 'chat');
                })
                ->count();
            $out['embedding_models'] = (int) (clone $activeModels)
                ->where('model_type', 'embedding')
                ->count();
            $out['used_today'] = (int) AiModel::query()->sum('used_today');
            $out['total_used'] = (int) AiModel::query()->sum('total_used');
            $out['active_models'] = AiModel::query()
                ->where('status', 'active')
                ->orderBy('failover_priority')
                ->orderBy('id')
                ->select('id', 'name', 'model_id', 'model_type', 'used_today', 'daily_limit')
                ->limit(5)
                ->get()
                ->all();
        } catch (\Throwable) {
            // ignore
        }

        return $out;
    }

    /**
     * @return array{total: int, running: int, completed: int, failed: int, waiting_import: int, recent_jobs: list<object>}
     */
    private function buildUrlImportHealth(): array
    {
        $out = [
            'total' => 0,
            'running' => 0,
            'completed' => 0,
            'failed' => 0,
            'waiting_import' => 0,
            'recent_jobs' => [],
        ];

        try {
            $statusCounts = UrlImportJob::query()
                ->selectRaw('status, COUNT(*) as c')
                ->groupBy('status')
                ->pluck('c', 'status')
                ->all();
            $out['total'] = (int) array_sum($statusCounts);
            $out['running'] = (int) (($statusCounts['running'] ?? 0) + ($statusCounts['queued'] ?? 0));
            $out['completed'] = (int) ($statusCounts['completed'] ?? 0);
            $out['failed'] = (int) ($statusCounts['failed'] ?? 0);
            $out['waiting_import'] = (int) UrlImportJob::query()
                ->where('status', 'completed')
                ->where('current_step', '!=', 'imported')
                ->count();
            $out['recent_jobs'] = UrlImportJob::query()
                ->orderByDesc('created_at')
                ->select('id', 'source_domain', 'page_title', 'status', 'current_step', 'progress_percent', 'created_at')
                ->limit(5)
                ->get()
                ->all();
        } catch (\Throwable) {
            // ignore
        }

        return $out;
    }

    /**
     * @return list<object>
     */
    private function buildPopularArticles(): array
    {
        try {
            return DB::table('articles as a')
                ->leftJoin('categories as c', 'a.category_id', '=', 'c.id')
                ->whereNull('a.deleted_at')
                ->orderByDesc('a.view_count')
                ->orderByDesc('a.created_at')
                ->select('a.id', 'a.title', 'a.view_count', 'a.status', 'c.name as category_name')
                ->limit(5)
                ->get()
                ->all();
        } catch (\Throwable) {
            return [];
        }
    }

    /**
     * @param  array<string, int|float>  $stats
     * @param  array<string, int>  $materialHealth
     * @param  array{chat_models: int, embedding_models: int, used_today: int, total_used: int, active_models: list<object>}  $aiHealth
     * @param  array{total: int, running: int, completed: int, failed: int, waiting_import: int, recent_jobs: list<object>}  $urlImportHealth
     * @return list<array{label: string, value: int, href: string, tone: string}>
     */
    private function buildTodoItems(array $stats, array $materialHealth, array $aiHealth, array $urlImportHealth): array
    {
        $items = [];

        if ((int) ($stats['failed_jobs'] ?? 0) > 0) {
            $items[] = [
                'label' => __('admin.dashboard.todo_failed_jobs'),
                'value' => (int) ($stats['failed_jobs'] ?? 0),
                'href' => route('admin.tasks.index'),
                'tone' => 'red',
            ];
        }
        if ((int) ($stats['pending_review'] ?? 0) > 0) {
            $items[] = [
                'label' => __('admin.dashboard.todo_pending_review'),
                'value' => (int) ($stats['pending_review'] ?? 0),
                'href' => route('admin.articles.index', ['review_status' => 'pending']),
                'tone' => 'amber',
            ];
        }
        if ((int) ($aiHealth['chat_models'] ?? 0) === 0) {
            $items[] = [
                'label' => __('admin.dashboard.todo_no_chat_model'),
                'value' => 0,
                'href' => route('admin.ai-models.index'),
                'tone' => 'red',
            ];
        }
        if ((int) ($aiHealth['embedding_models'] ?? 0) === 0 && (int) ($materialHealth['knowledge_bases'] ?? 0) > 0) {
            $items[] = [
                'label' => __('admin.dashboard.todo_no_embedding_model'),
                'value' => 0,
                'href' => route('admin.ai-models.index'),
                'tone' => 'amber',
            ];
        }
        if ((int) ($materialHealth['unvectorized_chunks'] ?? 0) > 0) {
            $items[] = [
                'label' => __('admin.dashboard.todo_unvectorized_chunks'),
                'value' => (int) ($materialHealth['unvectorized_chunks'] ?? 0),
                'href' => route('admin.knowledge-bases.index'),
                'tone' => 'blue',
            ];
        }
        if ((int) ($stats['total_titles'] ?? 0) < 20) {
            $items[] = [
                'label' => __('admin.dashboard.todo_low_titles'),
                'value' => (int) ($stats['total_titles'] ?? 0),
                'href' => route('admin.title-libraries.index'),
                'tone' => 'slate',
            ];
        }
        if ((int) ($urlImportHealth['failed'] ?? 0) > 0) {
            $items[] = [
                'label' => __('admin.dashboard.todo_url_import_failed'),
                'value' => (int) ($urlImportHealth['failed'] ?? 0),
                'href' => route('admin.url-import.history'),
                'tone' => 'red',
            ];
        }

        return array_slice($items, 0, 6);
    }

    /**
     * 最近 7 个自然日（含今天）每日新增文章数，用于趋势图横轴。
     *
     * @return list<array{date: string, count: int}>
     */
    private function buildArticleTrendSeries(): array
    {
        $series = [];
        for ($i = 6; $i >= 0; $i--) {
            $day = now()->subDays($i)->startOfDay();
            $key = $day->format('Y-m-d');
            try {
                $count = (int) Article::query()
                    ->whereNull('deleted_at')
                    ->whereBetween('created_at', [$day, $day->copy()->endOfDay()])
                    ->count();
            } catch (\Throwable) {
                $count = 0;
            }
            $series[] = ['date' => $key, 'count' => $count];
        }

        return $series;
    }

    /**
     * 根据每日发文数生成 SVG 折线、面积填充路径及纵轴刻度等绘图数据。
     *
     * @param  list<array{date: string, count: int}>  $articleTrend
     * @return array{
     *   chart_height: int,
     *   chart_width: int,
     *   points: list<array{x: float, y: float, count: int, date: string}>,
     *   y_max: float,
     *   y_ticks: list<float|int>,
     *   line_path: string,
     *   area_path: string,
     *   peak_index: int,
     *   max_count: int,
     *   total_trend_count: int,
     *   avg_articles: float
     * }
     */
    private function buildArticleTrendChartPaths(array $articleTrend): array
    {
        $chartHeight = 148;
        $chartWidth = 600;
        $dataMaxCount = $articleTrend === [] ? 0 : (int) max(array_column($articleTrend, 'count'));
        $scaleMaxCount = $dataMaxCount === 0 ? 10 : $dataMaxCount;
        $yMax = ceil($scaleMaxCount * 1.2);
        if ($yMax < 5) {
            $yMax = 5;
        }

        $pointCount = count($articleTrend);
        $xStep = $pointCount > 1 ? ($chartWidth / ($pointCount - 1)) : $chartWidth;

        $points = [];
        foreach ($articleTrend as $index => $day) {
            $x = $index * $xStep;
            $y = $chartHeight - (($day['count'] / $yMax) * $chartHeight);
            $points[] = ['x' => $x, 'y' => $y, 'count' => (int) $day['count'], 'date' => (string) $day['date']];
        }

        $linePath = '';
        if ($points !== []) {
            $linePath = 'M'.$points[0]['x'].','.$points[0]['y'];
            $totalPoints = count($points);
            for ($i = 0; $i < $totalPoints - 1; $i++) {
                $p0 = $points[max($i - 1, 0)];
                $p1 = $points[$i];
                $p2 = $points[$i + 1];
                $p3 = $points[min($i + 2, $totalPoints - 1)];
                $cp1x = $p1['x'] + (($p2['x'] - $p0['x']) / 6);
                $cp1y = $p1['y'] + (($p2['y'] - $p0['y']) / 6);
                $cp2x = $p2['x'] - (($p3['x'] - $p1['x']) / 6);
                $cp2y = $p2['y'] - (($p3['y'] - $p1['y']) / 6);
                $linePath .= " C{$cp1x},{$cp1y} {$cp2x},{$cp2y} {$p2['x']},{$p2['y']}";
            }
        }

        $areaPath = '';
        if ($points !== []) {
            $firstPoint = $points[0];
            $lastPoint = $points[count($points) - 1];
            $areaPath = $linePath
                .' L'.$lastPoint['x'].','.$chartHeight
                .' L'.$firstPoint['x'].','.$chartHeight
                .' Z';
        }

        $peakIndex = 0;
        foreach ($points as $index => $point) {
            if ($dataMaxCount > 0 && $point['count'] === $dataMaxCount) {
                $peakIndex = $index;
                break;
            }
        }

        $yTicks = [];
        for ($i = 0; $i <= 4; $i++) {
            $yTicks[] = round($yMax - ($yMax / 4) * $i);
        }

        $totalTrendCount = array_sum(array_column($articleTrend, 'count'));
        $avgArticles = $pointCount > 0 ? round($totalTrendCount / $pointCount, 1) : 0.0;

        return [
            'chart_height' => $chartHeight,
            'chart_width' => $chartWidth,
            'points' => $points,
            'y_max' => $yMax,
            'y_ticks' => $yTicks,
            'line_path' => $linePath,
            'area_path' => $areaPath,
            'peak_index' => $peakIndex,
            'max_count' => $dataMaxCount,
            'total_trend_count' => $totalTrendCount,
            'avg_articles' => $avgArticles,
        ];
    }

    /**
     * 仪表盘性能区：任务平均耗时、队列成功率（已完成 / (已完成+失败)）、当日 AI 发文数。
     *
     * @return array{avg_generation_time: float, success_rate: float, daily_quota_used: int}
     */
    private function buildPerformanceStats(int $completedJobs, int $failedJobs): array
    {
        $totalFinished = $completedJobs + $failedJobs;
        $successRate = $totalFinished > 0 ? round(($completedJobs * 100.0) / $totalFinished, 2) : 0.0;
        $avg = 0.0;
        $daily = 0;
        try {
            $raw = TaskRun::query()
                ->where('duration_ms', '>', 0)
                ->selectRaw('AVG(duration_ms) / 1000.0 as avg_time')
                ->value('avg_time');
            $avg = (float) ($raw ?? 0);
        } catch (\Throwable) {
            // ignore
        }
        try {
            $daily = (int) Article::query()
                ->whereNull('deleted_at')
                ->whereDate('created_at', Carbon::today())
                ->where('is_ai_generated', 1)
                ->count();
        } catch (\Throwable) {
            // ignore
        }

        return [
            'avg_generation_time' => $avg,
            'success_rate' => $successRate,
            'daily_quota_used' => $daily,
        ];
    }
}
EOF_DASHBOARD_CONTROLLER_PHP
sudo mkdir -p 'app/Providers'
sudo tee 'app/Providers/AppServiceProvider.php' >/dev/null <<'EOF_APP_SERVICE_PROVIDER_PHP'
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
use App\View\Composers\SiteLayoutComposer;
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
EOF_APP_SERVICE_PROVIDER_PHP
sudo mkdir -p 'resources/views/admin'
sudo tee 'resources/views/admin/dashboard.blade.php' >/dev/null <<'EOF_ADMIN_DASHBOARD_BLADE'
@extends('admin.layouts.app')

@section('content')
    @php
        $publishRate = ($stats['total_articles'] ?? 0) > 0 ? round((($stats['published_articles'] ?? 0) / ($stats['total_articles'] ?? 1)) * 100, 1) : 0;
        $aiRatio = ($stats['total_articles'] ?? 0) > 0 ? round((($stats['ai_generated_articles'] ?? 0) / ($stats['total_articles'] ?? 1)) * 100, 1) : 0;
        $materialTotal = ($stats['total_keywords'] ?? 0) + ($stats['total_titles'] ?? 0) + ($stats['total_images'] ?? 0);
        $tc = $trend_chart ?? [];
        $ch = (int) ($tc['chart_height'] ?? 148);
        $cw = (int) ($tc['chart_width'] ?? 600);
        $funnelTones = [
            'blue' => ['bar' => 'bg-blue-600', 'pill' => 'bg-blue-50 text-blue-700'],
            'amber' => ['bar' => 'bg-amber-500', 'pill' => 'bg-amber-50 text-amber-700'],
            'purple' => ['bar' => 'bg-purple-600', 'pill' => 'bg-purple-50 text-purple-700'],
            'green' => ['bar' => 'bg-emerald-600', 'pill' => 'bg-emerald-50 text-emerald-700'],
            'slate' => ['bar' => 'bg-slate-700', 'pill' => 'bg-slate-100 text-slate-700'],
            'red' => ['bar' => 'bg-red-600', 'pill' => 'bg-red-50 text-red-700'],
        ];
        $todoToneClasses = [
            'red' => 'border-red-100 bg-red-50 text-red-700',
            'amber' => 'border-amber-100 bg-amber-50 text-amber-700',
            'blue' => 'border-blue-100 bg-blue-50 text-blue-700',
            'slate' => 'border-slate-200 bg-slate-50 text-slate-700',
        ];
    @endphp

    <div class="px-4 sm:px-0">
        <div class="mb-8">
            <div class="flex items-center justify-between">
                <div>
                    <h1 class="text-3xl font-bold text-gray-900">{{ __('admin.dashboard.heading') }}</h1>
                    <p class="mt-1 text-sm text-gray-600">{{ __('admin.dashboard.subtitle', ['site' => e($adminSiteName)]) }}</p>
                </div>
                <div class="flex items-center space-x-3">
                    <span class="text-sm text-gray-500">{{ __('admin.dashboard.last_updated', ['time' => now()->format('Y-m-d H:i:s')]) }}</span>
                    <button type="button" onclick="location.reload()" class="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                        <i data-lucide="refresh-cw" class="w-4 h-4 mr-1"></i>
                        {{ __('admin.dashboard.refresh') }}
                    </button>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div class="bg-white overflow-hidden shadow-lg rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="file-text" class="h-8 w-8 text-blue-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.total_articles') }}</dt>
                                <dd class="text-2xl font-bold text-gray-900">{{ number_format($stats['total_articles'] ?? 0) }}</dd>
                                <dd class="text-xs text-gray-500">{{ __('admin.dashboard.today_added', ['count' => $today_stats['today_articles'] ?? 0]) }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow-lg rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="globe" class="h-8 w-8 text-green-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.published') }}</dt>
                                <dd class="text-2xl font-bold text-gray-900">{{ number_format($stats['published_articles'] ?? 0) }}</dd>
                                <dd class="text-xs text-gray-500">{{ __('admin.dashboard.publish_rate', ['rate' => $publishRate]) }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow-lg rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="brain" class="h-8 w-8 text-purple-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.ai_generated') }}</dt>
                                <dd class="text-2xl font-bold text-gray-900">{{ number_format($stats['ai_generated_articles'] ?? 0) }}</dd>
                                <dd class="text-xs text-gray-500">{{ __('admin.dashboard.ai_generated_ratio', ['rate' => $aiRatio]) }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow-lg rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="eye" class="h-8 w-8 text-orange-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.total_views') }}</dt>
                                <dd class="text-2xl font-bold text-gray-900">{{ number_format((int) ($stats['total_views'] ?? 0)) }}</dd>
                                <dd class="text-xs text-gray-500">{{ __('admin.dashboard.today_views', ['count' => number_format($today_stats['today_views'] ?? 0)]) }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="zap" class="h-6 w-6 text-yellow-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.active_tasks') }}</dt>
                                <dd class="text-lg font-medium text-gray-900">{{ ($stats['running_jobs'] ?? 0) + ($stats['pending_jobs'] ?? 0) }} / {{ $stats['total_tasks'] ?? 0 }}</dd>
                                <dd class="text-xs text-gray-500">{{ __('admin.dashboard.active_tasks_detail', ['running' => $stats['running_jobs'] ?? 0, 'pending' => $stats['pending_jobs'] ?? 0]) }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="cpu" class="h-6 w-6 text-indigo-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.ai_models') }}</dt>
                                <dd class="text-lg font-medium text-gray-900">{{ $stats['active_ai_models'] ?? 0 }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="database" class="h-6 w-6 text-teal-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.material_total') }}</dt>
                                <dd class="text-lg font-medium text-gray-900">{{ number_format($materialTotal) }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white overflow-hidden shadow rounded-lg">
                <div class="p-5">
                    <div class="flex items-center">
                        <div class="flex-shrink-0">
                            <i data-lucide="clock" class="h-6 w-6 text-red-600"></i>
                        </div>
                        <div class="ml-5 w-0 flex-1">
                            <dl>
                                <dt class="text-sm font-medium text-gray-500 truncate">{{ __('admin.dashboard.pending_review') }}</dt>
                                <dd class="text-lg font-medium text-gray-900">{{ $stats['pending_review'] ?? 0 }}</dd>
                            </dl>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <section class="mb-8 overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
            <div class="border-b border-gray-100 px-6 py-5">
                <div class="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
                    <div>
                        <p class="text-xs font-semibold uppercase tracking-[0.2em] text-blue-600">{{ __('admin.dashboard.quick_start.eyebrow') }}</p>
                        <h2 class="mt-2 text-xl font-semibold text-gray-900">{{ __('admin.dashboard.quick_start.title') }}</h2>
                    </div>
                </div>
            </div>

            <div class="grid grid-cols-1 divide-y divide-gray-100 lg:grid-cols-3 lg:divide-x lg:divide-y-0">
                <div class="p-6">
                    <div class="flex items-start gap-4">
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-blue-600 text-sm font-semibold text-white">1</div>
                        <div>
                            <h3 class="text-base font-semibold text-gray-900">{{ __('admin.dashboard.quick_start.api_title') }}</h3>
                            <p class="mt-2 text-sm leading-6 text-gray-500">{{ __('admin.dashboard.quick_start.api_desc') }}</p>
                            <a href="{{ route('admin.ai-models.index') }}" class="mt-4 inline-flex items-center rounded-lg bg-blue-600 px-3 py-2 text-sm font-medium text-white hover:bg-blue-700">
                                <i data-lucide="plug-zap" class="mr-1.5 h-4 w-4"></i>
                                {{ __('admin.dashboard.quick_start.api_button') }}
                            </a>
                        </div>
                    </div>
                </div>

                <div class="p-6">
                    <div class="flex items-start gap-4">
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-emerald-600 text-sm font-semibold text-white">2</div>
                        <div class="min-w-0 flex-1">
                            <h3 class="text-base font-semibold text-gray-900">{{ __('admin.dashboard.quick_start.material_title') }}</h3>
                            <p class="mt-2 text-sm leading-6 text-gray-500">{{ __('admin.dashboard.quick_start.material_desc') }}</p>
                            <div class="mt-4 flex flex-wrap gap-2">
                                <a href="{{ route('admin.knowledge-bases.index') }}" class="inline-flex items-center rounded-full border border-orange-100 bg-orange-50 px-3 py-1.5 text-xs font-medium text-orange-700 hover:bg-orange-100">
                                    {{ __('admin.dashboard.quick_start.knowledge') }}
                                </a>
                                <a href="{{ route('admin.title-libraries.index') }}" class="inline-flex items-center rounded-full border border-green-100 bg-green-50 px-3 py-1.5 text-xs font-medium text-green-700 hover:bg-green-100">
                                    {{ __('admin.dashboard.quick_start.titles') }}
                                </a>
                                <a href="{{ route('admin.keyword-libraries.index') }}" class="inline-flex items-center rounded-full border border-blue-100 bg-blue-50 px-3 py-1.5 text-xs font-medium text-blue-700 hover:bg-blue-100">
                                    {{ __('admin.dashboard.quick_start.keywords') }}
                                </a>
                                <a href="{{ route('admin.image-libraries.index') }}" class="inline-flex items-center rounded-full border border-purple-100 bg-purple-50 px-3 py-1.5 text-xs font-medium text-purple-700 hover:bg-purple-100">
                                    {{ __('admin.dashboard.quick_start.images') }}
                                </a>
                                <a href="{{ route('admin.authors.index') }}" class="inline-flex items-center rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-medium text-slate-700 hover:bg-slate-100">
                                    {{ __('admin.dashboard.quick_start.authors') }}
                                </a>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="p-6">
                    <div class="flex items-start gap-4">
                        <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-slate-900 text-sm font-semibold text-white">3</div>
                        <div>
                            <h3 class="text-base font-semibold text-gray-900">{{ __('admin.dashboard.quick_start.task_title') }}</h3>
                            <p class="mt-2 text-sm leading-6 text-gray-500">{{ __('admin.dashboard.quick_start.task_desc') }}</p>
                            <a href="{{ route('admin.tasks.create') }}" class="mt-4 inline-flex items-center rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50">
                                <i data-lucide="plus" class="mr-1.5 h-4 w-4"></i>
                                {{ __('admin.dashboard.quick_start.task_button') }}
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <div class="bg-white shadow rounded-lg">
                <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-medium text-gray-900">{{ __('admin.dashboard.category_distribution') }}</h3>
                        <a href="{{ route('admin.categories.index') }}" class="text-sm text-blue-600 hover:text-blue-800">
                            <i data-lucide="settings" class="w-4 h-4 inline mr-1"></i>
                            {{ __('admin.dashboard.manage_categories') }}
                        </a>
                    </div>
                </div>
                <div class="p-6">
                    @if (empty($category_distribution))
                        <p class="text-gray-500 text-center py-4">{{ __('admin.dashboard.no_data') }}</p>
                    @else
                        <div class="space-y-3">
                            @foreach ($category_distribution as $category)
                                <div class="flex items-center justify-between">
                                    <div class="flex-1">
                                        <div class="flex items-center justify-between mb-1">
                                            <span class="text-sm font-medium text-gray-900">{{ $category['name'] }}</span>
                                            <span class="text-sm text-gray-500">{{ $category['count'] }}</span>
                                        </div>
                                        <div class="w-full bg-gray-200 rounded-full h-2">
                                            <div class="bg-blue-600 h-2 rounded-full" style="width: {{ ($stats['total_articles'] ?? 0) > 0 ? ($category['count'] / ($stats['total_articles'] ?? 1)) * 100 : 0 }}%"></div>
                                        </div>
                                    </div>
                                </div>
                            @endforeach
                        </div>
                    @endif
                </div>
            </div>

            <div class="bg-white shadow rounded-lg">
                <div class="px-6 py-4 border-b border-gray-200">
                    <h3 class="text-lg font-medium text-gray-900">{{ __('admin.dashboard.system_performance') }}</h3>
                </div>
                <div class="p-6">
                    <div class="space-y-4">
                        <div>
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-sm font-medium text-gray-700">{{ __('admin.dashboard.task_success_rate') }}</span>
                                <span class="text-sm text-gray-900">{{ number_format($performance_stats['success_rate'] ?? 0, 1) }}%</span>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-green-600 h-2 rounded-full" style="width: {{ min($performance_stats['success_rate'] ?? 0, 100) }}%"></div>
                            </div>
                        </div>
                        <div>
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-sm font-medium text-gray-700">{{ __('admin.dashboard.avg_generation_time') }}</span>
                                <span class="text-sm text-gray-900">{{ number_format($performance_stats['avg_generation_time'] ?? 0, 1) }}s</span>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-yellow-600 h-2 rounded-full" style="width: {{ min((($performance_stats['avg_generation_time'] ?? 0) / 60) * 100, 100) }}%"></div>
                            </div>
                        </div>
                        <div>
                            <div class="flex items-center justify-between mb-2">
                                <span class="text-sm font-medium text-gray-700">{{ __('admin.dashboard.daily_ai_quota') }}</span>
                                <span class="text-sm text-gray-900">{{ $performance_stats['daily_quota_used'] ?? 0 }} / 100</span>
                            </div>
                            <div class="w-full bg-gray-200 rounded-full h-2">
                                <div class="bg-purple-600 h-2 rounded-full" style="width: {{ min((($performance_stats['daily_quota_used'] ?? 0) / 100) * 100, 100) }}%"></div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-white shadow rounded-lg">
                <div class="px-6 py-4 border-b border-gray-200">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-medium text-gray-900">{{ __('admin.dashboard.latest_articles') }}</h3>
                        <a href="{{ route('admin.articles.index') }}" class="text-sm text-blue-600 hover:text-blue-800">{{ __('admin.dashboard.view_all') }}</a>
                    </div>
                </div>
                <div class="p-6">
                    @if (empty($latest_articles))
                        <p class="text-gray-500 text-center py-4">{{ __('admin.dashboard.no_articles') }}</p>
                    @else
                        <div class="space-y-3">
                            @foreach ($latest_articles as $article)
                                <div class="flex items-start space-x-3">
                                    <div class="flex-shrink-0">
                                        @if (!empty($article->is_ai_generated))
                                            <i data-lucide="brain" class="w-4 h-4 text-purple-500 mt-0.5"></i>
                                        @else
                                            <i data-lucide="edit" class="w-4 h-4 text-gray-400 mt-0.5"></i>
                                        @endif
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <p class="text-sm font-medium text-gray-900 truncate">{{ $article->title }}</p>
                                        <p class="text-xs text-gray-500">
                                            {{ $article->category_name ?? __('admin.dashboard.uncategorized') }} •
                                            {{ $article->created_at ? \Illuminate\Support\Carbon::parse($article->created_at)->format('m-d H:i') : '' }}
                                        </p>
                                    </div>
                                    <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium {{ ($article->status ?? '') === 'published' ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800' }}">
                                        {{ ($article->status ?? '') === 'published' ? __('admin.articles.status.published') : __('admin.articles.status.draft') }}
                                    </span>
                                </div>
                            @endforeach
                        </div>
                    @endif
                </div>
            </div>
        </div>

        <div class="bg-white shadow rounded-lg" style="margin-bottom: 2rem;">
            <div class="px-6 py-4 border-b border-gray-200">
                <h3 class="text-lg font-medium text-gray-900">{{ __('admin.dashboard.trend_title') }}</h3>
            </div>
            <div class="p-6">
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="text-center">
                        <div class="text-2xl font-bold text-blue-600">{{ $week_stats['week_articles'] ?? 0 }}</div>
                        <div class="text-sm text-gray-500">{{ __('admin.dashboard.week_articles') }}</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-green-600">{{ $week_stats['week_tasks'] ?? 0 }}</div>
                        <div class="text-sm text-gray-500">{{ __('admin.dashboard.week_tasks') }}</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-purple-600">{{ $stats['approved_articles'] ?? 0 }}</div>
                        <div class="text-sm text-gray-500">{{ __('admin.dashboard.approved_articles') }}</div>
                    </div>
                </div>

                @if (!empty($article_trend))
                    <div class="mt-6">
                        <h4 class="text-sm font-medium text-gray-700 mb-4">{{ __('admin.dashboard.article_trend') }}</h4>
                        <div class="relative rounded-2xl border border-slate-200 bg-gradient-to-b from-slate-50 via-white to-white px-4 pt-5 pb-10 overflow-hidden" style="height: 236px;">
                            <div class="absolute left-0 top-0 flex flex-col justify-between text-[11px] text-slate-400" style="height: {{ $ch }}px; width: 28px;">
                                @foreach ($tc['y_ticks'] ?? [] as $tick)
                                    <span class="text-right">{{ $tick }}</span>
                                @endforeach
                            </div>

                            <svg class="absolute top-0" style="left: 36px; height: {{ $ch }}px; width: calc(100% - 48px);" viewBox="0 0 {{ $cw }} {{ $ch }}" preserveAspectRatio="none">
                                <defs>
                                    <linearGradient id="articleTrendFill" x1="0" y1="0" x2="0" y2="1">
                                        <stop offset="0%" stop-color="#3b82f6" stop-opacity="0.18"/>
                                        <stop offset="100%" stop-color="#3b82f6" stop-opacity="0.02"/>
                                    </linearGradient>
                                </defs>
                                @for ($i = 0; $i <= 4; $i++)
                                    @php $yPos = ($ch / 4) * $i; @endphp
                                    <line x1="0" y1="{{ $yPos }}" x2="{{ $cw }}" y2="{{ $yPos }}"
                                          stroke="{{ $i === 4 ? '#cbd5e1' : '#e2e8f0' }}"
                                          stroke-width="1"
                                          stroke-dasharray="{{ $i === 4 ? '0' : '4 6' }}"/>
                                @endfor

                                @if (!empty($tc['area_path']))
                                    <path d="{{ $tc['area_path'] }}" fill="url(#articleTrendFill)"/>
                                @endif
                                @if (!empty($tc['line_path']))
                                    <path d="{{ $tc['line_path'] }}"
                                          fill="none"
                                          stroke="rgba(59, 130, 246, 0.12)"
                                          stroke-width="6"
                                          stroke-linecap="round"
                                          stroke-linejoin="round"
                                          vector-effect="non-scaling-stroke"/>
                                    <path d="{{ $tc['line_path'] }}"
                                          fill="none"
                                          stroke="#3b82f6"
                                          stroke-width="2"
                                          stroke-linecap="round"
                                          stroke-linejoin="round"
                                          vector-effect="non-scaling-stroke"/>
                                @endif
                                @foreach ($tc['points'] ?? [] as $index => $point)
                                    <circle cx="{{ $point['x'] }}"
                                            cy="{{ $point['y'] }}"
                                            r="{{ $index === ($tc['peak_index'] ?? 0) ? '3.8' : '2.4' }}"
                                            fill="{{ $index === ($tc['peak_index'] ?? 0) ? '#3b82f6' : '#ffffff' }}"
                                            stroke="#3b82f6"
                                            stroke-width="{{ $index === ($tc['peak_index'] ?? 0) ? '1.8' : '1.4' }}"
                                            vector-effect="non-scaling-stroke"/>
                                @endforeach
                            </svg>

                            <div class="absolute flex justify-between text-xs text-slate-500" style="left: 36px; bottom: 0; width: calc(100% - 48px); height: 40px;">
                                @foreach ($article_trend as $day)
                                    <div class="flex items-start justify-center pt-2">
                                        <span>{{ \Illuminate\Support\Carbon::parse($day['date'])->format('m/d') }}</span>
                                    </div>
                                @endforeach
                            </div>
                        </div>

                        <div class="mt-3 flex items-center justify-center space-x-8 text-xs text-gray-600">
                            {!! __('admin.dashboard.total_stat', ['count' => '<strong class="text-gray-900">'.e($tc['total_trend_count'] ?? 0).'</strong>']) !!}
                            {!! __('admin.dashboard.avg_stat', ['count' => '<strong class="text-gray-900">'.e($tc['avg_articles'] ?? 0).'</strong>']) !!}
                            {!! __('admin.dashboard.peak_stat', ['count' => '<strong class="text-gray-900">'.e($tc['max_count'] ?? 0).'</strong>']) !!}
                        </div>
                    </div>
                @else
                    <div class="mt-6 text-center text-gray-500 py-8">
                        <p class="text-sm">{{ __('admin.dashboard.no_data') }}</p>
                    </div>
                @endif
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <section class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.task_health') }}</h3>
                </div>
                <div class="p-6">
                    <div class="grid grid-cols-2 gap-3">
                        <div class="rounded-xl bg-blue-50 p-4">
                            <div class="text-2xl font-bold text-blue-700">{{ $task_health['active_tasks'] ?? 0 }}</div>
                            <div class="mt-1 text-xs font-medium text-blue-700">{{ __('admin.dashboard.task_active') }}</div>
                        </div>
                        <div class="rounded-xl bg-slate-50 p-4">
                            <div class="text-2xl font-bold text-slate-700">{{ $task_health['paused_tasks'] ?? 0 }}</div>
                            <div class="mt-1 text-xs font-medium text-slate-600">{{ __('admin.dashboard.task_paused') }}</div>
                        </div>
                        <div class="rounded-xl bg-emerald-50 p-4">
                            <div class="text-2xl font-bold text-emerald-700">{{ $task_health['running_jobs'] ?? 0 }}</div>
                            <div class="mt-1 text-xs font-medium text-emerald-700">{{ __('admin.dashboard.task_running') }}</div>
                        </div>
                        <div class="rounded-xl bg-amber-50 p-4">
                            <div class="text-2xl font-bold text-amber-700">{{ $task_health['pending_jobs'] ?? 0 }}</div>
                            <div class="mt-1 text-xs font-medium text-amber-700">{{ __('admin.dashboard.task_pending') }}</div>
                        </div>
                    </div>
                    <div class="mt-5">
                        <div class="mb-2 text-sm font-semibold text-gray-900">{{ __('admin.dashboard.recent_failures') }}</div>
                        @if (empty($task_health['recent_failures']))
                            <p class="rounded-xl bg-gray-50 px-4 py-3 text-sm text-gray-500">{{ __('admin.dashboard.no_failures') }}</p>
                        @else
                            <div class="space-y-2">
                                @foreach ($task_health['recent_failures'] as $failure)
                                    <div class="rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-sm">
                                        <div class="font-medium text-red-700">{{ $failure->task_name ?? __('admin.dashboard.unknown_task') }}</div>
                                        <div class="mt-1 line-clamp-2 text-xs text-red-600">{{ $failure->error_message }}</div>
                                    </div>
                                @endforeach
                            </div>
                        @endif
                    </div>
                </div>
            </section>

            <section class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.material_health') }}</h3>
                </div>
                <div class="p-6">
                    <div class="grid grid-cols-2 gap-3 text-sm">
                        <a href="{{ route('admin.keyword-libraries.index') }}" class="rounded-xl border border-gray-100 p-4 hover:bg-gray-50">
                            <div class="text-xl font-bold text-gray-900">{{ $material_health['keyword_libraries'] ?? 0 }}</div>
                            <div class="mt-1 text-gray-500">{{ __('admin.dashboard.material_keywords') }}</div>
                        </a>
                        <a href="{{ route('admin.title-libraries.index') }}" class="rounded-xl border border-gray-100 p-4 hover:bg-gray-50">
                            <div class="text-xl font-bold text-gray-900">{{ $material_health['title_libraries'] ?? 0 }}</div>
                            <div class="mt-1 text-gray-500">{{ __('admin.dashboard.material_titles') }}</div>
                        </a>
                        <a href="{{ route('admin.knowledge-bases.index') }}" class="rounded-xl border border-gray-100 p-4 hover:bg-gray-50">
                            <div class="text-xl font-bold text-gray-900">{{ $material_health['knowledge_bases'] ?? 0 }}</div>
                            <div class="mt-1 text-gray-500">{{ __('admin.dashboard.material_knowledge') }}</div>
                        </a>
                        <a href="{{ route('admin.authors.index') }}" class="rounded-xl border border-gray-100 p-4 hover:bg-gray-50">
                            <div class="text-xl font-bold text-gray-900">{{ $material_health['authors'] ?? 0 }}</div>
                            <div class="mt-1 text-gray-500">{{ __('admin.dashboard.material_authors') }}</div>
                        </a>
                    </div>
                    <div class="mt-5 rounded-xl bg-slate-50 p-4">
                        @php
                            $chunkTotal = max(1, (int) ($material_health['knowledge_chunks'] ?? 0));
                            $vectorPercent = min(100, round(((int) ($material_health['vectorized_chunks'] ?? 0) / $chunkTotal) * 100));
                        @endphp
                        <div class="flex items-center justify-between text-sm">
                            <span class="font-medium text-gray-700">{{ __('admin.dashboard.material_vectorized') }}</span>
                            <span class="text-gray-500">{{ number_format($material_health['vectorized_chunks'] ?? 0) }} / {{ number_format($material_health['knowledge_chunks'] ?? 0) }}</span>
                        </div>
                        <div class="mt-3 h-2 rounded-full bg-white">
                            <div class="h-full rounded-full bg-emerald-600" style="width: {{ $vectorPercent }}%"></div>
                        </div>
                    </div>
                </div>
            </section>

            <section class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.ai_health') }}</h3>
                </div>
                <div class="p-6">
                    <div class="grid grid-cols-2 gap-3">
                        <div class="rounded-xl bg-indigo-50 p-4">
                            <div class="text-2xl font-bold text-indigo-700">{{ $ai_health['chat_models'] ?? 0 }}</div>
                            <div class="mt-1 text-xs font-medium text-indigo-700">{{ __('admin.dashboard.ai_chat_models') }}</div>
                        </div>
                        <div class="rounded-xl bg-purple-50 p-4">
                            <div class="text-2xl font-bold text-purple-700">{{ $ai_health['embedding_models'] ?? 0 }}</div>
                            <div class="mt-1 text-xs font-medium text-purple-700">{{ __('admin.dashboard.ai_embedding_models') }}</div>
                        </div>
                    </div>
                    <div class="mt-5 space-y-3 text-sm">
                        <div class="flex items-center justify-between rounded-xl bg-gray-50 px-4 py-3">
                            <span class="text-gray-500">{{ __('admin.dashboard.ai_used_today') }}</span>
                            <span class="font-semibold text-gray-900">{{ number_format($ai_health['used_today'] ?? 0) }}</span>
                        </div>
                        <div class="flex items-center justify-between rounded-xl bg-gray-50 px-4 py-3">
                            <span class="text-gray-500">{{ __('admin.dashboard.ai_total_calls') }}</span>
                            <span class="font-semibold text-gray-900">{{ number_format($ai_health['total_used'] ?? 0) }}</span>
                        </div>
                    </div>
                </div>
            </section>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <section class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.url_import_health') }}</h3>
                        <a href="{{ route('admin.url-import.history') }}" class="text-sm font-medium text-blue-600 hover:text-blue-800">{{ __('admin.dashboard.view_all') }}</a>
                    </div>
                </div>
                <div class="p-6">
                    <div class="grid grid-cols-4 gap-3">
                        <div class="rounded-xl bg-slate-50 p-3 text-center">
                            <div class="text-xl font-bold text-slate-900">{{ $url_import_health['total'] ?? 0 }}</div>
                            <div class="mt-1 text-xs text-slate-500">{{ __('admin.dashboard.url_import_total') }}</div>
                        </div>
                        <div class="rounded-xl bg-blue-50 p-3 text-center">
                            <div class="text-xl font-bold text-blue-700">{{ $url_import_health['running'] ?? 0 }}</div>
                            <div class="mt-1 text-xs text-blue-700">{{ __('admin.dashboard.url_import_running') }}</div>
                        </div>
                        <div class="rounded-xl bg-emerald-50 p-3 text-center">
                            <div class="text-xl font-bold text-emerald-700">{{ $url_import_health['completed'] ?? 0 }}</div>
                            <div class="mt-1 text-xs text-emerald-700">{{ __('admin.dashboard.url_import_completed') }}</div>
                        </div>
                        <div class="rounded-xl bg-red-50 p-3 text-center">
                            <div class="text-xl font-bold text-red-700">{{ $url_import_health['failed'] ?? 0 }}</div>
                            <div class="mt-1 text-xs text-red-700">{{ __('admin.dashboard.url_import_failed') }}</div>
                        </div>
                    </div>
                    <div class="mt-5 space-y-2">
                        @forelse (($url_import_health['recent_jobs'] ?? []) as $job)
                            <a href="{{ route('admin.url-import.show', $job->id) }}" class="flex items-center justify-between rounded-xl border border-gray-100 px-4 py-3 text-sm hover:bg-gray-50">
                                <span class="min-w-0 truncate text-gray-700">{{ $job->page_title ?: ($job->source_domain ?: '#'.$job->id) }}</span>
                                <span class="ml-3 shrink-0 rounded-full bg-slate-100 px-2 py-1 text-xs text-slate-600">{{ $job->status }}</span>
                            </a>
                        @empty
                            <p class="rounded-xl bg-gray-50 px-4 py-3 text-sm text-gray-500">{{ __('admin.dashboard.no_data') }}</p>
                        @endforelse
                    </div>
                </div>
            </section>

            <section class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.popular_articles') }}</h3>
                </div>
                <div class="p-6">
                    <div class="space-y-3">
                        @forelse (($popular_articles ?? []) as $article)
                            <div class="flex items-start justify-between gap-4 rounded-xl border border-gray-100 px-4 py-3">
                                <div class="min-w-0">
                                    <div class="truncate text-sm font-medium text-gray-900">{{ $article->title }}</div>
                                    <div class="mt-1 text-xs text-gray-500">{{ $article->category_name ?? __('admin.dashboard.uncategorized') }}</div>
                                </div>
                                <span class="shrink-0 text-sm font-semibold text-gray-700">{{ __('admin.dashboard.view_count_short', ['count' => number_format((int) $article->view_count)]) }}</span>
                            </div>
                        @empty
                            <p class="rounded-xl bg-gray-50 px-4 py-3 text-sm text-gray-500">{{ __('admin.dashboard.no_articles') }}</p>
                        @endforelse
                    </div>
                </div>
            </section>
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6 mb-8">
            <section class="xl:col-span-2 overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <div class="flex items-center justify-between">
                        <div>
                            <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.content_funnel') }}</h3>
                            <p class="mt-1 text-sm text-gray-500">{{ __('admin.dashboard.content_funnel_desc') }}</p>
                        </div>
                        <i data-lucide="activity" class="h-5 w-5 text-blue-500"></i>
                    </div>
                </div>
                <div class="p-6">
                    <div class="grid grid-cols-1 gap-4 md:grid-cols-5">
                        @foreach (($content_funnel['stages'] ?? []) as $stage)
                            @php
                                $tone = $funnelTones[$stage['tone'] ?? 'slate'] ?? $funnelTones['slate'];
                                $percent = (($content_funnel['max'] ?? 1) > 0) ? min(100, round(($stage['count'] / ($content_funnel['max'] ?? 1)) * 100)) : 0;
                            @endphp
                            <div class="rounded-xl border border-gray-100 bg-gray-50/60 p-4">
                                <div class="flex items-center justify-between gap-3">
                                    <span class="text-sm font-medium text-gray-600">{{ $stage['label'] }}</span>
                                    <span class="rounded-full px-2 py-1 text-xs font-semibold {{ $tone['pill'] }}">{{ number_format((int) $stage['count']) }}</span>
                                </div>
                                <div class="mt-4 h-2 overflow-hidden rounded-full bg-white">
                                    <div class="h-full rounded-full {{ $tone['bar'] }}" style="width: {{ $percent }}%"></div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            </section>

            <section class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
                <div class="border-b border-gray-100 px-6 py-5">
                    <div class="flex items-center justify-between">
                        <h3 class="text-lg font-semibold text-gray-900">{{ __('admin.dashboard.todo_title') }}</h3>
                        <i data-lucide="bell-ring" class="h-5 w-5 text-amber-500"></i>
                    </div>
                </div>
                <div class="p-6">
                    @if (empty($todo_items))
                        <div class="rounded-xl border border-emerald-100 bg-emerald-50 px-4 py-5 text-sm font-medium text-emerald-700">
                            {{ __('admin.dashboard.todo_empty') }}
                        </div>
                    @else
                        <div class="space-y-3">
                            @foreach ($todo_items as $item)
                                <a href="{{ $item['href'] }}" class="flex items-center justify-between rounded-xl border px-4 py-3 text-sm font-medium transition hover:-translate-y-0.5 hover:shadow-sm {{ $todoToneClasses[$item['tone'] ?? 'slate'] ?? $todoToneClasses['slate'] }}">
                                    <span>{{ $item['label'] }}</span>
                                    <span>{{ number_format((int) $item['value']) }}</span>
                                </a>
                            @endforeach
                        </div>
                    @endif
                </div>
            </section>
        </div>

    </div>
@endsection
EOF_ADMIN_DASHBOARD_BLADE
echo '[2/4] Rebuilding app image...'
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml build app
echo '[3/4] Restarting PHP services...'
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --force-recreate app queue scheduler reverb
echo '[4/4] Clearing and warming caches...'
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan optimize:clear
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan view:cache
echo 'DONE'
