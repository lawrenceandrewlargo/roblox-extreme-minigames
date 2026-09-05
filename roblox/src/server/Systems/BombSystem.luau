--!strict
-- Reusable bomb (hot potato) with server-validated transfers and explosion callbacks.
local Arena = require(script.Parent.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)
local AntiCheatService = require(Services.AntiCheatService)
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

local BombSystem = {}
BombSystem.__index = BombSystem

function BombSystem.new(ctx, opts: { Fuse: number, HiddenFuse: boolean?, OnExplode: (Player?) -> (), TransferCooldown: number? })
	local self = setmetatable({ ctx = ctx, opts = opts, Holder = nil :: Player?, Remaining = opts.Fuse, _lastTransfer = 0, Active = false }, BombSystem)
	return self
end

function BombSystem:Give(target: Player?, silent: boolean?)
	local prev = self.Holder
	if prev then PlayerStateService:SetFlag(prev, "HasBomb", false); PlayerStateService:SetRole(prev, nil) end
	self.Holder = target
	if target then
		PlayerStateService:SetFlag(target, "HasBomb", true)
		PlayerStateService:SetRole(target, "Bomb")
	end
	self._lastTransfer = os.clock()
	if not silent then self.ctx.Broadcast("BombHolder", target and target.UserId or nil, self.opts.HiddenFuse and -1 or self.Remaining) end
end

function BombSystem:Start(fuse: number?)
	self.Remaining = fuse or self.opts.Fuse
	self.Active = true
end

-- Called from minigame Update. Handles touch-transfer by proximity (server authoritative) and fuse countdown.
function BombSystem:Update(dt: number)
	if not self.Active then return end
	local holder = self.Holder
	if holder and (not holder.Parent or PlayerStateService:Get(holder).State ~= "Playing") then
		-- Holder left/eliminated: pass to a random alive player.
		local alive = self.ctx.AlivePlayers()
		self:Give(alive[self.ctx.Rng:NextInteger(1, math.max(1, #alive))])
		holder = self.Holder
	end
	if holder and os.clock() - self._lastTransfer >= (self.opts.TransferCooldown or 0.6) then
		for _, other in self.ctx.AlivePlayers() do
			if other ~= holder and Arena.Distance(holder, other) <= 4.5 then
				if AntiCheatService:WithinDistance(holder, other, GameConfig.AntiCheat.BombTransferMaxDistance) then
					self:Give(other)
					break
				end
			end
		end
	end
	self.Remaining -= dt
	if not self.opts.HiddenFuse and math.floor(self.Remaining + dt) ~= math.floor(self.Remaining) then
		self.ctx.Broadcast("BombTick", math.max(0, math.ceil(self.Remaining)))
	end
	if self.Remaining <= 0 then
		self.Active = false
		local victim = self.Holder
		self:Give(nil, true)
		self.ctx.Broadcast("BombExplode", victim and victim.UserId or nil)
		self.opts.OnExplode(victim)
	end
end

function BombSystem:Stop() self.Active = false; self:Give(nil, true) end

return BombSystem
