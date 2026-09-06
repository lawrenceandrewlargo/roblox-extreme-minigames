--!strict
-- Pure reward/level math. Unit tested under Lune and mirrored in the web command center.
local GameConfig = require(script.Parent.Config.GameConfig)
local RewardMath = {}

function RewardMath.XPForLevel(level: number): number
	return math.floor(GameConfig.Rewards.XPPerLevelBase * (GameConfig.Rewards.XPPerLevelGrowth ^ (level - 1)))
end

function RewardMath.Calculate(entry: { Won: boolean, Placement: number }): { XP: number, Coins: number, Crowns: number }
	local r = GameConfig.Rewards
	local xp, coins, crowns = r.ParticipationXP, r.ParticipationCoins, 0
	if entry.Won then
		xp += r.WinXP; coins += r.WinCoins; crowns += r.CrownForWin
	else
		local placeXP, placeCoins = r.PlacementXP[entry.Placement], r.PlacementCoins[entry.Placement]
		if placeXP then xp += placeXP; coins += placeCoins end
	end
	return { XP = xp, Coins = coins, Crowns = crowns }
end

-- Applies XP and returns new (xp, level) after level-ups.
function RewardMath.ApplyXP(xp: number, level: number, gained: number): (number, number)
	xp += gained
	while xp >= RewardMath.XPForLevel(level) do
		xp -= RewardMath.XPForLevel(level)
		level += 1
	end
	return xp, level
end

return RewardMath
