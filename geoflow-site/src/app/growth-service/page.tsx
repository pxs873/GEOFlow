import type { Metadata } from "next";
import { CtaSection } from "@/components/cta-section";
import { FeatureCard } from "@/components/feature-card";
import { ProcessStep } from "@/components/process-step";
import { SectionHeading } from "@/components/section-heading";
import { growthDeliverables, growthTimeline } from "@/lib/site";

export const metadata: Metadata = {
  title: "30 天提升服务",
  description: "查看 GEOFlow 30 天 AI 搜索曝光提升服务的适用对象、交付物与 4 周节奏。",
};

export default function GrowthServicePage() {
  return (
    <main className="flex-1">
      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <SectionHeading
          eyebrow="30-Day Growth Service"
          title="把品牌实体、官网内容和第三方引用，做成 AI 更愿意推荐的信号资产"
          description="我们不承诺排名第一，也不做夸张增长叙事。GEOFlow 的 30 天服务更像一个结构化冲刺：聚焦可执行的资产修复、内容增强和复测。"
        />
        <div className="mt-8 grid gap-5 lg:grid-cols-3">
          {growthDeliverables.map((item) => (
            <FeatureCard key={item.title} title={item.title} description={item.description} tone="soft" />
          ))}
        </div>
      </section>

      <section className="bg-slate-950 text-white">
        <div className="mx-auto max-w-7xl px-6 py-18 md:px-10">
          <SectionHeading
            eyebrow="Four-Week Sprint"
            title="4 周推进节奏，确保每一步都能解释为什么做"
            description="从体检诊断到复测回看，中间会覆盖品牌实体、官网页面、FAQ、行业报告和引用场景。"
            invert
          />
          <div className="mt-8 grid gap-5 lg:grid-cols-4">
            {growthTimeline.map((item, index) => (
              <ProcessStep
                key={item.title}
                step={`W${index + 1}`}
                title={item.title}
                description={item.description}
              />
            ))}
          </div>
        </div>
      </section>

      <CtaSection
        title="如果你已经有英文官网和海外线索来源，这个服务更容易产生结果"
        description="适合已经开始做品牌教育、内容营销或产品说明，但 AI 推荐结果还不稳定的出海团队。"
        primaryCta={{ href: "/free-audit", label: "申请免费诊断" }}
        secondaryCta={{ href: "/reports", label: "先看行业报告" }}
      />
    </main>
  );
}
