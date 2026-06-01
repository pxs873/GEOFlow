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
