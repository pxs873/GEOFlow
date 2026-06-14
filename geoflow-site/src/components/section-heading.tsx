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
          invert ? "text-blue-200" : "text-[var(--color-brand)]"
        }`}
      >
        {eyebrow}
      </div>
      <h2 className={`mt-4 text-3xl font-semibold tracking-tight sm:text-4xl ${invert ? "text-white" : "text-[var(--color-ink)]"}`}>
        {title}
      </h2>
      <p className={`mt-4 text-lg leading-8 ${invert ? "text-slate-300" : "text-[var(--color-ink-soft)]"}`}>
        {description}
      </p>
    </div>
  );
}
