type SectionHeadingProps = {
  eyebrow: string;
  title: string;
  description: string;
  invert?: boolean;
};

export function SectionHeading({ eyebrow, title, description, invert = false }: SectionHeadingProps) {
  return (
    <div className="max-w-3xl">
      <div
        className={`text-xs font-semibold tracking-[0.22em] uppercase ${
          invert ? "text-[color:var(--color-accent)]" : "text-[var(--color-brand)]"
        }`}
      >
        {eyebrow}
      </div>
      <h2
        className={`mt-4 text-[1.95rem] font-semibold tracking-tight leading-tight sm:text-4xl ${
          invert ? "text-white" : "text-[var(--color-ink)]"
        }`}
      >
        {title}
      </h2>
      <p
        className={`mt-4 text-base leading-7 sm:text-lg sm:leading-8 ${
          invert ? "text-white/72" : "text-[var(--color-ink-soft)]"
        }`}
      >
        {description}
      </p>
    </div>
  );
}
