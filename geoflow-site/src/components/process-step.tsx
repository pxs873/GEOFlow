type ProcessStepProps = {
  step: string;
  title: string;
  description: string;
};

export function ProcessStep({ step, title, description }: ProcessStepProps) {
  return (
    <article className="rounded-[2rem] border border-white/10 bg-white/5 p-6">
      <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-sm font-semibold text-[color:var(--color-accent)]">
        {step}
      </div>
      <h3 className="mt-5 text-lg font-semibold text-white">{title}</h3>
      <p className="mt-3 text-sm leading-7 text-white/72">{description}</p>
    </article>
  );
}
