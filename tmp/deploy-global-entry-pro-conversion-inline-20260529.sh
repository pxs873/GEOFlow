#!/usr/bin/env bash
set -euo pipefail
sudo -v
cd /opt/geoflow
echo '[1/4] Writing updated files...'
sudo mkdir -p 'app/Http/Controllers/Site'
sudo tee 'app/Http/Controllers/Site/ContactController.php' >/dev/null <<'EOF_APP_HTTP_CONTROLLERS_SITE_CONTACTCONTROLLER_PHP'
<?php

namespace App\Http\Controllers\Site;

use App\Http\Controllers\Controller;
use App\Models\Article;
use App\Support\Site\ArticleHtmlPresenter;
use App\Support\Site\SiteSettingsBag;
use App\Support\Site\SiteThemeViewResolver;
use Illuminate\View\View;

/**
 * 前台联系/评估页：承接强咨询意图，将访客导向 WhatsApp 为主、微信为辅的联系动作。
 */
class ContactController extends Controller
{
    public function show(): View
    {
        $map = SiteSettingsBag::all();

        $siteTitle = (string) ($map['site_name'] ?? config('geoflow.site_name', config('app.name')));
        $siteDescription = (string) ($map['site_description'] ?? config('geoflow.site_description', ''));
        $siteKeywords = (string) ($map['site_keywords'] ?? config('geoflow.site_keywords', ''));

        $featuredArticles = Article::query()
            ->with(['category', 'author'])
            ->published()
            ->orderByDesc('is_featured')
            ->orderByDesc('published_at')
            ->orderByDesc('id')
            ->limit(4)
            ->get();

        $cardSummaries = [];
        foreach ($featuredArticles as $article) {
            $cardSummaries[$article->id] = ArticleHtmlPresenter::cardSummary($article, 100);
        }

        return SiteThemeViewResolver::first('contact', [
            'activeNav' => 'contact',
            'siteTitle' => $siteTitle,
            'siteDescription' => $siteDescription,
            'siteKeywords' => $siteKeywords,
            'featuredArticles' => $featuredArticles,
            'cardSummaries' => $cardSummaries,
            'pageTitle' => '海外电商平台入驻咨询 - '.$siteTitle,
            'pageDescription' => '先判断产品适合哪个平台，再看资料、审核风险和启动成本，优先通过 WhatsApp 发起咨询。',
            'canonicalUrl' => route('site.contact'),
        ]);
    }
}
EOF_APP_HTTP_CONTROLLERS_SITE_CONTACTCONTROLLER_PHP
sudo mkdir -p 'routes'
sudo tee 'routes/web.php' >/dev/null <<'EOF_ROUTES_WEB_PHP'
<?php

/**
 * Web 路由：前台与 Blade 管理后台（路径见 config/geoflow.admin_base_path，默认 geo_admin）。
 */

use App\Http\Controllers\Admin\AdminActivityLogController;
use App\Http\Controllers\Admin\AdminAuthController;
use App\Http\Controllers\Admin\AdminUserController;
use App\Http\Controllers\Admin\AdminWelcomeController;
use App\Http\Controllers\Admin\AiModelController;
use App\Http\Controllers\Admin\AiPromptController;
use App\Http\Controllers\Admin\AiSpecialPromptController;
use App\Http\Controllers\Admin\ApiTokenController;
use App\Http\Controllers\Admin\ArticleController;
use App\Http\Controllers\Admin\AuthorController;
use App\Http\Controllers\Admin\CategoryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\ImageLibraryController;
use App\Http\Controllers\Admin\KeywordLibraryController;
use App\Http\Controllers\Admin\KnowledgeBaseController;
use App\Http\Controllers\Admin\LegacyController;
use App\Http\Controllers\Admin\MaterialsController;
use App\Http\Controllers\Admin\SecuritySettingsController;
use App\Http\Controllers\Admin\SiteSettingsController;
use App\Http\Controllers\Admin\TaskController;
use App\Http\Controllers\Admin\TitleLibraryController;
use App\Http\Controllers\Admin\UrlImportController;
use App\Models\Article;
use App\Models\Category;
use App\Http\Controllers\Site\ArchiveController;
use App\Http\Controllers\Site\ArticleController as SiteArticleController;
use App\Http\Controllers\Site\CategoryController as SiteCategoryController;
use App\Http\Controllers\Site\ContactController;
use App\Http\Controllers\Site\HomeController;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

Route::middleware(['site.locale'])->group(function (): void {
    Route::get('/', [HomeController::class, 'index'])->name('site.home');
    Route::get('/contact', [ContactController::class, 'show'])->name('site.contact');
    Route::get('/archive', [ArchiveController::class, 'index'])->name('site.archive');
    Route::get('/archive/{year}/{month}', [ArchiveController::class, 'month'])
        ->name('site.archive.month')
        ->where(['year' => '[0-9]{4}', 'month' => '[0-9]{2}']);
    Route::get('/category/{slug}', [SiteCategoryController::class, 'show'])->name('site.category');
    Route::get('/article/{slug}', [SiteArticleController::class, 'show'])->name('site.article');
});

Route::get('/sitemap.xml', function () {
    $baseUrl = rtrim((string) config('app.url'), '/');

    if (in_array(request()->getHost(), ['globalentrypro.com', 'www.globalentrypro.com'], true)) {
        $baseUrl = 'https://'.request()->getHost();
    } elseif ($baseUrl === '') {
        $baseUrl = rtrim(request()->getSchemeAndHttpHost(), '/');
    }

    $absoluteUrl = function (string $path) use ($baseUrl): string {
        return $baseUrl.'/'.ltrim($path, '/');
    };

    $urls = collect([
        [
            'loc' => $absoluteUrl(route('site.home', [], false)),
            'lastmod' => now()->toAtomString(),
            'changefreq' => 'daily',
            'priority' => '1.0',
        ],
        [
            'loc' => $absoluteUrl(route('site.contact', [], false)),
            'lastmod' => now()->toAtomString(),
            'changefreq' => 'weekly',
            'priority' => '0.9',
        ],
    ]);

    Category::query()
        ->whereHas('articles', fn ($query) => $query->published())
        ->orderBy('id')
        ->get(['slug', 'created_at'])
        ->each(function (Category $category) use (&$urls, $absoluteUrl): void {
            $urls->push([
                'loc' => $absoluteUrl(route('site.category', $category->slug, false)),
                'lastmod' => optional($category->created_at)->toAtomString() ?: now()->toAtomString(),
                'changefreq' => 'weekly',
                'priority' => '0.8',
            ]);
        });

    Article::query()
        ->published()
        ->orderByDesc('published_at')
        ->orderByDesc('id')
        ->get(['slug', 'updated_at', 'published_at'])
        ->each(function (Article $article) use (&$urls, $absoluteUrl): void {
            $urls->push([
                'loc' => $absoluteUrl(route('site.article', $article->slug, false)),
                'lastmod' => optional($article->updated_at ?? $article->published_at)->toAtomString() ?: now()->toAtomString(),
                'changefreq' => 'monthly',
                'priority' => '0.7',
            ]);
        });

    $xml = collect(['<?xml version="1.0" encoding="UTF-8"?>', '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'])
        ->merge($urls->map(function (array $url): string {
            return sprintf(
                "    <url>\n        <loc>%s</loc>\n        <lastmod>%s</lastmod>\n        <changefreq>%s</changefreq>\n        <priority>%s</priority>\n    </url>",
                e($url['loc']),
                e($url['lastmod']),
                e($url['changefreq']),
                e($url['priority'])
            );
        }))
        ->push('</urlset>')
        ->implode("\n");

    return response($xml, 200)
        ->header('Content-Type', 'application/xml; charset=UTF-8')
        ->header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
        ->header('Pragma', 'no-cache')
        ->header('Expires', '0');
})->name('site.sitemap');

$adminPrefix = trim((string) config('geoflow.admin_base_path', '/geo_admin'), '/');

