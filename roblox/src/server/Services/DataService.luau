--!strict
-- Resilient DataStore persistence with schema migrations, retries, periodic saves and BindToClose.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Utilities.Log)
local Remotes = require(script.Parent.Remotes)

export type Profile = {
	SchemaVersion: number, XP: number, Level: number, Coins: number, Crowns: number,
	Cosmetics: { Owned: { [string]: boolean }, Equipped: { [string]: string } },
	Achievements: { [string]: number }, Challenges: { Daily: { [string]: number }, Weekly: { [string]: number }, LastDaily: number, LastWeekly: number },
	Settings: { [string]: any }, Stats: { Wins: number, RoundsPlayed: number, PerGame: { [string]: number } },
}

local function defaultProfile(): Profile
	return {
		SchemaVersion = GameConfig.Data.SchemaVersion, XP = 0, Level = 1, Coins = 0, Crowns = 0,
		Cosmetics = { Owned = { TrailNone = true }, Equipped = {} },
		Achievements = {}, Challenges = { Daily = {}, Weekly = {}, LastDaily = 0, LastWeekly = 0 },
		Settings = { MusicVolume = 0.6, SfxVolume = 0.8, ReduceMotion = false, ShowVoteHUD = true },
		Stats = { Wins = 0, RoundsPlayed = 0, PerGame = {} },
	}
end

-- Each migration upgrades from version N to N+1.
local Migrations: { [number]: (any) -> () } = {
	[1] = function(p) p.Crowns = p.Crowns or 0 end,
	[2] = function(p) p.Challenges = p.Challenges or { Daily = {}, Weekly = {}, LastDaily = 0, LastWeekly = 0 } end,
}

local DataService = { _profiles = {} :: { [number]: Profile }, _dirty = {} :: { [number]: boolean }, _store = nil :: any, _saving = {} :: { [number]: boolean } }

local function migrate(p: any): Profile
	local base = defaultProfile()
	for k, v in base do if p[k] == nil then p[k] = v end end
	local v = p.SchemaVersion or 1
	while v < GameConfig.Data.SchemaVersion do
		local m = Migrations[v]
		if m then m(p) end
		v += 1
		p.SchemaVersion = v
	end
	return p
end

local function withRetry(fn: () -> any): (boolean, any)
	local ok, res
	for attempt = 1, GameConfig.Data.MaxRetries do
		ok, res = pcall(fn)
		if ok then return true, res end
		task.wait(math.min(2 ^ attempt, 10))
	end
	return false, res
end

function DataService:Init()
	local ok, store = pcall(function() return DataStoreService:GetDataStore(GameConfig.Data.StoreName) end)
	self._store = ok and store or nil
	if not ok then Log.Warn("Data", "DataStore unavailable (Studio without API access?). Using memory only.") end

	Players.PlayerAdded:Connect(function(p) self:_load(p) end)
	Players.PlayerRemoving:Connect(function(p) self:_save(p, true) end)
	for _, p in Players:GetPlayers() do task.spawn(self._load, self, p) end

	Remotes:SetCallback("GetProfile", function(player)
		local prof = self:Get(player)
		return prof and { ok = true, profile = prof } or { ok = false, error = "loading" }
	end)
	Remotes:SetCallback("UpdateSettings", function(player, settings)
		if type(settings) ~= "table" then return { ok = false, error = "invalid" } end
		local prof = self:Get(player)
		if not prof then return { ok = false, error = "loading" } end
		for k, v in settings do
			if prof.Settings[k] ~= nil and typeof(v) == typeof(prof.Settings[k]) then prof.Settings[k] = v end
		end
		self:MarkDirty(player)
		return { ok = true }
	end)

	task.spawn(function()
		while true do
			task.wait(GameConfig.Data.SaveIntervalSeconds)
			for _, p in Players:GetPlayers() do if self._dirty[p.UserId] then self:_save(p, false) end end
		end
	end)
	game:BindToClose(function()
		if RunService:IsStudio() then return end
		local pending = 0
		for _, p in Players:GetPlayers() do pending += 1; task.spawn(function() self:_save(p, true); pending -= 1 end) end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do task.wait(0.2) end
	end)
end

function DataService:_load(player: Player)
	local key = "u_" .. player.UserId
	local profile: Profile
	if self._store then
		local ok, data = withRetry(function() return self._store:GetAsync(key) end)
		if ok and type(data) == "table" then
			profile = migrate(data)
		elseif ok then
			profile = defaultProfile()
		else
			Log.Warn("Data", "Load failed for " .. player.UserId .. "; session will not save to protect data.")
			profile = defaultProfile()
			;(profile :: any).__nosave = true
		end
	else
		profile = defaultProfile()
	end
	self._profiles[player.UserId] = profile
end

function DataService:_save(player: Player, release: boolean)
	local profile = self._profiles[player.UserId]
	if not profile or (profile :: any).__nosave or not self._store then
		if release then self._profiles[player.UserId] = nil; self._dirty[player.UserId] = nil end
		return
	end
	if self._saving[player.UserId] then return end
	self._saving[player.UserId] = true
	local key = "u_" .. player.UserId
	local snapshot = profile
	local ok, err = withRetry(function()
		self._store:UpdateAsync(key, function(old)
			if type(old) == "table" and (old.SchemaVersion or 0) > snapshot.SchemaVersion then return nil end
			return snapshot
		end)
	end)
	self._saving[player.UserId] = nil
	if ok then self._dirty[player.UserId] = nil else Log.Warn("Data", "Save failed " .. player.UserId .. ": " .. tostring(err)) end
	if release then self._profiles[player.UserId] = nil; self._dirty[player.UserId] = nil end
end

function DataService:Get(player: Player): Profile? return self._profiles[player.UserId] end
function DataService:MarkDirty(player: Player) self._dirty[player.UserId] = true end
function DataService:ResetProfile(player: Player) self._profiles[player.UserId] = defaultProfile(); self:MarkDirty(player) end

return DataService
