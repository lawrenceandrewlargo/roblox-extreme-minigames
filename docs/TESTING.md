# Testing

## Automatically executed in this build
| Layer | Tool | Result |
|---|---|---|
| Parse every Luau file (84) | `luau-ast` | 0 errors |
| Undefined identifier scan | `luau-analyze` (no defs) | only engine globals reported |
| Static validation (catalog↔module parity, Ids, Start fn, strict mode, metadata ranges, modifiers valid, category caps ≤ 20%, remote-name parity client & server, bootstrap order, no module-level state) | Lune | pass |
| Unit tests (Signal, Janitor, Timer, TableUtil, RewardMath, CandidateSelector.Select/Tally/PickMap/PickModifier) | Lune | pass |
| Voting simulation 1,000 cycles (random 2–24 players, ties, zero-vote rounds, disconnects) | Lune (real Luau) | 0 repeats, 0 cooldown violations, all games played |
| Voting simulation 100 / 500 / 1,000 / 5,000 | TypeScript port | PASS |
| Round-loop simulation 100 / 500 / 1,000 with 25% join/leave churn | TypeScript | PASS — found & fixed the post-vote min-player gap |
| Web app | `tsc`, `next build`, health check | pass |

Run locally: `cd roblox && lune run tests/run`. Record to the dashboard: `POST /api/tests` with the output.

## Requires Roblox Studio (cannot be executed headlessly)
Physics (karts, knockback, boulders), character scaling visuals, BillboardGui readability, touch/controller input, DataStore round-trips, replication timing, multi-client join/leave during real rounds, UI window behaviour, 100+ live round soak. Use `FINAL_PLAYTEST_GUIDE.md` and the admin `CleanupDiagnostics`/`InspectServer` commands.

## Failure injection covered by design
Player leaves during voting (vote removed), while holding bomb (bomb re-assigned), before results (ranked by recorded state), joins mid-round (spectator), map missing (fallback map), minigame error in Start/Update/Finish (round ends, default result), round crash (loop recovers), remote spam (bucket), invalid admin payloads (rejected + audited).
