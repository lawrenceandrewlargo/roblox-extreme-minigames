import { readFileSync } from "node:fs";
import path from "node:path";

export type MinigameMeta = {
  Id: string;
  DisplayName: string;
  Description: string;
  Category: string;
  SecondaryCategory?: string;
  MinimumPlayers: number;
  MaximumPlayers: number;
  Duration: number;
  VoteCooldownRounds: number;
  SupportsTeams: boolean;
  HidesInformation: boolean;
  Maps: string[];
  AllowedModifiers: string[];
  Movement: Record<string, boolean | number>;
};

export type ModifierDef = { Id: string; DisplayName: string; Description: string; Weight: number };

const ROOT = process.cwd();
export const ROBLOX_DIR = path.join(ROOT, "roblox");
export const DOCS_DIR = path.join(ROOT, "docs");

const DEFAULT_MODIFIERS = ["None", "TinyPlayers", "GiantPlayers", "LowGravity", "HighSpeed", "Darkness", "Fog"];
const MOVEMENT: Record<string, Record<string, boolean>> = {
  FREE: { Sprint: true, Slide: true, Dash: false, Jump: true },
  BASIC: { Sprint: false, Slide: false, Dash: false, Jump: true },
  NOJUMP: { Sprint: false, Slide: false, Dash: false, Jump: false },
  PARKOUR: { Sprint: true, Slide: true, Dash: true, Jump: true },
};

function str(body: string, key: string): string | undefined {
  const m = body.match(new RegExp(`\\b${key}\\s*=\\s*"([^"]*)"`));
  return m?.[1];
}
function num(body: string, key: string): number | undefined {
  const m = body.match(new RegExp(`\\b${key}\\s*=\\s*(\\d+)`));
  return m ? Number(m[1]) : undefined;
}
function list(body: string, key: string): string[] | undefined {
  const m = body.match(new RegExp(`\\b${key}\\s*=\\s*\\{([^}]*)\\}`));
  if (!m) return undefined;
  return [...m[1].matchAll(/"([^"]+)"/g)].map((x) => x[1]);
}
function bool(body: string, key: string): boolean | undefined {
  const m = body.match(new RegExp(`\\b${key}\\s*=\\s*(true|false)`));
  return m ? m[1] === "true" : undefined;
}

let cache: { catalog: MinigameMeta[]; modifiers: ModifierDef[] } | null = null;

/** Parses the Luau catalog (single source of truth) into typed metadata. */
export function loadCatalog(): { catalog: MinigameMeta[]; modifiers: ModifierDef[] } {
  if (cache) return cache;
  const src = readFileSync(path.join(ROBLOX_DIR, "src/shared/MinigameCatalog.luau"), "utf8");
  const catalog: MinigameMeta[] = [];
  for (const m of src.matchAll(/def\(\{([\s\S]*?)\}\),?\n/g)) {
    const body = m[1];
    const Id = str(body, "Id");
    if (!Id) continue;
    const movementKey = body.match(/Movement\s*=\s*([A-Z]+)/)?.[1] ?? "BASIC";
    catalog.push({
      Id,
      DisplayName: str(body, "DisplayName") ?? Id,
      Description: str(body, "Description") ?? "",
      Category: str(body, "Category") ?? "Chaos",
      SecondaryCategory: str(body, "SecondaryCategory"),
      MinimumPlayers: num(body, "MinimumPlayers") ?? 2,
      MaximumPlayers: num(body, "MaximumPlayers") ?? 24,
      Duration: num(body, "Duration") ?? 90,
      VoteCooldownRounds: num(body, "VoteCooldownRounds") ?? 4,
      SupportsTeams: bool(body, "SupportsTeams") ?? false,
      HidesInformation: bool(body, "HidesInformation") ?? false,
      Maps: list(body, "Maps") ?? [],
      AllowedModifiers: list(body, "AllowedModifiers") ?? DEFAULT_MODIFIERS,
      Movement: MOVEMENT[movementKey] ?? MOVEMENT.BASIC,
    });
  }
  const modSrc = readFileSync(path.join(ROBLOX_DIR, "src/shared/Config/Modifiers.luau"), "utf8");
  const modifiers: ModifierDef[] = [];
  for (const m of modSrc.matchAll(/\{\s*Id = "([^"]+)", DisplayName = "([^"]+)", Description = "([^"]+)", Weight = (\d+)/g)) {
    modifiers.push({ Id: m[1], DisplayName: m[2], Description: m[3], Weight: Number(m[4]) });
  }
  cache = { catalog, modifiers };
  return cache;
}

export const VOTING_CONFIG = {
  CandidateCount: 3,
  DefaultCooldownRounds: 4,
  UnderplayedBonus: 0.75,
  OverplayedPenalty: 0.45,
  OverplayedThresholdMultiplier: 1.5,
};
