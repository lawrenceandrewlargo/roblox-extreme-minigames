--!strict
-- Daily/weekly challenges + achievements, evaluated from round results.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Log = require(ReplicatedStorage.Shared.Utilities.Log)
local DataService = require(script.Parent.DataService)
local Remotes = require(script.Parent.Remotes)

local ChallengeService = {}

ChallengeService.Definitions = {
	Daily = {
		{ Id = "PlayThree", Text = "Play 3 rounds", Goal = 3, Reward = { Coins = 40, XP = 60 }, Track = function(meta, entry) return 1 end },
		{ Id = "WinOne", Text = "Win a round", Goal = 1, Reward = { Coins = 80, XP = 100 }, Track = function(meta, entry) return entry.Won and 1 or 0 end },
		{ Id = "TopThree", Text = "Place top 3 twice", Goal = 2, Reward = { Coins = 60, XP = 80 }, Track = function(meta, entry) return entry.Placement <= 3 and 1 or 0 end },
	},
	Weekly = {
		{ Id = "PlayTwenty", Text = "Play 20 rounds", Goal = 20, Reward = { Coins = 250, XP = 400 }, Track = function(meta, entry) return 1 end },
		{ Id = "WinFive", Text = "Win 5 rounds", Goal = 5, Reward = { Coins = 400, XP = 600 }, Track = function(meta, entry) return entry.Won and 1 or 0 end },
		{ Id = "Variety", Text = "Play 10 different minigames", Goal = 10, Reward = { Coins = 300, XP = 500 }, Track = nil },
	},
	Achievements = {
		{ Id = "FirstWin", Text = "First Win", Check = function(profile) return profile.Stats.Wins >= 1 end },
		{ Id = "TenWins", Text = "Ten Wins", Check = function(profile) return profile.Stats.Wins >= 10 end },
		{ Id = "Centurion", Text = "100 Rounds", Check = function(profile) return profile.Stats.RoundsPlayed >= 100 end },
		{ Id = "Level10", Text = "Level 10", Check = function(profile) return profile.Level >= 10 end },
	},
}

local function dayKey() return math.floor(os.time() / 86400) end
local function weekKey() return math.floor(os.time() / (86400 * 7)) end

function ChallengeService:OnRoundResult(player: Player, meta, entry)
	local profile = DataService:Get(player)
	if not profile then return end
	if profile.Challenges.LastDaily ~= dayKey() then profile.Challenges.Daily = {}; profile.Challenges.LastDaily = dayKey() end
	if profile.Challenges.LastWeekly ~= weekKey() then profile.Challenges.Weekly = {}; profile.Challenges.LastWeekly = weekKey() end
	local completed = {}
	for _, scope in { "Daily", "Weekly" } do
		local bucket = profile.Challenges[scope]
		for _, def in self.Definitions[scope] do
			if bucket[def.Id] == -1 then continue end -- claimed
			local inc = def.Track and def.Track(meta, entry) or 0
			if def.Id == "Variety" then
				local distinct = 0
				for _ in profile.Stats.PerGame do distinct += 1 end
				bucket[def.Id] = distinct
			else
				bucket[def.Id] = (bucket[def.Id] or 0) + inc
			end
			if bucket[def.Id] >= def.Goal then
				profile.Coins += def.Reward.Coins
				profile.XP += def.Reward.XP
				bucket[def.Id] = -1
				table.insert(completed, def.Text)
			end
		end
	end
	for _, a in self.Definitions.Achievements do
		if not profile.Achievements[a.Id] and a.Check(profile) then
			profile.Achievements[a.Id] = os.time()
			table.insert(completed, "Achievement: " .. a.Text)
		end
	end
	if #completed > 0 then
		DataService:MarkDirty(player)
		Remotes:Fire("Announcement", player, { Text = table.concat(completed, " • "), Duration = 5, Kind = "Event", Priority = 2 })
		Log.Info("Challenge", "Completed", { user = player.UserId, items = completed })
	end
end

return ChallengeService
