--!strict
-- Central authority for per-player gameplay state and character modification/restoration.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local GameConfig = require(Shared.Config.GameConfig)
local Signal = require(Shared.Utilities.Signal)
local Log = require(Shared.Utilities.Log)
local Remotes = require(script.Parent.Remotes)

type Record = {
	State: string, Role: string?, Team: string?, Flags: { [string]: boolean },
	Original: { WalkSpeed: number, JumpHeight: number, Scale: number }?, Score: number,
}

local PlayerStateService = {
	StateChanged = Signal.new(),
	_records = {} :: { [number]: Record },
}

local function newRecord(): Record
	return { State = "Lobby", Role = nil, Team = nil, Flags = {}, Original = nil, Score = 0 }
end

function PlayerStateService:Init()
	Players.PlayerAdded:Connect(function(p) self._records[p.UserId] = newRecord() end)
	Players.PlayerRemoving:Connect(function(p) self._records[p.UserId] = nil end)
	for _, p in Players:GetPlayers() do self._records[p.UserId] = newRecord() end
end

function PlayerStateService:Get(player: Player): Record
	local r = self._records[player.UserId]
	if not r then r = newRecord(); self._records[player.UserId] = r end
	return r
end

function PlayerStateService:SetState(player: Player, state: string)
	local r = self:Get(player)
	if r.State == state then return end
	r.State = state
	self.StateChanged:Fire(player, state)
	Remotes:Fire("PlayerStateChanged", player, state, r.Role, r.Team)
end

function PlayerStateService:SetRole(player: Player, role: string?)
	local r = self:Get(player)
	r.Role = role
	Remotes:Fire("PlayerStateChanged", player, r.State, role, r.Team)
end

function PlayerStateService:SetTeam(player: Player, team: string?)
	local r = self:Get(player)
	r.Team = team
	Remotes:Fire("PlayerStateChanged", player, r.State, r.Role, team)
end

function PlayerStateService:SetFlag(player: Player, flag: string, value: boolean)
	self:Get(player).Flags[flag] = value or nil
end

function PlayerStateService:HasFlag(player: Player, flag: string): boolean
	return self:Get(player).Flags[flag] == true
end

function PlayerStateService:GetByState(state: string): { Player }
	local out = {}
	for _, p in Players:GetPlayers() do
		if self:Get(p).State == state then table.insert(out, p) end
	end
	return out
end

function PlayerStateService:Alive(): { Player }
	return self:GetByState("Playing")
end

-- Character modification helpers. All changes are reversible via RestoreCharacter.
local function humanoid(player: Player): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

function PlayerStateService:CaptureOriginal(player: Player)
	local r = self:Get(player)
	if r.Original then return end
	r.Original = { WalkSpeed = GameConfig.Movement.DefaultWalkSpeed, JumpHeight = GameConfig.Movement.DefaultJumpHeight, Scale = 1 }
end

function PlayerStateService:SetMovement(player: Player, walkSpeed: number?, jumpHeight: number?)
	self:CaptureOriginal(player)
	local h = humanoid(player)
	if not h then return end
	if walkSpeed then h.WalkSpeed = walkSpeed end
	if jumpHeight then
		h.UseJumpPower = false
		h.JumpHeight = jumpHeight
	end
end

function PlayerStateService:SetScale(player: Player, scale: number)
	self:CaptureOriginal(player)
	local h = humanoid(player)
	if not h then return end
	for _, name in { "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale" } do
		local v = h:FindFirstChild(name)
		if v and v:IsA("NumberValue") then v.Value = scale end
	end
	h.HipHeight = h.HipHeight -- scaling updates hip height automatically for R15; kept explicit for clarity
end

function PlayerStateService:RestoreCharacter(player: Player)
	local r = self:Get(player)
	local h = humanoid(player)
	if h then
		h.WalkSpeed = GameConfig.Movement.DefaultWalkSpeed
		h.UseJumpPower = false
		h.JumpHeight = GameConfig.Movement.DefaultJumpHeight
		h.PlatformStand = false
		h.Sit = false
		h.AutoRotate = true
		for _, name in { "BodyDepthScale", "BodyHeightScale", "BodyWidthScale", "HeadScale" } do
			local v = h:FindFirstChild(name)
			if v and v:IsA("NumberValue") then v.Value = 1 end
		end
		local char = player.Character :: Model
		for _, d in char:GetDescendants() do
			if d:IsA("ForceField") or d:GetAttribute("Temporary") then
				d:Destroy()
			elseif d:IsA("BasePart") then
				d.Transparency = if d.Name == "HumanoidRootPart" then 1 else 0
				d.CanCollide = d.Name ~= "HumanoidRootPart"
				d.Anchored = false
			elseif d:IsA("Decal") then
				d.Transparency = 0
			end
		end
	end
	r.Original = nil
	r.Role = nil
	r.Team = nil
	r.Score = 0
	table.clear(r.Flags)
end

function PlayerStateService:ResetAllToLobby()
	for _, p in Players:GetPlayers() do
		self:RestoreCharacter(p)
		self:SetState(p, "Lobby")
	end
	Log.Debug("PlayerState", "All players reset to lobby")
end

return PlayerStateService
