import { db } from "@/db";
import { testRuns } from "@/db/schema";
import { desc } from "drizzle-orm";
import { ensureBaselineTests } from "@/lib/data";
import { Card, Badge } from "@/components/ui";

export const dynamic = "force-dynamic";

const MATRIX: Array<[string, string, string]> = [
  ["Static validation", "luau-ast parse of every file; catalog↔module parity; remote name parity; no module-level state; category caps", "Automated (Lune)"],
  ["Unit tests", "Signal, Janitor, Timer, TableUtil, RewardMath, CandidateSelector, Tally", "Automated (Lune)"],
  ["Voting simulation", "100 / 500 / 1,000+ cycles, random player counts, ties, zero-vote rounds, disconnects", "Automated (Lune + web)"],
  ["Round-loop simulation", "100 / 500 rounds; join/leave during voting and gameplay; cleanup + restoration invariants", "Automated (web)"],
  ["Security tests", "Rate limiter, invalid payload rejection, admin authorization, bomb-transfer distance, checkpoint skipping", "Code-level; runtime needs Studio"],
  ["Integration / cross-minigame", "Lobby→Voting→Game→Results→Rewards→Lobby across all categories", "Simulated here; live in Studio"],
  ["Performance", "10Hz minigame tick, 6Hz vote scan, 20Hz kart drive, no RenderStepped except admin fly", "Design-verified; profile in Studio"],
  ["UI tests", "Window manager stack, Escape/B close, confirm dialog, minimize/restore", "Requires Studio"],
];

export default async function TestsPage() {
  await ensureBaselineTests();
  const runs = await db.select().from(testRuns).orderBy(desc(testRuns.createdAt)).limit(20);
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black">Testing status</h1>
        <p className="text-slate-400">Honest split between what was executed automatically, what is verified by construction, and what needs Roblox Studio or a human.</p>
      </div>
      <Card title="Test matrix">
        <table className="w-full text-sm">
          <thead className="text-left text-xs uppercase text-slate-500"><tr><th className="py-1">Layer</th><th>Scope</th><th>Verification</th></tr></thead>
          <tbody>{MATRIX.map(([a, b, c]) => <tr key={a} className="border-t border-white/5"><td className="py-2 font-medium">{a}</td><td className="text-slate-300">{b}</td><td><Badge tone={c.startsWith("Automated") ? "good" : c.startsWith("Requires") ? "warn" : "info"}>{c}</Badge></td></tr>)}</tbody>
        </table>
      </Card>
      {runs.map((r) => (
        <Card key={r.id} title={`${r.suite} — ${r.runner}`}>
          <div className="flex items-center gap-3"><Badge tone={r.failed === 0 ? "good" : "bad"}>{r.passed} passed / {r.failed} failed</Badge><span className="text-xs text-slate-500">{new Date(r.createdAt).toLocaleString()}</span></div>
          <pre className="mt-3 max-h-80 overflow-auto rounded-lg bg-black/40 p-3 text-xs text-slate-300">{r.output}</pre>
        </Card>
      ))}
      <Card title="Record a run">
        <p className="text-sm text-slate-300">From <code>roblox/</code>: <code>lune run tests/run | tee tests/last-run.txt</code>, then <code>curl -X POST /api/tests -H &quot;content-type: application/json&quot; -d &apos;{`{"output": "..."}`}&apos;</code>.</p>
      </Card>
    </div>
  );
}
