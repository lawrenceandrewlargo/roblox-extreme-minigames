--!strict
-- Server-side spectate target validation. Hidden-information games restrict targets to the spectator's own role team.
local Players = game:GetService("Players")
local Remotes = require(script.Parent.Remotes)
local PlayerStateService = require(script.Parent.PlayerStateService)

local SpectatorService = { _spectating = {} :: { [number]: { target: number?, restricted: boolean } } }

function SpectatorService:Init()
	Remotes:SetCallback("RequestSpectate", function(player, direction)
		local entry = self._spectating[player.UserId]
		if not entry then return { ok = false, error = "not_spectating" } end
		local candidates = self:AllowedTargets(player)
		if #candidates == 0 then return { ok = true, target = nil } end
		local idx = 1
		for i, p in candidates do if p.UserId == entry.target then idx = i break end end
		if direction == "next" then idx = idx % #candidates + 1 elseif direction == "prev" then idx = (idx - 2) % #candidates + 1 end
		entry.target = candidates[idx].UserId
		Remotes:Fire("SpectateTarget", player, entry.target)
		return { ok = true, target = entry.target }
	end)
	Players.PlayerRemoving:Connect(function(p) self._spectating[p.UserId] = nil end)
end

function SpectatorService:AllowedTargets(player: Player): { Player }
	local entry = self._spectating[player.UserId]
	local myRole = PlayerStateService:Get(player).Role
	local out = {}
	for _, p in PlayerStateService:Alive() do
		if p == player then continue end
		if entry and entry.restricted and myRole and PlayerStateService:Get(p).Role ~= myRole then continue end
		table.insert(out, p)
	end
	return out
end

function SpectatorService:Begin(player: Player, restricted: boolean)
	self._spectating[player.UserId] = { target = nil, restricted = restricted }
	local targets = self:AllowedTargets(player)
	local target = targets[1] and targets[1].UserId or nil
	self._spectating[player.UserId].target = target
	Remotes:Fire("SpectateTarget", player, target)
end

function SpectatorService:Stop(player: Player)
	self._spectating[player.UserId] = nil
	Remotes:Fire("SpectateTarget", player, nil)
end

function SpectatorService:StopAll()
	for _, p in Players:GetPlayers() do self:Stop(p) end
end

return SpectatorService
