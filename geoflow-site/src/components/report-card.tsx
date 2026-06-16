type ReportCardProps = {
  title: string;
  category: string;
  description: string;
};

export function ReportCard({ title, category, description }: ReportCardProps) {
  return (
    <article className="rounded-[2rem] border border-[var(--color-border)] bg-[var(--color-surface)] p-6 shadow-[var(--shadow-card)]">
      <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[var(--color-brand)]">{category}</div>
      <h3 className="mt-4 text-xl font-semibold text-[var(--color-ink)]">{title}</h3>
      <p className="mt-3 text-sm leading-7 text-[var(--color-ink-soft)]">{description}</p>
      <div className="mt-6 inline-flex items-center gap-2 text-sm font-semibold text-[var(--color-brand)]">
        即将发布
        <span aria-hidden="true">→</span>
      </div>
    </article>
  );
}
