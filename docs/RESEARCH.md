# Research

Research was conducted on genre patterns, public design knowledge, and the current (2026) Roblox tooling ecosystem. No source code, assets, maps, branding or UI from any existing experience was copied. Where a public experience is named it is only as a *genre reference*; all lessons are generalized.

## 1. Roblox experiences / genres studied (25)

| # | Experience or genre | What it teaches | Weakness / why players quit |
|---|---|---|---|
| 1 | Round-based minigame compilations (e.g. classic "Epic Minigames"-style) | Very short rounds (60–120 s) + huge variety keep sessions long; a voting/reveal beat before every game adds anticipation | Weak games drag the whole library down; players quit when the same 5 games repeat |
| 2 | Tag/bomb party games ("hot-potato" genre) | Proximity mechanics generate constant close calls; explosion moments are naturally shareable | Being eliminated early with nothing to do |
| 3 | Hide-and-seek genre | Asymmetry is fun when both sides have agency; hiding needs risk/reward decisions | Camping; seekers not finding anyone → dead time |
| 4 | Prop-hunt genre | Transformation + limited hunter resource (ammo/health) balances the asymmetry | Props that never move; rounds that end with nothing happening |
| 5 | NPC-deception / "blend in" genre | Observation and imitation are high-skill and very social | Hard to explain in 5 seconds; needs a strong tutorial line |
| 6 | Obby / tower genre | Checkpoints + visible progress; falls are funny when short | Long courses punish; players want <2 min segments |
| 7 | Speedrun / race genre | Podium (top 3) finishes keep mid-pack players motivated | Once the leader is far ahead, others disengage → add elimination/pursuit variants |
| 8 | Kart racing on Roblox | Drift/boost loops and ramps create skill expression even with simple physics | Bad collision handling and desync ruin it; keep karts network-owned by the driver |
| 9 | Natural-disaster survival genre | Telegraphed randomized hazards + a shared map produce collective panic | Some disasters are trivially survivable by standing still |
| 10 | Floor/tile games (color rush, falling tiles) | Instant readability; works on mobile; great spectator visuals | Pure RNG when the call time is too short |
| 11 | Red-light/green-light & Simon-says | Server-checked movement rules are cheap to run and cheat-resistant | Needs "fake-out" calls to stay interesting |
| 12 | Knockback / sumo arenas | Physics chaos is the best comedy generator | Excessive knockback removes skill; use lives + shrinking arena |
| 13 | Team objective modes (payload, zones, tug) | Group identity creates social moments and comebacks | Uneven teams; keep parties together but balance counts |
| 14 | Memory/puzzle micro-games | Cheap to build, huge variety, calms pacing between chaos games | Too many in a row feels slow → category rotation |
| 15 | Ragdoll physics games | Loss of control is intrinsically funny | Must be short (≤100 s) |
| 16 | Infection/zombie tag | Snowballing tension curve, natural end condition | Last survivor hunts can stall → speed scales with infected count |
| 17 | Crown/"king" holding modes | Constant target-switching, everyone has a goal at all times | Holder too fast = no steals; slow the king |
| 18 | Social hangout lobbies | Lobby activities between rounds retain players | Lobby time > 20 s feels dead → physical voting *is* the lobby activity |
| 19 | Progression-heavy games | XP/levels/dailies drive return visits | Pay-to-win kills fairness; keep cosmetic-only |
| 20 | Cosmetic economies | Trails/titles/victory effects are cheap status symbols | Too many currencies confuse players |
| 21 | Spectator systems in elimination games | Following friends after elimination keeps them in server | Leaking hidden info (hider positions) ruins asymmetric games |
| 22 | Mobile-first Roblox hits | One-thumb controls, large touch buttons, no precise aiming | Complex keybinds exclude ~60% of players |
| 23 | Console/controller support | D-pad/bumper navigation and B-to-close are expected | Menus that trap the cursor |
| 24 | Private servers / parties | Friends want to play together and stay on the same team | Parties splitting across teams |
| 25 | Admin-command experiences | Owners need instant control to test and moderate | Insecure admin remotes get exploited within hours |

