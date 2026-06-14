import type { Metadata } from "next";
import { AuditForm } from "@/components/audit-form";
import { CtaSection } from "@/components/cta-section";
import { SectionHeading } from "@/components/section-heading";

export const metadata: Metadata = {
  title: "免费诊断",
  description: "提交品牌、官网和竞品信息，获取 GEOFlow 的 AI 搜索曝光免费诊断入口。",
};

export default function FreeAuditPage() {
  return (
    <main className="flex-1">
      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <div className="grid gap-10 lg:grid-cols-[0.95fr_1.05fr] lg:items-start">
          <div className="space-y-6">
            <SectionHeading
              eyebrow="Free Audit"
              title="先把品牌、官网和竞品交给 GEOFlow，看清 AI 为什么没有稳定推荐你"
              description="第一版表单先承担线索收集和问题初筛。提交后，你可以用表单回执或占位逻辑继续接入 Formspree。"
            />
            <div className="grid gap-4">
              <div className="rounded-3xl border border-[var(--color-border)] bg-white p-6 shadow-[var(--shadow-card)]">
                <h3 className="text-lg font-semibold">你会得到什么</h3>
                <ul className="mt-4 space-y-3 text-sm leading-7 text-[var(--color-ink-soft)]">
                  <li>品牌在主流 AI 搜索中的出现率初步判断</li>
                  <li>竞品推荐差距与潜在缺口</li>
                  <li>官网内容、FAQ、案例、报告等资产的优先级建议</li>
                </ul>
              </div>
              <div className="rounded-3xl border border-[var(--color-border)] bg-[var(--color-surface-muted)] p-6">
                <h3 className="text-lg font-semibold">当前支持的渠道</h3>
                <p className="mt-3 text-sm leading-7 text-[var(--color-ink-soft)]">
                  ChatGPT、Perplexity、Google AI、DeepSeek、Kimi、豆包。
                </p>
              </div>
            </div>
          </div>
          <AuditForm />
        </div>
      </section>

      <CtaSection
        title="想先看报告结构，再决定是否提交信息？"
        description="你可以先浏览 GEOFlow 体检报告页，了解我们具体会检查哪些指标和内容资产。"
        primaryCta={{ href: "/audit", label: "查看体检报告页" }}
        secondaryCta={{ href: "/growth-service", label: "了解 30 天提升服务" }}
      />
    </main>
  );
}
