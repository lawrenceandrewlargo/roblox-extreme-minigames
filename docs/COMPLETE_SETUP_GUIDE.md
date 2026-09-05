# Complete Setup Guide (Windows)

Assumes no prior knowledge of Git, Roblox Studio, Rojo/Argon, or the terminal. Every command lists *where*, *what*, *why*, *expected*, *if it fails*.

## Part A — Accounts and Studio
1. Create/sign in to a Roblox account at roblox.com.
2. Install **Roblox Studio**: roblox.com/create → *Start Creating* → run the installer.
3. In Studio: *New* → *Baseplate*. Then **File → Publish to Roblox As…** → *Create new experience* → name it *Party Chaos*. Studio shows the **Place ID** in the URL and in *Game Settings → Basic Info*. Write down **Universe ID** and **Place ID** (Creator Dashboard → your experience → the number in the URL is the Universe ID).
4. In *Game Settings → Security* enable **Enable Studio Access to API Services** (needed for DataStores in Studio tests).
5. Insert a **SpawnLocation** inside a Folder named `Lobby` in Workspace (the voting platforms auto-build in front of it).

## Part B — Install developer tools

### B1. Git
```
Location: any
Command:  winget install --id Git.Git -e
Purpose:  version control
Expected: "Successfully installed"
If fails: download from git-scm.com and run the installer with defaults
```

### B2. VS Code
```
Command:  winget install --id Microsoft.VisualStudioCode -e
Expected: VS Code opens from Start menu
```
Extensions to install inside VS Code: **Luau Language Server** (JohnnyMorganz), **Argon**, **StyLua**, **Selene**.

### B3. Rokit (toolchain manager — installs Argon, Rojo, Lune, selene, StyLua for you)
```
Location: PowerShell
Command:  irm https://github.com/rojo-rbx/rokit/releases/latest/download/rokit-windows-x86_64.zip -OutFile rokit.zip; Expand-Archive rokit.zip -Force; .\rokit\rokit.exe self-install
Purpose:  installs the `rokit` command and adds it to PATH
Expected: "Rokit has been installed successfully"
If fails: close and reopen PowerShell; confirm `rokit --version` prints a version. Otherwise download the zip manually from the Rokit GitHub releases page.
```

### B4. Clone the repository
```
Location: PowerShell, in the folder where you keep projects (e.g. C:\Dev)
Command:  git clone <YOUR_REPO_URL> party-chaos
          cd party-chaos\roblox
Expected: a folder with default.project.json, src/, tests/, rokit.toml
If fails: check the URL and that you are signed into GitHub (git will prompt)
```

### B5. Install the pinned toolchain
```
Location: party-chaos\roblox
Command:  rokit install
Purpose:  reads rokit.toml and installs argon, rojo, lune, selene, stylua, wally at pinned versions
Expected: each tool listed as installed; `argon --version`, `rojo --version`, `lune --version` all print versions
If fails: run `rokit trust argon-rbx/argon` etc. when asked to trust a tool, then rerun
```

## Part C — Choose a path

### Beginner Path (Script Sync, no CLI)
1. Open your place in Studio. **File → Beta Features → enable "Script Sync"** (restart Studio).
2. In Explorer: create Folders `ReplicatedStorage/Shared`, `ServerScriptService/Server`, `StarterPlayer/StarterPlayerScripts/Client`.
3. Right-click each folder → **Sync from File System…** → choose `roblox/src/shared`, `roblox/src/server`, `roblox/src/client` respectively.
4. Press **Play**. Script Sync mirrors every `.luau` file into Studio as ModuleScripts/Scripts (`*.server.luau` → Script, `*.client.luau` → LocalScript).
Limitation: maps must be inserted manually (`ReplicatedStorage/Assets/Maps/<MapId>`); missing maps use procedural fallbacks so the game still runs.

### Advanced Path (Argon two-way sync — recommended)
```
Location: party-chaos\roblox
Command:  argon plugin install
Purpose:  installs the Argon Studio plugin
Expected: "Plugin installed" — restart Studio and see the Argon toolbar button
```
```
Command:  argon serve
Purpose:  starts the sync server on localhost:8000
Expected: "Serving on 127.0.0.1:8000"
If fails: port in use → `argon serve --port 8001` and connect the plugin to that port
```
In Studio: Argon toolbar → **Connect**. The tree from `default.project.json` appears. Enable *two-way sync* in the plugin settings to pull Studio edits back into files.

### Rojo (build a place file)
```
Command:  rojo build -o build\PartyChaos.rbxl
Purpose:  produces a full place file you can open in Studio
Expected: build\PartyChaos.rbxl created
If fails: check default.project.json syntax with `rojo doc` and that src/ exists
```

## Part D — First test
1. With Studio connected, press **Play** (or **Test → Start** with 4 players for multiplayer).
2. Watch Output: `[Info][Bootstrap] Server ready with 37 minigames`.
3. Walk onto a voting platform; the sign's vote count should update.
4. Press **F9** to open the admin panel (in Studio the local player is Owner).

## Part E — Run the automated tests
```
Location: party-chaos\roblox
Command:  lune run tests/run
Purpose:  executes static validation, unit tests and the 1,000-cycle voting simulation
Expected: "17 passed, 0 failed"
If fails: read the ✗ lines; each names the assertion and file
```

## Part F — Publish
Studio: **File → Publish to Roblox**. For CI publishing use Open Cloud (see `NEW_MACHINE_SETUP.md` → Advanced).

## Part G — Grant yourself admin in a published game
Edit `roblox/src/server/Admin/AdminConfig.luau` → `Users = { [YOUR_USER_ID] = "Owner" }` (your User ID is in your profile URL). Commit and sync.
