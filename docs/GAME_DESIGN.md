# Game Design — Party Chaos

## Pillars
1. **Sixty-second stories.** Every round should produce at least one "did you see that" moment.
2. **Read it in three seconds.** A player joining mid-session must understand any minigame from its one-line description and first five seconds.
3. **Everyone is always doing something.** Eliminated players spectate instantly; the lobby *is* the voting game.
4. **Skill with slack.** Outcomes reward skill but leave room for comebacks and comedy.
5. **Phone first, controller always.** No precise aiming; one primary action button; B/Escape closes anything.

## Session loop
Lobby → Intermission (12 s) → **Physical voting** (20 s) → Map selection → Intro card (5 s) → Countdown (3) → Gameplay (90–150 s) → Results (8 s) → Rewards (4 s) → Lobby.

Total dead time between rounds ≈ 50 s, of which 20 s is the interactive voting mini-activity.

## Player emotions per category
| Category | Core feeling | Example moment |
|---|---|---|
| Bomb | Dread → relief | Passing the bomb with 1 s left |
| Tag | Pursuit | Thawing a friend while the tagger turns around |
| Hide/Prop/Deception | Suspense | A "crate" bolting when the hunter turns away |
| Obby/Speedrun | Flow | Nailing the shortcut as the floor crumbles |
| Kart | Speed | Drift-boosting into a bomb pass |
| Survival/Disaster | Panic | Climbing as the flood swallows the roof |
| Reaction/Memory | Focus | Standing still through a fake color call |
| Platform/Physics | Slapstick | Getting punched off with two lives left |
| Team | Belonging | The last plank placed under fire |

## Body-size design (Hide & Seek)
Small: 0.55 scale, 12 walk speed, fits `SmallGate` passages. Normal: 1.0 / 16. Large: 1.6 scale, 20 speed, 9.5 jump height, pushed out of `SmallGate` zones. Choice is made during the 12-second hide phase and locked once seekers release — a real strategic commitment.

## Movement rules
Declared per minigame (`Movement` in the catalog): `BASIC` (jump only), `FREE` (sprint + slide), `PARKOUR` (sprint + slide + dash), `NOJUMP` (deception & karts). The client enables inputs only when the server sends the rule set; the server's anti-cheat allows the resulting speeds.

## Modifiers (12)
Data-driven in `Config/Modifiers.luau`; each minigame whitelists compatible modifiers. Modifiers never count as separate games.

## Shareable-moment engineering
Explosions broadcast a banner, last-second escapes are visible to spectators, meteors telegraph so near-misses are legible, team wins announce the winning team, and results show placements with crowns.
