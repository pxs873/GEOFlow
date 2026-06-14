type FeatureCardProps = {
  title: string;
  description: string;
  tone?: "default" | "soft";
};

export function FeatureCard({ title, description, tone = "default" }: FeatureCardProps) {
  return (
    <article
      className={`rounded-3xl border p-6 ${
        tone === "soft"
          ? "border-[var(--color-border)] bg-[linear-gradient(180deg,#f7fbff,#eef4fb)]"
          : "border-[var(--color-border)] bg-white"
      } shadow-[var(--shadow-card)]`}
    >
      <h3 className="text-lg font-semibold text-[var(--color-ink)]">{title}</h3>
      <p className="mt-3 text-sm leading-7 text-[var(--color-ink-soft)]">{description}</p>
    </article>
  );
}