Cross-cutting lessons adopted: rounds 90–150 s; intermission+voting ≤ 32 s; three candidates per vote; strict category rotation; eliminated players spectate immediately; everything readable on a phone; server authority for every consequential outcome.

## 2. Gameplay mechanics catalogue (100+)

**Tag (10):** proximity tag, freeze/thaw, infection spread, crown/king hold, safe zones with capacity, tag relay (baton), reverse tag (touch the tagger), speed swap on tag, invisible tagger pulse, tag cooldown.

**Bomb (10):** visible fuse, hidden fuse, blast radius, multi-bomb, reverse bomb (holding scores), bomb shrink-arena, bomb kart collision pass, bomb zones (only passable inside zones), bomb relay, bomb "pass back" lockout.

**Hide & Seek (8):** body size choice, small-only gaps, seeker release delay, hider score per second, hiding spot markers, sound chirp anti-camp, reveal pulse, seeker speed boost late-round.

**Prop Hunt (8):** prop transformation, limited swaps, hunter ammo with self-damage on miss, auto-taunt, chirp when idle, prop lock (freeze in place), prop size classes, hunter release delay.

**Deception (8):** NPC crowd with wander/idle, panic-flee behaviour, accusation with penalty, disguise attribute, monster role, NPC removal on wrong guess, movement-speed parity, no-jump parity.

**Obby / Speedrun (10):** checkpoints, respawn at checkpoint, risky shortcut, crumbling parts, rising lava, procedural segments (gaps/zigzag/pillars/movers/stairs), podium finish, fall penalty, moving pads, elimination on fall.

**Racing / Kart (10):** ordered checkpoints, lap counting, last-place elimination timer, drift boost, boost pads, ramps, kart respawn, kart destroy on elimination, network ownership, collision bomb pass.

**Survival / Disaster (10):** flood, lava rise, meteors with shadow telegraph, tornado wander, earthquake destructibles, lightning cover check, sinking platforms under load, shelter detection via raycast, double-disaster rounds, disaster warning banners.

**Reaction (8):** color call, fake color switch, red/green light velocity check, yellow fake-out, Simon says with impostor commands, shrinking windows, per-command detection (jump/still/left/right/forward), zap elimination.

**Platform (8):** tile drop on touch delay, multi-layer grids, lava pulse phases, sinking furniture, sweeping arms low/high, duck pads, rotating speed ramp, tile paint refresh.

**Physics (8):** punch knockback with facing check, lives, shrinking disc, rolling boulders, fans with direction warning, handholds, ragdoll platform-stand, stamina-limited fling.

**Memory (8):** flashed safe path, wrong-tile drop, room object change (move/recolor/resize), blackout phase, first-touch claim, door hint symbols, trapdoor return, reveal answer.

**Team (10):** party-aware balanced assignment, rhythm-prompt tug, missed-prompt penalty, payload push by majority, contest state, zone capture, zone rotation, plank carry, plank steal, bridge slot placement.

**Meta (10):** physical voting platforms, candidate cooldowns, category diversity weighting, under/over-played weights, map LRU, modifier rotation, spectator cycling, round modifiers (12), challenge tracking, admin hooks per game.

## 3. Candidate minigames evaluated (50) → 37 kept

Scoring (1–5) on: simplicity, fun, replay, skill, social, spectator, chaos, humour, mobile, controller, originality, feasibility, performance.

