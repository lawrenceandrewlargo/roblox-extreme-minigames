import { db } from "@/db";
import { minigames, simulationRuns, testRuns, decisions } from "@/db/schema";
import { loadCatalog } from "./catalog";
import { simulateVoting, simulateRoundLoop, type SimResult } from "./sim/runner";
import { desc, sql } from "drizzle-orm";
import { readFileSync, existsSync, readdirSync } from "node:fs";
import path from "node:path";

export async function syncMinigames() {
  const { catalog } = loadCatalog();
  for (const m of catalog) {
    await db
      .insert(minigames)
      .values({
        id: m.Id, displayName: m.DisplayName, description: m.Description, category: m.Category, secondaryCategory: m.SecondaryCategory ?? null,
        minPlayers: m.MinimumPlayers, maxPlayers: m.MaximumPlayers, duration: m.Duration, cooldownRounds: m.VoteCooldownRounds,
        supportsTeams: m.SupportsTeams, hidesInformation: m.HidesInformation, maps: m.Maps, allowedModifiers: m.AllowedModifiers, movement: m.Movement,
      })
      .onConflictDoUpdate({
        target: minigames.id,
        set: {
          displayName: m.DisplayName, description: m.Description, category: m.Category, secondaryCategory: m.SecondaryCategory ?? null,
          minPlayers: m.MinimumPlayers, maxPlayers: m.MaximumPlayers, duration: m.Duration, cooldownRounds: m.VoteCooldownRounds,
          supportsTeams: m.SupportsTeams, hidesInformation: m.HidesInformation, maps: m.Maps, allowedModifiers: m.AllowedModifiers, movement: m.Movement, syncedAt: new Date(),
        },
      });
  }
  return db.select().from(minigames).orderBy(minigames.category, minigames.displayName);
}

export async function recordSimulation(result: SimResult) {
  const [row] = await db.insert(simulationRuns).values({
    kind: result.kind, cycles: result.cycles, seed: result.seed, params: result.params, metrics: result.metrics,
    violations: result.violations, passed: result.passed, durationMs: result.durationMs,
  }).returning();
  return row;
}

export async function runAndRecord(kind: "voting" | "roundloop", cycles: number, seed: number, extra: Record<string, number> = {}) {
  const result = kind === "voting" ? simulateVoting({ cycles, seed, ...extra }) : simulateRoundLoop({ cycles, seed, ...extra });
  return recordSimulation(result);
}

/** First-run: populate the required simulation matrix so the dashboard is never empty. */
export async function ensureBaselineSimulations() {
  const [{ count }] = await db.select({ count: sql<number>`count(*)::int` }).from(simulationRuns);
  if (count > 0) return false;
  const matrix: Array<["voting" | "roundloop", number, number]> = [["voting", 100, 1], ["voting", 500, 2], ["voting", 1000, 3], ["roundloop", 100, 11], ["roundloop", 500, 12]];
  for (const [kind, cycles, seed] of matrix) await runAndRecord(kind, cycles, seed);
  return true;
}

export async function ensureBaselineTests() {
  const [{ count }] = await db.select({ count: sql<number>`count(*)::int` }).from(testRuns);
  if (count > 0) return;
  const p = path.join(process.cwd(), "roblox/tests/last-run.txt");
  if (existsSync(p)) {
    const output = readFileSync(p, "utf8");
    const m = output.match(/(\d+) passed, (\d+) failed/);
    await db.insert(testRuns).values({ suite: "luau (lune)", runner: "lune run tests/run", passed: m ? Number(m[1]) : 0, failed: m ? Number(m[2]) : 0, output });
  }
}

export async function ensureBaselineDecisions() {
  const [{ count }] = await db.select({ count: sql<number>`count(*)::int` }).from(decisions);
  if (count > 0) return;
  await db.insert(decisions).values([
    { title: "Rojo/Argon-compatible filesystem layout as code source of truth", context: "2026 ecosystem: Script Sync (official, scripts only), Rojo (build tool), Argon (two-way sync, project.json compatible), Azul (1:1 mirror, no project file).", decision: "Keep all Luau in roblox/src with default.project.json. Recommend Argon for daily two-way sync, Rojo as CI build, Script Sync as beginner fallback.", consequences: "Portable across all three tools; maps/terrain stay Studio-authored and are exported as .rbxm into roblox/assets/maps." },
    { title: "Physical voting derived from server-side overlap scans only", context: "Client-sent votes are trivially spoofable and desync from platform positions.", decision: "VotingService scans HumanoidRootPart positions against platform bounds at ~6Hz; clients never send votes.", consequences: "One vote per player by construction; disconnects clear votes; no vote remote exists to exploit." },
    { title: "Minigame state lives on a per-round context, never at module level", context: "Module-level tables are the #1 cause of cross-round leakage in Roblox minigame frameworks.", decision: "MinigameService builds a ctx with its own Janitor; static test rejects module-level mutable tables.", consequences: "Cleanup is guaranteed by destroying one Janitor; restart/abort paths are trivial." },
    { title: "Admin actions are a single validated remote with a command registry", context: "Scattered admin remotes leak permissions and are hard to audit.", decision: "AdminService:Register(cmd) with category-based rank gating, dangerous-action confirmation and an audit ring buffer.", consequences: "GUI is generated from the server's permitted command list; adding a command is one Register call." },
    { title: "Lune + luau-ast as the headless verification layer", context: "Roblox Studio is not available to the AI agent; unverified Luau is a major risk.", decision: "All 80+ files are parsed with luau-ast; pure modules are executed under Lune with a virtual instance tree harness.", consequences: "Selector/tally/timer/janitor/reward math are proven; engine-dependent code is marked 'Requires Studio verification'." },
  ]);
}

export async function dashboardData() {
  const games = await syncMinigames();
  await ensureBaselineSimulations();
  await ensureBaselineTests();
  await ensureBaselineDecisions();
  const sims = await db.select().from(simulationRuns).orderBy(desc(simulationRuns.createdAt)).limit(20);
  const tests = await db.select().from(testRuns).orderBy(desc(testRuns.createdAt)).limit(5);
  const adrs = await db.select().from(decisions).orderBy(decisions.id);
  return { games, sims, tests, adrs };
}

export function listDocs(): { slug: string; title: string }[] {
  const dir = path.join(process.cwd(), "docs");
  if (!existsSync(dir)) return [];
  return readdirSync(dir).filter((f: string) => f.endsWith(".md")).map((f: string) => ({ slug: f.replace(/\.md$/, ""), title: f.replace(/\.md$/, "").replace(/_/g, " ") }));
}

export function readDoc(slug: string): string | null {
  if (!/^[A-Za-z0-9_\-]+$/.test(slug)) return null;
  const p = path.join(process.cwd(), "docs", `${slug}.md`);
  return existsSync(p) ? readFileSync(p, "utf8") : null;
}