Route::prefix($adminPrefix)->name('admin.')->middleware(['admin.locale'])->group(function () {
    // 通用入口与语言切换
    Route::get('locale/{locale}', [AdminAuthController::class, 'switchLocale'])->name('locale.switch');

    Route::get('/', function () {
        return Auth::guard('admin')->check()
            ? redirect()->route('admin.dashboard')
            : redirect()->route('admin.login');
    })->name('entry');

    // 访客认证路由
    Route::middleware('guest:admin')->group(function () {
        Route::get('login', [AdminAuthController::class, 'showLoginForm'])->name('login');
        Route::post('login', [AdminAuthController::class, 'login'])->name('login.attempt');
    });

    // 后台受保护路由
    Route::middleware(['admin.auth', 'admin.activity'])->group(function () {
        // 会话与首页
        Route::post('logout', [AdminAuthController::class, 'logout'])->name('logout');
        Route::post('welcome/dismiss', [AdminWelcomeController::class, 'dismiss'])->name('welcome.dismiss');
        Route::get('dashboard', [DashboardController::class, 'index'])->name('dashboard');

        // 任务管理（Blade 新路径）
        Route::prefix('tasks')->name('tasks.')->group(function () {
            Route::get('/', [TaskController::class, 'index'])->name('index');
            Route::post('{taskId}/toggle-status', [TaskController::class, 'toggleStatus'])->name('toggle-status');
            Route::post('{taskId}/delete', [TaskController::class, 'destroyTask'])->name('delete');
            Route::get('create', [TaskController::class, 'create'])->name('create');
            Route::post('create', [TaskController::class, 'store'])->name('store');
            Route::get('{taskId}/edit', [TaskController::class, 'edit'])->name('edit');
            Route::put('{taskId}', [TaskController::class, 'update'])->name('update');
            Route::get('health-check', [TaskController::class, 'healthCheck'])->name('health');
            Route::post('batch/start', [TaskController::class, 'batchAction'])->name('batch');
        });

        // 文章管理（Blade 新路径）
        Route::prefix('articles')->name('articles.')->group(function () {
            Route::get('/', [ArticleController::class, 'index'])->name('index');
            Route::post('batch/update-status', [ArticleController::class, 'batchUpdateStatus'])->name('batch.update-status');
            Route::post('batch/update-review', [ArticleController::class, 'batchUpdateReview'])->name('batch.update-review');
            Route::post('batch/delete', [ArticleController::class, 'batchDelete'])->name('batch.delete');
            Route::post('batch/restore', [ArticleController::class, 'batchRestore'])->name('batch.restore');
            Route::post('batch/force-delete', [ArticleController::class, 'batchForceDelete'])->name('batch.force-delete');
            Route::post('trash/empty', [ArticleController::class, 'emptyTrash'])->name('trash.empty');
            Route::get('create', [ArticleController::class, 'create'])->name('create');
            Route::post('create', [ArticleController::class, 'store'])->name('store');
            Route::post('{articleId}/restore', [ArticleController::class, 'restore'])->name('restore')->whereNumber('articleId');
            Route::post('{articleId}/force-delete', [ArticleController::class, 'forceDelete'])->name('force-delete')->whereNumber('articleId');
            Route::get('{articleId}/edit', [ArticleController::class, 'edit'])->name('edit');
            Route::put('{articleId}', [ArticleController::class, 'update'])->name('update');
        });

        // 栏目管理（保持 geo_admin/categories 路径语义）
        Route::prefix('categories')->name('categories.')->group(function () {
            Route::get('/', [CategoryController::class, 'index'])->name('index');
            Route::get('create', [CategoryController::class, 'create'])->name('create');
            Route::post('create', [CategoryController::class, 'store'])->name('store');
            Route::get('{categoryId}/edit', [CategoryController::class, 'edit'])->name('edit');
            Route::put('{categoryId}', [CategoryController::class, 'update'])->name('update');
            Route::post('{categoryId}/delete', [CategoryController::class, 'destroy'])->name('delete');
        });

        // 素材管理：作者管理
        Route::prefix('authors')->name('authors.')->group(function () {
            Route::get('/', [AuthorController::class, 'index'])->name('index');
            Route::get('create', [AuthorController::class, 'create'])->name('create');
            Route::post('create', [AuthorController::class, 'store'])->name('store');
            Route::get('{authorId}/edit', [AuthorController::class, 'edit'])->name('edit');
            Route::get('{authorId}/detail', [AuthorController::class, 'detail'])->name('detail');
            Route::put('{authorId}', [AuthorController::class, 'update'])->name('update');
            Route::post('{authorId}/delete', [AuthorController::class, 'destroy'])->name('delete');
        });

        // 素材管理：关键词库管理
        Route::prefix('keyword-libraries')->name('keyword-libraries.')->group(function () {
            Route::get('/', [KeywordLibraryController::class, 'index'])->name('index');
            Route::get('create', [KeywordLibraryController::class, 'create'])->name('create');
            Route::post('create', [KeywordLibraryController::class, 'store'])->name('store');
            Route::get('{libraryId}/edit', [KeywordLibraryController::class, 'edit'])->name('edit');
            Route::get('{libraryId}/detail', [KeywordLibraryController::class, 'detail'])->name('detail');
            Route::post('{libraryId}/keywords', [KeywordLibraryController::class, 'storeKeyword'])->name('keywords.store');
            Route::post('{libraryId}/keywords/delete', [KeywordLibraryController::class, 'destroyKeywords'])->name('keywords.delete');
            Route::post('{libraryId}/import', [KeywordLibraryController::class, 'importKeywords'])->name('import');
            Route::put('{libraryId}/detail', [KeywordLibraryController::class, 'updateFromDetail'])->name('detail.update');
            Route::put('{libraryId}', [KeywordLibraryController::class, 'update'])->name('update');
            Route::post('{libraryId}/delete', [KeywordLibraryController::class, 'destroy'])->name('delete');
        });

        // 素材管理：标题库管理
        Route::prefix('title-libraries')->name('title-libraries.')->group(function () {
            Route::get('/', [TitleLibraryController::class, 'index'])->name('index');
            Route::get('create', [TitleLibraryController::class, 'create'])->name('create');
            Route::post('create', [TitleLibraryController::class, 'store'])->name('store');
            Route::get('{libraryId}/edit', [TitleLibraryController::class, 'edit'])->name('edit');
            Route::get('{libraryId}/detail', [TitleLibraryController::class, 'detail'])->name('detail');
            Route::post('{libraryId}/titles', [TitleLibraryController::class, 'storeTitle'])->name('titles.store');
            Route::post('{libraryId}/titles/delete', [TitleLibraryController::class, 'destroyTitles'])->name('titles.delete');
            Route::post('{libraryId}/import', [TitleLibraryController::class, 'importTitles'])->name('import');
            Route::get('{libraryId}/ai-generate', [TitleLibraryController::class, 'aiGenerate'])->name('ai-generate');
            Route::post('{libraryId}/ai-generate', [TitleLibraryController::class, 'generateWithAi'])->name('ai-generate.submit');
            Route::put('{libraryId}', [TitleLibraryController::class, 'update'])->name('update');
            Route::post('{libraryId}/delete', [TitleLibraryController::class, 'destroy'])->name('delete');
        });

        // 素材管理：图片库管理
        Route::prefix('image-libraries')->name('image-libraries.')->group(function () {
            Route::get('/', [ImageLibraryController::class, 'index'])->name('index');
            Route::get('create', [ImageLibraryController::class, 'create'])->name('create');
            Route::post('create', [ImageLibraryController::class, 'store'])->name('store');
            Route::get('{libraryId}/edit', [ImageLibraryController::class, 'edit'])->name('edit');
            Route::get('{libraryId}/detail', [ImageLibraryController::class, 'detail'])->name('detail');
            Route::post('{libraryId}/images/upload', [ImageLibraryController::class, 'uploadImages'])->name('images.upload');
            Route::post('{libraryId}/images/delete', [ImageLibraryController::class, 'destroyImages'])->name('images.delete');
            Route::put('{libraryId}/detail', [ImageLibraryController::class, 'updateFromDetail'])->name('detail.update');
            Route::put('{libraryId}', [ImageLibraryController::class, 'update'])->name('update');
            Route::post('{libraryId}/delete', [ImageLibraryController::class, 'destroy'])->name('delete');
        });

        // 素材管理：知识库管理
        Route::prefix('knowledge-bases')->name('knowledge-bases.')->group(function () {
            Route::get('/', [KnowledgeBaseController::class, 'index'])->name('index');
            Route::get('create', [KnowledgeBaseController::class, 'create'])->name('create');
            Route::post('create', [KnowledgeBaseController::class, 'store'])->name('store');
            Route::get('{knowledgeBaseId}/edit', [KnowledgeBaseController::class, 'edit'])->name('edit');
            Route::get('{knowledgeBaseId}/detail', [KnowledgeBaseController::class, 'detail'])->name('detail');
            Route::post('upload', [KnowledgeBaseController::class, 'uploadFile'])->name('upload');
            Route::put('{knowledgeBaseId}/detail', [KnowledgeBaseController::class, 'updateFromDetail'])->name('detail.update');
            Route::put('{knowledgeBaseId}', [KnowledgeBaseController::class, 'update'])->name('update');
            Route::post('{knowledgeBaseId}/delete', [KnowledgeBaseController::class, 'destroy'])->name('delete');
        });

        // 业务页面
        Route::get('materials', [MaterialsController::class, 'index'])->name('materials.index');
        Route::get('url-import', [UrlImportController::class, 'index'])->name('url-import');
        Route::post('url-import', [UrlImportController::class, 'store'])->name('url-import.store');
        Route::get('url-import/history', [UrlImportController::class, 'history'])->name('url-import.history');
        Route::post('url-import/{jobId}/run', [UrlImportController::class, 'run'])
            ->name('url-import.run')
            ->whereNumber('jobId');
        Route::get('url-import/{jobId}/status', [UrlImportController::class, 'status'])
            ->name('url-import.status')
            ->whereNumber('jobId');
        Route::post('url-import/{jobId}/commit', [UrlImportController::class, 'commit'])
            ->name('url-import.commit')
            ->whereNumber('jobId');
        Route::get('url-import/{jobId}', [UrlImportController::class, 'show'])
            ->name('url-import.show')
            ->whereNumber('jobId');

        // AI 配置模块（配置器 / 模型 / 提示词）
        Route::group([], function () {
            Route::get('ai-configurator', [LegacyController::class, 'aiConfigurator'])->name('ai.configurator');
            Route::prefix('ai-models')->name('ai-models.')->group(function () {
                Route::get('/', [AiModelController::class, 'index'])->name('index');
                Route::post('create', [AiModelController::class, 'store'])->name('store');
                Route::put('{modelId}', [AiModelController::class, 'update'])->name('update');
                Route::post('{modelId}/test', [AiModelController::class, 'testConnection'])->name('test');
                Route::post('{modelId}/delete', [AiModelController::class, 'destroy'])->name('delete');
                Route::post('default-embedding', [AiModelController::class, 'updateDefaultEmbedding'])->name('default-embedding');
            });
            Route::get('ai-prompts', [AiPromptController::class, 'index'])->name('ai-prompts');
            Route::post('ai-prompts/create', [AiPromptController::class, 'store'])->name('ai-prompts.store');
            Route::put('ai-prompts/{promptId}', [AiPromptController::class, 'update'])->name('ai-prompts.update');
            Route::post('ai-prompts/{promptId}/delete', [AiPromptController::class, 'destroy'])->name('ai-prompts.delete');
            Route::get('ai-special-prompts', [AiSpecialPromptController::class, 'index'])->name('ai-special-prompts');
            Route::post('ai-special-prompts/keyword', [AiSpecialPromptController::class, 'updateKeyword'])->name('ai-special-prompts.keyword');
            Route::post('ai-special-prompts/description', [AiSpecialPromptController::class, 'updateDescription'])->name('ai-special-prompts.description');
        });

        Route::prefix('site-settings')->name('site-settings.')->group(function () {
            Route::get('/', [SiteSettingsController::class, 'index'])->name('index');
            Route::post('/', [SiteSettingsController::class, 'update'])->name('update');
            Route::post('theme', [SiteSettingsController::class, 'updateTheme'])->name('theme');
            Route::post('article-detail-ads', [SiteSettingsController::class, 'updateArticleDetailAds'])->name('ads');
            Route::get('sensitive-words', [SecuritySettingsController::class, 'index'])->name('sensitive-words');
            Route::post('sensitive-words', [SecuritySettingsController::class, 'storeSensitiveWords'])->name('sensitive-words.store');
            Route::post('sensitive-words/{wordId}/delete', [SecuritySettingsController::class, 'destroySensitiveWord'])
                ->name('sensitive-words.delete')
                ->whereNumber('wordId');
        });
        Route::prefix('security-settings')->name('security-settings.')->group(function () {
            Route::get('/', fn () => redirect()->route('admin.site-settings.sensitive-words'))->name('index');
            Route::post('sensitive-words', [SecuritySettingsController::class, 'storeSensitiveWords'])->name('words.store');
            Route::post('sensitive-words/{wordId}/delete', [SecuritySettingsController::class, 'destroySensitiveWord'])->name('words.delete');
            Route::post('password', [SecuritySettingsController::class, 'updatePassword'])->name('password.update');
        });

        // 超级管理员功能
        Route::middleware('admin.super')->group(function () {
            Route::prefix('admin-users')->name('admin-users.')->group(function () {
                Route::get('/', [AdminUserController::class, 'index'])->name('index');
                Route::post('create', [AdminUserController::class, 'store'])->name('store');
                Route::post('{adminId}/update', [AdminUserController::class, 'update'])->name('update');
                Route::post('{adminId}/toggle-status', [AdminUserController::class, 'toggleStatus'])->name('toggle-status');
                Route::post('{adminId}/delete', [AdminUserController::class, 'destroy'])->name('delete');
            });
            Route::get('admin-activity-logs', [AdminActivityLogController::class, 'index'])->name('admin-activity-logs');
            Route::prefix('api-tokens')->name('api-tokens.')->group(function () {
                Route::get('/', [ApiTokenController::class, 'index'])->name('index');
                Route::post('/', [ApiTokenController::class, 'store'])->name('store');
                Route::post('{tokenId}/revoke', [ApiTokenController::class, 'revoke'])->name('revoke');
            });
        });
    });
});
EOF_ROUTES_WEB_PHP
sudo mkdir -p 'resources/views/site'
sudo tee 'resources/views/site/contact.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_SITE_CONTACT_BLADE_PHP'
@extends('site.layout')

@section('content')
    @php($whatsappLink = 'https://wa.me/447856110363')
    <div class="site-container px-4 sm:px-6 lg:px-8 py-8">
        <section class="article-shell p-8">
            <h1 class="text-3xl font-bold text-gray-900">先看你的产品适合哪个平台，再决定怎么入驻</h1>
            <p class="mt-4 text-gray-600 leading-8">发来产品类目、目标国家和公司主体情况，先帮你判断平台选择、资料缺口、审核风险和启动预算。</p>
            <div class="mt-6 flex flex-wrap gap-3">
                <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="inline-flex items-center px-5 py-3 rounded-lg bg-gray-900 text-white font-semibold">WhatsApp +44 7856110363</a>
                <a href="{{ route('site.home') }}" class="inline-flex items-center px-5 py-3 rounded-lg border border-gray-300 text-gray-900 font-semibold">先看平台内容</a>
            </div>
            <div class="mt-6 rounded-xl border border-dashed border-gray-300 p-5 text-gray-700">
                微信备用咨询：<strong>douyinbaobai168</strong>
            </div>
        </section>
    </div>
@endsection
EOF_RESOURCES_VIEWS_SITE_CONTACT_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509'
sudo tee 'resources/views/theme/global-entry-pro-20260509/home.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_HOME_BLADE_PHP'
@extends('theme.global-entry-pro-20260509.layout')

@push('head')
    @php
        $schemaAtContext = chr(64).'context';
        $schemaAtType = chr(64).'type';
        $schemaItems = [];
        foreach ((method_exists($articles, 'getCollection') ? $articles->getCollection() : collect($articles))->take(10) as $schemaArticle) {
            $schemaItems[] = [
                $schemaAtType => 'ListItem',
                'position' => count($schemaItems) + 1,
                'url' => route('site.article', $schemaArticle->slug),
                'name' => $schemaArticle->title,
            ];
        }
        $collectionSchema = [
            $schemaAtContext => 'https://schema.org',
            $schemaAtType => 'CollectionPage',
            'name' => $pageTitle,
            'description' => $pageDescription,
            'url' => $canonicalUrl ?? route('site.home'),
            'mainEntity' => [
                $schemaAtType => 'ItemList',
                'itemListElement' => $schemaItems,
            ],
        ];
    @endphp
    <script type="application/ld+json">
        {!! json_encode($collectionSchema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) !!}
    </script>
@endpush

