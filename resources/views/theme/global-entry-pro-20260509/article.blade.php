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
