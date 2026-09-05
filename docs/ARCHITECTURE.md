# Architecture

```
roblox/
  default.project.json          Rojo/Argon tree
  src/shared/                   ReplicatedStorage.Shared
    Config/GameConfig.luau      all tunables
    Config/Modifiers.luau       round modifiers (data)
    Types.luau                  Luau types
    MinigameCatalog.luau        metadata for all 37 games (single source of truth)
    CandidateSelector.luau      pure voting/selection algorithm
    RewardMath.luau             pure reward/level math
    Utilities/{Signal,Janitor,Timer,Log,TableUtil}.luau
    Net/RemoteNames.luau        remote name registry
  src/server/                   ServerScriptService.Server
    Bootstrap.server.luau       service load order + minigame registration
    Services/                   Remotes, PlayerState, Map, Voting, Round, Minigame, Reward, Data,
                                Spectator, Announcement, AntiCheat, Party, Challenge, Cosmetic
    Admin/{AdminConfig,AdminService}.luau
    Systems/                    Arena, TileGrid, Teams, BombSystem, Checkpoints, Karts, NPCCrowd, Hazards
    Minigames/                  MinigameBase (contract doc) + 37 modules
  src/client/                   StarterPlayerScripts.Client
    Bootstrap.client.luau
    Controllers/                Net, UIController, HUD, VotingHUD, Spectator, Movement, Profile, AdminPanel
  tests/                        Lune harness + specs
  assets/maps/                  Studio-authored .rbxm maps (see MAP workflow)
```

## Service lifecycle
`Bootstrap.server` requires services in dependency order, calls `Init()` on each, then `Start()` in separate threads. A failing service logs and is skipped — one broken service must never kill the server.

## Round state machine (RoundService)
`Lobby → Intermission → Voting → MapSelection → Intro → Countdown → Gameplay → Results → Rewards → Lobby`.
`_runOneRound` is wrapped in `pcall`; on failure it aborts the minigame, unloads the map, cancels voting, resets players and resumes. Admin `Skip`, `Abort`, `Force(game,map,modifier)`, `AddTime` hooks are honoured at phase boundaries. Player count is re-validated after voting (fallback game or skip).

## Minigame lifecycle (MinigameService)
`Initialize → CanStart → LoadMap → PreparePlayers → Start → Update(≈10 Hz) → Finish → (RewardService) → Cleanup`.
Every run gets a fresh **context** (`ctx`) with its own `Janitor`, RNG, scores, elimination/finish order and helpers (`Eliminate`, `Finish`, `AddScore`, `Broadcast`, `Send`, `End`, `Modified`). Default end conditions: last standing (elimination games), all finished, or time-up. Default ranking: finish order → survivors by score → eliminated in reverse. Module-level state in minigames is forbidden (static test).

## Cleanup guarantee
`ctx.Janitor` owns every Instance, thread, connection and tween a minigame creates (`Arena.Part` auto-registers). `MinigameService:Cleanup` destroys it, then `MapService:Unload` clears `Workspace.ActiveMap`, `SpectatorService:StopAll`, `PlayerStateService:ResetAllToLobby` restores speed/jump/scale/transparency/collision and removes `Temporary`-tagged instances. `Janitor.ActiveCount()` is exposed to the admin panel for leak detection.

## Player state
`PlayerStateService` is the only writer of state (`Lobby/Playing/Eliminated/Spectating/Finished`), role, team, flags and character modifications; everything is reversible via `RestoreCharacter`.

## Networking
All remotes are created from `RemoteNames.luau`. Inbound calls pass through a per-player, per-remote token bucket (12/s). Minigame-specific client intents (Punch, Pull, Accuse, Shoot, Fling, ChooseSize, SwapProp) share one `MinigameEvent` remote; the active minigame validates role, cooldown, distance and phase before acting.

## Data
`DataService` loads/saves a versioned profile with migrations, retry/backoff, periodic saves, `BindToClose`, and a "no-save on failed load" guard against wiping data.

## Extensibility
Adding a minigame = (1) add metadata to `MinigameCatalog.luau`, (2) create `Minigames/<Id>.luau`, (3) optionally add a map model, (4) run `lune run tests/run`. No service edits.
