import type { Metadata } from "next";
import { CtaSection } from "@/components/cta-section";
import { FeatureCard } from "@/components/feature-card";
import { SectionHeading } from "@/components/section-heading";

export const metadata: Metadata = {
  title: "关于我们",
  description: "了解 GEOFlow 为什么聚焦 AI 搜索曝光优化，以及我们服务中国出海软件公司的方法论。",
};

export default function AboutPage() {
  return (
    <main className="flex-1">
      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <SectionHeading
          eyebrow="About GEOFlow"
          title="我们关注的不是“内容数量”，而是 AI 是否真的理解并推荐你的品牌"
          description="GEOFlow 服务中国出海 AI / SaaS / B2B 软件公司，把官网、报告、FAQ、案例与第三方内容变成更适合 AI 搜索时代的品牌资产。"
        />
        <div className="mt-8 grid gap-5 lg:grid-cols-3">
          <FeatureCard
            title="方法论"
            description="检测 → 诊断 → 内容资产优化 → 追踪复测。每一步都对应清晰指标，而不是抽象建议。"
          />
          <FeatureCard
            title="服务对象"
            description="已经开始做海外获客和品牌表达，希望把 SEO 时代的内容沉淀升级成 GEO 时代的 AI 信号。"
          />
          <FeatureCard
            title="交付边界"
            description="我们优先交付能解释清楚、能复测、能持续演化的内容资产与品牌曝光结构。"
          />
        </div>
      </section>

      <CtaSection
        title="如果你已经意识到 AI 在替客户做第一轮品牌筛选，我们可以一起先把这件事看清楚"
        description="先从免费诊断开始，确认品牌在哪些查询场景被忽略、被误解、或被竞品抢走推荐入口。"
        primaryCta={{ href: "/free-audit", label: "申请免费诊断" }}
        secondaryCta={{ href: "/audit", label: "查看体检报告结构" }}
      />
    </main>
  );
}