@section('content')
    @php
        $whatsappLink = 'https://wa.me/447856110363';
        $homeArticles = (method_exists($articles, 'getCollection') ? $articles->getCollection() : collect($articles))
            ->reject(fn ($item) => $item->category?->slug === 'geo-ai-search');
        $homepageHotArticles = collect($hotArticles ?? [])->reject(fn ($item) => $item->category?->slug === 'geo-ai-search');
        $isDefaultHome = $search === '' && !$category && !$categoryMissing;
        $trustArticles = $isDefaultHome
            ? collect($featuredArticles)
                ->reject(fn ($item) => $item->category?->slug === 'geo-ai-search')
                ->concat($homeArticles)
                ->filter()
                ->unique(fn ($item) => $item->id)
                ->take(4)
            : collect();
        $platforms = [
            ['name' => 'Amazon', 'search' => 'Amazon 入驻', 'desc' => '品牌备案、账号资料、类目审核和启动节奏。'],
            ['name' => 'Walmart', 'search' => 'Walmart 入驻', 'desc' => '美国主体、供应链能力、审核要求和上线节奏。'],
            ['name' => 'TikTok Shop', 'search' => 'TikTok Shop 入驻', 'desc' => '跨境店资质、招商类目、内容与达人起步。'],
            ['name' => 'eBay', 'search' => 'eBay 入驻', 'desc' => '卖家账号、刊登规则、收款与风控基础。'],
            ['name' => 'Temu', 'search' => 'Temu 入驻', 'desc' => '平台招商、供货资料、价格策略和履约要求。'],
        ];
        $serviceTopics = [
            ['title' => '入驻条件', 'desc' => '先看主体、类目、品牌和收款条件是否达标。', 'search' => '入驻条件'],
            ['title' => '资料清单', 'desc' => '公司、品牌、店铺、收款、物流资料先补齐。', 'search' => '入驻资料清单'],
            ['title' => '审核失败原因', 'desc' => '提前排查主体、类目、品牌和证明材料风险。', 'search' => '审核失败原因'],
            ['title' => '费用和预算', 'desc' => '先算清保证金、样品、物流和起步运营成本。', 'search' => '入驻费用'],
        ];
        $evaluationPoints = [
            ['title' => '适合哪个平台', 'desc' => '按产品类目、利润结构、供应链和团队阶段判断。'],
            ['title' => '资料是否齐全', 'desc' => '先确认公司主体、品牌、收款、物流和店铺资料。'],
            ['title' => '审核风险在哪里', 'desc' => '提前识别容易被卡的主体、类目、品牌和图片问题。'],
            ['title' => '预算要准备多少', 'desc' => '把注册、样品、物流、广告和基础运营预算先算清。'],
        ];
        $riskSignals = [
            ['title' => '不同平台规则差异大', 'desc' => '同一个产品，在不同平台的资料要求、审核重点和起量方式都不一样。'],
            ['title' => '资料错一轮就会拖慢节奏', 'desc' => '很多卖家不是没资格，而是资料顺序和表达方式不对，白白浪费时间。'],
            ['title' => '先判断再申请更省钱', 'desc' => '先看适配平台和预算，再决定要不要做，能少走很多弯路。'],
        ];
    @endphp
    <div class="ne-shell ne-layout">
        <section class="ne-feed">
            @if($search !== '')
                <div class="ne-page-head">
                    <div class="ne-page-kicker">{{ __('site.search_button') }}</div>
                    <h1 class="ne-page-title">{{ __('site.search_breadcrumb', ['term' => $search]) }}</h1>
                    <p class="ne-page-desc">{{ $pageDescription }}</p>
                </div>
            @elseif($categoryMissing)
                <div class="ne-page-head">
                    <div class="ne-page-kicker">{{ __('site.category_not_found') }}</div>
                    <h1 class="ne-page-title">{{ __('site.category_not_found') }}</h1>
                    <p class="ne-page-desc">{{ $pageDescription }}</p>
                </div>
            @else
                <section class="ne-service-hero">
                    <div class="ne-service-copy">
                        <div class="ne-page-kicker">海外电商平台入驻咨询</div>
                        <h1>帮中国商家判断 Amazon、Walmart、TikTok Shop、eBay、Temu 该先做哪个</h1>
                        <p>先判断产品适合哪个平台，再看资料是否齐全、审核风险在哪里、要准备多少启动预算。你可以直接通过 WhatsApp 发来产品类目、目标国家和公司主体情况，先做一轮判断。</p>
                        <div class="ne-hero-actions">
                            <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action">WhatsApp 立即咨询</a>
                            <a href="{{ route('site.contact') }}" class="ne-secondary-action">先做免费评估</a>
                        </div>
                        <div class="ne-hero-notes">
                            <span>服务对象：工厂、品牌方、贸易商、跨境新团队</span>
                            <span>支持平台：Amazon / Walmart / TikTok Shop / eBay / Temu</span>
                        </div>
                    </div>
                    <div class="ne-service-panel">
                        <span>先发这 3 类信息</span>
                        <strong>产品类目、目标国家、公司主体</strong>
                        <ul>
                            <li>先看适合做哪个平台</li>
                            <li>先看资料还差什么</li>
                            <li>先看审核风险和预算</li>
                        </ul>
                    </div>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">五大平台入口</span>
                    </div>
                    <div class="ne-platform-grid" aria-label="Platform entry guides">
                        @foreach($platforms as $platform)
                            <a href="{{ route('site.home', ['search' => $platform['search']]) }}" class="ne-platform-card">
                                <span>{{ $platform['name'] }}</span>
                                <strong>{{ $platform['name'] }} 入驻</strong>
                                <p>{{ $platform['desc'] }}</p>
                                <em class="ne-card-note">查看{{ $platform['name'] }}相关内容</em>
                            </a>
                        @endforeach
                    </div>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">高意向问题入口</span>
                    </div>
                    <div class="ne-topic-grid" aria-label="Service topic guides">
                        @foreach($serviceTopics as $topic)
                            <a href="{{ route('site.home', ['search' => $topic['search']]) }}" class="ne-topic-card">
                                <span>{{ $topic['title'] }}</span>
                                <strong>{{ $topic['title'] }}</strong>
                                <p>{{ $topic['desc'] }}</p>
                            </a>
                        @endforeach
                    </div>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">你现在最需要先判断什么</span>
                    </div>
                    <div class="ne-proof-grid">
                        @foreach($evaluationPoints as $point)
                            <article class="ne-proof-card">
                                <span>{{ str_pad((string) $loop->iteration, 2, '0', STR_PAD_LEFT) }}</span>
                                <strong>{{ $point['title'] }}</strong>
                                <p>{{ $point['desc'] }}</p>
                            </article>
                        @endforeach
                    </div>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">为什么现在就联系</span>
                    </div>
                    <div class="ne-warning-grid">
                        @foreach($riskSignals as $signal)
                            <article class="ne-warning-card">
                                <strong>{{ $signal['title'] }}</strong>
                                <p>{{ $signal['desc'] }}</p>
                            </article>
                        @endforeach
                    </div>
                </section>

                @if($trustArticles->isNotEmpty())
                    <section class="ne-feed-card">
                        <div class="ne-section-title">
                            <span class="ne-title-row">精选文章背书</span>
                        </div>
                        <div class="ne-feed">
                            @foreach($trustArticles as $article)
                                @include('theme.global-entry-pro-20260509.partials.article-card', ['article' => $article, 'showFeaturedBadge' => $loop->first])
                            @endforeach
                        </div>
                    </section>
                @endif

                <section class="ne-home-cta" id="consult">
                    <div>
                        <span>现在就可以开始</span>
                        <h2>先别盲目申请，先把平台、资料和审核风险判断清楚。</h2>
                        <p class="ne-cta-copy">直接发产品类目、目标国家和公司主体，先做一轮判断，再决定下一步怎么入驻。</p>
                    </div>
                    <div class="ne-home-cta-actions">
                        <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action ne-cta-action">WhatsApp +44 7856110363</a>
                        <a href="{{ route('site.contact') }}" class="ne-secondary-action ne-cta-action">进入免费评估页</a>
                        <div class="ne-inline-wechat">微信：douyinbaobai168</div>
                    </div>
                </section>
            @endif

            <section class="ne-feed-card">
                <div class="ne-section-title">
                    <span class="ne-title-row">{{ $isDefaultHome ? '最新收录文章' : $viewTitle }}</span>
                </div>
                <div class="ne-feed">
                    @forelse($homeArticles as $article)
                        @include('theme.global-entry-pro-20260509.partials.article-card', ['article' => $article])
                    @empty
                        <div class="rounded-2xl border border-dashed border-gray-200 bg-white p-10 text-center text-gray-500">
                            {{ __('site.home_empty_title') }}
                        </div>
                    @endforelse
                </div>
            </section>

            <div class="mt-3">
                {{ $articles->links() }}
            </div>
        </section>

        @include('theme.global-entry-pro-20260509.partials.sidebar', ['showFeedPanel' => $isDefaultHome])
    </div>
@endsection
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_HOME_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509'
sudo tee 'resources/views/theme/global-entry-pro-20260509/article.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_ARTICLE_BLADE_PHP'
@extends('theme.global-entry-pro-20260509.layout')

@push('head')
    @php
        $displayCategory = $article->category?->slug === 'geo-ai-search' ? null : $article->category;
        $schemaAtContext = chr(64).'context';
        $schemaAtType = chr(64).'type';
        $schemaAtId = chr(64).'id';
        $articleSchema = [
            $schemaAtContext => 'https://schema.org',
            $schemaAtType => 'NewsArticle',
            'headline' => $article->title,
            'description' => $pageDescription,
            'datePublished' => optional($article->published_at ?? $article->created_at)->toAtomString(),
            'dateModified' => optional($article->updated_at ?? $article->published_at ?? $article->created_at)->toAtomString(),
            'mainEntityOfPage' => [
                $schemaAtType => 'WebPage',
                $schemaAtId => $canonicalUrl ?? route('site.article', $article->slug),
            ],
            'author' => [
                $schemaAtType => 'Person',
                'name' => $article->author?->name ?? $siteTitle,
            ],
            'publisher' => [
                $schemaAtType => 'Organization',
                'name' => $siteTitle,
            ],
            'articleSection' => $displayCategory?->name,
            'keywords' => $tags,
        ];
    @endphp
    <meta property="og:title" content="{{ $article->title }}">
    <meta property="og:description" content="{{ $pageDescription }}">
    <meta property="og:type" content="article">
    <meta property="og:url" content="{{ $canonicalUrl ?? route('site.article', $article->slug) }}">
    @if($displayCategory)
        <meta property="article:section" content="{{ $displayCategory->name }}">
    @endif
    <script type="application/ld+json">
        {!! json_encode($articleSchema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) !!}
    </script>
@endpush

@section('content')
    @php($whatsappLink = 'https://wa.me/447856110363')
    <div class="ne-shell ne-article-layout">
        <main class="ne-post-column">
            <nav class="ne-breadcrumb" aria-label="Breadcrumb">
                <a href="{{ route('site.home') }}">{{ __('front.nav.home') }}</a>
                @if($displayCategory)
                    <span>/</span>
                    <a href="{{ route('site.category', $displayCategory->slug) }}">{{ $displayCategory->name }}</a>
                @endif
                <span>/</span>
                <span>{{ $article->title }}</span>
            </nav>

            <article class="ne-article-main">
                <h1 class="ne-article-h1">{{ $article->title }}</h1>

                <div class="ne-post-info">
                    @if($displayCategory)
                        <a href="{{ route('site.category', $displayCategory->slug) }}">{{ $displayCategory->name }}</a>
                    @endif
                    <time datetime="{{ ($article->published_at ?? $article->created_at)?->toAtomString() }}">
                        {{ ($article->published_at ?? $article->created_at)?->format('Y-m-d H:i') }}
                    </time>
                    @if($article->author)
                        <span>{{ $article->author->name }}</span>
                    @endif
                    <span>{{ (int) $article->view_count }} views</span>
                </div>

                @if($excerptPlain !== '')
                    <p class="ne-article-excerpt">{{ $excerptPlain }}</p>
                @endif

                <section class="ne-article-service-brief">
                    <div>
                        <span>读完这篇可以顺手确认</span>
                        <h2>你的产品适合哪个平台、资料是否齐、审核风险在哪里。</h2>
                    </div>
                    <a href="{{ $whatsappLink }}" target="_blank" rel="noopener">WhatsApp 立即咨询</a>
                </section>

                <div class="ne-prose">
                    {!! $contentHtml !!}
                </div>

                <section class="ne-article-cta" id="consult">
                    <div>
                        <span>需要入驻判断？</span>
                        <h2>把你的产品类目、目标国家和公司主体发来，先看平台、资料和审核风险。</h2>
                        <p class="ne-cta-copy">支持 Amazon、Walmart、TikTok Shop、eBay、Temu，先判断再申请，少走弯路。</p>
                    </div>
                    <div class="ne-cta-actions">
                        <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action ne-cta-action">WhatsApp +44 7856110363</a>
                        <a href="{{ route('site.contact') }}" class="ne-secondary-action ne-cta-action">进入免费评估页</a>
                        <div class="ne-inline-wechat">微信：douyinbaobai168</div>
                    </div>
                </section>

                @if(!empty($tags))
                    <div class="ne-tag-list">
                        @foreach($tags as $tag)
                            <span>{{ $tag }}</span>
                        @endforeach
                    </div>
                @endif

                @if($stickyAd)
                    <section class="ne-ad-slot">
                        @if($stickyAd->title)
                            <h2>{{ $stickyAd->title }}</h2>
                        @endif
                        {!! $stickyAd->content_html !!}
                    </section>
                @endif
            </article>

            @if($relatedArticles->isNotEmpty())
                <section class="ne-related-block">
                    <div class="ne-section-title">
                        <span class="ne-title-row">{{ __('site.article_related') }}</span>
                    </div>
                    <div class="ne-related-grid">
                        @foreach($relatedArticles as $related)
                            <a href="{{ route('site.article', $related->slug) }}" class="ne-related-card">
                                <span class="ne-related-index">{{ $loop->iteration }}</span>
                                <span>{{ $related->title }}</span>
                            </a>
                        @endforeach
                    </div>
                </section>
            @endif
        </main>

        <aside class="ne-post-aside">
            @if($relatedArticles->isNotEmpty())
                <section class="ne-panel">
                    <div class="ne-section-title">
                        <span class="ne-title-row">{{ __('site.article_related') }}</span>
                    </div>
                    <div class="ne-hot-list">
                        @foreach($relatedArticles as $related)
                            <a href="{{ route('site.article', $related->slug) }}" class="ne-hot-item">
                                <span class="ne-hot-index">{{ $loop->iteration }}</span>
                                <span>{{ $related->title }}</span>
                            </a>
                        @endforeach
                    </div>
                </section>
            @endif

            <section class="ne-panel">
                <div class="ne-section-title">
                    <span class="ne-title-row">入驻咨询</span>
                </div>
                <p class="ne-feed-panel-desc">做 Amazon、Walmart、TikTok Shop、eBay、Temu 等平台入驻前，先发产品类目和目标市场，先看适合哪个平台。</p>
                <div class="ne-panel-actions">
                    <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action ne-panel-action">WhatsApp +44 7856110363</a>
                    <a href="{{ route('site.contact') }}" class="ne-secondary-action ne-panel-action">进入免费评估页</a>
                </div>
                <div class="ne-wechat-card">
                    <span>微信备用咨询</span>
                    <strong>douyinbaobai168</strong>
                </div>
                <ul class="ne-side-checks">
                    <li>平台是否适合当前产品</li>
                    <li>公司和品牌资料是否达标</li>
                    <li>审核前需要避开的风险点</li>
                </ul>
                <a href="{{ route('site.contact') }}" class="ne-card-action">查看免费评估说明 <i data-lucide="arrow-right" class="w-4 h-4"></i></a>
            </section>
        </aside>
    </div>
