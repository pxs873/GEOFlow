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
