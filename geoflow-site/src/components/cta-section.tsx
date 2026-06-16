import Link from "next/link";

type CtaSectionProps = {
  title: string;
  description: string;
  primaryCta: { href: string; label: string };
  secondaryCta: { href: string; label: string };
};

export function CtaSection({ title, description, primaryCta, secondaryCta }: CtaSectionProps) {
  return (
    <section className="mx-auto max-w-7xl px-6 py-18 md:px-10">
      <div className="rounded-[2rem] border border-[var(--color-border)] bg-[var(--color-brand-deep)] px-5 py-8 text-white shadow-[var(--shadow-card)] sm:px-6 sm:py-10 md:px-10 md:py-12">
        <div className="max-w-3xl">
          <div className="text-xs font-semibold uppercase tracking-[0.22em] text-[color:var(--color-accent)]">Final CTA</div>
          <h2 className="mt-4 text-[1.95rem] font-semibold tracking-tight leading-tight sm:text-4xl">{title}</h2>
          <p className="mt-4 text-base leading-7 text-white/72 sm:text-lg sm:leading-8">{description}</p>
        </div>
        <div className="mt-7 flex flex-col gap-3 sm:mt-8 sm:flex-row">
          <Link
            href={primaryCta.href}
            className="rounded-2xl bg-[color:var(--color-accent)] px-6 py-3.5 text-center font-semibold text-[var(--color-brand-deep)]"
          >
            {primaryCta.label}
          </Link>
          <Link
            href={secondaryCta.href}
            className="rounded-2xl border border-white/20 px-6 py-3.5 text-center font-semibold text-white"
          >
            {secondaryCta.label}
          </Link>
        </div>
      </div>
    </section>
  );
}
