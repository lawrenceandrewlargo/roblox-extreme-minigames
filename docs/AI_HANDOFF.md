# AI Handoff — Party Chaos

Read this first. You do not need the original specification; this document plus the repo is sufficient.

## Project objective
An **original Roblox multiplayer party game**: lobby → *physical* in-world voting (stand on a platform) → one of 37 short chaotic minigames → results → rewards → lobby. Mobile + controller friendly, server-authoritative, extensible to 100+ minigames, with a full owner/admin system, progression, cosmetics, parties and spectating.

## Current state (release candidate, code complete; awaiting Studio verification + owner playtest)
- `roblox/` — complete Luau game (84 files): shared config/types/utilities, 15 server services, admin system (60+ commands), 8 reusable gameplay systems, 37 minigame modules, client controllers (UI window manager, HUD, voting HUD, spectator, movement, profile/shop/challenges/settings, admin panel).
- `roblox/tests/` — Lune harness + 17 tests (static validation, units, 1,000-cycle voting sim). **All green under a real Luau runtime.**
- Web **Command Center** (Next.js + Drizzle + PostgreSQL): parses the Luau catalog, runs voting/round-loop simulations (TS port of the selector), stores runs/tests/ADRs, serves docs. Routes: `/`, `/minigames`, `/simulations`, `/tests`, `/docs/[slug]`, `/handoff`; APIs: `/api/minigames`, `/api/simulations` (GET/POST), `/api/tests` (GET/POST), `/api/docs/[slug]`, `/api/health`.
- `docs/` — 20 documents.

## Architecture (short)
See `ARCHITECTURE.md`. Key: `RoundService` state machine → `VotingService` (overlap-scan votes) → `CandidateSelector` (pure) → `MinigameService` (per-round `ctx` + `Janitor`) → minigame module → `RewardService`/`DataService`. `PlayerStateService` is the sole writer of player state and character modifications. `AdminService` = single validated remote + registry + audit.

## Tooling decision
Repo is the code source of truth in a Rojo/Argon-compatible layout (`roblox/default.project.json`, `rokit.toml`). Argon recommended (two-way), Rojo for builds, Script Sync for beginners, Lune for headless tests. Maps are Studio-authored `.rbxm` in `roblox/assets/maps/`. Arena AI cannot use MCP/local sockets — do not depend on it. Details: `DEVELOPMENT_TOOLING_DECISION.md`.

## Setup / commands
| Where | Command | Purpose |
|---|---|---|
| `roblox/` | `rokit install` | toolchain |
| `roblox/` | `argon serve` / `rojo serve` | sync to Studio |
| `roblox/` | `rojo build -o build/PartyChaos.rbxl` | build place |
| `roblox/` | `lune run tests/run` | Luau tests (expect `17 passed, 0 failed`) |
| repo root | `npx drizzle-kit push` | create DB tables |
| repo root | `npm run build && npm start` | command center |
| sandbox only | `/tmp/luau-ast <file>` | parse check (download luau release zip) |

## Completed features
Core loop, physical voting, smart candidate selection, map/modifier rotation, 12 modifiers, minigame lifecycle with guaranteed cleanup, default ranking/results, rewards/levels, DataStore profiles with migrations, daily/weekly challenges + achievements, cosmetics shop, party system (invite/accept/leave; teams keep parties together), spectator service with hidden-info restriction, anti-cheat (rate limit, movement, checkpoint skip, bomb distance, raycast-origin shots), announcements, structured logs, admin system with roles/confirmation/audit, client UI stack, movement rules (sprint/slide/dash), admin fly/noclip/infinite jump.

## Completed minigames (37)
BombTag, HiddenTimerBomb, ReverseBomb, BombKart, FreezeTag, InfectionTag, CrownTag, SafeZoneTag, HideAndSeek, PropHunt, BlendIn, NPCPanic, SpeedRun, CollapsingObby, RandomRoute, KartRace, EliminationKart, DisasterSurvival, RisingFlood, MeteorShower, ColorSurvival, RedLightGreenLight, SimonSays, FallingPlatforms, FloorIsLava, RotatingArena, KnockbackArena, GiantBallSurvival, FanSurvival, RagdollRace, MemoryTiles, FindTheChange, SafeDoor, TugOfWar, PushThePayload, CaptureZone, BuildTheBridge. (`MINIGAMES.md` has mechanics.)

