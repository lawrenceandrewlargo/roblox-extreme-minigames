import { db } from "@/db";
import { testRuns } from "@/db/schema";
import { desc } from "drizzle-orm";
export const dynamic = "force-dynamic";

export async function GET() {
  const rows = await db.select().from(testRuns).orderBy(desc(testRuns.createdAt)).limit(20);
  return Response.json({ ok: true, runs: rows });
}

/** Record a test run (used by `lune run tests/run | tee` + curl, or CI). */
export async function POST(req: Request) {
  let body: Record<string, unknown> = {};
  try { body = await req.json(); } catch { return Response.json({ ok: false, error: "invalid_json" }, { status: 400 }); }
  const output = typeof body.output === "string" ? body.output.slice(0, 20000) : "";
  const m = output.match(/(\d+) passed, (\d+) failed/);
  const passed = Number(body.passed ?? m?.[1] ?? 0);
  const failed = Number(body.failed ?? m?.[2] ?? 0);
  const [row] = await db.insert(testRuns).values({ suite: String(body.suite ?? "luau (lune)"), runner: String(body.runner ?? "lune run tests/run"), passed, failed, output }).returning();
  return Response.json({ ok: true, run: row });
}
