"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { navItems, siteConfig } from "@/lib/site";

export function SiteHeader() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const pathname = usePathname();

  const closeMobileMenu = () => setMobileOpen(false);

  return (
    <header className="sticky top-0 z-40 border-b border-[var(--color-border)] bg-[var(--color-surface)]/96 backdrop-blur-xl">
      <div className="bg-[var(--color-brand-deep)]">
        <div className="mx-auto flex max-w-7xl flex-col gap-1.5 px-6 py-2.5 text-xs text-white/78 md:px-10 md:text-sm lg:flex-row lg:items-center lg:justify-between">
          <p>{siteConfig.tagline}</p>
          <p className="font-medium text-[color:var(--color-accent)]">{siteConfig.intakeLabel}</p>
        </div>
      </div>

      <div className="relative mx-auto flex max-w-7xl items-center justify-between gap-6 px-6 py-4 md:px-10 md:py-5">
        <Link href="/" className="flex items-center gap-3">
          <span className="flex h-12 w-12 items-center justify-center rounded-full border border-[var(--color-border)] bg-[linear-gradient(135deg,var(--color-brand),#75a39f)] text-sm font-semibold text-white">
            GF
          </span>
          <div>
            <div className="text-sm font-semibold tracking-[0.14em] text-[var(--color-ink)]">GEOFLOW</div>
            <div className="text-xs text-[var(--color-ink-soft)]">AI 搜索曝光优化编辑台</div>
          </div>
        </Link>

        <nav className="hidden items-center gap-7 text-sm font-medium text-[var(--color-ink-soft)] xl:flex">
          {navItems.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={`relative pb-3 transition hover:text-[var(--color-brand)] ${
                pathname === item.href ? "text-[var(--color-brand)]" : ""
              }`}
            >
              {item.label}
              <span
                className={`absolute inset-x-0 bottom-0 h-[3px] rounded-full bg-[var(--color-brand)] transition ${
                  pathname === item.href ? "opacity-100" : "opacity-0"
                }`}
              />
            </Link>
          ))}
        </nav>

        <div className="hidden items-center gap-3 lg:flex">
          <Link
            href="/audit"
            className="rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-2.5 text-sm font-medium text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
          >
            体检报告页
          </Link>
          <Link
            href="/free-audit"
            className="rounded-2xl bg-[var(--color-brand)] px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-[var(--color-brand-deep)]"
          >
            免费诊断
          </Link>
        </div>

        <button
          type="button"
          aria-controls="mobile-site-nav"
          aria-expanded={mobileOpen}
          onClick={() => setMobileOpen((open) => !open)}
          className="inline-flex items-center gap-3 rounded-2xl border border-[var(--color-border)] bg-[var(--color-surface)] px-3.5 py-2.5 text-[var(--color-ink)] shadow-sm transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)] lg:hidden"
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
            className="absolute inset-x-0 top-full mt-3 rounded-[1.75rem] border border-[var(--color-border)] bg-[var(--color-surface)]/98 p-5 shadow-[var(--shadow-card)] lg:hidden"
          >
            <div className="flex items-center justify-between border-b border-[var(--color-border)] pb-4">
              <div>
                <p className="text-xs font-semibold tracking-[0.18em] text-[var(--color-brand)]">EDITORIAL NAV</p>
                <p className="mt-1 text-sm text-[var(--color-ink-soft)]">快速进入 GEOFlow 栏目和转化入口</p>
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
                  className={`rounded-2xl border px-4 py-3 transition hover:border-[var(--color-border)] hover:bg-[var(--color-surface-muted)] ${
                    pathname === item.href
                      ? "border-[var(--color-border)] bg-[var(--color-surface-muted)] text-[var(--color-brand)]"
                      : "border-transparent"
                  }`}
                >
                  {item.label}
                </Link>
              ))}

              <div className="mt-2 grid gap-3 sm:grid-cols-2">
                <Link
                  href="/audit"
                  onClick={closeMobileMenu}
                  className="rounded-2xl border border-[var(--color-border)] px-4 py-3 text-center font-medium text-[var(--color-ink)] transition hover:border-[var(--color-brand)] hover:text-[var(--color-brand)]"
                >
                  体检报告页
                </Link>
                <Link
                  href="/free-audit"
                  onClick={closeMobileMenu}
                  className="rounded-2xl bg-[var(--color-brand)] px-4 py-3 text-center font-semibold text-white"
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
