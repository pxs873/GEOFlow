import type { Metadata } from "next";
import { ReportCard } from "@/components/report-card";
import { SectionHeading } from "@/components/section-heading";
import { reportCards } from "@/lib/site";

export const metadata: Metadata = {
  title: "行业报告",
  description: "浏览 GEOFlow 的 AI 搜索曝光行业报告方向，理解 GEO 与内容资产优化的研究主题。",
};

export default function ReportsPage() {
  return (
    <main className="flex-1">
      <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
        <SectionHeading
          eyebrow="Industry Reports"
          title="行业报告不是装饰，而是建立 AI 引用信号的长期资产"
          description="第一版先展示 3 个核心方向。后续可扩展为完整报告页、报告详情页和线索转化入口。"
        />
        <div className="mt-8 grid gap-5 lg:grid-cols-3">
          {reportCards.map((item) => (
            <ReportCard key={item.title} {...item} />
          ))}
        </div>
      </section>
    </main>
  );
}
