# Development Tooling Decision

## Options evaluated (state of the ecosystem, early 2026)

| Tool | Type | Two-way sync | Full DataModel (maps/UI/terrain) | Git-friendly | Team Create | Setup | Notes |
|---|---|---|---|---|---|---|---|
| **Roblox Studio only** | Editor | n/a | Yes | No (binary place) | Yes | None | Source of truth is the cloud place; no diffs, no AI editing |
| **Script Sync** (official, beta) | Studio feature | Yes (scripts, LocalScripts, ModuleScripts, Folders) | No | Yes for scripts | Yes | Right-click → Sync | Barebones; no project file; no packages |
| **Rojo 7.5** | Build/sync CLI + plugin | One-way (FS → Studio); two-way experimental | Yes via `.rbxm` / JSON models | Yes | Limited | Medium | De-facto standard; `default.project.json` |
| **Argon 2** | CLI + VS Code ext + plugin | **Yes, first-class** | Yes (Rojo-compatible project) | Yes | Limited | Low-medium | Spiritual successor to Rojo; friendlier |
| **Azul** | Plugin + CLI | Yes, 1:1 mirror | Mirrors whole tree | Yes | Unknown | Low | No project.json; newer, smaller community |
| **RbxSync** | Sync | Yes | Partial | Yes | — | Medium | Less active |
| **Lune** | Headless Luau runtime | — | — | — | — | Low | Tests without Studio |
| **Rokit** | Toolchain manager | — | — | Yes (`rokit.toml`) | — | Low | Successor to aftman |
| **luau-lsp / selene / StyLua** | Types / lint / format | — | — | Yes | — | Low | Editor quality |
| **Open Cloud API** | Publishing | — | — | — | — | Medium | `POST /universes/{id}/places/{id}/versions` for CI publish |
| **MCP servers (Argon/community)** | AI integration | — | — | — | — | Medium | **Not reachable from Arena AI** (sandboxed, no local socket) |

## Decision
1. **Code source of truth = this repository** in a Rojo/Argon-compatible layout (`roblox/default.project.json`). This is readable by Rojo, Argon and (folder-by-folder) Script Sync, so the owner can switch tools without touching game code.
2. **Recommended daily driver: Argon** (VS Code extension + Studio plugin) for two-way sync — edits from Claude land in the repo and flow into Studio; small tweaks made in Studio flow back.
3. **Rojo** remains the CI/build path (`rojo build -o build/PartyChaos.rbxl`) because it is the most stable headless builder.
4. **Script Sync** is the zero-install beginner path documented in `COMPLETE_SETUP_GUIDE.md` (Beginner Path).
5. **Lune + luau-ast** provide headless verification (used in this build: 84 files parsed, 17 tests executed).
6. **Maps, lighting, terrain, UI art** are authored in Studio and exported as `.rbxm` into `roblox/assets/maps/<MapId>.rbxm`; Rojo/Argon place them under `ReplicatedStorage.Assets.Maps`.

## Why not X
- *Rojo alone*: no comfortable two-way flow for Studio-side map tweaks.
- *Azul alone*: no project file means the tree layout would be implicit; community/tooling smaller; reports of file-creation edge cases.
- *MCP-driven workflow*: Arena AI cannot connect to a local MCP server; building around it would leave the AI blind.

## Game architecture independence
Nothing in `roblox/src` references Rojo, Argon or any sync tool. Only `default.project.json` and `rokit.toml` are tooling-specific.
