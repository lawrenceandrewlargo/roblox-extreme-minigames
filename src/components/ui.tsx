import type { ReactNode } from "react";

export function Card({ title, children, className = "" }: { title?: string; children: ReactNode; className?: string }) {
  return (
    <section className={`rounded-2xl border border-white/10 bg-white/[0.03] p-5 ${className}`}>
      {title && <h2 className="mb-3 text-sm font-semibold uppercase tracking-wider text-slate-400">{title}</h2>}
      {children}
    </section>
  );
}

export function Stat({ label, value, sub, tone = "default" }: { label: string; value: string | number; sub?: string; tone?: "default" | "good" | "bad" | "warn" }) {
  const color = tone === "good" ? "text-emerald-300" : tone === "bad" ? "text-rose-300" : tone === "warn" ? "text-amber-300" : "text-white";
  return (
    <div className="rounded-xl border border-white/10 bg-black/20 p-4">
      <div className="text-xs uppercase tracking-wider text-slate-400">{label}</div>
      <div className={`mt-1 text-2xl font-bold ${color}`}>{value}</div>
      {sub && <div className="mt-1 text-xs text-slate-400">{sub}</div>}
    </div>
  );
}

export function Badge({ children, tone = "default" }: { children: ReactNode; tone?: "default" | "good" | "bad" | "warn" | "info" }) {
  const cls = { default: "bg-white/10 text-slate-200", good: "bg-emerald-500/15 text-emerald-300", bad: "bg-rose-500/15 text-rose-300", warn: "bg-amber-500/15 text-amber-300", info: "bg-sky-500/15 text-sky-300" }[tone];
  return <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${cls}`}>{children}</span>;
}

export const CATEGORY_COLORS: Record<string, string> = {
  Tag: "bg-rose-500", Bomb: "bg-orange-500", HideSeek: "bg-violet-500", PropHunt: "bg-purple-500", Deception: "bg-fuchsia-500", Obby: "bg-lime-500", Speedrun: "bg-green-500",
  Racing: "bg-teal-500", Kart: "bg-cyan-500", Survival: "bg-sky-500", Disaster: "bg-blue-500", Physics: "bg-indigo-500", Reaction: "bg-yellow-500", Memory: "bg-amber-500",
  Team: "bg-emerald-500", Social: "bg-pink-500", Elimination: "bg-red-500", Movement: "bg-lime-400", Platform: "bg-stone-400", Chaos: "bg-fuchsia-400",
};
