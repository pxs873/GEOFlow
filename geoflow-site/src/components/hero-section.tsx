import type { ReactNode } from "react";
import Link from "next/link";

type HeroSectionProps = {
  eyebrow: string;
  title: string;
  description: string;
  primaryCta: { href: string; label: string };
  secondaryCta: { href: string; label: string };
  aside: ReactNode;
};

export function HeroSection({
  eyebrow,
  title,
  description,
  primaryCta,
  secondaryCta,
  aside,
}: HeroSectionProps) {
  return (
    <section className="mx-auto max-w-7xl px-6 py-18 md:px-10 md:py-24">
      <div className="grid gap-10 lg:grid-cols-[0.92fr_1.08fr] lg:items-center">
        <div>
          <div className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border)] bg-white px-3 py-1 text-xs font-semibold tracking-[0.18em] text-[var(--color-brand)] uppercase">
            <span className="h-2 w-2 rounded-full bg-[var(--color-accent)]" />
            {eyebrow}
          </div>
          <h1 className="mt-6 max-w-3xl text-4xl font-semibold tracking-tight text-[var(--color-ink)] sm:text-5xl lg:text-6xl">
            {title}
          </h1>
          <p className="mt-6 max-w-2xl text-lg leading-8 text-[var(--color-ink-soft)]">{description}</p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <Link
              href={primaryCta.href}
              className="rounded-full bg-[linear-gradient(135deg,var(--color-brand),var(--color-brand-deep))] px-6 py-3.5 text-center font-semibold text-white shadow-lg shadow-blue-600/20 transition hover:translate-y-[-1px]"
            >
              {primaryCta.label}
            </Link>
            <Link
              href={secondaryCta.href}
              className="rounded-full border border-[var(--color-border)] bg-white px-6 py-3.5 text-center font-semibold text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
            >
              {secondaryCta.label}
            </Link>
          </div>
          <div className="mt-8 flex flex-wrap gap-3 text-sm text-[var(--color-ink-soft)]">
            {["ChatGPT", "Perplexity", "Google AI", "DeepSeek", "Kimi", "豆包"].map((item) => (
              <span key={item} className="rounded-full border border-[var(--color-border)] bg-white px-3 py-1.5">
                {item}
              </span>
            ))}
          </div>
        </div>
        {aside}
      </div>
    </section>
  );
}