@endsection
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_ARTICLE_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509'
sudo tee 'resources/views/theme/global-entry-pro-20260509/contact.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_CONTACT_BLADE_PHP'
@extends('theme.global-entry-pro-20260509.layout')

@push('head')
    @php
        $schemaAtContext = chr(64).'context';
        $schemaAtType = chr(64).'type';
        $contactSchema = [
            $schemaAtContext => 'https://schema.org',
            $schemaAtType => 'ContactPage',
            'name' => $pageTitle,
            'description' => $pageDescription,
            'url' => $canonicalUrl ?? route('site.contact'),
        ];
    @endphp
    <script type="application/ld+json">
        {!! json_encode($contactSchema, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES | JSON_PRETTY_PRINT) !!}
    </script>
@endpush

@section('content')
    @php
        $whatsappLink = 'https://wa.me/447856110363';
        $platforms = [
            ['name' => 'Amazon', 'desc' => '品牌备案、类目审核、账号和启动节奏判断。'],
            ['name' => 'Walmart', 'desc' => '主体要求、供应链能力、审核重点和上线规划。'],
            ['name' => 'TikTok Shop', 'desc' => '跨境店资质、招商类目、内容和达人起步。'],
            ['name' => 'eBay', 'desc' => '卖家账号、收款方式、风控和刊登基础。'],
            ['name' => 'Temu', 'desc' => '平台招商、供货资料、价格策略和履约要求。'],
        ];
        $consultItems = [
            ['title' => '适合做哪个平台', 'desc' => '按产品类目、目标市场和团队阶段先判断平台方向。'],
            ['title' => '资料还差什么', 'desc' => '先看公司主体、品牌、收款、物流等资料是否齐。'],
            ['title' => '为什么可能审核不过', 'desc' => '把主体、类目、品牌和证明材料的风险点先排掉。'],
            ['title' => '大概要准备多少预算', 'desc' => '先算清注册、样品、物流、广告和基础运营成本。'],
        ];
        $reasonCards = [
            ['title' => '先判断平台，再申请', 'desc' => '平台选错了，后面资料、预算和运营动作都会浪费。'],
            ['title' => '先排资料风险，再提交', 'desc' => '很多问题不是没资格，而是资料表达、顺序和证明方式不对。'],
            ['title' => '先算预算，再决定投入', 'desc' => '把成本算清楚，再做平台选择，避免一开始就走偏。'],
        ];
    @endphp

    <div class="ne-shell">
        <section class="ne-page-head ne-contact-hero">
            <div class="ne-page-kicker">免费评估 / 联系咨询</div>
            <h1 class="ne-page-title">先看你的产品适合哪个平台，再决定怎么入驻</h1>
            <p class="ne-page-desc">发来产品类目、目标国家和公司主体情况，先帮你判断平台选择、资料缺口、审核风险和启动预算。主联系通道是 WhatsApp，微信作为备用。</p>
            <div class="ne-contact-hero-actions">
                <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action">WhatsApp 立即咨询</a>
                <a href="{{ route('site.home') }}" class="ne-secondary-action">先看平台内容</a>
            </div>
        </section>

        <div class="ne-contact-layout">
            <section class="ne-feed">
                <section class="ne-contact-primary">
                    <article class="ne-contact-primary-card">
                        <span class="ne-page-kicker">主联系通道</span>
                        <h2>WhatsApp：+44 7856110363</h2>
                        <p>适合直接发消息、发产品信息、先做平台判断。把产品类目、目标国家、公司主体情况一起发来更高效。</p>
                        <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action ne-contact-main-action">点击打开 WhatsApp</a>
                    </article>

                    <article class="ne-contact-secondary-card">
                        <span class="ne-page-kicker">微信备用通道</span>
                        <strong>douyinbaobai168</strong>
                        <p>如果你更习惯微信，也可以直接沟通。建议同样把产品类目、目标国家和公司主体一起发来。</p>
                    </article>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">可以先咨询的 4 件事</span>
                    </div>
                    <div class="ne-proof-grid">
                        @foreach($consultItems as $item)
                            <article class="ne-proof-card">
                                <span>{{ str_pad((string) $loop->iteration, 2, '0', STR_PAD_LEFT) }}</span>
                                <strong>{{ $item['title'] }}</strong>
                                <p>{{ $item['desc'] }}</p>
                            </article>
                        @endforeach
                    </div>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">支持的平台</span>
                    </div>
                    <div class="ne-platform-grid">
                        @foreach($platforms as $platform)
                            <article class="ne-platform-card">
                                <span>{{ $platform['name'] }}</span>
                                <strong>{{ $platform['name'] }} 入驻</strong>
                                <p>{{ $platform['desc'] }}</p>
                            </article>
                        @endforeach
                    </div>
                </section>

                <section class="ne-feed-card">
                    <div class="ne-section-title">
                        <span class="ne-title-row">为什么建议先问一下</span>
                    </div>
                    <div class="ne-warning-grid">
                        @foreach($reasonCards as $card)
                            <article class="ne-warning-card">
                                <strong>{{ $card['title'] }}</strong>
                                <p>{{ $card['desc'] }}</p>
                            </article>
                        @endforeach
                    </div>
                </section>

                @if($featuredArticles->isNotEmpty())
                    <section class="ne-feed-card">
                        <div class="ne-section-title">
                            <span class="ne-title-row">先看这些文章也可以</span>
                        </div>
                        <div class="ne-feed">
                            @foreach($featuredArticles as $article)
                                @include('theme.global-entry-pro-20260509.partials.article-card', ['article' => $article, 'showFeaturedBadge' => $loop->first])
                            @endforeach
                        </div>
                    </section>
                @endif
            </section>

            <aside class="ne-sidebar">
                <section class="ne-panel ne-consult-panel">
                    <div class="ne-page-kicker">快速开始</div>
                    <h2 class="ne-feed-panel-title">直接把这 3 项发来</h2>
                    <ul class="ne-check-list">
                        <li>产品类目</li>
                        <li>目标国家或站点</li>
                        <li>公司主体和品牌情况</li>
                    </ul>
                    <div class="ne-panel-actions">
                        <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action ne-panel-action">WhatsApp +44 7856110363</a>
                    </div>
                    <div class="ne-wechat-card">
                        <span>微信备用咨询</span>
                        <strong>douyinbaobai168</strong>
                    </div>
                </section>

                @if($featuredArticles->isNotEmpty())
                    <section class="ne-panel">
                        <div class="ne-section-title">
                            <span class="ne-title-row">精选内容</span>
                        </div>
                        <div class="ne-hot-list">
                            @foreach($featuredArticles as $article)
                                <a href="{{ route('site.article', $article->slug) }}" class="ne-hot-item">
                                    <span class="ne-hot-index">{{ $loop->iteration }}</span>
                                    <span>{{ $article->title }}</span>
                                </a>
                            @endforeach
                        </div>
                    </section>
                @endif
            </aside>
        </div>
    </div>
@endsection
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_CONTACT_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509/partials'
sudo tee 'resources/views/theme/global-entry-pro-20260509/partials/header.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_PARTIALS_HEADER_BLADE_PHP'
@php
    $path = request()->path();
    $isHome = $path === '' || $path === '/';
    $activeNavName = (string) ($activeNav ?? '');
    $businessNav = [
        ['label' => 'Amazon入驻', 'search' => 'Amazon 入驻'],
        ['label' => 'Walmart入驻', 'search' => 'Walmart 入驻'],
        ['label' => 'TikTok Shop', 'search' => 'TikTok Shop 入驻'],
        ['label' => 'eBay入驻', 'search' => 'eBay 入驻'],
        ['label' => 'Temu入驻', 'search' => 'Temu 入驻'],
    ];
    $contactUrl = route('site.contact');
@endphp
<header class="ne-header">
    <div class="ne-globalbar">
        <div class="ne-shell ne-globalbar-row">
            <span>中国商家海外电商平台入驻内容中心</span>
            <span class="ne-globalbar-contact">WhatsApp：+44 7856110363 · 微信咨询：douyinbaobai168</span>
        </div>
    </div>
    <div class="ne-shell">
        <div class="ne-header-row">
            <a href="{{ route('site.home') }}" class="ne-brand" aria-label="{{ $siteName }}">
                @if(!empty($siteLogo))
                    <img src="{{ $siteLogo }}" alt="{{ $siteName }}" class="h-9 w-auto max-w-48 object-contain">
                @else
                    <span class="ne-brand-mark">{{ mb_substr($siteName, 0, 1) }}</span>
                    <span>{{ $siteName }}</span>
                @endif
            </a>

            <nav class="ne-topnav" aria-label="Primary">
                <a href="{{ route('site.home') }}" class="{{ $activeNavName === 'home' || $isHome ? 'is-active' : '' }}">{{ __('front.nav.home') }}</a>
                @foreach($businessNav as $navItem)
                    <a href="{{ route('site.home', ['search' => $navItem['search']]) }}" class="{{ request('search') === $navItem['search'] ? 'is-active' : '' }}">{{ $navItem['label'] }}</a>
                @endforeach
                <a href="{{ $contactUrl }}" class="{{ $activeNavName === 'contact' ? 'is-active' : '' }}">免费评估</a>
            </nav>

            <a href="{{ $contactUrl }}" class="ne-header-cta">免费评估 / 咨询</a>

            <form method="get" action="{{ route('site.home') }}" class="ne-search" role="search">
                <input type="search" name="search" value="{{ request('search') }}" placeholder="{{ __('site.search_placeholder') }}">
                <button type="submit">{{ __('site.search_button') }}</button>
            </form>

            <button type="button" class="ne-mobile-menu" onclick="document.getElementById('neMobileNav')?.classList.toggle('hidden')" aria-label="{{ __('front.nav.categories') }}">
                <i data-lucide="menu" class="w-7 h-7"></i>
            </button>
        </div>
        <div id="neMobileNav" class="hidden pb-4">
            <div class="ne-channel-rail !sticky !top-auto">
                <a href="{{ route('site.home') }}" class="ne-channel {{ $activeNavName === 'home' || $isHome ? 'is-active' : '' }}">{{ __('front.nav.home') }}</a>
                @foreach($businessNav as $navItem)
                    <a href="{{ route('site.home', ['search' => $navItem['search']]) }}" class="ne-channel {{ request('search') === $navItem['search'] ? 'is-active' : '' }}">{{ $navItem['label'] }}</a>
                @endforeach
                <a href="{{ $contactUrl }}" class="ne-channel {{ $activeNavName === 'contact' ? 'is-active' : '' }}">免费评估</a>
            </div>
        </div>
    </div>
</header>
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_PARTIALS_HEADER_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509/partials'
sudo tee 'resources/views/theme/global-entry-pro-20260509/partials/footer.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_PARTIALS_FOOTER_BLADE_PHP'
<footer class="ne-footer">
    <div class="ne-shell">
        <div class="ne-footer-inner">
            <span>{{ $footerCopyright !== '' ? $footerCopyright : '© '.date('Y').' '.$siteName.'. All rights reserved.' }}</span>
            <span><a href="{{ route('site.contact') }}">免费评估 / 联系咨询</a> · WhatsApp +44 7856110363 · 微信 douyinbaobai168</span>
        </div>
    </div>
</footer>
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_PARTIALS_FOOTER_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509/partials'
sudo tee 'resources/views/theme/global-entry-pro-20260509/partials/sidebar.blade.php' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_PARTIALS_SIDEBAR_BLADE_PHP'
@php
    $sidebarHotArticles = collect($hotArticles ?? [])->reject(fn ($item) => $item->category?->slug === 'geo-ai-search')->take(6);
    $latestArticles = method_exists($articles ?? null, 'getCollection')
        ? $articles->getCollection()->reject(fn ($item) => $item->category?->slug === 'geo-ai-search')->take(6)
        : collect($articles ?? [])->reject(fn ($item) => $item->category?->slug === 'geo-ai-search')->take(6);
    $sidebarArticles = $sidebarHotArticles->isNotEmpty() ? $sidebarHotArticles : $latestArticles;
    $feedTitle = trim((string) (($siteSubtitle ?? '') !== '' ? $siteSubtitle : ($siteTitle ?? 'GEOFlow')));
    $feedDescription = trim((string) ($siteDescription ?? ''));