| Candidate | Verdict | Reason |
|---|---|---|
| Bomb Tag | **Keep** | Core hot-potato, high chaos |
| Hidden Fuse | **Keep** | Distinct tension model + shrinking arena |
| Hot Treasure (reverse bomb) | **Keep** | Inverted incentive, constant steals |
| Bomb Kart | **Keep** | Karts + bomb is a different skill set |
| Multi Bomb | Reject → modifier | Only differs by count → `DoubleBomb` modifier |
| Bomb Zones | Reject | Confusing rule; low mobile clarity |
| Bomb Parkour | Reject | Obby + bomb overlaps CollapsingObby chaos |
| Team Bomb | Reject | Team-tag rules unclear in 5 s |
| Bomb Relay | Reject | Stalls when a team is eliminated |
| Freeze Tag | **Keep** | Rescue mechanic = social |
| Outbreak (infection) | **Keep** | Snowball curve |
| Crown Keeper | **Keep** | Everyone always has a target |
| Safe Zone Tag | **Keep** | Zone capacity creates betrayals |
| Advanced/parkour tag | Reject → movement rules | Movement is a rule set, not a game |
| Tag Relay | Reject | Baton hand-off ambiguous with touch tag |
| Hide & Seek (body size) | **Keep** | Size choice is a real decision |
| Prop Hunt | **Keep** | Ammo cost + anti-camp |
| Blend In | **Keep** | Strong social/observation play |
| NPC Panic | **Keep** | Inverse roles, imitation under pressure |
| Criminal among NPCs | Reject | Too close to Blend In |
| Speed Run | **Keep** | Podium racing baseline |
| Collapse (collapsing obby) | **Keep** | Pressure from behind |
| Random Route | **Keep** | Procedural, infinite variety |
| Shortcut Race | Reject → map feature | Shortcuts belong in SpeedRun maps |
| Moving Obby | Reject → segment | Folded into RandomRoute "Movers" |
| Kart Race | **Keep** | Laps + drift |
| Last Kart (elimination) | **Keep** | Pressure timer |
| Kart Survival / Arena | Reject | Collision-only karts felt aimless |
| Disaster Island | **Keep** | Random pairs of 5 disasters |
| Rising Flood | **Keep** | Sinking-under-load platforms are social |
| Meteor Shower | **Keep** | Permanent floor deletion |
| Runaway Train | Reject | Needs bespoke map animation; roadmap |
| Color Rush | **Keep** | Fake calls |
| Red Light Green Light | **Keep** | Server-checked velocity |
| Simon Says | **Keep** | Five detectable actions |
| Freeze Dance | Reject | Same detection as RLGL |
| Wrong Direction | Reject | Confusing on controller |
| Falling Platforms | **Keep** | Three layers |
| Floor Is Lava | **Keep** | Sinking furniture |
| Spin Cycle | **Keep** | Jump/duck dual threat |
| Conveyor Panic | Reject | Physics conveyors unreliable → roadmap |
| Knockback Arena | **Keep** | Lives + shrink |
| Boulder Run | **Keep** | Slope physics |
| Wind Tunnel | **Keep** | Handholds |
| Ragdoll Downhill | **Keep** | Stamina fling |
| Giant Hammer / Cannon Chaos | Reject | Overlap with Knockback; roadmap |
| Memory Path | **Keep** | |
| Spot the Change | **Keep** | |
| Safe Door | **Keep** | |
| Tug of War | **Keep** | Rhythm prompts instead of mashing |
| Push the Payload | **Keep** | Symmetric cart |
| Zone Control | **Keep** | Rotation |
| Build the Bridge | **Keep** | Steal mechanic |
| Delivery Race | Reject | Same loop as bridge without the steal |

## 4. Tooling research (2026)

See `DEVELOPMENT_TOOLING_DECISION.md`. Summary: Script Sync (official, scripts only, Team-Create friendly), Rojo 7.5 (filesystem build tool), Argon 2 (Rojo-compatible project file + two-way sync + VS Code extension), Azul (project-file-free 1:1 mirror), Lune (headless Luau runtime), Rokit (toolchain manager), Wally (packages), selene/StyLua (lint/format), luau-lsp (types). MCP: Argon and community MCP servers exist for Studio; **Arena AI cannot reach a local MCP server**, so the workflow does not depend on one.
