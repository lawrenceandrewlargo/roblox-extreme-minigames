// 1:1 port of roblox/src/shared/CandidateSelector.luau. Keep in sync.
import type { MinigameMeta, ModifierDef } from "../catalog";
import { VOTING_CONFIG } from "../catalog";
import type { Rng } from "./prng";

export type HistoryEntry = { GameId: string; Round: number; MapId?: string; ModifierId?: string };
export type Stats = { plays: Record<string, number>; lastRound: Record<string, number> };

export function buildStats(history: HistoryEntry[]): Stats {
  const plays: Record<string, number> = {};
  const lastRound: Record<string, number> = {};
  for (const h of history) {
    plays[h.GameId] = (plays[h.GameId] ?? 0) + 1;
    lastRound[h.GameId] = h.Round;
  }
  return { plays, lastRound };
}

function roundsSince(stats: Stats, id: string, currentRound: number): number {
  const last = stats.lastRound[id];
  return last === undefined ? Infinity : currentRound - last;
}
const cooldownOf = (m: MinigameMeta) => m.VoteCooldownRounds || VOTING_CONFIG.DefaultCooldownRounds;

export function compareTieBreak(stats: Stats, currentRound: number) {
  return (a: MinigameMeta, b: MinigameMeta): number => {
    const ra = roundsSince(stats, a.Id, currentRound);
    const rb = roundsSince(stats, b.Id, currentRound);
    if (ra !== rb) return ra > rb ? -1 : 1;
    const pa = stats.plays[a.Id] ?? 0;
    const pb = stats.plays[b.Id] ?? 0;
    if (pa !== pb) return pa - pb;
    return a.Id < b.Id ? -1 : a.Id > b.Id ? 1 : 0;
  };
}

export function weight(meta: MinigameMeta, stats: Stats, currentRound: number, avgPlays: number): number {
  const cfg = VOTING_CONFIG;
  const plays = stats.plays[meta.Id] ?? 0;
  let w = 1;
  if (plays < avgPlays) w *= 1 + cfg.UnderplayedBonus;
  if (avgPlays > 0 && plays > avgPlays * cfg.OverplayedThresholdMultiplier) w *= cfg.OverplayedPenalty;
  const since = roundsSince(stats, meta.Id, currentRound);
  if (since !== Infinity) w *= Math.min(1, Math.max(0.25, since / (cooldownOf(meta) * 2)));
  return w;
}

function weightedPick<T>(items: T[], weights: number[], rng: Rng): [T | undefined, number] {
  const total = weights.reduce((a, b) => a + b, 0);
  if (total <= 0) return [undefined, -1];
  let r = rng.NextNumber() * total;
  for (let i = 0; i < weights.length; i++) {
    r -= weights[i];
    if (r <= 0) return [items[i], i];
  }
  return [items[items.length - 1], items.length - 1];
}

export function select(library: MinigameMeta[], history: HistoryEntry[], playerCount: number, currentRound: number, rng: Rng, count = VOTING_CONFIG.CandidateCount): MinigameMeta[] {
  const stats = buildStats(history);
  const previous = history.length ? history[history.length - 1].GameId : undefined;
  let compatible = library.filter((m) => playerCount >= m.MinimumPlayers && playerCount <= m.MaximumPlayers);
  if (compatible.length === 0) compatible = library.filter((m) => playerCount >= m.MinimumPlayers);
  if (compatible.length === 0) return [];
  let eligible: MinigameMeta[] = [];
  for (const relax of [1, 0.5, 0]) {
    eligible = compatible.filter((m) => m.Id !== previous && roundsSince(stats, m.Id, currentRound) >= cooldownOf(m) * relax);
    if (eligible.length >= count) break;
  }
  if (eligible.length === 0) eligible = compatible;
  const total = eligible.reduce((a, m) => a + (stats.plays[m.Id] ?? 0), 0);
  const avgPlays = total / Math.max(1, eligible.length);
  const pool = [...eligible];
  const chosen: MinigameMeta[] = [];
  const usedCategories = new Set<string>();
  while (chosen.length < count && pool.length > 0) {
    const weights = pool.map((m) => weight(m, stats, currentRound, avgPlays) * (usedCategories.has(m.Category) ? 0.15 : 1));
    const [pick, idx] = weightedPick(pool, weights, rng);
    if (!pick) break;
    chosen.push(pick);
    usedCategories.add(pick.Category);
    pool.splice(idx, 1);
  }
  return chosen;
}

/** votes: userId -> candidate index (1-based like Luau). Returns 1-based winner index + counts. */
export function tally(candidates: MinigameMeta[], votes: Record<number, number>, history: HistoryEntry[], currentRound: number, rng: Rng): [number, number[]] {
  const counts = new Array<number>(candidates.length).fill(0);
  for (const idx of Object.values(votes)) if (candidates[idx - 1]) counts[idx - 1]++;
  let best = -1;
  let tied: number[] = [];
  counts.forEach((c, i) => {
    if (c > best) { best = c; tied = [i + 1]; } else if (c === best) tied.push(i + 1);
  });
  if (tied.length === 1) return [tied[0], counts];
  const cmp = compareTieBreak(buildStats(history), currentRound);
  tied.sort((a, b) => {
    const c = cmp(candidates[a - 1], candidates[b - 1]);
    return c !== 0 ? c : rng.NextNumber() < 0.5 ? -1 : 1;
  });
  return [tied[0], counts];
}

export function pickMap(meta: MinigameMeta, history: HistoryEntry[], rng: Rng): string {
  if (meta.Maps.length === 0) return "Default";
  const lastMaps: Record<string, number> = {};
  history.forEach((h, i) => { if (h.GameId === meta.Id && h.MapId) lastMaps[h.MapId] = i + 1; });
  const cands = [...meta.Maps].sort((a, b) => (lastMaps[a] ?? 0) - (lastMaps[b] ?? 0) || (a < b ? -1 : 1));
  if (rng.NextNumber() < 0.2 && cands.length > 1) return cands[rng.NextInteger(1, cands.length) - 1];
  return cands[0];
}

export function pickModifier(meta: MinigameMeta, modifiers: ModifierDef[], history: HistoryEntry[], rng: Rng): string {
  const allowed = new Set(meta.AllowedModifiers);
  const recent = new Set(history.slice(-3).map((h) => h.ModifierId).filter(Boolean));
  const items: string[] = [];
  const weights: number[] = [];
  for (const m of modifiers) if (allowed.has(m.Id) && (m.Id === "None" || !recent.has(m.Id))) { items.push(m.Id); weights.push(m.Weight); }
  const [pick] = weightedPick(items, weights, rng);
  return pick ?? "None";
}
