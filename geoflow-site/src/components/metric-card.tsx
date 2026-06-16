type MetricCardProps = {
  label: string;
  value: string;
  detail: string;
  delta: string;
};

export function MetricCard({ label, value, detail, delta }: MetricCardProps) {
  return (
    <article className="rounded-[2rem] border border-[var(--color-border)] bg-[var(--color-surface)] p-6 shadow-[var(--shadow-card)]">
      <div className="flex items-center justify-between gap-4">
        <span className="text-sm font-medium text-[var(--color-ink-soft)]">{label}</span>
        <span className="rounded-full bg-[var(--color-surface-muted)] px-3 py-1 text-xs font-semibold text-[var(--color-brand)]">
          {delta}
        </span>
      </div>
      <div className="mt-5 text-3xl font-semibold text-[var(--color-ink)]">{value}</div>
      <p className="mt-3 text-sm leading-7 text-[var(--color-ink-soft)]">{detail}</p>
    </article>
  );
}
