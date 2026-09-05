# Disaster Recovery

| Scenario | Recovery |
|---|---|
| Local files lost | `git clone` again; `rokit install`; reconnect Argon. Nothing important lives only on disk. |
| Sync breaks / tree mangled in Studio | Stop Argon, `rojo build -o build/PartyChaos.rbxl`, open the fresh build, re-insert your maps from `assets/maps/*.rbxm`. |
| Map corrupted in Studio | Re-insert `assets/maps/<MapId>.rbxm` from Git; if the rbxm itself is bad, `git log -- roblox/assets/maps/<MapId>.rbxm` and `git checkout <sha> -- <path>`. |
| Studio place corrupted | Creator Dashboard → Places → *Version History* → restore a previous version, or publish a fresh `rojo build`. |
| Git history problems | `git reflog` to find the last good commit; `git reset --hard <sha>`; if the remote is damaged, force-push from a healthy clone. |
| Published content wrong | Version History rollback (Creator Dashboard) — instant. |
| Accidentally deleted an asset | Assets in Git: `git checkout -- <file>`. Roblox-uploaded assets (audio/mesh) remain in your inventory; re-link the id. |
| Tooling stops working after an update | Pin the previous version in `rokit.toml` and `rokit install`. |
| Player data corrupted | DataStore versioning: `DataStoreService:GetDataStore(...):ListVersionsAsync(key)` and restore a version; migrations are idempotent. |
| Web command center DB lost | `npx drizzle-kit push`; dashboard re-seeds baselines automatically. |

Backups: Git remote (code, config, docs, rbxm maps); Roblox Version History (published place); DataStore versioning (player data). Verify quarterly by restoring into a test place.
