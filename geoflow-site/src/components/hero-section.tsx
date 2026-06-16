import type { ReactNode } from "react";
import Link from "next/link";

type HeroSectionProps = {
  eyebrow: string;
  title: string;
  description: string;
  primaryCta: { href: string; label: string };
  secondaryCta: { href: string; label: string };
  sidebarEyebrow: string;
  sidebarTitle: string;
  sidebarDescription: string;
  sidebarBullets: string[];
  aside: ReactNode;
};

export function HeroSection({
  eyebrow,
  title,
  description,
  primaryCta,
  secondaryCta,
  sidebarEyebrow,
  sidebarTitle,
  sidebarDescription,
  sidebarBullets,
  aside,
}: HeroSectionProps) {
  return (
    <section className="mx-auto max-w-7xl px-5 py-9 sm:px-6 md:px-10 md:py-16">
      <div className="grid gap-5 xl:grid-cols-[1.08fr_0.82fr_0.68fr]">
        <div className="rounded-[2rem] border border-[var(--color-border)] bg-[linear-gradient(180deg,#f9fbf7,#eef3ed)] p-5 shadow-[var(--shadow-card)] sm:p-6 md:p-10">
          <div className="inline-flex items-center gap-2 rounded-full border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-1 text-xs font-semibold tracking-[0.18em] text-[var(--color-brand)] uppercase">
            <span className="h-2 w-2 rounded-full bg-[var(--color-accent)]" />
            {eyebrow}
          </div>
          <h1 className="mt-5 max-w-3xl text-[2.25rem] leading-[1.08] font-semibold tracking-tight text-[var(--color-ink)] sm:text-5xl lg:text-[4.4rem] lg:leading-[1.02]">
            {title}
          </h1>
          <p className="mt-5 max-w-2xl text-[0.98rem] leading-7 text-[var(--color-ink-soft)] sm:text-lg sm:leading-8">
            {description}
          </p>
          <div className="mt-7 flex flex-col gap-3 sm:flex-row">
            <Link
              href={primaryCta.href}
              className="rounded-2xl bg-[var(--color-brand)] px-6 py-3.5 text-center font-semibold text-white transition hover:bg-[var(--color-brand-deep)]"
            >
              {primaryCta.label}
            </Link>
            <Link
              href={secondaryCta.href}
              className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] px-6 py-3.5 text-center font-semibold text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
            >
              {secondaryCta.label}
            </Link>
          </div>
          <div className="mt-6 flex flex-wrap gap-2 text-sm text-[var(--color-ink-soft)] sm:gap-3">
            {["ChatGPT", "Perplexity", "Google AI", "DeepSeek", "Kimi", "豆包"].map((item) => (
              <span
                key={item}
                className="rounded-full border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-1.5"
              >
                {item}
              </span>
            ))}
          </div>
        </div>

        {aside}

        <aside className="rounded-[2rem] border border-[var(--color-border)] bg-[var(--color-surface)] p-6 shadow-[var(--shadow-card)] md:p-8">
          <div className="text-sm font-semibold text-[var(--color-brand)]">{sidebarEyebrow}</div>
          <h2 className="mt-4 text-[1.8rem] font-semibold leading-tight text-[var(--color-ink)] sm:text-3xl">{sidebarTitle}</h2>
          <p className="mt-4 text-base leading-7 text-[var(--color-ink-soft)] sm:text-lg sm:leading-8">{sidebarDescription}</p>

          <div className="mt-7 flex flex-col gap-3">
            <Link
              href={primaryCta.href}
              className="rounded-2xl bg-[var(--color-brand)] px-5 py-3 text-center text-base font-semibold text-white"
            >
              {primaryCta.label}
            </Link>
            <Link
              href={secondaryCta.href}
              className="rounded-2xl border border-[var(--color-border)] px-5 py-3 text-center text-base font-semibold text-[var(--color-ink)]"
            >
              {secondaryCta.label}
            </Link>
          </div>

          <ul className="mt-7 space-y-4 text-base leading-7 text-[var(--color-ink-soft)] sm:leading-8">
            {sidebarBullets.map((item) => (
              <li key={item} className="flex gap-3">
                <span className="mt-3 h-2.5 w-2.5 shrink-0 rounded-full bg-[var(--color-accent)]" />
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </aside>
      </div>
    </section>
  );
}
