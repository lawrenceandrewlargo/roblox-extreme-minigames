import type { Metadata } from "next";
import type { ReactNode } from "react";
import Link from "next/link";
import "./globals.css";

export const metadata: Metadata = {
  title: "Party Chaos — Command Center",
  description: "Design, simulation and release dashboard for the Party Chaos Roblox party game.",
};

const nav = [
  ["/", "Dashboard"],
  ["/minigames", "Minigames"],
  ["/simulations", "Simulations"],
  ["/tests", "Tests"],
  ["/docs", "Docs"],
  ["/handoff", "AI Handoff"],
];

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-[#0d0f17] text-slate-100 antialiased">
        <header className="sticky top-0 z-20 border-b border-white/10 bg-[#0d0f17]/90 backdrop-blur">
          <div className="mx-auto flex max-w-7xl items-center gap-6 px-6 py-3">
            <Link href="/" className="flex items-center gap-2 font-bold tracking-tight">
              <span className="inline-block h-3 w-3 rounded-full bg-gradient-to-br from-fuchsia-400 to-amber-300" />
              Party Chaos <span className="text-slate-400 font-normal">/ Command Center</span>
            </Link>
            <nav className="ml-auto flex flex-wrap gap-1 text-sm">
              {nav.map(([href, label]) => (
                <Link key={href} href={href} className="rounded-md px-3 py-1.5 text-slate-300 hover:bg-white/10 hover:text-white">
                  {label}
                </Link>
              ))}
            </nav>
          </div>
        </header>
        <main className="mx-auto max-w-7xl px-6 py-8">{children}</main>
        <footer className="mx-auto max-w-7xl px-6 py-10 text-xs text-slate-500">
          Roblox source lives in <code>roblox/</code>. This dashboard parses the Luau catalog directly and runs the same selection algorithm at scale.
        </footer>
      </body>
    </html>
  );
}
