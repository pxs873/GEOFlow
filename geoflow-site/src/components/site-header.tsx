"use client";

import Link from "next/link";
import { useState } from "react";
import { navItems } from "@/lib/site";

export function SiteHeader() {
  const [mobileOpen, setMobileOpen] = useState(false);

  const closeMobileMenu = () => setMobileOpen(false);

  return (
    <header className="sticky top-0 z-30 border-b border-white/60 bg-white/78 backdrop-blur-xl">
      <div className="relative mx-auto flex max-w-7xl items-center justify-between px-6 py-4 md:px-10">
        <Link href="/" className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[linear-gradient(135deg,var(--color-brand),var(--color-accent))] text-sm font-semibold text-white shadow-lg shadow-blue-500/20">
            GF
          </span>
          <div>
            <div className="text-sm font-semibold tracking-[0.2em] text-[var(--color-ink)]">GEOFLOW</div>
            <div className="text-xs text-[var(--color-ink-soft)]">AI 搜索曝光优化服务商</div>
          </div>
        </Link>

        <nav className="hidden items-center gap-7 text-sm text-[var(--color-ink-soft)] lg:flex">
          {navItems.map((item) => (
            <Link key={item.href} href={item.href} className="transition hover:text-[var(--color-brand)]">
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-3 lg:flex">
          <Link
            href="/audit"
            className="rounded-full border border-[var(--color-border)] px-4 py-2.5 text-sm font-medium text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
          >
            体检报告页
          </Link>
          <Link
            href="/free-audit"
            className="rounded-full bg-[linear-gradient(135deg,var(--color-brand),var(--color-brand-deep))] px-5 py-2.5 text-sm font-semibold text-white shadow-lg shadow-blue-600/20 transition hover:translate-y-[-1px]"
          >
            免费诊断
          </Link>
        </div>

        <button
          type="button"
          aria-controls="mobile-site-nav"
          aria-expanded={mobileOpen}
          onClick={() => setMobileOpen((open) => !open)}
          className="inline-flex items-center gap-3 rounded-2xl border border-[var(--color-border)] bg-white px-3.5 py-2.5 text-[var(--color-ink)] shadow-sm transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)] lg:hidden"
        >
          <span className="relative flex h-4 w-5 flex-col justify-between">
            <span
              className={`block h-0.5 w-5 rounded-full bg-current transition ${
                mobileOpen ? "translate-y-[7px] rotate-45" : ""
              }`}
            />
            <span className={`block h-0.5 w-5 rounded-full bg-current transition ${mobileOpen ? "opacity-0" : ""}`} />
            <span
              className={`block h-0.5 w-5 rounded-full bg-current transition ${
                mobileOpen ? "-translate-y-[7px] -rotate-45" : ""
              }`}
            />
          </span>
          <span className="text-sm font-semibold">{mobileOpen ? "关闭" : "菜单"}</span>
        </button>

        {mobileOpen ? (
          <div
            id="mobile-site-nav"
            className="absolute inset-x-0 top-full mt-3 rounded-[1.75rem] border border-[var(--color-border)] bg-white/96 p-5 shadow-[var(--shadow-card)] lg:hidden"
          >
            <div className="flex items-center justify-between border-b border-[var(--color-border)] pb-4">
              <div>
                <p className="text-xs font-semibold tracking-[0.18em] text-[var(--color-brand)]">MOBILE NAV</p>
                <p className="mt-1 text-sm text-[var(--color-ink-soft)]">快速进入关键页面和转化入口</p>
              </div>
              <span className="rounded-full bg-[var(--color-surface-muted)] px-3 py-1 text-xs font-semibold text-[var(--color-brand)]">
                GEOFlow
              </span>
            </div>

            <div className="mt-4 flex flex-col gap-3 text-sm text-[var(--color-ink)]">
              {navItems.map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  onClick={closeMobileMenu}
                  className="rounded-2xl border border-transparent px-4 py-3 transition hover:border-[var(--color-border)] hover:bg-[var(--color-surface-muted)]"
                >
                  {item.label}
                </Link>
              ))}

              <div className="mt-2 grid gap-3 sm:grid-cols-2">
                <Link
                  href="/audit"
                  onClick={closeMobileMenu}
                  className="rounded-full border border-[var(--color-border)] px-4 py-3 text-center font-medium text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
                >
                  体检报告页
                </Link>
                <Link
                  href="/free-audit"
                  onClick={closeMobileMenu}
                  className="rounded-full bg-[linear-gradient(135deg,var(--color-brand),var(--color-brand-deep))] px-4 py-3 text-center font-semibold text-white shadow-lg shadow-blue-600/20"
                >
                  免费诊断
                </Link>
              </div>
            </div>
          </div>
        ) : null}
      </div>
    </header>
  );
}
