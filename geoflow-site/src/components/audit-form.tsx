"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

const initialState = {
  name: "",
  company: "",
  website: "",
  brand: "",
  market: "",
  industry: "",
  competitor: "",
  contact: "",
  problem: "",
};

export function AuditForm() {
  const endpoint = process.env.NEXT_PUBLIC_FORMSPREE_ENDPOINT?.trim();
  const router = useRouter();
  const [values, setValues] = useState(initialState);
  const [status, setStatus] = useState<string>("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();

    if (!endpoint) {
      setStatus("当前环境还没配置 NEXT_PUBLIC_FORMSPREE_ENDPOINT，所以先保留本地预览模式。上线前补上 endpoint 后就会直连 Formspree。");
      return;
    }

    setIsSubmitting(true);
    setStatus("正在提交，请稍候…");

    const formData = new FormData();

    for (const [key, value] of Object.entries(values)) {
      formData.append(key, value.trim());
    }

    formData.append("_subject", "GEOFlow 免费诊断提交");
    formData.append("form_name", "GEOFlow Free Audit");

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        body: formData,
        headers: {
          Accept: "application/json",
        },
      });

      const result = await response.json().catch(() => null);

      if (!response.ok) {
        const errorMessage =
          result?.errors?.[0]?.message || "提交失败，请稍后重试，或直接通过邮箱 / 微信联系 GEOFlow。";

        throw new Error(errorMessage);
      }

      setValues(initialState);
      setStatus("提交成功，正在跳转到确认页…");
      router.push("/thank-you?source=free-audit");
    } catch (error) {
      const message = error instanceof Error ? error.message : "提交失败，请稍后重试。";
      setStatus(message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form
      method="post"
      onSubmit={handleSubmit}
      aria-busy={isSubmitting}
      className="rounded-[2rem] border border-[var(--color-border)] bg-white p-5 shadow-[var(--shadow-card)] sm:p-6"
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h3 className="text-[1.6rem] font-semibold text-[var(--color-ink)] sm:text-2xl">提交免费诊断信息</h3>
          <p className="mt-2 text-sm leading-6 text-[var(--color-ink-soft)] sm:leading-7">
            现在已经支持 Formspree 提交。上线前只需要配置 `NEXT_PUBLIC_FORMSPREE_ENDPOINT`，即可把线索直接收进表单。
          </p>
        </div>
        <span className="w-fit rounded-full bg-[var(--color-surface-muted)] px-3 py-1 text-xs font-semibold text-[var(--color-brand)]">
          {endpoint ? "Formspree Ready" : "Preview Mode"}
        </span>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <Field
          name="name"
          label="姓名"
          value={values.name}
          autoComplete="name"
          required
          onChange={(value) => setValues({ ...values, name: value })}
        />
        <Field
          name="company"
          label="公司名"
          value={values.company}
          autoComplete="organization"
          required
          onChange={(value) => setValues({ ...values, company: value })}
        />
        <Field
          name="website"
          label="官网 URL"
          type="url"
          value={values.website}
          autoComplete="url"
          required
          onChange={(value) => setValues({ ...values, website: value })}
        />
        <Field
          name="brand"
          label="品牌 / 产品名"
          value={values.brand}
          required
          onChange={(value) => setValues({ ...values, brand: value })}
        />
        <Field
          name="market"
          label="目标市场"
          value={values.market}
          onChange={(value) => setValues({ ...values, market: value })}
        />
        <Field
          name="industry"
          label="所属行业"
          value={values.industry}
          onChange={(value) => setValues({ ...values, industry: value })}
        />
        <Field
          name="competitor"
          label="主要竞品"
          value={values.competitor}
          onChange={(value) => setValues({ ...values, competitor: value })}
        />
        <Field
          name="contact"
          label="邮箱 / 微信"
          value={values.contact}
          autoComplete="email"
          required
          onChange={(value) => setValues({ ...values, contact: value })}
        />
      </div>

      <label className="mt-4 block">
        <span className="mb-2 block text-sm font-medium text-[var(--color-ink)]">当前问题描述</span>
        <textarea
          name="problem"
          rows={5}
          required
          value={values.problem}
          onChange={(event) => setValues({ ...values, problem: event.target.value })}
          className="w-full rounded-2xl border border-[var(--color-border)] bg-[var(--color-page)] px-4 py-3 outline-none transition focus:border-[var(--color-brand)]"
          placeholder="例如：品牌在 ChatGPT 里几乎搜不到；行业关键词下竞品总被优先推荐。"
        />
      </label>

      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm leading-6 text-[var(--color-ink-soft)]">
          {endpoint
            ? "已检测到 Formspree endpoint。提交成功后会跳转到确认页。"
            : "尚未配置 NEXT_PUBLIC_FORMSPREE_ENDPOINT，当前为提交占位状态。"}
        </p>
        <button
          type="submit"
          disabled={isSubmitting}
          className="rounded-full bg-[linear-gradient(135deg,var(--color-brand),var(--color-brand-deep))] px-6 py-3.5 font-semibold text-white shadow-lg shadow-blue-600/20 transition disabled:cursor-not-allowed disabled:opacity-70"
        >
          {isSubmitting ? "正在提交…" : "提交诊断信息"}
        </button>
      </div>

      {status ? (
        <p
          aria-live="polite"
          className={`mt-4 text-sm leading-6 ${
            status.includes("失败") ? "text-[#a34f3f]" : "text-[var(--color-brand)]"
          }`}
        >
          {status}
        </p>
      ) : null}
    </form>
  );
}

type FieldProps = {
  name: string;
  label: string;
  value: string;
  type?: string;
  autoComplete?: string;
  required?: boolean;
  onChange: (value: string) => void;
};

function Field({ name, label, value, type = "text", autoComplete, required = false, onChange }: FieldProps) {
  return (
    <label>
      <span className="mb-2 block text-sm font-medium text-[var(--color-ink)]">{label}</span>
      <input
        name={name}
        type={type}
        autoComplete={autoComplete}
        required={required}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-[var(--color-border)] bg-[var(--color-page)] px-4 py-3 outline-none transition focus:border-[var(--color-brand)]"
      />
    </label>
  );
}
