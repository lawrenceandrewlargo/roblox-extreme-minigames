# Progression

Rewards (`GameConfig.Rewards`): participation 25 XP / 10 coins; win +120 XP / +60 coins / +1 crown; 2nd/3rd +70/50 XP and +30/20 coins (1st place bonus is the win bonus). Level cost = 250 × 1.12^(level−1) XP; levels roll over correctly (tested).

Persistence: `DataService` profile v3 — XP, Level, Coins, Crowns, Cosmetics (Owned/Equipped), Achievements, Challenges (Daily/Weekly with day/week keys), Settings, Stats (Wins, RoundsPlayed, PerGame).

Challenges: Daily — play 3, win 1, top-3 twice. Weekly — play 20, win 5, play 10 different minigames. Achievements — First Win, Ten Wins, 100 Rounds, Level 10. Completion auto-grants rewards and toasts the player.

Cosmetics (server-validated purchases, no gameplay effect): trails (none/fire/rainbow), titles (Rookie, Agent of Chaos), victory confetti. Equipped items are exposed as player attributes for client rendering.

Non-pay-to-win: no purchasable stats, speed, lives or votes exist in the codebase.
