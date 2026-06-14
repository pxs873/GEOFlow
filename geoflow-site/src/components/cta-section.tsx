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
      <div className="rounded-[2rem] border border-[var(--color-border)] bg-[linear-gradient(135deg,#0f2343,#17315f)] px-6 py-10 text-white shadow-[var(--shadow-card)] md:px-10 md:py-12">
        <div className="max-w-3xl">
          <div className="text-xs font-semibold uppercase tracking-[0.22em] text-blue-200">Final CTA</div>
          <h2 className="mt-4 text-3xl font-semibold tracking-tight sm:text-4xl">{title}</h2>
          <p className="mt-4 text-lg leading-8 text-slate-300">{description}</p>
        </div>
        <div className="mt-8 flex flex-col gap-3 sm:flex-row">
          <Link
            href={primaryCta.href}
            className="rounded-full bg-white px-6 py-3.5 text-center font-semibold text-[var(--color-brand-deep)]"
          >
            {primaryCta.label}
          </Link>
          <Link
            href={secondaryCta.href}
            className="rounded-full border border-white/20 px-6 py-3.5 text-center font-semibold text-white"
          >
            {secondaryCta.label}
          </Link>
        </div>
      </div>
    </section>
  );
}