@endphp
@php($whatsappLink = 'https://wa.me/447856110363')
<aside class="ne-sidebar">
    <section class="ne-panel ne-consult-panel" id="consult">
        <div class="ne-page-kicker">入驻咨询</div>
        <h2 class="ne-feed-panel-title">先用 WhatsApp 发产品类目，先判断适合哪个平台</h2>
        <p class="ne-feed-panel-desc">先看平台选择、资料缺口、审核风险和启动预算，再决定怎么入驻，适合 Amazon、Walmart、TikTok Shop、eBay、Temu。</p>
        <div class="ne-panel-actions">
            <a href="{{ $whatsappLink }}" target="_blank" rel="noopener" class="ne-primary-action ne-panel-action">WhatsApp +44 7856110363</a>
            <a href="{{ route('site.contact') }}" class="ne-secondary-action ne-panel-action">进入免费评估页</a>
        </div>
        <div class="ne-wechat-card">
            <span>微信备用咨询</span>
            <strong>douyinbaobai168</strong>
        </div>
        <ul class="ne-check-list">
            <li>平台选择建议</li>
            <li>资料清单梳理</li>
            <li>审核风险提示</li>
        </ul>
    </section>

    <section class="ne-panel">
        <div class="ne-section-title">
            <span class="ne-title-row">{{ $sidebarHotArticles->isNotEmpty() ? '热门入驻问题' : '最新入驻文章' }}</span>
        </div>
        <div class="ne-hot-list">
            @forelse($sidebarArticles as $hotArticle)
                <a href="{{ route('site.article', $hotArticle->slug) }}" class="ne-hot-item">
                    <span class="ne-hot-index">{{ $loop->iteration }}</span>
                    <span>{{ $hotArticle->title }}</span>
                </a>
            @empty
                <p class="text-sm text-gray-500">{{ __('site.home_empty_title') }}</p>
            @endforelse
        </div>
    </section>

    <section class="ne-panel">
        <div class="ne-section-title">
            <span class="ne-title-row">平台专题</span>
        </div>
        <div class="ne-side-platforms">
            <a href="{{ route('site.contact') }}">免费评估 / 联系咨询</a>
            @foreach(['Amazon', 'Walmart', 'TikTok Shop', 'eBay', 'Temu'] as $platformName)
                <a href="{{ route('site.home', ['search' => $platformName.' 入驻']) }}">{{ $platformName }} 入驻</a>
            @endforeach
        </div>
    </section>
</aside>
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_PARTIALS_SIDEBAR_BLADE_PHP
sudo mkdir -p 'resources/views/theme/global-entry-pro-20260509/assets'
sudo tee 'resources/views/theme/global-entry-pro-20260509/assets/theme.css' >/dev/null <<'EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_ASSETS_THEME_CSS'
:root {
    --ne-ink: #102326;
    --ne-muted: #5d6b6e;
    --ne-subtle: #879295;
    --ne-line: #dde6e4;
    --ne-soft-line: #edf3f1;
    --ne-bg: #f5f8f7;
    --ne-panel: #ffffff;
    --ne-soft: #eef5f2;
    --ne-green: #0f766e;
    --ne-green-dark: #0b4f4a;
    --ne-gold: #c99632;
    --ne-blue: #16324f;
}

* {
    box-sizing: border-box;
}

.ne-body {
    margin: 0;
    background: var(--ne-bg);
    color: var(--ne-ink);
    font-family: Arial, "Microsoft YaHei", "PingFang SC", sans-serif;
    overflow-x: hidden;
}

.ne-body a {
    color: inherit;
    text-decoration: none;
}

.ne-main {
    min-height: 60vh;
}

.ne-shell {
    width: min(1180px, calc(100vw - 40px));
    margin: 0 auto;
}

.ne-globalbar {
    background: #0c2526;
    color: rgba(255, 255, 255, .78);
    font-size: 13px;
}

.ne-globalbar-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    min-height: 38px;
    gap: 16px;
}

.ne-globalbar-contact {
    color: #f4d58b;
    font-weight: 700;
}

.ne-header {
    position: sticky;
    top: 0;
    z-index: 50;
    border-bottom: 1px solid rgba(15, 118, 110, .14);
    background: rgba(255, 255, 255, .96);
    backdrop-filter: blur(12px);
}

.ne-header-row {
    display: flex;
    align-items: center;
    min-height: 76px;
    gap: 20px;
}

.ne-brand {
    display: inline-flex;
    align-items: center;
    flex: 0 0 auto;
    gap: 11px;
    min-width: 190px;
    color: var(--ne-ink);
    font-size: 23px;
    font-weight: 900;
    line-height: 1;
}

.ne-brand-mark {
    display: inline-grid;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 8px;
    background: linear-gradient(135deg, var(--ne-green), var(--ne-blue));
    color: #fff;
    font-size: 22px;
    font-weight: 900;
}

.ne-topnav {
    display: flex;
    align-items: center;
    min-width: 0;
    gap: 16px;
    color: #273f42;
    font-size: 15px;
    font-weight: 700;
    white-space: nowrap;
}

.ne-topnav a {
    display: inline-flex;
    align-items: center;
    min-height: 76px;
    border-bottom: 3px solid transparent;
}

.ne-topnav a:hover,
.ne-topnav a.is-active {
    color: var(--ne-green);
    border-bottom-color: var(--ne-green);
}

.ne-header-cta,
.ne-primary-action,
.ne-secondary-action,
.ne-card-action {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    min-height: 38px;
    border-radius: 8px;
    font-weight: 800;
}

.ne-header-cta {
    margin-left: auto;
    padding: 0 14px;
    background: var(--ne-green);
    color: #fff;
    font-size: 14px;
}

.ne-search {
    display: flex;
    align-items: center;
    width: 230px;
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #f8fbfa;
    overflow: hidden;
}

.ne-search input {
    min-width: 0;
    flex: 1;
    border: 0;
    background: transparent;
    padding: 9px 10px;
    color: var(--ne-ink);
    font-size: 13px;
    outline: none;
}

.ne-search button {
    flex: 0 0 auto;
    border: 0;
    background: var(--ne-blue);
    padding: 9px 12px;
    color: #fff;
    font-size: 13px;
    font-weight: 800;
}

.ne-mobile-menu {
    display: none;
    margin-left: auto;
    color: var(--ne-ink);
}

.ne-channel-rail {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 10px 0 16px;
}

.ne-channel,
.ne-category-tabs a,
.ne-platform-strip a {
    display: inline-flex;
    align-items: center;
    min-height: 36px;
    border: 1px solid var(--ne-line);
    border-radius: 999px;
    padding: 0 14px;
    color: #28474a;
    background: #fff;
    font-size: 14px;
    font-weight: 800;
}

.ne-channel:hover,
.ne-channel.is-active,
.ne-category-tabs a:hover,
.ne-category-tabs a.is-active,
.ne-platform-strip a:hover {
    border-color: var(--ne-green);
    background: var(--ne-green);
    color: #fff;
}

.ne-layout {
    display: grid;
    grid-template-columns: minmax(0, 800px) 330px;
    gap: 32px;
    align-items: start;
    padding: 28px 0 54px;
}

.ne-feed {
    display: grid;
    min-width: 0;
    gap: 18px;
}

.ne-service-hero {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 320px;
    gap: 28px;
    align-items: stretch;
    border: 1px solid rgba(15, 118, 110, .16);
    border-radius: 8px;
    padding: 34px;
    background:
        linear-gradient(135deg, rgba(15, 118, 110, .10), rgba(22, 50, 79, .07)),
        #fff;
}

.ne-service-copy h1 {
    margin: 10px 0 0;
    max-width: 680px;
    color: var(--ne-ink);
    font-size: 42px;
    line-height: 1.18;
    font-weight: 900;
}

.ne-service-copy p {
    margin: 16px 0 0;
    max-width: 720px;
    color: var(--ne-muted);
    font-size: 16px;
    line-height: 1.85;
}

.ne-hero-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 24px;
}

.ne-primary-action {
    padding: 0 18px;
    background: var(--ne-green);
    color: #fff;
    box-shadow: 0 10px 24px rgba(15, 118, 110, .16);
}

.ne-secondary-action {
    border: 1px solid var(--ne-line);
    padding: 0 16px;
    background: #fff;
    color: var(--ne-green-dark);
}

.ne-hero-notes {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

.ne-hero-notes span {
    display: inline-flex;
    align-items: center;
    min-height: 34px;
    border-radius: 999px;
    padding: 0 12px;
    background: rgba(15, 118, 110, .09);
    color: var(--ne-green-dark);
    font-size: 13px;
    font-weight: 800;
}

.ne-service-panel {
    border: 1px solid rgba(15, 118, 110, .18);
    border-radius: 8px;
    padding: 24px;
    background: #0f2d30;
    color: #fff;
}

.ne-service-panel span {
    color: #f4d58b;
    font-size: 13px;
    font-weight: 900;
}

.ne-service-panel strong {
    display: block;
    margin-top: 10px;
    font-size: 22px;
    line-height: 1.35;
}

.ne-service-panel ul,
.ne-check-list {
    display: grid;
    gap: 9px;
    margin: 18px 0 0;
    padding: 0;
    list-style: none;
}

.ne-service-panel li,
.ne-check-list li {
    position: relative;
    padding-left: 18px;
    color: rgba(255, 255, 255, .82);
    line-height: 1.6;
}

.ne-service-panel li::before,
.ne-check-list li::before {
    content: "";
    position: absolute;
    left: 0;
    top: .72em;
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--ne-gold);
}

.ne-platform-strip {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.ne-platform-grid,
.ne-topic-grid {
    display: grid;
    gap: 12px;
}

.ne-platform-grid {
    grid-template-columns: repeat(5, minmax(0, 1fr));
}

.ne-topic-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
}

.ne-platform-card,
.ne-topic-card,
.ne-category-service-row {
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #fff;
}

.ne-platform-card {
    display: grid;
    min-height: 154px;
    align-content: start;
    gap: 8px;
    padding: 18px;
}

.ne-platform-card span,
.ne-topic-card span,
.ne-category-service-row span {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
}

.ne-platform-card strong {
    color: var(--ne-ink);
    font-size: 18px;
    line-height: 1.35;
    font-weight: 900;
}

.ne-platform-card p,
.ne-topic-card p {
    margin: 0;
    color: var(--ne-muted);
    font-size: 13px;
    line-height: 1.65;
}

.ne-topic-card strong,
.ne-proof-card strong,
.ne-warning-card strong {
    color: var(--ne-ink);
    font-size: 18px;
    line-height: 1.45;
    font-weight: 900;
}

.ne-card-note {
    margin-top: auto;
    color: var(--ne-green-dark);
    font-size: 12px;
    font-style: normal;
    font-weight: 800;
}

.ne-platform-card:hover,
.ne-topic-card:hover {
    border-color: rgba(15, 118, 110, .38);
    box-shadow: 0 12px 28px rgba(16, 35, 38, .08);
    transform: translateY(-1px);
}

.ne-topic-card {
    display: grid;
    gap: 8px;
    padding: 16px;
    background: linear-gradient(180deg, #ffffff, #f7fbfa);
}

.ne-proof-grid,
.ne-warning-grid {
    display: grid;
    gap: 12px;
}

.ne-proof-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
}

.ne-warning-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
}

.ne-proof-card,
.ne-warning-card {
    display: grid;
    gap: 8px;
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #fff;
    padding: 18px;
}

.ne-proof-card span {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
}

.ne-proof-card p,
.ne-warning-card p {
    margin: 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.75;
}

