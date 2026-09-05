# Minigames (37)

Each entry lists the distinct core mechanic (what makes it *not* a reskin), player range, and end condition.

| Id | Name | Category | Distinct mechanic | Players | Ends |
|---|---|---|---|---|---|
| BombTag | Bomb Tag | Bomb/Tag | Visible 20 s fuse, proximity pass, fuse shortens per elimination | 3–24 | last standing |
| HiddenTimerBomb | Hidden Fuse | Bomb/Chaos | Unknown 8–30 s fuse, blast radius, ring shrinks 25% per blast | 4–20 | last standing |
| ReverseBomb | Hot Treasure | Bomb/Chaos | Holding scores; steal by touch; 25 s detonation stuns holder & drops points | 3–20 | time |
| BombKart | Bomb Kart | Kart/Bomb | Bomb passes on kart collision; holder's kart destroyed on blast | 4–16 | last standing |
| FreezeTag | Freeze Tag | Tag/Team | Taggers freeze; runners thaw by 2 s proximity; taggers win if all frozen | 4–24 | all frozen / time |
| InfectionTag | Outbreak | Tag/Elim | Touch converts; infected speed scales with count | 4–24 | all infected / time |
| CrownTag | Crown Keeper | Tag/Chaos | Hold crown longest; king slowed; parkour movement | 3–20 | time |
| SafeZoneTag | Safe Zone Tag | Tag/Movement | Zones relocate every 15 s, capacity 3 — 4th bumps 1st; tagger swaps on tag | 4–24 | time |
| HideAndSeek | Hide & Seek | HideSeek | Small/Normal/Large body choice with gates & speed trade-offs | 4–20 | all found / time |
| PropHunt | Prop Hunt | PropHunt | 5 prop shapes, 3 swaps, hunters 8 ammo, miss = −10 HP, idle chirp, 40 s taunts | 4–20 | all found / time |
| BlendIn | Blend In | Deception | Humans at NPC speed/no-jump; accuse nearest; wrong = 5 s freeze | 4–16 | all caught / time |
| NPCPanic | NPC Panic | Deception | One monster; NPCs flee; humans must flee like NPCs; catching NPC slows monster | 4–16 | all caught / time |
| SpeedRun | Speed Run | Speedrun | Ordered checkpoints, respawn at checkpoint, podium ends 10 s after 3rd | 2–24 | podium / time |
| CollapsingObby | Collapse | Obby/Elim | Destructible parts crumble 1.2 s after touch; lava rises; no respawn | 2–24 | last / finish |
| RandomRoute | Random Route | Obby | 5 procedural segments from 5 generators per round | 2–24 | podium / time |
| KartRace | Kart Race | Kart | 3 laps, drift boost (1.2 s sustained steer), boost pads | 2–16 | podium / time |
| EliminationKart | Last Kart | Kart/Elim | Last place eliminated every 12 s by checkpoint rank | 3–16 | last standing |
| DisasterSurvival | Disaster Island | Disaster | Two random disasters of five at 5 s and 55 s | 2–24 | last / time |
| RisingFlood | Rising Flood | Survival | Water rises 1 stud/s; platform with ≥3 players sinks | 2–24 | last / time |
| MeteorShower | Meteor Shower | Disaster | Shadow telegraph 1.3 s; tiles permanently deleted; accelerating | 2–24 | last / time |
| ColorSurvival | Color Rush | Reaction | Color call; 20% fake switch with 1 s left; delay shrinks | 2–24 | last / time |
| RedLightGreenLight | Red Light, Green Light | Reaction | Server velocity check on red; yellow fake-outs; 0.6 s grace | 2–24 | podium / time |
| SimonSays | Simon Says | Reaction | 5 detectable actions; 30% impostor commands; window shrinks | 2–24 | last / time |
| FallingPlatforms | Falling Platforms | Platform | 3 stacked grids; tile drops 0.9 s after touch | 2–24 | last / time |
| FloorIsLava | Floor Is Lava | Platform | Safe/warn/lava pulses; furniture sinks while occupied | 2–24 | last / time |
| RotatingArena | Spin Cycle | Platform | Low arm (jump) + high arm (duck pads); speed ramps | 2–24 | last / time |
| KnockbackArena | Knockback Arena | Physics | Punch with facing check; 3 lives; disc shrinks every 20 s | 2–16 | last / time |
| GiantBallSurvival | Boulder Run | Physics | Rolling boulders of random size on a slope, accelerating spawn | 2–24 | last / time |
| FanSurvival | Wind Tunnel | Physics | Direction warning 1.5 s; handhold pads grant immunity | 2–24 | last / time |
| RagdollRace | Ragdoll Downhill | Physics/Racing | PlatformStand ragdoll; stamina-limited fling steering | 2–24 | podium / time |
| MemoryTiles | Memory Path | Memory | Safe path flashed 4 s; wrong tiles drop instantly | 2–24 | finish / time |
| FindTheChange | Spot the Change | Memory | 5 rounds: study, blackout, one object moved/recolored/resized | 2–20 | rounds |
| SafeDoor | Safe Door | Memory | 4 rooms × 5 doors; 3 s hint; wrong door returns to start | 2–24 | podium / time |
| TugOfWar | Tug of War | Team | Rhythm prompts; missed prompt pulls for the enemy | 4–24 | rope / time |
| PushThePayload | Push the Payload | Team | Cart moves toward majority within 10 studs | 4–24 | delivery / time |
| CaptureZone | Zone Control | Team | 3 zones, uncontested hold scores, rotate every 30 s | 4–24 | 150 pts / time |
| BuildTheBridge | Build the Bridge | Team | Carry plank → slot; loose planks stealable; cross to win | 4–24 | cross / time |

## Admin hooks
`GiveBomb` (BombTag, HiddenTimerBomb, ReverseBomb, BombKart), `Tag` (FreezeTag, InfectionTag, CrownTag), `Reveal` (HideAndSeek, PropHunt, BlendIn, NPCPanic, MemoryTiles, SafeDoor), `Hazard` (DisasterSurvival), `Checkpoint` (SpeedRun, CollapsingObby, KartRace, EliminationKart).

## Adding a minigame
1. Append a `def({...})` entry in `roblox/src/shared/MinigameCatalog.luau`.
2. Create `roblox/src/server/Minigames/<Id>.luau` following `MinigameBase.luau`.
3. Build any temporary geometry through `Arena.Part(ctx, {...})`; register threads with `ctx.Janitor:AddThread`.
4. Add a map model named after each `Maps` entry to `ReplicatedStorage.Assets.Maps` (fallback exists).
5. `cd roblox && lune run tests/run` — static tests verify catalog/module parity.
