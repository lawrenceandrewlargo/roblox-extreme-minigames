--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Utilities.Log)
local Remotes = require(script.Parent.Remotes)
local DataService = require(script.Parent.DataService)
local ChallengeService = require(script.Parent.ChallengeService)

local RewardService = {}

local RewardMath = require(ReplicatedStorage.Shared.RewardMath)
RewardService.XPForLevel = RewardMath.XPForLevel
RewardService.Calculate = RewardMath.Calculate

function RewardService:Award(meta, result)
	for _, entry in result.Entries do
		local player = Players:GetPlayerByUserId(entry.UserId)
		if not player then continue end
		local reward = RewardService.Calculate(entry)
		local profile = DataService:Get(player)
		if profile then
			profile.XP += reward.XP
			profile.Coins += reward.Coins
			profile.Crowns += reward.Crowns
			profile.Stats.RoundsPlayed += 1
			if entry.Won then profile.Stats.Wins += 1 end
			profile.Stats.PerGame[meta.Id] = (profile.Stats.PerGame[meta.Id] or 0) + 1
			while profile.XP >= RewardService.XPForLevel(profile.Level) do
				profile.XP -= RewardService.XPForLevel(profile.Level)
				profile.Level += 1
			end
			DataService:MarkDirty(player)
		end
		ChallengeService:OnRoundResult(player, meta, entry)
		Remotes:Fire("RewardsGranted", player, reward, entry.Placement, profile and profile.Level)
	end
	Log.Info("Reward", "Rewards granted", { game = meta.Id, count = #result.Entries })
end

return RewardService