.ne-warning-card {
    background: linear-gradient(180deg, #ffffff, #fff8ee);
}

.ne-home-lead,
.ne-feed-card,
.ne-panel,
.ne-page-head,
.ne-article-main,
.ne-related-block {
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #fff;
}

.ne-home-lead {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 270px;
    gap: 24px;
    padding: 24px;
}

.ne-home-lead-main h2,
.ne-home-lead-main h1 {
    margin: 8px 0 0;
    color: var(--ne-ink);
    font-size: 30px;
    line-height: 1.28;
    font-weight: 900;
}

.ne-home-lead-main p {
    margin: 13px 0 0;
    color: var(--ne-muted);
    font-size: 15px;
    line-height: 1.8;
}

.ne-home-headlines {
    display: grid;
    align-content: start;
    gap: 10px;
    border-left: 1px solid var(--ne-soft-line);
    padding-left: 20px;
}

.ne-home-headlines a {
    color: #243c3f;
    font-weight: 800;
    line-height: 1.5;
}

.ne-mini-title,
.ne-page-kicker {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
    letter-spacing: .02em;
}

.ne-feed-card,
.ne-panel,
.ne-page-head,
.ne-related-block {
    padding: 22px;
}

.ne-section-title {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
}

.ne-title-row {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: var(--ne-ink);
    font-size: 18px;
    font-weight: 900;
}

.ne-title-row::before {
    content: "";
    width: 4px;
    height: 18px;
    border-radius: 999px;
    background: var(--ne-green);
}

.ne-article-card {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 92px;
    gap: 18px;
    border-top: 1px solid var(--ne-soft-line);
    padding: 18px 0 0;
}

.ne-article-card:first-child {
    border-top: 0;
    padding-top: 0;
}

.ne-card-meta,
.ne-post-info {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px 12px;
    color: var(--ne-subtle);
    font-size: 13px;
}

.ne-pill {
    display: inline-flex;
    align-items: center;
    min-height: 24px;
    border-radius: 999px;
    padding: 0 9px;
    background: var(--ne-soft);
    color: var(--ne-green-dark);
    font-weight: 800;
}

.ne-article-title {
    margin: 9px 0 0;
    color: var(--ne-ink);
    font-size: 21px;
    line-height: 1.42;
    font-weight: 900;
}

.ne-article-title a:hover,
.ne-home-lead-main a:hover,
.ne-hot-item:hover,
.ne-related-card:hover {
    color: var(--ne-green);
}

.ne-article-summary {
    margin: 9px 0 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.75;
}

.ne-card-action {
    justify-content: flex-start;
    min-height: 30px;
    margin-top: 10px;
    color: var(--ne-green);
    font-size: 14px;
}

.ne-thumb {
    display: grid;
    place-items: center;
    width: 92px;
    height: 92px;
    border-radius: 8px;
    background: linear-gradient(135deg, #e5f4ef, #f8f1df);
    color: var(--ne-green-dark);
    font-size: 30px;
    font-weight: 900;
}

.ne-sidebar,
.ne-post-aside {
    display: grid;
    gap: 18px;
    min-width: 0;
}

.ne-consult-panel {
    position: sticky;
    top: 96px;
    border-color: rgba(15, 118, 110, .20);
    background: linear-gradient(180deg, #ffffff, #f1f8f5);
}

.ne-feed-panel-title {
    margin: 8px 0 0;
    color: var(--ne-ink);
    font-size: 22px;
    line-height: 1.35;
    font-weight: 900;
}

.ne-feed-panel-desc {
    margin: 12px 0 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.75;
}

.ne-panel-actions {
    display: grid;
    gap: 10px;
    margin-top: 18px;
}

.ne-panel-action {
    min-height: 44px;
    justify-content: center;
}

.ne-wechat-box {
    margin-top: 16px;
    border: 1px dashed rgba(15, 118, 110, .42);
    border-radius: 8px;
    padding: 12px 14px;
    background: #fff;
    color: var(--ne-green-dark);
    font-size: 18px;
    font-weight: 900;
    text-align: center;
}

.ne-check-list li {
    color: var(--ne-muted);
    font-size: 14px;
}

.ne-wechat-card {
    display: grid;
    gap: 6px;
    margin-top: 16px;
    border: 1px dashed rgba(15, 118, 110, .42);
    border-radius: 8px;
    padding: 13px 14px;
    background: #fff;
}

.ne-wechat-card span {
    color: var(--ne-green);
    font-size: 12px;
    font-weight: 900;
}

.ne-wechat-card strong {
    color: var(--ne-green-dark);
    font-size: 18px;
    line-height: 1.35;
}

.ne-side-checks,
.ne-side-platforms {
    display: grid;
    gap: 10px;
    margin: 16px 0 0;
    padding: 0;
    list-style: none;
}

.ne-side-checks li {
    border-left: 3px solid var(--ne-green);
    padding-left: 10px;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.55;
}

.ne-side-platforms a {
    display: flex;
    align-items: center;
    justify-content: space-between;
    border: 1px solid var(--ne-soft-line);
    border-radius: 8px;
    padding: 11px 12px;
    color: #263f42;
    font-size: 14px;
    font-weight: 900;
}

.ne-side-platforms a::after {
    content: ">";
    color: var(--ne-green);
}

.ne-side-platforms a:hover {
    border-color: rgba(15, 118, 110, .32);
    background: var(--ne-soft);
    color: var(--ne-green-dark);
}

.ne-hot-list {
    display: grid;
    gap: 12px;
}

.ne-hot-item,
.ne-related-card {
    display: grid;
    grid-template-columns: 28px minmax(0, 1fr);
    gap: 10px;
    color: #263f42;
    font-size: 14px;
    font-weight: 800;
    line-height: 1.55;
}

.ne-hot-index,
.ne-related-index {
    display: inline-grid;
    place-items: center;
    width: 24px;
    height: 24px;
    border-radius: 7px;
    background: var(--ne-soft);
    color: var(--ne-green);
    font-size: 12px;
    font-weight: 900;
}

.ne-page-title {
    margin: 8px 0 0;
    color: var(--ne-ink);
    font-size: 34px;
    line-height: 1.25;
    font-weight: 900;
}

.ne-page-desc {
    margin: 12px 0 0;
    color: var(--ne-muted);
    font-size: 15px;
    line-height: 1.75;
}

.ne-category-tabs {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 18px;
}

.ne-category-service-row {
    display: grid;
    gap: 6px;
    margin-top: 18px;
    padding: 15px 16px;
    background: var(--ne-soft);
}

.ne-category-service-row strong {
    color: var(--ne-ink);
    font-size: 15px;
    line-height: 1.6;
}

.ne-article-layout {
    display: grid;
    grid-template-columns: minmax(0, 780px) 330px;
    gap: 34px;
    align-items: start;
    padding: 28px 0 54px;
}

.ne-post-column {
    min-width: 0;
}

.ne-breadcrumb {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 14px;
    color: var(--ne-subtle);
    font-size: 13px;
}

.ne-breadcrumb a:hover {
    color: var(--ne-green);
}

.ne-article-main {
    padding: 34px;
}

.ne-article-h1 {
    margin: 0;
    color: var(--ne-ink);
    font-size: 38px;
    line-height: 1.22;
    font-weight: 900;
}

.ne-article-excerpt {
    margin: 20px 0 0;
    border-left: 4px solid var(--ne-green);
    padding: 12px 16px;
    background: var(--ne-soft);
    color: #2a4a4d;
    font-size: 16px;
    line-height: 1.8;
}

.ne-article-service-brief {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
    margin-top: 22px;
    border: 1px solid rgba(15, 118, 110, .18);
    border-radius: 8px;
    padding: 18px;
    background: linear-gradient(135deg, #f1f8f5, #fff8e8);
}

.ne-article-service-brief span {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
}

.ne-article-service-brief h2 {
    margin: 5px 0 0;
    color: var(--ne-ink);
    font-size: 19px;
    line-height: 1.45;
    font-weight: 900;
}

.ne-article-service-brief a {
    flex: 0 0 auto;
    border-radius: 8px;
    padding: 11px 14px;
    background: var(--ne-green);
    color: #fff;
    font-size: 14px;
    font-weight: 900;
}

.ne-prose {
    margin-top: 28px;
    color: #253b3d;
    font-size: 17px;
    line-height: 1.9;
    overflow-wrap: anywhere;
}

.ne-prose h2,
.ne-prose h3 {
    margin: 32px 0 12px;
    color: var(--ne-ink);
    line-height: 1.35;
    font-weight: 900;
}

.ne-prose h2 {
    font-size: 25px;
}

.ne-prose h3 {
    font-size: 21px;
}

.ne-prose p,
.ne-prose ul,
.ne-prose ol,
.ne-prose blockquote,
.ne-prose table,
.ne-prose pre {
    margin: 16px 0;
}

.ne-prose a {
    color: var(--ne-green);
    font-weight: 800;
}

.ne-prose ul,
.ne-prose ol {
    padding-left: 1.4em;
}

.ne-prose blockquote {
    border-left: 4px solid var(--ne-gold);
    padding: 12px 16px;
    background: #fff8e8;
    color: #574421;
}

.ne-prose img {
    max-width: 100%;
    border-radius: 8px;
}

.ne-tag-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 26px;
}

.ne-tag-list span {
    border-radius: 999px;
    padding: 6px 11px;
    background: var(--ne-soft);
    color: var(--ne-green-dark);
    font-size: 13px;
    font-weight: 800;
}

.ne-article-cta,
.ne-ad-slot {
    margin-top: 30px;
    border-radius: 8px;
    padding: 22px;
    background: #0f2d30;
    color: #fff;
}

.ne-article-cta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
}

.ne-article-cta span {
    color: #f4d58b;
    font-size: 13px;
    font-weight: 900;
}

.ne-article-cta h2 {
    margin: 6px 0 0;
    font-size: 20px;
    line-height: 1.45;
    font-weight: 900;
}

.ne-cta-copy {
    margin: 10px 0 0;
    color: rgba(255, 255, 255, .8);
    font-size: 14px;
    line-height: 1.7;
}

.ne-cta-actions,
.ne-home-cta-actions {
    display: grid;
    gap: 10px;
    min-width: min(320px, 100%);
}

.ne-cta-action {
    min-height: 46px;
}

.ne-cta-actions .ne-secondary-action,
.ne-home-cta-actions .ne-secondary-action {
    border-color: rgba(255, 255, 255, .22);
    background: transparent;
    color: #fff;
}

.ne-inline-wechat {
    border: 1px solid rgba(255, 255, 255, .18);
    border-radius: 8px;
    padding: 11px 14px;
    background: rgba(255, 255, 255, .06);
    color: #fff;
    font-size: 14px;
    font-weight: 800;
    text-align: center;
}

.ne-related-block {
    margin-top: 18px;
}

.ne-related-grid {
    display: grid;
    gap: 12px;
}

.ne-footer {
    border-top: 1px solid var(--ne-line);
    background: #0c2526;
    color: rgba(255, 255, 255, .72);
}

.ne-footer-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    min-height: 76px;
    font-size: 13px;
}

.ne-hot-carousel,
.ne-breaking,
.ne-hot-dots {
    display: none;
}

.ne-home-cta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
    border-radius: 8px;
    padding: 26px;
    background: #0f2d30;
    color: #fff;
}

.ne-home-cta span {
    color: #f4d58b;
    font-size: 13px;
    font-weight: 900;
}

.ne-home-cta h2 {
    margin: 6px 0 0;
    font-size: 24px;
    line-height: 1.4;
    font-weight: 900;
}

.ne-contact-hero {
    margin-top: 28px;
}

.ne-contact-hero-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 22px;
}

.ne-contact-layout {
    display: grid;
    grid-template-columns: minmax(0, 800px) 330px;
    gap: 32px;
    align-items: start;
    padding: 24px 0 54px;
}

.ne-contact-primary {
    display: grid;
    grid-template-columns: minmax(0, 1.2fr) minmax(0, .8fr);
    gap: 18px;
}

.ne-contact-primary-card,
.ne-contact-secondary-card {
    display: grid;
    gap: 10px;
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    padding: 22px;
    background: #fff;
}

.ne-contact-primary-card {
    background: linear-gradient(135deg, rgba(15, 118, 110, .08), rgba(22, 50, 79, .06)), #fff;
}

.ne-contact-primary-card h2 {
    margin: 0;
    color: var(--ne-ink);
    font-size: 28px;
    line-height: 1.28;
    font-weight: 900;
}

.ne-contact-primary-card p,
.ne-contact-secondary-card p {
    margin: 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.8;
}

.ne-contact-secondary-card strong {
    color: var(--ne-green-dark);
    font-size: 26px;
    line-height: 1.2;
    font-weight: 900;
}

.ne-contact-main-action {
    min-height: 48px;
    margin-top: 6px;
}

.ne-home-lead-main,
.ne-home-headlines,
.ne-article-card > div,
.ne-post-column,
.ne-service-copy,
.ne-prose,
.ne-page-title,
.ne-article-title,
.ne-article-h1,
.ne-hot-item,
.ne-related-card {
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
}

@media (max-width: 980px) {
    .ne-shell {
        width: min(100% - 28px, 760px);
    }

    .ne-topnav,
    .ne-search,
    .ne-header-cta {
        display: none;
    }

    .ne-mobile-menu {
        display: inline-flex;
    }

    .ne-layout,
    .ne-article-layout,
    .ne-service-hero,
    .ne-home-lead,
    .ne-contact-layout,
    .ne-contact-primary {
        grid-template-columns: 1fr;
    }

    .ne-platform-grid,
    .ne-topic-grid,
    .ne-proof-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .ne-warning-grid {
        grid-template-columns: 1fr;
    }

    .ne-home-headlines {
        border-left: 0;
        border-top: 1px solid var(--ne-soft-line);
        padding: 18px 0 0;
    }

    .ne-consult-panel,
    .ne-home-cta {
        position: static;
    }

    .ne-home-cta,
    .ne-article-cta {
        align-items: flex-start;
        flex-direction: column;
    }
}

