# Voting System

## Physical in-world voting
Three platforms (`Workspace.Lobby.VotingPlatforms.VotePlatform1..3`, auto-created if the lobby lacks them) each carry a BillboardGui sign with **title, description, category and live vote count**. During the Voting phase platforms glow with distinct hues and the leader's count turns gold; outside voting they are grey and signs are hidden.

**A player's vote is the platform they are standing on.** `VotingService:_scan()` runs at ~6 Hz on Heartbeat and tests each player's `HumanoidRootPart` against each platform's local bounds (X/Z within half-size, Y between −1 and +8). No client message can create or change a vote.

Rules (documented behaviour):
- One vote per player, by construction (a body is in one place).
- Moving to another platform changes the vote after a 0.2 s debounce.
- Leaving all platforms **clears** the vote (`GameConfig.Voting.LeavingPlatformClearsVote = true`).
- Disconnecting clears the vote (`PlayerRemoving`).
- Players without a character (respawning, AFK-flagged) cannot vote.
- Votes are wiped when voting starts and ends; nothing persists between rounds.
- Late joiners receive the current `VotingState` and can walk onto a platform until the timer ends.

## Candidate generation (`CandidateSelector.Select`)
1. Filter by player count compatibility (fallback: minimum only).
2. Exclude the previous game and games inside their `VoteCooldownRounds`; relax cooldown to 50% then 0% only if fewer than 3 games remain.
3. Weight = 1 × (1 + 0.75 if under-played) × (0.45 if over-played > 1.5× average) × clamp(roundsSince / (2 × cooldown), 0.25, 1).
4. Weighted sample without replacement; a candidate sharing a primary category with an already-chosen one is multiplied by 0.15.

## Tally (`CandidateSelector.Tally`)
Majority wins. Ties (including zero-vote rounds) break by: least recently played → lowest session frequency → id (deterministic) → RNG only if identical.

## Map & modifier
`PickMap` = least-recently-used map for that game (20% random for variety). `PickModifier` = weighted pick among the game's `AllowedModifiers`, excluding modifiers used in the last 3 rounds (except `None`).

## Post-vote validation
`RoundService` re-counts eligible players after voting; if below the winner's `MinimumPlayers` it swaps to a compatible game (announced) or returns to lobby.

## Simulation evidence
- Lune (real Luau): 1,000 cycles with random 2–24 players, random/zero votes, 10% vote removals → 0 immediate repeats, 0 cooldown violations, all 37 games played, frequency spread < 4×, same-category rounds < 25%.
- Web runner (TS port): 100 / 500 / 1,000 / 5,000 cycles PASS (see `/simulations`), favourite-game share ≈ 3–4% even with a 50% popularity bias on a single game.

## Extensions (roadmap)
Mystery platform (`MysteryPlatformChance`), community wildcard, per-server exclusion list.
