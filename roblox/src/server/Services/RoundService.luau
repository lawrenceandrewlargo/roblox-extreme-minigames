--!strict
-- Owns the session loop: Lobby -> Intermission -> Voting -> MapSelection -> Intro -> Countdown -> Gameplay -> Results -> Rewards -> Lobby.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local GameConfig = require(Shared.Config.GameConfig)
local Modifiers = require(Shared.Config.Modifiers)
local Catalog = require(Shared.MinigameCatalog)
local CandidateSelector = require(Shared.CandidateSelector)
local Signal = require(Shared.Utilities.Signal)
local Log = require(Shared.Utilities.Log)
local Timer = require(Shared.Utilities.Timer)

local Remotes = require(script.Parent.Remotes)
local VotingService = require(script.Parent.VotingService)
local MinigameService = require(script.Parent.MinigameService)
local MapService = require(script.Parent.MapService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local RewardService = require(script.Parent.RewardService)
local SpectatorService = require(script.Parent.SpectatorService)
local AnnouncementService = require(script.Parent.AnnouncementService)

local RoundService = {
	PhaseChanged = Signal.new(),
	Phase = "Lobby" :: string,
	Round = 0,
	History = {} :: { any },
	_timer = nil :: any,
	_forced = nil :: { GameId: string?, MapId: string?, ModifierId: string? }?,
	_skipRequested = false,
	_abortRequested = false,
	_rng = Random.new(),
	_loopThread = nil :: thread?,
}

function RoundService:SetPhase(phase: string, duration: number?)
	self.Phase = phase
	self.PhaseChanged:Fire(phase, duration)
	Remotes:FireAll("PhaseChanged", phase, duration or 0, self.Round)
	Log.Info("Round", "Phase " .. phase, { round = self.Round })
end

-- Waits `seconds` unless an admin skip/abort arrives.
function RoundService:WaitPhase(seconds: number)
	self._skipRequested = false
	local timer = Timer.new(seconds)
	self._timer = timer
	timer:Start()
	while timer.Running and not self._skipRequested and not self._abortRequested do task.wait(0.1) end
	timer:Destroy()
	self._timer = nil
end

function RoundService:Skip() self._skipRequested = true end
function RoundService:Abort() self._abortRequested = true; MinigameService:Abort("admin_abort") end
function RoundService:Force(gameId: string?, mapId: string?, modifierId: string?)
	self._forced = { GameId = gameId, MapId = mapId, ModifierId = modifierId }
end
function RoundService:AddTime(seconds: number) if self._timer then self._timer:AddTime(seconds) end end
function RoundService:TimeRemaining(): number return self._timer and self._timer.Remaining or 0 end

function RoundService:_eligiblePlayers(): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and not PlayerStateService:HasFlag(p, "AFK") then
			table.insert(out, p)
		end
	end
	return out
end

function RoundService:_runOneRound()
	self._abortRequested = false
	self.Round += 1
	PlayerStateService:ResetAllToLobby()

	-- Intermission
	self:SetPhase("Intermission", GameConfig.Lobby.IntermissionSeconds)
	self:WaitPhase(GameConfig.Lobby.IntermissionSeconds)
	while #self:_eligiblePlayers() < GameConfig.MinPlayersToStart do
		self:SetPhase("Lobby")
		task.wait(2)
	end

	-- Voting (unless forced)
	local meta
	if self._forced and self._forced.GameId and Catalog.ById[self._forced.GameId] then
		meta = Catalog.ById[self._forced.GameId]
	else
		self:SetPhase("Voting", GameConfig.Lobby.VotingSeconds)
		VotingService:StartVoting(self.History, self.Round, #self:_eligiblePlayers())
		self:WaitPhase(GameConfig.Lobby.VotingSeconds)
		if self._abortRequested then VotingService:Cancel(); return end
		meta = VotingService:EndVoting()
		if self._forced and self._forced.GameId and Catalog.ById[self._forced.GameId] then meta = Catalog.ById[self._forced.GameId] end
	end
	if not meta then Log.Warn("Round", "No minigame selected; retrying"); return end

	-- Map + modifier selection. Players may have left since voting closed: re-validate the player count
	-- and fall back to a compatible game rather than starting an unplayable round.
	self:SetPhase("MapSelection", 1)
	local participants = self:_eligiblePlayers()
	if #participants < meta.MinimumPlayers then
		local fallback = CandidateSelector.Select(Catalog.List, self.History, #participants, self.Round, self._rng, 1)[1]
		if not fallback then
			Log.Warn("Round", ("Not enough players for %s (%d) and no fallback; returning to lobby"):format(meta.Id, #participants))
			AnnouncementService:Broadcast("Not enough players — waiting for more.", 3, "Warning")
			return
		end
		Log.Warn("Round", ("Player count dropped to %d; swapping %s -> %s"):format(#participants, meta.Id, fallback.Id))
		AnnouncementService:Broadcast(("Not enough players for %s — playing %s instead."):format(meta.DisplayName, fallback.DisplayName), 4, "Warning")
		meta = fallback
	end
	local mapId = (self._forced and self._forced.MapId and table.find(meta.Maps, self._forced.MapId)) and self._forced.MapId or CandidateSelector.PickMap(meta, self.History, self._rng)
	local modifierId = (self._forced and self._forced.ModifierId and table.find(meta.AllowedModifiers, self._forced.ModifierId)) and self._forced.ModifierId or CandidateSelector.PickModifier(meta, Modifiers, self.History, self._rng)
	self._forced = nil
	table.insert(self.History, { GameId = meta.Id, Round = self.Round, MapId = mapId, ModifierId = modifierId })
	if #self.History > 200 then table.remove(self.History, 1) end

	-- Intro
	self:SetPhase("Intro", GameConfig.Lobby.IntroSeconds)
	Remotes:FireAll("MinigameIntro", { Id = meta.Id, DisplayName = meta.DisplayName, Description = meta.Description, MapId = mapId, ModifierId = modifierId, Movement = meta.Movement })
	participants = self:_eligiblePlayers()
	if #participants < GameConfig.MinPlayersToStart then
		Log.Warn("Round", "Players left during intro; cancelling round")
		table.remove(self.History)
		return
	end
	local ok, err = pcall(function()
		MinigameService:Prepare(meta, mapId, modifierId, participants)
	end)
	if not ok then
		Log.Warn("Round", "Prepare failed: " .. tostring(err))
		MinigameService:Abort("prepare_failed")
		MapService:Unload()
		return
	end
	self:WaitPhase(GameConfig.Lobby.IntroSeconds)

	-- Countdown
	self:SetPhase("Countdown", GameConfig.Lobby.CountdownSeconds)
	for i = GameConfig.Lobby.CountdownSeconds, 1, -1 do
		Remotes:FireAll("Countdown", i)
		if self._skipRequested or self._abortRequested then break end
		task.wait(1)
	end
	Remotes:FireAll("Countdown", 0)

	-- Gameplay
	self:SetPhase("Gameplay", meta.Duration)
	local result = MinigameService:Run(meta.Duration)

	-- Results
	self:SetPhase("Results", GameConfig.Lobby.ResultsSeconds)
	Remotes:FireAll("Results", result)
	if result and #result.WinnerUserIds > 0 then
		local names = {}
		for _, id in result.WinnerUserIds do
			local p = Players:GetPlayerByUserId(id)
			if p then table.insert(names, p.DisplayName) end
		end
		AnnouncementService:Broadcast(("Winner: %s"):format(table.concat(names, ", ")), 4, "Round")
	end
	self:WaitPhase(GameConfig.Lobby.ResultsSeconds)

	-- Rewards
	self:SetPhase("Rewards", GameConfig.Lobby.RewardsSeconds)
	if result then RewardService:Award(meta, result) end
	self:WaitPhase(GameConfig.Lobby.RewardsSeconds)

	-- Cleanup + return
	MinigameService:Cleanup()
	MapService:Unload()
	SpectatorService:StopAll()
	PlayerStateService:ResetAllToLobby()
	for _, p in Players:GetPlayers() do
		if p.Character then p.Character:PivotTo(MapService:LobbySpawn()) end
	end
	self:SetPhase("Lobby")
end

function RoundService:Start()
	self._loopThread = task.spawn(function()
		while true do
			local ok, err = pcall(self._runOneRound, self)
			if not ok then
				Log.Warn("Round", "Round crashed, recovering: " .. tostring(err))
				pcall(MinigameService.Abort, MinigameService, "round_crash")
				pcall(MinigameService.Cleanup, MinigameService)
				pcall(MapService.Unload, MapService)
				pcall(VotingService.Cancel, VotingService)
				pcall(PlayerStateService.ResetAllToLobby, PlayerStateService)
				self:SetPhase("Lobby")
				task.wait(3)
			end
			task.wait(0.5)
		end
	end)
end

function RoundService:Snapshot()
	return { phase = self.Phase, round = self.Round, remaining = self:TimeRemaining(), history = self.History, forced = self._forced }
end

return RoundService
