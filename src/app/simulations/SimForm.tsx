"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export function SimForm() {
  const router = useRouter();
  const [kind, setKind] = useState<"voting" | "roundloop">("voting");
  const [cycles, setCycles] = useState(1000);
  const [seed, setSeed] = useState("");
  const [busy, setBusy] = useState(false);
  const [msg, setMsg] = useState<string | null>(null);

  async function run() {
    setBusy(true); setMsg(null);
    const res = await fetch("/api/simulations", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ kind, cycles, seed: seed === "" ? undefined : Number(seed) }) });
    const json = await res.json();
    setBusy(false);
    setMsg(json.ok ? `${json.run.kind} × ${json.run.cycles}: ${json.run.passed ? "PASS" : json.run.violations.length + " violations"} in ${Math.round(json.run.durationMs)} ms` : "Failed");
    router.refresh();
  }

  return (
    <div className="flex flex-wrap items-end gap-3 rounded-2xl border border-white/10 bg-white/[0.03] p-4">
      <label className="text-xs text-slate-400">Kind
        <select value={kind} onChange={(e) => setKind(e.target.value as "voting" | "roundloop")} className="mt-1 block rounded-md border border-white/10 bg-black/30 px-3 py-2 text-sm text-white">
          <option value="voting">Voting cycles</option>
          <option value="roundloop">Round loop (join/leave chaos)</option>
        </select>
      </label>
      <label className="text-xs text-slate-400">Cycles
        <input type="number" min={1} max={20000} value={cycles} onChange={(e) => setCycles(Number(e.target.value))} className="mt-1 block w-28 rounded-md border border-white/10 bg-black/30 px-3 py-2 text-sm text-white" />
      </label>
      <label className="text-xs text-slate-400">Seed (optional)
        <input value={seed} onChange={(e) => setSeed(e.target.value)} placeholder="random" className="mt-1 block w-28 rounded-md border border-white/10 bg-black/30 px-3 py-2 text-sm text-white" />
      </label>
      <button onClick={run} disabled={busy} className="rounded-lg bg-fuchsia-500 px-4 py-2 text-sm font-semibold text-white hover:bg-fuchsia-400 disabled:opacity-50">{busy ? "Running…" : "Run simulation"}</button>
      {msg && <span className="text-sm text-slate-300">{msg}</span>}
    </div>
  );
}
