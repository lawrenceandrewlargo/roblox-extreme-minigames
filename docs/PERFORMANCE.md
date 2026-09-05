# Performance

## Budget and choices
- Minigame `Update` runs at ~10 Hz (accumulated Heartbeat), not per frame.
- Vote scanning ~6 Hz; anti-cheat 2 Hz; karts 20 Hz drive loop per kart; NPC crowd 0.67 Hz decision loop with `Humanoid:MoveTo` (physics does the walking).
- No `RenderStepped` on the client except the admin fly/noclip step (owner only).
- Proximity checks use cheap `Magnitude`/local-space bounds; no raycasts in hot loops except lightning cover checks (≤ 1 per 3 s) and Prop Hunt shots (per click).
- All temporary instances are created under `Workspace.ActiveMap` and destroyed together; `Janitor.ActiveCount()` and `ActiveMap` child count are inspectable via `CleanupDiagnostics`.
- Remote traffic: phase/vote/HUD events are batched (`VoteCountsChanged` only on change; `BombTick` once per second; `TeamScore`/`Payload` per tick could be reduced to 2 Hz if profiling shows cost).
- Tile grids: max 144 parts (MeteorShower 12×12), 243 for FallingPlatforms (3×81) — well within budgets.
- Boulders auto-destroy after 14 s; meteors/shadows destroy themselves.

## Recommendations for Studio profiling
MicroProfiler during KartRace (16 karts), FallingPlatforms (24 players), DisasterSurvival (Meteors + Destroys). Watch `Stats:GetTotalMemoryUsageMb()` across 20 rounds via `InspectServer`; expect flat memory.
