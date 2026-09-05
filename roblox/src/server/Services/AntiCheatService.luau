--!strict
-- Server-side sanity checks. Never trusts client claims; flags impossible movement and validates gameplay requests.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Utilities.Log)
local PlayerStateService = require(script.Parent.PlayerStateService)

local AntiCheatService = { _last = {} :: { [number]: { pos: Vector3, t: number } }, _flags = {} :: { [number]: number }, Exempt = {} :: { [number]: boolean } }

function AntiCheatService:Init()
	Players.PlayerRemoving:Connect(function(p) self._last[p.UserId] = nil; self._flags[p.UserId] = nil end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.5 then return end
		local step = acc
		acc = 0
		for _, p in Players:GetPlayers() do
			if self.Exempt[p.UserId] then continue end
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if not root or not hum then continue end
			local pos = (root :: BasePart).Position
			local last = self._last[p.UserId]
			if last and not PlayerStateService:HasFlag(p, "Teleported") then
				local flat = Vector3.new(pos.X - last.pos.X, 0, pos.Z - last.pos.Z).Magnitude
				local maxSpeed = math.max((hum :: Humanoid).WalkSpeed, GameConfig.Movement.SlideSpeed) * GameConfig.AntiCheat.MaxHorizontalSpeedTolerance
				local allowed = maxSpeed * step + 6 -- slack for knockback
				if flat > GameConfig.AntiCheat.TeleportDistanceThreshold or (flat > allowed and not PlayerStateService:HasFlag(p, "Launched")) then
					self:Flag(p, "movement", { d = flat, allowed = allowed })
					;(root :: BasePart).CFrame = CFrame.new(last.pos) * ((root :: BasePart).CFrame - (root :: BasePart).CFrame.Position)
					pos = last.pos
				end
			end
			PlayerStateService:SetFlag(p, "Teleported", false)
			self._last[p.UserId] = { pos = pos, t = os.clock() }
		end
	end)
end

function AntiCheatService:Flag(player: Player, kind: string, data: any?)
	self._flags[player.UserId] = (self._flags[player.UserId] or 0) + 1
	Log.Warn("AntiCheat", ("Flag %s for %d (%d total)"):format(kind, player.UserId, self._flags[player.UserId]), data)
end

-- Call before server-side teleports so the next movement sample is not flagged.
function AntiCheatService:MarkTeleport(player: Player)
	PlayerStateService:SetFlag(player, "Teleported", true)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then self._last[player.UserId] = { pos = (root :: BasePart).Position, t = os.clock() } end
end

-- Generic validators used by minigames.
function AntiCheatService:WithinDistance(a: Player, b: Player, maxDist: number): boolean
	local ra = a.Character and a.Character:FindFirstChild("HumanoidRootPart")
	local rb = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
	if not ra or not rb then return false end
	return ((ra :: BasePart).Position - (rb :: BasePart).Position).Magnitude <= maxDist
end

function AntiCheatService:ValidateType(value: any, expected: string): boolean
	return typeof(value) == expected
end

function AntiCheatService:Flags(): { [number]: number } return self._flags end

return AntiCheatService
