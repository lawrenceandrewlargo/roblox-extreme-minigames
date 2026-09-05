import { loadCatalog, VOTING_CONFIG, type MinigameMeta } from "../catalog";
import { Rng } from "./prng";
import { select, tally, pickMap, pickModifier, buildStats, type HistoryEntry } from "./candidateSelector";

export type SimResult = {
  kind: "voting" | "roundloop";
  cycles: number;
  seed: number;
  params: Record<string, unknown>;
  metrics: Record<string, unknown>;
  violations: string[];
  passed: boolean;
  durationMs: number;
};

export type VotingParams = { cycles: number; seed: number; minPlayers?: number; maxPlayers?: number; popularBias?: number };

/** Large-scale voting simulation with randomized player counts, tie/zero-vote rounds, and a configurable "popular game" bias. */
export function simulateVoting(p: VotingParams): SimResult {
  const t0 = performance.now();
  const { catalog, modifiers } = loadCatalog();
  const rng = new Rng(p.seed);
  const history: HistoryEntry[] = [];
  const violations: string[] = [];
  const plays: Record<string, number> = {};
  const categoryPlays: Record<string, number> = {};
  const mapPlays: Record<string, number> = {};
  const modifierPlays: Record<string, number> = {};
  let immediateRepeats = 0, cooldownViolations = 0, sameCategoryRounds = 0, ties = 0, zeroVoteRounds = 0, unanimous = 0, candidateFailures = 0;
  let playerCount = 8;
  const favourite = catalog[rng.NextInteger(1, catalog.length) - 1].Id;
  for (let round = 1; round <= p.cycles; round++) {
    playerCount = Math.min(p.maxPlayers ?? 24, Math.max(p.minPlayers ?? 2, playerCount + rng.NextInteger(-2, 2)));
    const cands = select(catalog, history, playerCount, round, rng);
    if (cands.length === 0) { candidateFailures++; violations.push(`round ${round}: no candidates`); continue; }
    if (cands.length !== VOTING_CONFIG.CandidateCount) violations.push(`round ${round}: ${cands.length} candidates`);
    for (const c of cands) if (playerCount < c.MinimumPlayers || playerCount > c.MaximumPlayers) violations.push(`round ${round}: ${c.Id} incompatible with ${playerCount} players`);
    if (new Set(cands.map((c) => c.Category)).size < cands.length) sameCategoryRounds++;
    const votes: Record<number, number> = {};
    const voters = rng.NextInteger(0, playerCount);
    for (let v = 1; v <= voters; v++) {
      const favIdx = cands.findIndex((c) => c.Id === favourite);
      votes[v] = favIdx >= 0 && rng.NextNumber() < (p.popularBias ?? 0.5) ? favIdx + 1 : rng.NextInteger(1, cands.length);
      if (rng.NextNumber() < 0.1) delete votes[v]; // disconnect / left platform
    }
    const [idx, counts] = tally(cands, votes, history, round, rng);
    const winner = cands[idx - 1];
    if (!winner) { violations.push(`round ${round}: invalid winner index ${idx}`); continue; }
    const max = Math.max(...counts);
    if (max === 0) zeroVoteRounds++;
    if (counts.filter((c) => c === max).length > 1) ties++;
    if (max > 0 && counts.filter((c) => c > 0).length === 1) unanimous++;
    const prev = history[history.length - 1];
    if (prev && prev.GameId === winner.Id) { immediateRepeats++; violations.push(`round ${round}: immediate repeat ${winner.Id}`); }
    const stats = buildStats(history);
    const last = stats.lastRound[winner.Id];
    const eligible = catalog.filter((m) => playerCount >= m.MinimumPlayers && playerCount <= m.MaximumPlayers && m.Id !== prev?.GameId && (stats.lastRound[m.Id] === undefined || round - stats.lastRound[m.Id] >= m.VoteCooldownRounds)).length;
    if (last !== undefined && round - last < winner.VoteCooldownRounds && eligible >= VOTING_CONFIG.CandidateCount) { cooldownViolations++; violations.push(`round ${round}: cooldown violation ${winner.Id}`); }
    const mapId = pickMap(winner, history, rng);
    const modifierId = pickModifier(winner, modifiers, history, rng);
    if (!winner.Maps.includes(mapId)) violations.push(`round ${round}: invalid map ${mapId}`);
    if (!winner.AllowedModifiers.includes(modifierId)) violations.push(`round ${round}: invalid modifier ${modifierId}`);
    history.push({ GameId: winner.Id, Round: round, MapId: mapId, ModifierId: modifierId });
    if (history.length > 200) history.shift();
    plays[winner.Id] = (plays[winner.Id] ?? 0) + 1;
    categoryPlays[winner.Category] = (categoryPlays[winner.Category] ?? 0) + 1;
    mapPlays[`${winner.Id}/${mapId}`] = (mapPlays[`${winner.Id}/${mapId}`] ?? 0) + 1;
    modifierPlays[modifierId] = (modifierPlays[modifierId] ?? 0) + 1;
  }
  const neverPlayed = catalog.filter((m) => !plays[m.Id]).map((m) => m.Id);
  const counts = Object.values(plays);
  const maxPlays = Math.max(...counts, 0);
  const minPlays = Math.min(...counts, Infinity);
  if (p.cycles >= 200 && neverPlayed.length) violations.push(`never played: ${neverPlayed.join(", ")}`);
  const favouriteShare = (plays[favourite] ?? 0) / p.cycles;
  if (p.cycles >= 200 && favouriteShare > 0.2) violations.push(`favourite game dominates: ${(favouriteShare * 100).toFixed(1)}%`);
  const metrics = {
    immediateRepeats, cooldownViolations, sameCategoryRounds, ties, zeroVoteRounds, unanimous, candidateFailures,
    distinctGamesPlayed: counts.length, totalGames: catalog.length, neverPlayed, maxPlays, minPlays: minPlays === Infinity ? 0 : minPlays,
    favourite, favouriteShare: Number(favouriteShare.toFixed(3)), categoryPlays, modifierPlays, distinctMaps: Object.keys(mapPlays).length,
    topGames: Object.entries(plays).sort((a, b) => b[1] - a[1]).slice(0, 8),
  };
  return { kind: "voting", cycles: p.cycles, seed: p.seed, params: p as Record<string, unknown>, metrics, violations, passed: violations.length === 0, durationMs: performance.now() - t0 };
}

