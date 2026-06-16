import type { Metadata } from "next";
import Link from "next/link";
import { CtaSection } from "@/components/cta-section";

export const metadata: Metadata = {
  title: "提交成功",
  description: "GEOFlow 已收到你的免费诊断信息，下一步会进入人工初筛与联系。",
};

export default function ThankYouPage() {
  return (
    <main className="flex-1">
      <section className="mx-auto max-w-4xl px-6 py-14 md:px-10 md:py-18">
        <div className="rounded-[2rem] border border-[var(--color-border)] bg-white p-6 shadow-[var(--shadow-card)] sm:p-8 md:p-10">
          <div className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border)] bg-[var(--color-surface-muted)] px-3 py-1 text-xs font-semibold uppercase tracking-[0.18em] text-[var(--color-brand)]">
            Submission Received
          </div>
          <h1 className="mt-5 text-[2rem] font-semibold leading-tight text-[var(--color-ink)] sm:text-[2.6rem]">
            GEOFlow 已收到你的免费诊断信息
          </h1>
          <p className="mt-4 max-w-2xl text-base leading-7 text-[var(--color-ink-soft)] sm:text-lg sm:leading-8">
            下一步我们会先做基础初筛，判断品牌出现率、竞品差距和内容资产缺口，再通过你留下的邮箱或微信联系你。
          </p>

          <div className="mt-8 grid gap-4 md:grid-cols-3">
            <div className="rounded-3xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
              <div className="text-sm font-semibold text-[var(--color-ink)]">1. 初步判断</div>
              <p className="mt-2 text-sm leading-6 text-[var(--color-ink-soft)]">
                先看品牌是否已经进入主流 AI 回答的候选名单。
              </p>
            </div>
            <div className="rounded-3xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
              <div className="text-sm font-semibold text-[var(--color-ink)]">2. 找差距</div>
              <p className="mt-2 text-sm leading-6 text-[var(--color-ink-soft)]">
                对照竞品与内容资产，识别最值得先补的信号缺口。
              </p>
            </div>
            <div className="rounded-3xl border border-[var(--color-border)] bg-[var(--color-surface)] p-5">
              <div className="text-sm font-semibold text-[var(--color-ink)]">3. 再联系你</div>
              <p className="mt-2 text-sm leading-6 text-[var(--color-ink-soft)]">
                确认是否进入下一步诊断或 30 天提升方案。
              </p>
            </div>
          </div>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              href="/audit"
              className="rounded-2xl bg-[var(--color-brand)] px-6 py-3.5 text-center font-semibold text-white transition hover:bg-[var(--color-brand-deep)]"
            >
              先看体检报告示例
            </Link>
            <Link
              href="/"
              className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] px-6 py-3.5 text-center font-semibold text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
            >
              返回首页
            </Link>
          </div>
        </div>
      </section>

      <CtaSection
        title="想继续了解 GEOFlow 的 30 天提升流程？"
        description="你也可以直接继续看服务页，提前了解我们会怎样把诊断结果转成后续优化动作。"
        primaryCta={{ href: "/growth-service", label: "查看 30 天提升服务" }}
        secondaryCta={{ href: "/reports", label: "浏览行业报告方向" }}
      />
    </main>
  );
}
