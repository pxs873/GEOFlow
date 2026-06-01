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