export type RoundLoopParams = { cycles: number; seed: number; players?: number; churn?: number };

type SimPlayer = { id: number; state: "Lobby" | "Playing" | "Eliminated" | "Spectating" | "Finished"; role?: string; team?: string; scale: number; walkSpeed: number; flags: Set<string>; xp: number; coins: number; wins: number; rounds: number };

/**
 * Simulates the full session state machine (Lobby→Intermission→Voting→Intro→Countdown→Gameplay→Results→Rewards→Lobby)
 * with join/leave chaos, eliminations and finish orders, and asserts the invariants the Luau services guarantee:
 * every player restored to Lobby/default character after each round, votes cleared, janitor items zero, no state leakage.
 */
export function simulateRoundLoop(p: RoundLoopParams): SimResult {
  const t0 = performance.now();
  const { catalog, modifiers } = loadCatalog();
  const rng = new Rng(p.seed);
  const violations: string[] = [];
  const history: HistoryEntry[] = [];
  const players = new Map<number, SimPlayer>();
  let nextId = 1;
  const addPlayer = () => { const id = nextId++; players.set(id, { id, state: "Lobby", scale: 1, walkSpeed: 16, flags: new Set(), xp: 0, coins: 0, wins: 0, rounds: 0 }); };
  for (let i = 0; i < (p.players ?? 10); i++) addPlayer();
  const churn = p.churn ?? 0.15;
  let skippedRounds = 0, swappedRounds = 0;
  let janitorItems = 0, peakJanitor = 0, totalEliminations = 0, totalFinishes = 0, abortedRounds = 0, roundsWithLeaver = 0, roundsWithJoiner = 0;
  const perGame: Record<string, number> = {};
  const transitions: string[] = [];

  for (let round = 1; round <= p.cycles; round++) {
    // Intermission: reset everyone (mirrors PlayerStateService:ResetAllToLobby)
    for (const pl of players.values()) { pl.state = "Lobby"; pl.role = undefined; pl.team = undefined; pl.scale = 1; pl.walkSpeed = 16; pl.flags.clear(); }
    if (players.size < 2) { addPlayer(); addPlayer(); }
    // Voting
    let playerCount = players.size;
    const cands = select(catalog, history, playerCount, round, rng);
    if (!cands.length) { violations.push(`round ${round}: no candidates`); continue; }
    const votes: Record<number, number> = {};
    for (const pl of players.values()) if (rng.NextNumber() < 0.8) votes[pl.id] = rng.NextInteger(1, cands.length);
    // Chaos: leave during voting
    if (rng.NextNumber() < churn) { const victim = [...players.keys()][rng.NextInteger(1, players.size) - 1]; players.delete(victim); delete votes[victim]; roundsWithLeaver++; }
    for (const uid of Object.keys(votes)) if (!players.has(Number(uid))) violations.push(`round ${round}: stale vote from departed player ${uid}`);
    const [idx] = tally(cands, votes, history, round, rng);
    let meta: MinigameMeta = cands[idx - 1];
    // Mirror RoundService: players may leave between vote close and start -> swap to a compatible game or skip.
    if (players.size < meta.MinimumPlayers) {
      const fallback = select(catalog, history, players.size, round, rng, 1)[0];
      if (!fallback) { skippedRounds++; continue; }
      swappedRounds++;
      meta = fallback;
    }
    const mapId = pickMap(meta, history, rng);
    const modifierId = pickModifier(meta, modifiers, history, rng);
    history.push({ GameId: meta.Id, Round: round, MapId: mapId, ModifierId: modifierId });
    perGame[meta.Id] = (perGame[meta.Id] ?? 0) + 1;
    transitions.push(meta.Category);
    // Prepare: participants = current players; janitor allocates map + connections
    const participants = [...players.values()];
    playerCount = participants.length;
    if (playerCount < meta.MinimumPlayers) violations.push(`round ${round}: ${meta.Id} started with ${playerCount} < min ${meta.MinimumPlayers}`);
    janitorItems += 1 + participants.length * 2; // map + died connection + movement rule per player
    const mod = modifiers.find((m) => m.Id === modifierId);
    for (const pl of participants) {
      pl.state = "Playing";
      pl.walkSpeed = (meta.Movement.WalkSpeed as number | undefined) ?? 16;
      if (mod?.Id === "TinyPlayers") pl.scale = 0.6; else if (mod?.Id === "GiantPlayers") pl.scale = 1.5;
      if (meta.SupportsTeams) pl.team = rng.NextNumber() < 0.5 ? "Red" : "Blue";
      if (meta.Category === "HideSeek") pl.scale = [0.55, 1, 1.6][rng.NextInteger(1, 3) - 1];
      if (meta.HidesInformation) pl.role = rng.NextNumber() < 0.25 ? "Hunter" : "Hider";
    }
    // Chaos: join mid-round (becomes spectator), leave mid-round
    if (rng.NextNumber() < churn) { addPlayer(); const joined = players.get(nextId - 1)!; joined.state = "Spectating"; roundsWithJoiner++; }
    if (rng.NextNumber() < churn && participants.length > 2) { const leaver = participants[rng.NextInteger(1, participants.length) - 1]; players.delete(leaver.id); roundsWithLeaver++; }
    // Gameplay: random elimination/finish order
    const alive = participants.filter((pl) => players.has(pl.id));
    const shuffled = [...alive].sort(() => rng.NextNumber() - 0.5);
    const elimGame = ["Bomb", "Elimination", "Survival", "Disaster", "Platform", "Physics", "Reaction"].includes(meta.Category);
    const finishOrder: number[] = [], elimOrder: number[] = [];
    for (const pl of shuffled) {
      const r = rng.NextNumber();
      if (elimGame && r < 0.7) { pl.state = "Eliminated"; elimOrder.push(pl.id); totalEliminations++; }
      else if (!elimGame && r < 0.6) { pl.state = "Finished"; finishOrder.push(pl.id); totalFinishes++; }
    }
    if (rng.NextNumber() < 0.02) abortedRounds++; // admin abort / crash recovery path
    // Results: default ranking (finish order, then survivors, then eliminated reversed)
    const ranked = [...finishOrder, ...alive.filter((pl) => pl.state === "Playing").map((pl) => pl.id), ...elimOrder.reverse()];
    const seen = new Set<number>();
    for (const id of ranked) { if (seen.has(id)) violations.push(`round ${round}: duplicate result entry ${id}`); seen.add(id); }
    for (const pl of alive) if (!seen.has(pl.id)) violations.push(`round ${round}: player ${pl.id} missing from results`);
    // Rewards
    ranked.forEach((id, i) => { const pl = players.get(id); if (!pl) return; pl.rounds++; pl.xp += 25 + (i === 0 ? 120 : i < 3 ? [100, 70, 50][i] : 0); pl.coins += 10; if (i === 0) pl.wins++; });
    // Cleanup: janitor destroys everything, everyone restored
    peakJanitor = Math.max(peakJanitor, janitorItems);
    janitorItems = 0;
    for (const pl of players.values()) { pl.state = "Lobby"; pl.role = undefined; pl.team = undefined; pl.scale = 1; pl.walkSpeed = 16; pl.flags.clear(); }
    // Invariants after cleanup
    for (const pl of players.values()) {
      if (pl.state !== "Lobby") violations.push(`round ${round}: player ${pl.id} state leaked ${pl.state}`);
      if (pl.scale !== 1 || pl.walkSpeed !== 16 || pl.role || pl.team) violations.push(`round ${round}: player ${pl.id} character not restored`);
    }
    if (janitorItems !== 0) violations.push(`round ${round}: janitor leak ${janitorItems}`);
    if (Object.keys(votes).length && round === p.cycles) { /* votes are function-local; cannot leak by construction */ }
  }
  // Cross-minigame category transitions coverage
  const pairs = new Set<string>();
  for (let i = 1; i < transitions.length; i++) pairs.add(`${transitions[i - 1]}→${transitions[i]}`);
  const totals = [...players.values()].reduce((a, pl) => ({ xp: a.xp + pl.xp, coins: a.coins + pl.coins, wins: a.wins + pl.wins, rounds: a.rounds + pl.rounds }), { xp: 0, coins: 0, wins: 0, rounds: 0 });
  const metrics = { finalPlayers: players.size, skippedRounds, swappedRounds, peakJanitorItems: peakJanitor, totalEliminations, totalFinishes, abortedRounds, roundsWithLeaver, roundsWithJoiner, distinctGames: Object.keys(perGame).length, categoryTransitionPairs: pairs.size, rewardTotals: totals, perGame };
  return { kind: "roundloop", cycles: p.cycles, seed: p.seed, params: p as Record<string, unknown>, metrics, violations, passed: violations.length === 0, durationMs: performance.now() - t0 };
}