## Incomplete / not yet verifiable
- **Maps are placeholders** (procedural fallbacks); real maps must be authored in Studio.
- Client cosmetic renderers (trails/titles/confetti visuals) — attributes are set, visuals not drawn.
- Icons (`Icon` fields are `rbxassetid://0`), music/SFX.
- Final-round/overall-winner flow (optional in spec) not implemented.
- Kart handling is a simple hinge-motor arcade model; needs Studio tuning.
- Nothing has run inside Roblox Studio or a live server (see Testing status).

## Known bugs / risks (severity)
- (Med) Type-checker noise: files are `--!strict` but some annotations are loose (`any` contexts). luau-lsp with Roblox defs will show warnings, not runtime errors.
- (Med) `PlayerStateService:SetScale` relies on R15 scale NumberValues; R6 characters won't scale (Hide & Seek body sizes need R15 — set in Game Settings → Avatar).
- (Low) `HUDController` toasts for every eliminated player could spam in 24-player Simon Says; consider batching.
- (Low) Admin `Invisible` hides accessories only via BasePart transparency; layered clothing may remain.

## Testing status
Static: pass (luau-ast on 84 files, Lune static spec). Unit: pass (Lune). Voting sims: 1,000 (Lune) + 100/500/1,000/5,000 (TS) pass. Round-loop sims: 100/500/1,000 with churn pass (TS). Security/perf/UI/integration on device: **requires Studio** (see `TESTING.md`). Web: tsc + build + health pass.

## Important decisions (why)
1. Votes from overlap scans, never client messages → unspoofable, one-vote-per-body.
2. Per-round `ctx` + `Janitor`; module-level state banned by test → cleanup guaranteed, restart/abort trivial.
3. Catalog is a Luau file parsed by the web app → single source of truth, no drift.
4. Selector is pure and mirrored in TS → millions of simulated cycles without Studio.
5. Admin = registry + one remote → auditable, permission-gated, GUI auto-generated.

## Known limitations
No Studio/live execution from Arena AI; no MCP; physics/UI feel unverified; DataStores untestable headlessly; the luau-analyze build lacks Roblox definitions (identifier typos were checked by filtering engine globals).

## Source of truth
Code/config/docs/tests/rbxm maps → **Git repo**. Map authoring, lighting, terrain → **Studio**, exported to `roblox/assets/maps`. Published experience → **Roblox** (Version History). Player data → **Roblox DataStores**. Simulation/test history → **Command Center PostgreSQL** (disposable).

## Immediate next tasks
1. Owner: follow `COMPLETE_SETUP_GUIDE.md`, connect Studio, run one session, report `Output` warnings.
2. Fix anything Studio surfaces (most likely: API differences in `Karts`, R15 scaling, BillboardGui sizing).
3. Author 3 real maps (Courtyard, ColorGrid, SpeedwayOval) to validate the marker conventions (`Spawns`, `TeamSpawns/Red|Blue`, `Checkpoints`, `Objectives`, `HidingSpots/SmallGate`, `NPCNodes`, `SafeZones`, `KillZones`).
4. Add client cosmetic renderers.
5. Run the owner playtest (`FINAL_PLAYTEST_GUIDE.md`) and tune durations.

## Do not break
- Never trust client input for outcomes; minigame intents go through `MinigameEvent` and are validated by the active minigame.
- Never store minigame state at module level; use `ctx`.
- Every Instance/thread/connection a minigame creates must be on `ctx.Janitor`.
- Only `PlayerStateService` mutates Humanoid speed/jump/scale; always reversible.
- Every catalog Id has exactly one module and vice versa (test enforced).
- Remote names only in `RemoteNames.luau` (test enforced).
- Keep `CandidateSelector.luau` and `src/lib/sim/candidateSelector.ts` in sync when changing selection rules.
- `AdminConfig.luau` stays server-only; never move it under `shared/`.
- Run `lune run tests/run` before committing.
