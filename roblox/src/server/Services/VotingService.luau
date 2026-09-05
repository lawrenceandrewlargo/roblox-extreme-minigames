--!strict
-- Physical in-world voting. Players vote by standing on a platform in the lobby.
-- Server authoritative: votes derive ONLY from server-side overlap queries, never from client messages.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local GameConfig = require(Shared.Config.GameConfig)
local Catalog = require(Shared.MinigameCatalog)
local CandidateSelector = require(Shared.CandidateSelector)
local Signal = require(Shared.Utilities.Signal)
local Janitor = require(Shared.Utilities.Janitor)
local Log = require(Shared.Utilities.Log)
local Remotes = require(script.Parent.Remotes)

local VotingService = {
	VotingEnded = Signal.new(),
	_active = false,
	_candidates = {} :: { any },
	_votes = {} :: { [number]: number },
	_platforms = {} :: { BasePart },
	_janitor = nil :: any,
	_history = {} :: { any },
	_round = 0,
	_rng = Random.new(),
	_lastEnter = {} :: { [number]: number },
}

local PLATFORM_COUNT = GameConfig.Voting.CandidateCount

local function platformFolder(): Folder
	local lobby = Workspace:FindFirstChild("Lobby") or Workspace
	local folder = lobby:FindFirstChild("VotingPlatforms")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "VotingPlatforms"
		folder.Parent = lobby
	end
	return folder :: Folder
end

-- Builds platforms if the lobby map does not already provide "VotePlatform1..N".
local function ensurePlatforms(): { BasePart }
	local folder = platformFolder()
	local platforms = {}
	for i = 1, PLATFORM_COUNT do
		local p = folder:FindFirstChild("VotePlatform" .. i)
		if not p then
			p = Instance.new("Part")
			p.Name = "VotePlatform" .. i
			p.Size = Vector3.new(14, 1, 14)
			p.Anchored = true
			p.Material = Enum.Material.Neon
			p.Position = Vector3.new((i - (PLATFORM_COUNT + 1) / 2) * 22, 0.5, -40)
			p.Parent = folder
			local bb = Instance.new("BillboardGui")
			bb.Name = "Sign"
			bb.Size = UDim2.fromScale(12, 5)
			bb.StudsOffset = Vector3.new(0, 9, 0)
			bb.AlwaysOnTop = false
			bb.MaxDistance = 150
			bb.Parent = p
			for _, name in { "Title", "Description", "Category", "Votes" } do
				local l = Instance.new("TextLabel")
				l.Name = name
				l.BackgroundTransparency = 1
				l.TextScaled = true
				l.Font = Enum.Font.GothamBold
				l.TextColor3 = Color3.new(1, 1, 1)
				l.TextStrokeTransparency = 0.4
				l.Size = UDim2.fromScale(1, 0.25)
				l.Parent = bb
			end
			(bb:FindFirstChild("Title") :: TextLabel).Position = UDim2.fromScale(0, 0)
			;(bb:FindFirstChild("Description") :: TextLabel).Position = UDim2.fromScale(0, 0.3)
			;(bb:FindFirstChild("Category") :: TextLabel).Position = UDim2.fromScale(0, 0.55)
			;(bb:FindFirstChild("Votes") :: TextLabel).Position = UDim2.fromScale(0, 0.75)
		end
		platforms[i] = p :: BasePart
	end
	return platforms
end

function VotingService:Init()
	self._platforms = ensurePlatforms()
	self:_setPlatformsActive(false)
	Players.PlayerRemoving:Connect(function(p)
		if self._votes[p.UserId] then
			self._votes[p.UserId] = nil
			self:_broadcast()
		end
	end)
end

function VotingService:_setPlatformsActive(active: boolean)
	for i, p in self._platforms do
		p.Color = active and Color3.fromHSV((i - 1) / PLATFORM_COUNT, 0.6, 1) or Color3.fromRGB(60, 60, 70)
		p.Material = active and Enum.Material.Neon or Enum.Material.SmoothPlastic
		local sign = p:FindFirstChild("Sign")
		if sign then (sign :: BillboardGui).Enabled = active end
	end
end

function VotingService:_populateSigns()
	for i, p in self._platforms do
		local meta = self._candidates[i]
		local sign = p:FindFirstChild("Sign")
		if sign and meta then
			(sign:FindFirstChild("Title") :: TextLabel).Text = meta.DisplayName
			;(sign:FindFirstChild("Description") :: TextLabel).Text = meta.Description
			;(sign:FindFirstChild("Category") :: TextLabel).Text = meta.Category .. (meta.SecondaryCategory and (" / " .. meta.SecondaryCategory) or "")
			;(sign:FindFirstChild("Votes") :: TextLabel).Text = "0 votes"
		end
		p:SetAttribute("GameId", meta and meta.Id or "")
	end
