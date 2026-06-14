import Link from "next/link";
import { navItems } from "@/lib/site";

export function SiteFooter() {
  return (
    <footer className="border-t border-[var(--color-border)] bg-white/88">
      <div className="mx-auto flex max-w-7xl flex-col gap-6 px-6 py-10 md:px-10 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <div className="text-sm font-semibold tracking-[0.2em] text-[var(--color-ink)]">GEOFLOW</div>
          <p className="mt-2 max-w-xl text-sm leading-7 text-[var(--color-ink-soft)]">
            帮中国出海 AI / SaaS / B2B 软件公司，提升品牌在 AI 搜索结果中的出现率、引用率和推荐率。
          </p>
        </div>
        <div className="flex flex-wrap gap-4 text-sm text-[var(--color-ink-soft)]">
          {navItems.map((item) => (
            <Link key={item.href} href={item.href}>
              {item.label}
            </Link>
          ))}
        </div>
      </div>
    </footer>
  );
}
