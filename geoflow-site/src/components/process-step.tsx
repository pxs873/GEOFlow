type ProcessStepProps = {
  step: string;
  title: string;
  description: string;
};

export function ProcessStep({ step, title, description }: ProcessStepProps) {
  return (
    <article className="rounded-3xl border border-white/12 bg-white/6 p-6">
      <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-white/10 text-sm font-semibold text-white">
        {step}
      </div>
      <h3 className="mt-5 text-lg font-semibold text-white">{title}</h3>
      <p className="mt-3 text-sm leading-7 text-slate-300">{description}</p>
    </article>
  );
}
