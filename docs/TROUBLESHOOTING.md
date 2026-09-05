# Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Output: `Missing service module X` | Bootstrap order names a file that doesn't exist | Check `Services/` and `Admin/` folder names; run `lune run tests/run` (static test catches this) |
| `Minigame X missing from MinigameCatalog` | Module Id not in catalog | Add `def({...})` entry |
| Voting platforms don't appear | No `Workspace.Lobby` folder | Create Folder `Lobby` with a SpawnLocation; platforms build at Z = −40 relative to origin |
| Vote count doesn't change when standing on a platform | Character has no HumanoidRootPart or platform Y bounds | Stand on the top surface; check platform Size/Position; watch `[Debug][Voting]` with `SetLogLevel Debug` |
| Map is a plain grey disc | Map asset missing → fallback | Add Model `ReplicatedStorage/Assets/Maps/<MapId>` with a `Spawns` folder |
| Players keep speed/size after a round | A minigame changed the Humanoid without PlayerStateService | Use `PlayerStateService:SetMovement/SetScale`; `ResetCharacter` admin command as a stopgap |
| `DataStore unavailable` warning in Studio | API access disabled | Game Settings → Security → Enable Studio Access to API Services |
| Admin panel doesn't open with F9 | Not authorised | In Studio you are Owner automatically; live: add your UserId to `AdminConfig.Users` |
| `confirm_required` from an admin command | Dangerous command needs confirmation | Use the panel (shows a dialog) or send `confirmed = true` |
| Anti-cheat rubber-bands an admin flying | Exempt flag not set | Use the `Fly`/`WalkSpeed` commands (they set exemption) rather than editing Humanoid manually |
| `argon serve` says port in use | Another Argon/Rojo instance | `argon serve --port 8001` |
| `lune run tests/run` → `Virtual instance has no child` | A `require(script.Parent.X)` path is wrong | Fix the path; the harness mirrors folder structure exactly |
| Karts don't move | Seat not occupied / network ownership | Ensure the player character exists before `Karts.SpawnAll`; check `Seat:Sit` fired |
| Web dashboard: `DATABASE_URL is required` | `.env` missing | Copy `.env.example` or set the variable |
