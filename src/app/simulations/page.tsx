import { db } from "@/db";
import { simulationRuns } from "@/db/schema";
import { desc } from "drizzle-orm";
import { ensureBaselineSimulations } from "@/lib/data";
import { Card, Badge } from "@/components/ui";
import { SimForm } from "./SimForm";

export const dynamic = "force-dynamic";

export default async function SimulationsPage() {
  await ensureBaselineSimulations();
  const runs = await db.select().from(simulationRuns).orderBy(desc(simulationRuns.createdAt)).limit(50);
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black">Simulations</h1>
        <p className="text-slate-400">The TypeScript runner is a 1:1 port of <code>CandidateSelector.luau</code>; the same algorithm is also executed under Lune in <code>roblox/tests</code>. Results are persisted in PostgreSQL.</p>
      </div>
      <SimForm />
      <div className="space-y-4">
        {runs.map((r) => {
          const m = r.metrics as Record<string, unknown>;
          return (
            <Card key={r.id}>
              <div className="flex flex-wrap items-center gap-3">
                <Badge tone={r.passed ? "good" : "bad"}>{r.passed ? "PASS" : "FAIL"}</Badge>
                <span className="font-semibold capitalize">{r.kind}</span>
                <span className="text-slate-400">{r.cycles.toLocaleString()} cycles · seed {r.seed} · {Math.round(r.durationMs)} ms</span>
                <span className="ml-auto text-xs text-slate-500">{new Date(r.createdAt).toLocaleString()}</span>
              </div>
              <div className="mt-3 grid gap-2 text-xs sm:grid-cols-2 lg:grid-cols-4">
                {Object.entries(m).filter(([, v]) => typeof v !== "object").map(([k, v]) => (
                  <div key={k} className="rounded bg-black/20 px-2 py-1"><span className="text-slate-500">{k}</span> <span className="float-right text-slate-200">{String(v)}</span></div>
                ))}
              </div>
              {Array.isArray(m.topGames) && (
                <div className="mt-2 text-xs text-slate-400">Top games: {(m.topGames as [string, number][]).map(([g, n]) => `${g} (${n})`).join(", ")}</div>
              )}
              {m.categoryPlays ? <div className="mt-1 text-xs text-slate-400">Categories: {Object.entries(m.categoryPlays as Record<string, number>).map(([c, n]) => `${c} ${n}`).join(" · ")}</div> : null}
              {r.violations.length > 0 && (
                <details className="mt-2 text-xs text-rose-300"><summary>{r.violations.length} violations</summary><ul className="mt-1 list-disc pl-5">{r.violations.slice(0, 30).map((v, i) => <li key={i}>{v}</li>)}</ul></details>
              )}
            </Card>
          );
        })}
      </div>
    </div>
  );
}