@media (max-width: 640px) {
    .ne-globalbar-row,
    .ne-footer-inner,
    .ne-article-cta,
    .ne-article-service-brief {
        align-items: flex-start;
        flex-direction: column;
    }

    .ne-brand {
        min-width: 0;
        font-size: 20px;
    }

    .ne-service-hero,
    .ne-article-main,
    .ne-feed-card,
    .ne-panel,
    .ne-page-head,
    .ne-related-block,
    .ne-home-cta,
    .ne-contact-primary-card,
    .ne-contact-secondary-card {
        padding: 20px;
    }

    .ne-service-copy h1 {
        font-size: 31px;
    }

    .ne-article-h1,
    .ne-page-title {
        font-size: 29px;
    }

    .ne-contact-primary-card h2 {
        font-size: 24px;
    }

    .ne-platform-grid,
    .ne-topic-grid,
    .ne-proof-grid {
        grid-template-columns: 1fr;
    }

    .ne-hero-actions,
    .ne-contact-hero-actions,
    .ne-panel-actions,
    .ne-cta-actions,
    .ne-home-cta-actions {
        display: grid;
        width: 100%;
    }

    .ne-article-card {
        grid-template-columns: 1fr;
    }

    .ne-thumb {
        display: none;
    }
}
EOF_RESOURCES_VIEWS_THEME_GLOBAL-ENTRY-PRO-20260509_ASSETS_THEME_CSS
sudo mkdir -p 'public/themes/global-entry-pro-20260509'
sudo tee 'public/themes/global-entry-pro-20260509/theme.css' >/dev/null <<'EOF_PUBLIC_THEMES_GLOBAL-ENTRY-PRO-20260509_THEME_CSS'
:root {
    --ne-ink: #102326;
    --ne-muted: #5d6b6e;
    --ne-subtle: #879295;
    --ne-line: #dde6e4;
    --ne-soft-line: #edf3f1;
    --ne-bg: #f5f8f7;
    --ne-panel: #ffffff;
    --ne-soft: #eef5f2;
    --ne-green: #0f766e;
    --ne-green-dark: #0b4f4a;
    --ne-gold: #c99632;
    --ne-blue: #16324f;
}

* {
    box-sizing: border-box;
}

.ne-body {
    margin: 0;
    background: var(--ne-bg);
    color: var(--ne-ink);
    font-family: Arial, "Microsoft YaHei", "PingFang SC", sans-serif;
    overflow-x: hidden;
}

.ne-body a {
    color: inherit;
    text-decoration: none;
}

.ne-main {
    min-height: 60vh;
}

.ne-shell {
    width: min(1180px, calc(100vw - 40px));
    margin: 0 auto;
}

.ne-globalbar {
    background: #0c2526;
    color: rgba(255, 255, 255, .78);
    font-size: 13px;
}

.ne-globalbar-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    min-height: 38px;
    gap: 16px;
}

.ne-globalbar-contact {
    color: #f4d58b;
    font-weight: 700;
}

.ne-header {
    position: sticky;
    top: 0;
    z-index: 50;
    border-bottom: 1px solid rgba(15, 118, 110, .14);
    background: rgba(255, 255, 255, .96);
    backdrop-filter: blur(12px);
}

.ne-header-row {
    display: flex;
    align-items: center;
    min-height: 76px;
    gap: 20px;
}

.ne-brand {
    display: inline-flex;
    align-items: center;
    flex: 0 0 auto;
    gap: 11px;
    min-width: 190px;
    color: var(--ne-ink);
    font-size: 23px;
    font-weight: 900;
    line-height: 1;
}

.ne-brand-mark {
    display: inline-grid;
    place-items: center;
    width: 42px;
    height: 42px;
    border-radius: 8px;
    background: linear-gradient(135deg, var(--ne-green), var(--ne-blue));
    color: #fff;
    font-size: 22px;
    font-weight: 900;
}

.ne-topnav {
    display: flex;
    align-items: center;
    min-width: 0;
    gap: 16px;
    color: #273f42;
    font-size: 15px;
    font-weight: 700;
    white-space: nowrap;
}

.ne-topnav a {
    display: inline-flex;
    align-items: center;
    min-height: 76px;
    border-bottom: 3px solid transparent;
}

.ne-topnav a:hover,
.ne-topnav a.is-active {
    color: var(--ne-green);
    border-bottom-color: var(--ne-green);
}

.ne-header-cta,
.ne-primary-action,
.ne-secondary-action,
.ne-card-action {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    min-height: 38px;
    border-radius: 8px;
    font-weight: 800;
}

.ne-header-cta {
    margin-left: auto;
    padding: 0 14px;
    background: var(--ne-green);
    color: #fff;
    font-size: 14px;
}

.ne-search {
    display: flex;
    align-items: center;
    width: 230px;
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #f8fbfa;
    overflow: hidden;
}

.ne-search input {
    min-width: 0;
    flex: 1;
    border: 0;
    background: transparent;
    padding: 9px 10px;
    color: var(--ne-ink);
    font-size: 13px;
    outline: none;
}

.ne-search button {
    flex: 0 0 auto;
    border: 0;
    background: var(--ne-blue);
    padding: 9px 12px;
    color: #fff;
    font-size: 13px;
    font-weight: 800;
}

.ne-mobile-menu {
    display: none;
    margin-left: auto;
    color: var(--ne-ink);
}

.ne-channel-rail {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    padding: 10px 0 16px;
}

.ne-channel,
.ne-category-tabs a,
.ne-platform-strip a {
    display: inline-flex;
    align-items: center;
    min-height: 36px;
    border: 1px solid var(--ne-line);
    border-radius: 999px;
    padding: 0 14px;
    color: #28474a;
    background: #fff;
    font-size: 14px;
    font-weight: 800;
}

.ne-channel:hover,
.ne-channel.is-active,
.ne-category-tabs a:hover,
.ne-category-tabs a.is-active,
.ne-platform-strip a:hover {
    border-color: var(--ne-green);
    background: var(--ne-green);
    color: #fff;
}

.ne-layout {
    display: grid;
    grid-template-columns: minmax(0, 800px) 330px;
    gap: 32px;
    align-items: start;
    padding: 28px 0 54px;
}

.ne-feed {
    display: grid;
    min-width: 0;
    gap: 18px;
}

.ne-service-hero {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 320px;
    gap: 28px;
    align-items: stretch;
    border: 1px solid rgba(15, 118, 110, .16);
    border-radius: 8px;
    padding: 34px;
    background:
        linear-gradient(135deg, rgba(15, 118, 110, .10), rgba(22, 50, 79, .07)),
        #fff;
}

.ne-service-copy h1 {
    margin: 10px 0 0;
    max-width: 680px;
    color: var(--ne-ink);
    font-size: 42px;
    line-height: 1.18;
    font-weight: 900;
}

.ne-service-copy p {
    margin: 16px 0 0;
    max-width: 720px;
    color: var(--ne-muted);
    font-size: 16px;
    line-height: 1.85;
}

.ne-hero-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 24px;
}

.ne-primary-action {
    padding: 0 18px;
    background: var(--ne-green);
    color: #fff;
    box-shadow: 0 10px 24px rgba(15, 118, 110, .16);
}

.ne-secondary-action {
    border: 1px solid var(--ne-line);
    padding: 0 16px;
    background: #fff;
    color: var(--ne-green-dark);
}

.ne-hero-notes {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    margin-top: 18px;
}

.ne-hero-notes span {
    display: inline-flex;
    align-items: center;
    min-height: 34px;
    border-radius: 999px;
    padding: 0 12px;
    background: rgba(15, 118, 110, .09);
    color: var(--ne-green-dark);
    font-size: 13px;
    font-weight: 800;
}

.ne-service-panel {
    border: 1px solid rgba(15, 118, 110, .18);
    border-radius: 8px;
    padding: 24px;
    background: #0f2d30;
    color: #fff;
}

.ne-service-panel span {
    color: #f4d58b;
    font-size: 13px;
    font-weight: 900;
}

.ne-service-panel strong {
    display: block;
    margin-top: 10px;
    font-size: 22px;
    line-height: 1.35;
}

.ne-service-panel ul,
.ne-check-list {
    display: grid;
    gap: 9px;
    margin: 18px 0 0;
    padding: 0;
    list-style: none;
}

.ne-service-panel li,
.ne-check-list li {
    position: relative;
    padding-left: 18px;
    color: rgba(255, 255, 255, .82);
    line-height: 1.6;
}

.ne-service-panel li::before,
.ne-check-list li::before {
    content: "";
    position: absolute;
    left: 0;
    top: .72em;
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--ne-gold);
}

.ne-platform-strip {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.ne-platform-grid,
.ne-topic-grid {
    display: grid;
    gap: 12px;
}

.ne-platform-grid {
    grid-template-columns: repeat(5, minmax(0, 1fr));
}

.ne-topic-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
}

.ne-platform-card,
.ne-topic-card,
.ne-category-service-row {
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #fff;
}

.ne-platform-card {
    display: grid;
    min-height: 154px;
    align-content: start;
    gap: 8px;
    padding: 18px;
}

.ne-platform-card span,
.ne-topic-card span,
.ne-category-service-row span {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
}

.ne-platform-card strong {
    color: var(--ne-ink);
    font-size: 18px;
    line-height: 1.35;
    font-weight: 900;
}

.ne-platform-card p,
.ne-topic-card p {
    margin: 0;
    color: var(--ne-muted);
    font-size: 13px;
    line-height: 1.65;
}

.ne-topic-card strong,
.ne-proof-card strong,
.ne-warning-card strong {
    color: var(--ne-ink);
    font-size: 18px;
    line-height: 1.45;
    font-weight: 900;
}

.ne-card-note {
    margin-top: auto;
    color: var(--ne-green-dark);
    font-size: 12px;
    font-style: normal;
    font-weight: 800;
}

.ne-platform-card:hover,
.ne-topic-card:hover {
    border-color: rgba(15, 118, 110, .38);
    box-shadow: 0 12px 28px rgba(16, 35, 38, .08);
    transform: translateY(-1px);
}

.ne-topic-card {
    display: grid;
    gap: 8px;
    padding: 16px;
    background: linear-gradient(180deg, #ffffff, #f7fbfa);
}

.ne-proof-grid,
.ne-warning-grid {
    display: grid;
    gap: 12px;
}

.ne-proof-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
}

.ne-warning-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
}

.ne-proof-card,
.ne-warning-card {
    display: grid;
    gap: 8px;
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #fff;
    padding: 18px;
}

.ne-proof-card span {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
}

.ne-proof-card p,
.ne-warning-card p {
    margin: 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.75;
}

