type DashboardMockupProps = {
  expanded?: boolean;
};

const channels = ["ChatGPT", "Perplexity", "Google AI", "DeepSeek", "Kimi", "豆包"];

export function DashboardMockup({ expanded = false }: DashboardMockupProps) {
  return (
    <div className="relative">
      <div className="absolute -inset-6 rounded-[2rem] bg-[radial-gradient(circle,rgba(47,109,246,0.18),transparent_60%)] blur-2xl" />
      <div className="relative overflow-hidden rounded-[2rem] border border-[var(--color-border)] bg-white p-6 shadow-[var(--shadow-card)]">
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-sm font-medium text-[var(--color-ink-soft)]">AI 搜索曝光仪表盘</p>
            <h3 className="mt-2 text-2xl font-semibold text-[var(--color-ink)]">Brand Visibility Score</h3>
          </div>
          <div className="rounded-2xl bg-[var(--color-surface-muted)] px-4 py-3 text-right">
            <div className="text-xs text-[var(--color-ink-soft)]">Score</div>
            <div className="text-2xl font-semibold text-[var(--color-brand)]">62 / 100</div>
          </div>
        </div>

        <div className="mt-6 grid gap-4 sm:grid-cols-2">
          {[
            ["Mention Rate", "38%", "+12%"],
            ["Citation Rate", "21%", "+7%"],
            ["Recommendation", "14%", "+5%"],
            ["Competitor Gap", "-27%", "-3%"],
          ].map(([label, value, delta]) => (
            <div key={label} className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] p-4">
              <div className="text-sm text-[var(--color-ink-soft)]">{label}</div>
              <div className="mt-2 flex items-end justify-between gap-3">
                <span className="text-2xl font-semibold text-[var(--color-ink)]">{value}</span>
                <span className="text-sm font-medium text-[var(--color-brand)]">{delta}</span>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-6 rounded-3xl border border-[var(--color-border)] bg-[linear-gradient(180deg,#f8fbff,#eef4fb)] p-5">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-sm font-medium text-[var(--color-ink-soft)]">Query Coverage</div>
              <div className="mt-1 text-xl font-semibold text-[var(--color-ink)]">42 / 80 queries tracked</div>
            </div>
            <div className="text-right text-sm text-[var(--color-brand)]">内容资产健康度 74</div>
          </div>
          <div className="mt-5 h-3 rounded-full bg-white">
            <div className="h-3 w-[56%] rounded-full bg-[linear-gradient(90deg,var(--color-brand),var(--color-accent))]" />
          </div>
          <div className="mt-5 flex flex-wrap gap-2">
            {channels.map((channel) => (
              <span
                key={channel}
                className="rounded-full border border-[var(--color-border)] bg-white px-3 py-1 text-xs text-[var(--color-ink-soft)]"
              >
                {channel}
              </span>
            ))}
          </div>
        </div>

        {expanded ? (
          <div className="mt-6 grid gap-4 md:grid-cols-2">
            <div className="rounded-2xl border border-[var(--color-border)] p-4">
              <div className="text-sm text-[var(--color-ink-soft)]">最强引用来源</div>
              <div className="mt-3 space-y-3 text-sm">
                <div className="flex items-center justify-between">
                  <span>官网产品页</span>
                  <span className="font-medium text-[var(--color-brand)]">+11 signals</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>FAQ / Help Center</span>
                  <span className="font-medium text-[var(--color-brand)]">+7 signals</span>
                </div>
                <div className="flex items-center justify-between">
                  <span>第三方评测</span>
                  <span className="font-medium text-[var(--color-brand)]">+5 signals</span>
                </div>
              </div>
            </div>
            <div className="rounded-2xl border border-[var(--color-border)] p-4">
              <div className="text-sm text-[var(--color-ink-soft)]">当前优先修复</div>
              <div className="mt-3 space-y-3 text-sm">
                <div className="rounded-2xl bg-[var(--color-surface-muted)] px-3 py-2">英文功能页缺少实体描述</div>
                <div className="rounded-2xl bg-[var(--color-surface-muted)] px-3 py-2">品牌和解决方案命名不一致</div>
                <div className="rounded-2xl bg-[var(--color-surface-muted)] px-3 py-2">行业报告数量不足</div>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
