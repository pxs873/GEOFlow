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
