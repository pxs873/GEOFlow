import { CtaSection } from "@/components/cta-section";
import { DashboardMockup } from "@/components/dashboard-mockup";
import { FeatureCard } from "@/components/feature-card";
import { HeroSection } from "@/components/hero-section";
import { MetricCard } from "@/components/metric-card";
import { ProcessStep } from "@/components/process-step";
import { ReportCard } from "@/components/report-card";
import { SectionHeading } from "@/components/section-heading";
import {
  coreMetrics,
  homepagePainPoints,
  reportCards,
  serviceCapabilities,
  serviceSteps,
} from "@/lib/site";

export default function Home() {
  return (
    <main className="flex-1">
      <HeroSection
        eyebrow="AI Search Visibility"
        title="让你的品牌，被 AI 搜索看见、引用和推荐"
        description="GEOFlow 帮助中国出海 AI / SaaS / B2B 软件公司，检测并提升品牌在 ChatGPT、Perplexity、Google AI、DeepSeek、Kimi、豆包等 AI 搜索结果中的出现率、引用率和推荐率。"
        primaryCta={{ href: "/free-audit", label: "免费获取 AI 搜索曝光诊断" }}
        secondaryCta={{ href: "/audit", label: "查看体检报告示例" }}
        aside={<DashboardMockup />}
      />

      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <SectionHeading
          eyebrow="Why Brands Miss Out"
          title="你的客户正在问 AI，但 AI 不一定会推荐你"
          description="当海外客户通过 AI 工具找方案、比品牌、问推荐时，很多中国出海公司的官网和内容资产还没有被 AI 正确理解。"
        />
        <div className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {homepagePainPoints.map((item) => (
            <FeatureCard key={item.title} title={item.title} description={item.description} />
          ))}
        </div>
      </section>

      <section className="bg-[linear-gradient(180deg,rgba(235,243,255,0.55),rgba(255,255,255,0.9))]">
        <div className="mx-auto max-w-7xl px-6 py-18 md:px-10">
          <SectionHeading
            eyebrow="What GEOFlow Does"
            title="把 AI 搜索曝光问题，拆成可检测、可优化、可复测的增长流程"
            description="GEOFlow 不是抽象咨询，而是围绕品牌实体、官网内容、第三方引用和报告资产做结构化诊断与 30 天提升。"
          />
          <div className="mt-8 grid gap-5 lg:grid-cols-2 xl:grid-cols-4">
            {serviceCapabilities.map((item) => (
              <FeatureCard
                key={item.title}
                title={item.title}
                description={item.description}
                tone="soft"
              />
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <SectionHeading
          eyebrow="Core Metrics"
          title="先看清 AI 为什么不提你，再决定优化什么"
          description="首页首屏右侧展示仪表盘，页面中段继续展开关键指标，让用户快速理解 GEOFlow 的数据感与交付边界。"
        />
        <div className="mt-8 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {coreMetrics.map((item) => (
            <MetricCard
              key={item.label}
              label={item.label}
              value={item.value}
              detail={item.detail}
              delta={item.delta}
            />
          ))}
        </div>
      </section>

      <section className="bg-slate-950 text-white">
        <div className="mx-auto max-w-7xl px-6 py-18 md:px-10">
          <SectionHeading
            eyebrow="Execution Flow"
            title="先诊断，再提升，再复测"
            description="第一版官网强调清晰、可信、可落地。流程区直接告诉客户，从提交信息到拿到复测结果，中间每一步会发生什么。"
            invert
          />
          <div className="mt-8 grid gap-5 lg:grid-cols-4">
            {serviceSteps.map((item, index) => (
              <ProcessStep
                key={item.title}
                step={`${index + 1}`}
                title={item.title}
                description={item.description}
              />
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <SectionHeading
          eyebrow="Best Fit"
          title="更适合这些已经开始海外获客、但 AI 曝光不足的团队"
          description="不是所有公司都需要 GEOFlow。我们更适合已经有英文官网、有海外目标市场、并准备系统提升 AI 搜索可见度的团队。"
        />
        <div className="mt-8 grid gap-5 lg:grid-cols-3">
          <FeatureCard
            title="出海 AI 公司"
            description="正在做品牌教育，但在 ChatGPT、Perplexity、Google AI 的推荐结果里还没有稳定出现。"
          />
          <FeatureCard
            title="出海 SaaS 公司"
            description="官网有内容、有功能页，但 AI 对品牌和解决方案的理解还不完整，容易被竞品抢走推荐入口。"
          />
          <FeatureCard
            title="出海 B2B 软件公司"
            description="已有行业案例和内容资产，想把 SEO 时代的内容沉淀迁移成 AI 搜索时代的品牌信号。"
          />
        </div>
      </section>

      <section className="bg-[linear-gradient(180deg,rgba(243,247,255,0.9),rgba(255,255,255,1))]">
        <div className="mx-auto max-w-7xl px-6 py-18 md:px-10">
          <SectionHeading
            eyebrow="Reports"
            title="用行业报告把品牌从“被搜索”推进到“被引用”"
            description="第一版先展示 GEOFlow 的报告方向。正式报告页可继续扩展为内容入口和获客资产。"
          />
          <div className="mt-8 grid gap-5 lg:grid-cols-3">
            {reportCards.map((item) => (
              <ReportCard key={item.title} {...item} />
            ))}
          </div>
        </div>
      </section>

      <CtaSection
        title="先做一次 AI 搜索曝光体检，再决定下一步怎么投资源"
        description="提交品牌、官网和竞品信息，我们会从出现率、引用率、推荐率、场景覆盖率和内容资产健康度几条线，给你一个可执行的起点。"
        primaryCta={{ href: "/free-audit", label: "申请免费诊断" }}
        secondaryCta={{ href: "/growth-service", label: "查看 30 天提升服务" }}
      />
    </main>
  );
}
