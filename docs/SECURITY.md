# Security

## Server authority
Winners, scores, eliminations, checkpoints, laps, bomb ownership, rewards, XP/coins, teams, votes and progression are computed only on the server. Clients send *intents* (Punch, Pull, Accuse, Shoot direction, Fling direction, ChooseSize, SwapProp) through one remote; the active minigame validates phase, role, cooldown and distance.

## Controls
- **Rate limiting**: per-player, per-remote token bucket (12/s) in `Remotes`; excess is dropped and logged.
- **Payload validation**: every handler type-checks arguments; unknown commands/ids are rejected; numbers are clamped (`num()` in AdminService).
- **Voting**: no vote remote exists; votes derive from server overlap scans.
- **Movement**: `AntiCheatService` samples positions at 2 Hz; horizontal displacement beyond `WalkSpeed × 1.35 × dt + slack` or > 80 studs without a server teleport flag is reverted and flagged. Server teleports call `MarkTeleport`; knockbacks set a `Launched` flag. Admins using movement tools are explicitly exempt.
- **Bomb transfers**: server proximity ≤ 4.5 studs plus `WithinDistance` ≤ 12 check; cooldown after each pass.
- **Checkpoints**: ordered; skipping more than `MaxCheckpointSkip` flags the player.
- **Prop Hunt shots**: raycast origin is the server-side head position; the client only supplies a direction; ammo is server-tracked.
- **Rewards**: computed from server results; profiles are server-owned; cosmetic purchases check ownership and balance.
- **Admin**: server role table, category rank gate, confirmation for dangerous actions, audit log, no secrets in replicated code.
- **Data**: failed loads mark the session no-save to avoid overwriting good data; `UpdateAsync` refuses to downgrade a newer schema.

## Tested intentionally-malformed inputs (code paths)
Invalid vote index (ignored by tally), stale vote after leave (removed), unknown game id in ForceMinigame (assert), non-number args (clamped/default), remote spam (bucket), non-Vector3 shoot direction (ignored), accuse outside range (no-op), swap with no swaps left (ignored).

## Not covered / roadmap
Server-side hitbox validation for exotic exploits (teleport-during-knockback windows), speculative anti-fly heuristics for non-admins beyond speed checks, and an external ban list (DataStore or Open Cloud) instead of per-server bans.
