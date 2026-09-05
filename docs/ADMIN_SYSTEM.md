# Admin System

## Authorization
`roblox/src/server/Admin/AdminConfig.luau` (server-only): `Users = { [UserId] = "Owner" | "SuperAdmin" | "Admin" | "Moderator" | "Tester" }`. In Studio the local player is Owner (`StudioLocalPlayerIsOwner`). Every command has a category; `CategoryRank` maps categories to the minimum role. The client never decides permissions — the server sends each admin only the commands they may run, and re-checks on every invocation.

## Command registry (60+)
Round: SkipPhase, ForceVoting, EndRound, AbortRound⚠, ForceMinigame(gameId,mapId,modifierId), RestartMinigame, RerollVotes, AddTime.
Server: ReturnAllToLobby, ShutdownServer⚠.
Teleport: Goto, Bring, TeleportToLobby, TeleportToMap, TeleportToPosition, SaveWaypoint, GotoWaypoint (with raycast floor validation).
Player: Kill, Respawn, Heal, Damage, Freeze, Unfreeze, Ragdoll, Sit, Stand, ForceField, Invisible, Visible, SetScale, ResetCharacter, Spectate, Unspectate.
Movement: Fly(enabled,speed), Noclip, InfiniteJump, WalkSpeed, JumpHeight, ResetMovement; World: Gravity.
Gameplay: EliminatePlayer, ForceFinish, SetScore, GiveBomb, TagPlayer, RevealHidden, TriggerHazard, CompleteCheckpoint, SetTeam, SetRole.
World/Debug: ShowMarkers, ReloadMap, InspectRound, InspectMinigame, InspectVotes, InspectPlayers, InspectServer, AuditLog, SetLogLevel.
Testing: GrantCurrency, ResetProgression⚠, SimulateVictory, CleanupDiagnostics.
Moderation: Kick⚠, ServerBan⚠, Warn, Announce.

⚠ = dangerous → requires `confirmed = true` (panel shows a confirmation dialog).

## Audit
Every invocation (allowed or rejected) is appended to a 500-entry ring buffer with admin id, command, args, success and timestamp, and logged as `[AdminAudit]`. Secrets are never logged.

## Adding a command
```lua
AdminService:Register({ Name = "MyCmd", Category = "Testing", Description = "...", Args = { "target", "amount" }, Run = function(admin, args) ... return "ok" end })
```
The panel updates automatically.
