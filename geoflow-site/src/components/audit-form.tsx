"use client";

import { useMemo, useState } from "react";

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
  const endpoint = process.env.NEXT_PUBLIC_FORMSPREE_ENDPOINT;
  const [status, setStatus] = useState<string>("");
  const [values, setValues] = useState(initialState);

  const action = useMemo(() => endpoint || "#", [endpoint]);

  return (
    <form
      action={action}
      method="post"
      onSubmit={(event) => {
        if (!endpoint) {
          event.preventDefault();
          setStatus("已记录前端占位提交逻辑。后续配置 NEXT_PUBLIC_FORMSPREE_ENDPOINT 后即可接入真实表单收集。");
        } else {
          setStatus("正在提交，请稍候…");
        }
      }}
      className="rounded-[2rem] border border-[var(--color-border)] bg-white p-6 shadow-[var(--shadow-card)]"
    >
      <div className="flex items-center justify-between gap-4">
        <div>
          <h3 className="text-2xl font-semibold text-[var(--color-ink)]">提交免费诊断信息</h3>
          <p className="mt-2 text-sm leading-7 text-[var(--color-ink-soft)]">
            第一版支持前端占位提交；接入 Formspree 时只需要配置 `NEXT_PUBLIC_FORMSPREE_ENDPOINT`。
          </p>
        </div>
        <span className="rounded-full bg-[var(--color-surface-muted)] px-3 py-1 text-xs font-semibold text-[var(--color-brand)]">
          Form Ready
        </span>
      </div>

      <div className="mt-6 grid gap-4 sm:grid-cols-2">
        <Field label="姓名" value={values.name} onChange={(value) => setValues({ ...values, name: value })} />
        <Field label="公司名" value={values.company} onChange={(value) => setValues({ ...values, company: value })} />
        <Field label="官网 URL" value={values.website} onChange={(value) => setValues({ ...values, website: value })} />
        <Field label="品牌 / 产品名" value={values.brand} onChange={(value) => setValues({ ...values, brand: value })} />
        <Field label="目标市场" value={values.market} onChange={(value) => setValues({ ...values, market: value })} />
        <Field label="所属行业" value={values.industry} onChange={(value) => setValues({ ...values, industry: value })} />
        <Field
          label="主要竞品"
          value={values.competitor}
          onChange={(value) => setValues({ ...values, competitor: value })}
        />
        <Field label="邮箱 / 微信" value={values.contact} onChange={(value) => setValues({ ...values, contact: value })} />
      </div>

      <label className="mt-4 block">
        <span className="mb-2 block text-sm font-medium text-[var(--color-ink)]">当前问题描述</span>
        <textarea
          name="problem"
          rows={5}
          value={values.problem}
          onChange={(event) => setValues({ ...values, problem: event.target.value })}
          className="w-full rounded-2xl border border-[var(--color-border)] bg-[var(--color-page)] px-4 py-3 outline-none transition focus:border-[var(--color-brand)]"
          placeholder="例如：品牌在 ChatGPT 里几乎搜不到；行业关键词下竞品总被优先推荐。"
        />
      </label>

      <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-[var(--color-ink-soft)]">
          {endpoint
            ? "已检测到表单环境变量，提交将直接发送到配置的 Formspree endpoint。"
            : "尚未配置 NEXT_PUBLIC_FORMSPREE_ENDPOINT，当前为提交占位状态。"}
        </p>
        <button
          type="submit"
          className="rounded-full bg-[linear-gradient(135deg,var(--color-brand),var(--color-brand-deep))] px-6 py-3.5 font-semibold text-white shadow-lg shadow-blue-600/20"
        >
          提交诊断信息
        </button>
      </div>

      {status ? (
        <p aria-live="polite" className="mt-4 text-sm text-[var(--color-brand)]">
          {status}
        </p>
      ) : null}
    </form>
  );
}

type FieldProps = {
  label: string;
  value: string;
  onChange: (value: string) => void;
};

function Field({ label, value, onChange }: FieldProps) {
  return (
    <label>
      <span className="mb-2 block text-sm font-medium text-[var(--color-ink)]">{label}</span>
      <input
        name={label}
        value={value}
        onChange={(event) => onChange(event.target.value)}
        className="w-full rounded-2xl border border-[var(--color-border)] bg-[var(--color-page)] px-4 py-3 outline-none transition focus:border-[var(--color-brand)]"
      />
    </label>
  );
}
