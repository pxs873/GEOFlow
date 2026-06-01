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
