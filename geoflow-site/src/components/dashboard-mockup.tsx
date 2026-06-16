type DashboardMockupProps = {
  expanded?: boolean;
};

const channels = ["ChatGPT", "Perplexity", "Google AI", "DeepSeek", "Kimi", "豆包"];

export function DashboardMockup({ expanded = false }: DashboardMockupProps) {
  return (
    <div className="rounded-[2rem] border border-white/10 bg-[var(--color-brand-deep)] p-5 text-white shadow-[var(--shadow-card)] sm:p-6 md:p-8">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-sm font-semibold text-[color:var(--color-accent)]">Editorial focus</p>
          <h3 className="mt-3 text-[2rem] font-semibold leading-tight sm:mt-4 sm:text-4xl">把 AI 回答里的候选资格拆清楚</h3>
        </div>
        <div className="w-fit rounded-2xl bg-white/8 px-4 py-3 text-left sm:text-right">
          <div className="text-xs text-white/60">Visibility</div>
          <div className="text-2xl font-semibold text-[color:var(--color-accent)]">62 / 100</div>
        </div>
      </div>

      <ul className="mt-6 space-y-4 text-base leading-7 text-white/84 sm:mt-8 sm:text-lg sm:leading-9">
        <li className="flex gap-4">
          <span className="mt-3 h-2.5 w-2.5 shrink-0 rounded-full bg-[var(--color-accent)]" />
          <span>先看品牌有没有进入 AI 的候选名单，而不是只盯着零散流量词排名。</span>
        </li>
        <li className="flex gap-4">
          <span className="mt-3 h-2.5 w-2.5 shrink-0 rounded-full bg-[var(--color-accent)]" />
          <span>定位 AI 为什么引用竞品：是 FAQ、案例、外部提及，还是命名表达更清晰。</span>
        </li>
        <li className="flex gap-4">
          <span className="mt-3 h-2.5 w-2.5 shrink-0 rounded-full bg-[var(--color-accent)]" />
          <span>把官网、报告、第三方页面整理成 AI 更容易抓取和复述的品牌信号。</span>
        </li>
      </ul>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        {[
          ["Mention Rate", "38%", "+12%"],
          ["Citation Rate", "21%", "+7%"],
          ["Recommendation", "14%", "+5%"],
          ["Coverage", "42 / 80", "+9"],
        ].map(([label, value, delta]) => (
          <div key={label} className="rounded-2xl border border-white/10 bg-white/5 p-4">
            <div className="text-sm text-white/60">{label}</div>
            <div className="mt-2 flex items-end justify-between gap-3">
              <span className="text-2xl font-semibold text-white">{value}</span>
              <span className="text-sm font-medium text-[color:var(--color-accent)]">{delta}</span>
            </div>
          </div>
        ))}
      </div>

      <div className="mt-6 flex flex-wrap gap-2 sm:mt-8">
        {channels.map((channel) => (
          <span
            key={channel}
            className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs text-white/70"
          >
            {channel}
          </span>
        ))}
      </div>

      {expanded ? (
        <div className="mt-8 rounded-2xl border border-white/10 bg-white/5 p-5">
          <div className="text-sm font-medium text-white/60">当前优先修复</div>
          <div className="mt-3 space-y-3 text-sm text-white/84">
            <div>英文功能页缺少实体描述</div>
            <div>品牌和解决方案命名不一致</div>
            <div>行业报告数量不足</div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
