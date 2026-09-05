# New Machine Setup (checklist)

1. Install Git, VS Code, Roblox Studio (see COMPLETE_SETUP_GUIDE Part A–B).
2. `git clone <repo>` → `cd roblox` → `rokit install`.
3. VS Code extensions: Luau LSP, Argon, StyLua, Selene.
4. `argon plugin install` → restart Studio.
5. Open the experience's place in Studio (File → Open from Roblox).
6. `argon serve` → Studio → Argon → Connect.
7. `lune run tests/run` → expect all green.
8. Optional web command center: from repo root `npm install`, set `DATABASE_URL` in `.env`, `npx drizzle-kit push`, `npm run dev` → http://localhost:3000.

## Advanced: CI publish with Open Cloud
Create an API key (Creator Dashboard → Open Cloud → API Keys) with *universe-places:write* for your experience. Store it as a CI secret `ROBLOX_API_KEY` — **never commit it**.
```
rojo build -o build/PartyChaos.rbxl
curl -X POST "https://apis.roblox.com/universes/v1/$UNIVERSE_ID/places/$PLACE_ID/versions?versionType=Published" -H "x-api-key: $ROBLOX_API_KEY" -H "Content-Type: application/octet-stream" --data-binary @build/PartyChaos.rbxl
```
Expected: JSON with `versionNumber`. If 401 → key scope; if 400 → file path.