.ne-warning-card {
    background: linear-gradient(180deg, #ffffff, #fff8ee);
}

.ne-home-lead,
.ne-feed-card,
.ne-panel,
.ne-page-head,
.ne-article-main,
.ne-related-block {
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    background: #fff;
}

.ne-home-lead {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 270px;
    gap: 24px;
    padding: 24px;
}

.ne-home-lead-main h2,
.ne-home-lead-main h1 {
    margin: 8px 0 0;
    color: var(--ne-ink);
    font-size: 30px;
    line-height: 1.28;
    font-weight: 900;
}

.ne-home-lead-main p {
    margin: 13px 0 0;
    color: var(--ne-muted);
    font-size: 15px;
    line-height: 1.8;
}

.ne-home-headlines {
    display: grid;
    align-content: start;
    gap: 10px;
    border-left: 1px solid var(--ne-soft-line);
    padding-left: 20px;
}

.ne-home-headlines a {
    color: #243c3f;
    font-weight: 800;
    line-height: 1.5;
}

.ne-mini-title,
.ne-page-kicker {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
    letter-spacing: .02em;
}

.ne-feed-card,
.ne-panel,
.ne-page-head,
.ne-related-block {
    padding: 22px;
}

.ne-section-title {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 16px;
}

.ne-title-row {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    color: var(--ne-ink);
    font-size: 18px;
    font-weight: 900;
}

.ne-title-row::before {
    content: "";
    width: 4px;
    height: 18px;
    border-radius: 999px;
    background: var(--ne-green);
}

.ne-article-card {
    display: grid;
    grid-template-columns: minmax(0, 1fr) 92px;
    gap: 18px;
    border-top: 1px solid var(--ne-soft-line);
    padding: 18px 0 0;
}

.ne-article-card:first-child {
    border-top: 0;
    padding-top: 0;
}

.ne-card-meta,
.ne-post-info {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px 12px;
    color: var(--ne-subtle);
    font-size: 13px;
}

.ne-pill {
    display: inline-flex;
    align-items: center;
    min-height: 24px;
    border-radius: 999px;
    padding: 0 9px;
    background: var(--ne-soft);
    color: var(--ne-green-dark);
    font-weight: 800;
}

.ne-article-title {
    margin: 9px 0 0;
    color: var(--ne-ink);
    font-size: 21px;
    line-height: 1.42;
    font-weight: 900;
}

.ne-article-title a:hover,
.ne-home-lead-main a:hover,
.ne-hot-item:hover,
.ne-related-card:hover {
    color: var(--ne-green);
}

.ne-article-summary {
    margin: 9px 0 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.75;
}

.ne-card-action {
    justify-content: flex-start;
    min-height: 30px;
    margin-top: 10px;
    color: var(--ne-green);
    font-size: 14px;
}

.ne-thumb {
    display: grid;
    place-items: center;
    width: 92px;
    height: 92px;
    border-radius: 8px;
    background: linear-gradient(135deg, #e5f4ef, #f8f1df);
    color: var(--ne-green-dark);
    font-size: 30px;
    font-weight: 900;
}

.ne-sidebar,
.ne-post-aside {
    display: grid;
    gap: 18px;
    min-width: 0;
}

.ne-consult-panel {
    position: sticky;
    top: 96px;
    border-color: rgba(15, 118, 110, .20);
    background: linear-gradient(180deg, #ffffff, #f1f8f5);
}

.ne-feed-panel-title {
    margin: 8px 0 0;
    color: var(--ne-ink);
    font-size: 22px;
    line-height: 1.35;
    font-weight: 900;
}

.ne-feed-panel-desc {
    margin: 12px 0 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.75;
}

.ne-panel-actions {
    display: grid;
    gap: 10px;
    margin-top: 18px;
}

.ne-panel-action {
    min-height: 44px;
    justify-content: center;
}

.ne-wechat-box {
    margin-top: 16px;
    border: 1px dashed rgba(15, 118, 110, .42);
    border-radius: 8px;
    padding: 12px 14px;
    background: #fff;
    color: var(--ne-green-dark);
    font-size: 18px;
    font-weight: 900;
    text-align: center;
}

.ne-check-list li {
    color: var(--ne-muted);
    font-size: 14px;
}

.ne-wechat-card {
    display: grid;
    gap: 6px;
    margin-top: 16px;
    border: 1px dashed rgba(15, 118, 110, .42);
    border-radius: 8px;
    padding: 13px 14px;
    background: #fff;
}

.ne-wechat-card span {
    color: var(--ne-green);
    font-size: 12px;
    font-weight: 900;
}

.ne-wechat-card strong {
    color: var(--ne-green-dark);
    font-size: 18px;
    line-height: 1.35;
}

.ne-side-checks,
.ne-side-platforms {
    display: grid;
    gap: 10px;
    margin: 16px 0 0;
    padding: 0;
    list-style: none;
}

.ne-side-checks li {
    border-left: 3px solid var(--ne-green);
    padding-left: 10px;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.55;
}

.ne-side-platforms a {
    display: flex;
    align-items: center;
    justify-content: space-between;
    border: 1px solid var(--ne-soft-line);
    border-radius: 8px;
    padding: 11px 12px;
    color: #263f42;
    font-size: 14px;
    font-weight: 900;
}

.ne-side-platforms a::after {
    content: ">";
    color: var(--ne-green);
}

.ne-side-platforms a:hover {
    border-color: rgba(15, 118, 110, .32);
    background: var(--ne-soft);
    color: var(--ne-green-dark);
}

.ne-hot-list {
    display: grid;
    gap: 12px;
}

.ne-hot-item,
.ne-related-card {
    display: grid;
    grid-template-columns: 28px minmax(0, 1fr);
    gap: 10px;
    color: #263f42;
    font-size: 14px;
    font-weight: 800;
    line-height: 1.55;
}

.ne-hot-index,
.ne-related-index {
    display: inline-grid;
    place-items: center;
    width: 24px;
    height: 24px;
    border-radius: 7px;
    background: var(--ne-soft);
    color: var(--ne-green);
    font-size: 12px;
    font-weight: 900;
}

.ne-page-title {
    margin: 8px 0 0;
    color: var(--ne-ink);
    font-size: 34px;
    line-height: 1.25;
    font-weight: 900;
}

.ne-page-desc {
    margin: 12px 0 0;
    color: var(--ne-muted);
    font-size: 15px;
    line-height: 1.75;
}

.ne-category-tabs {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 18px;
}

.ne-category-service-row {
    display: grid;
    gap: 6px;
    margin-top: 18px;
    padding: 15px 16px;
    background: var(--ne-soft);
}

.ne-category-service-row strong {
    color: var(--ne-ink);
    font-size: 15px;
    line-height: 1.6;
}

.ne-article-layout {
    display: grid;
    grid-template-columns: minmax(0, 780px) 330px;
    gap: 34px;
    align-items: start;
    padding: 28px 0 54px;
}

.ne-post-column {
    min-width: 0;
}

.ne-breadcrumb {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 14px;
    color: var(--ne-subtle);
    font-size: 13px;
}

.ne-breadcrumb a:hover {
    color: var(--ne-green);
}

.ne-article-main {
    padding: 34px;
}

.ne-article-h1 {
    margin: 0;
    color: var(--ne-ink);
    font-size: 38px;
    line-height: 1.22;
    font-weight: 900;
}

.ne-article-excerpt {
    margin: 20px 0 0;
    border-left: 4px solid var(--ne-green);
    padding: 12px 16px;
    background: var(--ne-soft);
    color: #2a4a4d;
    font-size: 16px;
    line-height: 1.8;
}

.ne-article-service-brief {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
    margin-top: 22px;
    border: 1px solid rgba(15, 118, 110, .18);
    border-radius: 8px;
    padding: 18px;
    background: linear-gradient(135deg, #f1f8f5, #fff8e8);
}

.ne-article-service-brief span {
    color: var(--ne-green);
    font-size: 13px;
    font-weight: 900;
}

.ne-article-service-brief h2 {
    margin: 5px 0 0;
    color: var(--ne-ink);
    font-size: 19px;
    line-height: 1.45;
    font-weight: 900;
}

.ne-article-service-brief a {
    flex: 0 0 auto;
    border-radius: 8px;
    padding: 11px 14px;
    background: var(--ne-green);
    color: #fff;
    font-size: 14px;
    font-weight: 900;
}

.ne-prose {
    margin-top: 28px;
    color: #253b3d;
    font-size: 17px;
    line-height: 1.9;
    overflow-wrap: anywhere;
}

.ne-prose h2,
.ne-prose h3 {
    margin: 32px 0 12px;
    color: var(--ne-ink);
    line-height: 1.35;
    font-weight: 900;
}

.ne-prose h2 {
    font-size: 25px;
}

.ne-prose h3 {
    font-size: 21px;
}

.ne-prose p,
.ne-prose ul,
.ne-prose ol,
.ne-prose blockquote,
.ne-prose table,
.ne-prose pre {
    margin: 16px 0;
}

.ne-prose a {
    color: var(--ne-green);
    font-weight: 800;
}

.ne-prose ul,
.ne-prose ol {
    padding-left: 1.4em;
}

.ne-prose blockquote {
    border-left: 4px solid var(--ne-gold);
    padding: 12px 16px;
    background: #fff8e8;
    color: #574421;
}

.ne-prose img {
    max-width: 100%;
    border-radius: 8px;
}

.ne-tag-list {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 26px;
}

.ne-tag-list span {
    border-radius: 999px;
    padding: 6px 11px;
    background: var(--ne-soft);
    color: var(--ne-green-dark);
    font-size: 13px;
    font-weight: 800;
}

.ne-article-cta,
.ne-ad-slot {
    margin-top: 30px;
    border-radius: 8px;
    padding: 22px;
    background: #0f2d30;
    color: #fff;
}

.ne-article-cta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
}

.ne-article-cta span {
    color: #f4d58b;
    font-size: 13px;
    font-weight: 900;
}

.ne-article-cta h2 {
    margin: 6px 0 0;
    font-size: 20px;
    line-height: 1.45;
    font-weight: 900;
}

.ne-cta-copy {
    margin: 10px 0 0;
    color: rgba(255, 255, 255, .8);
    font-size: 14px;
    line-height: 1.7;
}

.ne-cta-actions,
.ne-home-cta-actions {
    display: grid;
    gap: 10px;
    min-width: min(320px, 100%);
}

.ne-cta-action {
    min-height: 46px;
}

.ne-cta-actions .ne-secondary-action,
.ne-home-cta-actions .ne-secondary-action {
    border-color: rgba(255, 255, 255, .22);
    background: transparent;
    color: #fff;
}

.ne-inline-wechat {
    border: 1px solid rgba(255, 255, 255, .18);
    border-radius: 8px;
    padding: 11px 14px;
    background: rgba(255, 255, 255, .06);
    color: #fff;
    font-size: 14px;
    font-weight: 800;
    text-align: center;
}

.ne-related-block {
    margin-top: 18px;
}

.ne-related-grid {
    display: grid;
    gap: 12px;
}

.ne-footer {
    border-top: 1px solid var(--ne-line);
    background: #0c2526;
    color: rgba(255, 255, 255, .72);
}

.ne-footer-inner {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    min-height: 76px;
    font-size: 13px;
}

.ne-hot-carousel,
.ne-breaking,
.ne-hot-dots {
    display: none;
}

.ne-home-cta {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 18px;
    border-radius: 8px;
    padding: 26px;
    background: #0f2d30;
    color: #fff;
}

.ne-home-cta span {
    color: #f4d58b;
    font-size: 13px;
    font-weight: 900;
}

.ne-home-cta h2 {
    margin: 6px 0 0;
    font-size: 24px;
    line-height: 1.4;
    font-weight: 900;
}

.ne-contact-hero {
    margin-top: 28px;
}

.ne-contact-hero-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
    margin-top: 22px;
}

.ne-contact-layout {
    display: grid;
    grid-template-columns: minmax(0, 800px) 330px;
    gap: 32px;
    align-items: start;
    padding: 24px 0 54px;
}

.ne-contact-primary {
    display: grid;
    grid-template-columns: minmax(0, 1.2fr) minmax(0, .8fr);
    gap: 18px;
}

.ne-contact-primary-card,
.ne-contact-secondary-card {
    display: grid;
    gap: 10px;
    border: 1px solid var(--ne-line);
    border-radius: 8px;
    padding: 22px;
    background: #fff;
}

.ne-contact-primary-card {
    background: linear-gradient(135deg, rgba(15, 118, 110, .08), rgba(22, 50, 79, .06)), #fff;
}

.ne-contact-primary-card h2 {
    margin: 0;
    color: var(--ne-ink);
    font-size: 28px;
    line-height: 1.28;
    font-weight: 900;
}

.ne-contact-primary-card p,
.ne-contact-secondary-card p {
    margin: 0;
    color: var(--ne-muted);
    font-size: 14px;
    line-height: 1.8;
}

.ne-contact-secondary-card strong {
    color: var(--ne-green-dark);
    font-size: 26px;
    line-height: 1.2;
    font-weight: 900;
}

.ne-contact-main-action {
    min-height: 48px;
    margin-top: 6px;
}

.ne-home-lead-main,
.ne-home-headlines,
.ne-article-card > div,
.ne-post-column,
.ne-service-copy,
.ne-prose,
.ne-page-title,
.ne-article-title,
.ne-article-h1,
.ne-hot-item,
.ne-related-card {
    min-width: 0;
    overflow-wrap: anywhere;
    word-break: break-word;
}

@media (max-width: 980px) {
    .ne-shell {
        width: min(100% - 28px, 760px);
    }

    .ne-topnav,
    .ne-search,
    .ne-header-cta {
        display: none;
    }

    .ne-mobile-menu {
        display: inline-flex;
    }

    .ne-layout,
    .ne-article-layout,
    .ne-service-hero,
    .ne-home-lead,
    .ne-contact-layout,
    .ne-contact-primary {
        grid-template-columns: 1fr;
    }

    .ne-platform-grid,
    .ne-topic-grid,
    .ne-proof-grid {
        grid-template-columns: repeat(2, minmax(0, 1fr));
    }

    .ne-warning-grid {
        grid-template-columns: 1fr;
    }

    .ne-home-headlines {
        border-left: 0;
        border-top: 1px solid var(--ne-soft-line);
        padding: 18px 0 0;
    }

    .ne-consult-panel,
    .ne-home-cta {
        position: static;
    }

    .ne-home-cta,
    .ne-article-cta {
        align-items: flex-start;
        flex-direction: column;
    }
}

@media (max-width: 640px) {
    .ne-globalbar-row,
    .ne-footer-inner,
    .ne-article-cta,
    .ne-article-service-brief {
        align-items: flex-start;
        flex-direction: column;
    }

    .ne-brand {
        min-width: 0;
        font-size: 20px;
    }

    .ne-service-hero,
    .ne-article-main,
    .ne-feed-card,
    .ne-panel,
    .ne-page-head,
    .ne-related-block,
    .ne-home-cta,
    .ne-contact-primary-card,
    .ne-contact-secondary-card {
        padding: 20px;
    }

    .ne-service-copy h1 {
        font-size: 31px;
    }

    .ne-article-h1,
    .ne-page-title {
        font-size: 29px;
    }

    .ne-contact-primary-card h2 {
        font-size: 24px;
    }

    .ne-platform-grid,
    .ne-topic-grid,
    .ne-proof-grid {
        grid-template-columns: 1fr;
    }

    .ne-hero-actions,
    .ne-contact-hero-actions,
    .ne-panel-actions,
    .ne-cta-actions,
    .ne-home-cta-actions {
        display: grid;
        width: 100%;
    }

    .ne-article-card {
        grid-template-columns: 1fr;
    }

    .ne-thumb {
        display: none;
    }
}
EOF_PUBLIC_THEMES_GLOBAL-ENTRY-PRO-20260509_THEME_CSS
echo '[2/4] Rebuilding containers...'
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml build app web
echo '[3/4] Restarting services...'
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --force-recreate app web queue scheduler reverb
echo '[4/4] Clearing and warming caches...'
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan optimize:clear
sudo docker compose --env-file .env.prod -f docker-compose.prod.yml exec -T app php artisan view:cache
echo 'DONE' 
