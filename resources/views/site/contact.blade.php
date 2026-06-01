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
