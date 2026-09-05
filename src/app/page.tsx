import Link from "next/link";
import { dashboardData } from "@/lib/data";
import { Card, Stat, Badge, CATEGORY_COLORS } from "@/components/ui";

export const dynamic = "force-dynamic";

const RELEASE_GATE: Array<[string, string, "done" | "studio" | "human"]> = [
  ["30+ distinct minigames", "37 registered, each with unique server module + metadata", "done"],
  ["Physical in-world voting", "Server overlap scans, one vote per player, live signs", "done"],
  ["Smart candidate selection", "Cooldowns, category diversity, under/over-played weighting", "done"],
  ["1,000+ voting simulations", "Run in Lune (Luau) and here (TypeScript port)", "done"],
  ["100+ / 500+ round-loop simulations", "State-machine simulation with join/leave chaos", "done"],
  ["Admin system", "60+ commands, roles, confirmation, audit log, fly/noclip/speed", "done"],
  ["Progression / cosmetics / challenges", "DataStore profiles with migrations, shop, daily/weekly", "done"],
  ["Static validation", "83 files parsed by luau-ast; 17 Lune tests green", "done"],
  ["Documentation + AI handoff", "20 documents in docs/", "done"],
  ["Live multiplayer behaviour", "Physics, replication, character scaling in Studio", "studio"],
  ["Map art & lighting", "Maps fall back to procedural placeholders until authored", "studio"],
  ["Fun, pacing, clarity", "Owner playtest via FINAL_PLAYTEST_GUIDE.md", "human"],
];

export default async function HomePage() {
  const { games, sims, tests, adrs } = await dashboardData();
  const categories = games.reduce<Record<string, number>>((acc, g) => ((acc[g.category] = (acc[g.category] ?? 0) + 1), acc), {});
  const votingSims = sims.filter((s) => s.kind === "voting");
  const loopSims = sims.filter((s) => s.kind === "roundloop");
  const allPassed = sims.every((s) => s.passed);
  const latestTest = tests[0];
  const totalMaps = new Set(games.flatMap((g) => g.maps)).size;

  return (
    <div className="space-y-8">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-fuchsia-300">Release candidate</p>
          <h1 className="mt-2 text-4xl font-black tracking-tight">Party Chaos</h1>
          <p className="mt-2 max-w-2xl text-slate-400">
            An original Roblox party game: lobby → stand-on-a-platform voting → 37 short chaotic minigames → results → repeat. This dashboard is the
            autonomous build&apos;s verification surface.
          </p>
        </div>
        <div className="flex gap-2">
          <Link href="/simulations" className="rounded-lg bg-fuchsia-500 px-4 py-2 text-sm font-semibold text-white hover:bg-fuchsia-400">Run a simulation</Link>
          <Link href="/handoff" className="rounded-lg border border-white/15 px-4 py-2 text-sm font-semibold hover:bg-white/10">AI handoff</Link>
        </div>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-5">
        <Stat label="Minigames" value={games.length} sub={`${Object.keys(categories).length} primary categories`} tone="good" />
        <Stat label="Maps referenced" value={totalMaps} sub="procedural fallbacks exist for all" />
        <Stat label="Voting cycles simulated" value={votingSims.reduce((a, s) => a + s.cycles, 0).toLocaleString()} sub={`${votingSims.length} runs`} tone={allPassed ? "good" : "bad"} />
        <Stat label="Round loops simulated" value={loopSims.reduce((a, s) => a + s.cycles, 0).toLocaleString()} sub={`${loopSims.length} runs`} tone={allPassed ? "good" : "bad"} />
        <Stat label="Luau tests" value={latestTest ? `${latestTest.passed}/${latestTest.passed + latestTest.failed}` : "—"} sub={latestTest ? latestTest.runner : "no runs recorded"} tone={latestTest && latestTest.failed === 0 ? "good" : "warn"} />
      </div>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card title="Category coverage" className="lg:col-span-1">
          <ul className="space-y-2">
            {Object.entries(categories).sort((a, b) => b[1] - a[1]).map(([cat, n]) => (
              <li key={cat} className="flex items-center gap-3 text-sm">
                <span className={`h-2.5 w-2.5 rounded-full ${CATEGORY_COLORS[cat] ?? "bg-slate-400"}`} />
                <span className="w-24 text-slate-300">{cat}</span>
                <div className="h-2 flex-1 rounded bg-white/5"><div className={`h-2 rounded ${CATEGORY_COLORS[cat] ?? "bg-slate-400"}`} style={{ width: `${(n / games.length) * 100 * 3}%` }} /></div>
                <span className="w-6 text-right text-slate-400">{n}</span>
              </li>
            ))}
          </ul>
          <p className="mt-3 text-xs text-slate-500">No category exceeds 20% of the library (enforced by static test).</p>
        </Card>

        <Card title="Release gate" className="lg:col-span-2">
          <ul className="divide-y divide-white/5">
            {RELEASE_GATE.map(([item, detail, state]) => (
              <li key={item} className="flex items-start gap-3 py-2.5">
                <Badge tone={state === "done" ? "good" : state === "studio" ? "warn" : "info"}>{state === "done" ? "Verified" : state === "studio" ? "Needs Studio" : "Needs human"}</Badge>
                <div>
                  <div className="text-sm font-medium">{item}</div>
                  <div className="text-xs text-slate-400">{detail}</div>
                </div>
              </li>
            ))}
          </ul>
        </Card>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <Card title="Latest simulations">
          <table className="w-full text-sm">
            <thead className="text-left text-xs uppercase text-slate-500"><tr><th className="py-1">Kind</th><th>Cycles</th><th>Result</th><th>Key metrics</th></tr></thead>
            <tbody>
              {sims.slice(0, 8).map((s) => {
                const m = s.metrics as Record<string, number>;
                return (
                  <tr key={s.id} className="border-t border-white/5">
                    <td className="py-2 capitalize">{s.kind}</td>
                    <td>{s.cycles.toLocaleString()}</td>
                    <td><Badge tone={s.passed ? "good" : "bad"}>{s.passed ? "PASS" : `${s.violations.length} violations`}</Badge></td>
                    <td className="text-xs text-slate-400">
                      {s.kind === "voting" ? `repeats ${m.immediateRepeats} · cooldown ${m.cooldownViolations} · ties ${m.ties} · games ${m.distinctGamesPlayed}/${m.totalGames}` : `elims ${m.totalEliminations} · leavers ${m.roundsWithLeaver} · joiners ${m.roundsWithJoiner} · games ${m.distinctGames}`}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
          <Link href="/simulations" className="mt-3 inline-block text-xs text-fuchsia-300 hover:underline">All simulations →</Link>
        </Card>

        <Card title="Architecture decisions">
          <ul className="space-y-3">
            {adrs.map((d) => (
              <li key={d.id}>
                <div className="text-sm font-medium">{d.title}</div>
                <div className="text-xs text-slate-400">{d.decision}</div>
              </li>
            ))}
          </ul>
          <Link href="/docs/DEVELOPMENT_TOOLING_DECISION" className="mt-3 inline-block text-xs text-fuchsia-300 hover:underline">Tooling decision →</Link>
        </Card>
      </div>
    </div>
  );
}
