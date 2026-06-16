type FeatureCardProps = {
  title: string;
  description: string;
  tone?: "default" | "soft";
};

export function FeatureCard({ title, description, tone = "default" }: FeatureCardProps) {
  return (
    <article
      className={`rounded-[2rem] border p-6 ${
        tone === "soft"
          ? "border-[var(--color-border)] bg-[linear-gradient(180deg,#f8faf5,#edf2ea)]"
          : "border-[var(--color-border)] bg-[var(--color-surface)]"
      } shadow-[var(--shadow-card)]`}
    >
      <div className="text-xs font-semibold uppercase tracking-[0.18em] text-[var(--color-brand)]">GEOFlow Note</div>
      <h3 className="text-lg font-semibold text-[var(--color-ink)]">{title}</h3>
      <p className="mt-3 text-sm leading-7 text-[var(--color-ink-soft)]">{description}</p>
    </article>
  );
}
