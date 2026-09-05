# Party Chaos

Original Roblox party/minigame experience (37 minigames, physical in-world voting, full admin system) plus a fullstack **Command Center** dashboard.

- `roblox/` — the game (Rojo/Argon-compatible Luau project) and Lune tests. Start with `docs/COMPLETE_SETUP_GUIDE.md`.
- `docs/` — 20 design/ops documents. New AI or developer? Read `docs/AI_HANDOFF.md`.
- `src/` — Next.js + Drizzle + PostgreSQL command center: minigame library, large-scale voting/round-loop simulations, test history, documentation viewer.

```bash
# Luau tests
cd roblox && lune run tests/run
# Command center
npm install && npx drizzle-kit push && npm run dev
```
