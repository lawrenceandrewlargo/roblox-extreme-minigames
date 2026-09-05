# Final Playtest Guide (for the owner)

You are testing *feel*, not correctness — the automated layers already cover logic. Use **Test → Start (4–8 players)** in Studio for the core loop, then a published private server with friends for social feel.

## Setup (5 min)
1. Connect Argon (or Script Sync) and press Play. Output should read `Server ready with 37 minigames`.
2. Press **F9** → admin panel opens. Try `InspectServer`.

## 1. Lobby & physical voting (5 min)
- Walk onto each of the three platforms. Does the sign's count update within a second? Is it obvious that standing = voting?
- Step off: does your vote clear? Switch platforms quickly: any flicker?
- With 4 test clients: create a tie and a zero-vote round (nobody stands). Does a reasonable game start?
- **Ask:** Is 20 seconds of voting too long or too short?

## 2. Minigames (45 min)
Use `ForceMinigame <Id>` to jump straight to games. Play at least: BombTag, HiddenTimerBomb, FreezeTag, HideAndSeek (try all three sizes), PropHunt, BlendIn, SpeedRun, CollapsingObby, KartRace, DisasterSurvival, ColorSurvival, RedLightGreenLight, SimonSays, FallingPlatforms, KnockbackArena, MemoryTiles, TugOfWar, BuildTheBridge.
For each, note in one line: *Understood in 5 s? Fun? Too long/short? Any confusing moment? Any funny moment?*

## 3. Repeated rounds (15 min)
Let the loop run 10+ rounds untouched. After each: are you back in the lobby at normal size/speed? Run `CleanupDiagnostics` — `activeJanitors` should stay flat and `activeMapChildren` should be 0 in the lobby.

## 4. Spectating
Get eliminated in BombTag. Can you cycle players with ◀ ▶ / Q / E? In HideAndSeek as an eliminated hider, confirm you cannot spectate seekers' view of unfound hiders being revealed unfairly.

## 5. Progression, shop, challenges, settings
Open each window from the right-side icons. Close with ✕, Escape and (controller) B. Buy a trail with `GrantCurrency` coins. Toggle a setting and rejoin — did it persist? (Needs API access enabled.)

## 6. Admin
Try Fly, Noclip, WalkSpeed 50, Bring/Goto, Freeze/Unfreeze, Announce, Kick (confirm dialog appears). `ResetMovement` after.

## 7. Parties
With two clients: `PartyAction invite/accept` is exposed via the PartyAction remote; verify both land on the same team in TugOfWar.

## 8. Mobile & controller
Studio → Device emulator (phone). Are the Sprint/Slide/Action buttons reachable? Is the vote panel readable? Controller: can you open/close every window with B?

## 9. Edge cases
Leave a client while it holds the bomb; join a client mid-round; abort a round with `AbortRound`; force a map that doesn't exist (`ForceMinigame BombTag NoSuchMap`) — expect a fallback, never a stuck server.

## Questions to answer
Is it fun? Which three games are weakest? Are transitions satisfying? Does voting feel like a game in itself? Did anything frustrate you? Did anyone laugh out loud — at what?
