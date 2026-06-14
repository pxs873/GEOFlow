import type { Metadata } from "next";
import { DashboardMockup } from "@/components/dashboard-mockup";
import { FeatureCard } from "@/components/feature-card";
import { SectionHeading } from "@/components/section-heading";
import { auditChecks } from "@/lib/site";

export const metadata: Metadata = {
  title: "曝光体检报告",
  description: "了解 GEOFlow 的 AI 搜索曝光体检会检查什么、覆盖哪些渠道，以及报告如何组织。",
};

export default function AuditPage() {
  return (
    <main className="flex-1">
      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <div className="grid gap-10 lg:grid-cols-[0.92fr_1.08fr] lg:items-center">
          <div>
            <SectionHeading
              eyebrow="Audit Preview"
              title="这不是后台，而是一份让客户看懂“为什么 AI 不推荐你”的营销报告结构"
              description="GEOFlow 第一版的体检报告页先作为营销说明页，帮助客户理解体检内容、交付方式和常见指标。"
            />
            <div className="mt-8 grid gap-4">
              {auditChecks.map((item) => (
                <FeatureCard key={item.title} title={item.title} description={item.description} />
              ))}
            </div>
          </div>
          <DashboardMockup expanded />
        </div>
      </section>
    </main>
  );
}