end

function VotingService:_counts(): { number }
	local counts = table.create(#self._candidates, 0)
	for _, idx in self._votes do
		if counts[idx] ~= nil then counts[idx] += 1 end
	end
	return counts
end

function VotingService:_broadcast()
	local counts = self:_counts()
	local leader, best = 0, -1
	for i, c in counts do if c > best then best = c; leader = i end end
	for i, p in self._platforms do
		local sign = p:FindFirstChild("Sign")
		if sign then
			local l = sign:FindFirstChild("Votes") :: TextLabel
			l.Text = ("%d vote%s"):format(counts[i] or 0, (counts[i] or 0) == 1 and "" or "s")
			l.TextColor3 = (i == leader and best > 0) and Color3.fromRGB(255, 230, 90) or Color3.new(1, 1, 1)
		end
	end
	Remotes:FireAll("VoteCountsChanged", counts, self._votes)
end

-- Server authoritative detection: which platform is each eligible player standing on?
function VotingService:_scan()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	local changed = false
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then
			if self._votes[player.UserId] then self._votes[player.UserId] = nil; changed = true end
			continue
		end
		local onIndex: number? = nil
		for i, p in self._platforms do
			local rel = p.CFrame:PointToObjectSpace((root :: BasePart).Position)
			local half = p.Size / 2
			if math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and rel.Y > -1 and rel.Y < 8 then
				onIndex = i
				break
			end
		end
		local current = self._votes[player.UserId]
		if onIndex ~= current then
			local lastT = self._lastEnter[player.UserId] or 0
			if now - lastT < GameConfig.Voting.PlatformDebounceSeconds then continue end
			self._lastEnter[player.UserId] = now
			if onIndex then
				self._votes[player.UserId] = onIndex
				changed = true
			elseif GameConfig.Voting.LeavingPlatformClearsVote then
				self._votes[player.UserId] = nil
				changed = true
			end
			if changed then Log.Debug("Voting", ("Vote %d -> %s"):format(player.UserId, tostring(onIndex))) end
		end
	end
	if changed then self:_broadcast() end
end

function VotingService:StartVoting(history: { any }, round: number, playerCount: number, duration: number?)
	assert(not self._active, "Voting already active")
	self._history = history
	self._round = round
	self._votes = {}
	self._lastEnter = {}
	self._candidates = CandidateSelector.Select(Catalog.List, history, playerCount, round, self._rng)
	if #self._candidates == 0 then
		Log.Warn("Voting", "No candidates available; falling back to full catalog")
		self._candidates = { Catalog.List[1] }
	end
	self._active = true
	self._janitor = Janitor.new()
	self:_populateSigns()
	self:_setPlatformsActive(true)
	local payload = {}
	for i, m in self._candidates do payload[i] = { Id = m.Id, DisplayName = m.DisplayName, Description = m.Description, Category = m.Category, Icon = m.Icon } end
	Remotes:FireAll("VotingState", true, payload, duration or GameConfig.Lobby.VotingSeconds)
	local acc = 0
	self._janitor:Add(RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 0.15 then acc = 0; self:_scan() end
	end))
	self:_broadcast()
	Log.Info("Voting", "Voting started", { candidates = #self._candidates })
end

function VotingService:EndVoting(): (any, { number })
	assert(self._active, "Voting not active")
	self:_scan()
	local winnerIdx, counts = CandidateSelector.Tally(self._candidates, self._votes, self._history, self._round, self._rng)
	local winner = self._candidates[winnerIdx]
	self._active = false
	self._janitor:Destroy()
	self._janitor = nil
	self._votes = {}
	self:_setPlatformsActive(false)
	Remotes:FireAll("VotingState", false, nil, 0, winner and winner.Id)
	Log.Info("Voting", "Voting ended", { winner = winner and winner.Id, counts = counts })
	self.VotingEnded:Fire(winner, counts)
	return winner, counts
end

function VotingService:Cancel()
	if not self._active then return end
	self._active = false
	if self._janitor then self._janitor:Destroy(); self._janitor = nil end
	self._votes = {}
	self:_setPlatformsActive(false)
	Remotes:FireAll("VotingState", false, nil, 0, nil)
end

function VotingService:IsActive(): boolean return self._active end
function VotingService:Candidates() return self._candidates end
function VotingService:Votes() return self._votes end
function VotingService:Snapshot()
	return { active = self._active, candidates = self._candidates, votes = self._votes, counts = self:_counts() }
end

return VotingService
