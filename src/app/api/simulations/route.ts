import { db } from "@/db";
import { simulationRuns } from "@/db/schema";
import { desc } from "drizzle-orm";
import { runAndRecord } from "@/lib/data";
export const dynamic = "force-dynamic";

export async function GET() {
  const rows = await db.select().from(simulationRuns).orderBy(desc(simulationRuns.createdAt)).limit(50);
  return Response.json({ ok: true, runs: rows });
}

export async function POST(req: Request) {
  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { /* allow empty */ }
  const kind = body.kind === "roundloop" ? "roundloop" : "voting";
  const cycles = Math.min(20000, Math.max(1, Number(body.cycles) || 100));
  const seed = Number.isFinite(Number(body.seed)) ? Number(body.seed) : Math.floor(Math.random() * 1e9);
  const extra: Record<string, number> = {};
  for (const k of ["minPlayers", "maxPlayers", "popularBias", "players", "churn"]) if (body[k] !== undefined && Number.isFinite(Number(body[k]))) extra[k] = Number(body[k]);
  const row = await runAndRecord(kind, cycles, seed, extra);
  return Response.json({ ok: true, run: row });
}
