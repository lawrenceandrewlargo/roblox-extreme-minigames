# Migration Guide

## Switching sync tools
- **Argon → Rojo**: no changes; `rojo serve` reads the same `default.project.json`.
- **Rojo/Argon → Script Sync**: sync the three `src/*` folders individually; delete the `Remotes`/`Assets` folders from the project file's responsibilities (Studio owns them).
- **Script Sync → Argon**: stop Script Sync on each folder first to avoid double-writes.

## Moving maps from Studio into the repo
Select the map Model in Studio → right-click → *Save to File…* → `roblox/assets/maps/<MapId>.rbxm`. Commit. Rojo/Argon insert it under `ReplicatedStorage.Assets.Maps`.

## Schema migrations (player data)
Bump `GameConfig.Data.SchemaVersion`, add `Migrations[oldVersion] = function(profile) ... end` in `DataService.luau`. Migrations run sequentially on load; never delete old migration functions.

## Upgrading toolchain versions
Edit `rokit.toml`, run `rokit install`, run `lune run tests/run`, then commit.

## Moving the web command center to a new database
Set `DATABASE_URL`, run `npx drizzle-kit push`; tables are recreated and the dashboard re-seeds baselines on first load.
