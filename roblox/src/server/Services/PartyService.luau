--!strict
-- Lightweight party system: invites, leader, and keeping parties on the same team when a minigame supports teams.
local Players = game:GetService("Players")
local Remotes = require(script.Parent.Remotes)

local PartyService = { _parties = {} :: { [string]: { Leader: number, Members: { number } } }, _memberOf = {} :: { [number]: string }, _invites = {} :: { [number]: { [number]: string } } }

local function newId(): string return game:GetService("HttpService"):GenerateGUID(false) end

function PartyService:Init()
	Players.PlayerRemoving:Connect(function(p) self:Leave(p) end)
	Remotes:SetCallback("PartyAction", function(player, action, targetUserId)
		if type(action) ~= "string" then return { ok = false, error = "invalid" } end
		if action == "invite" then
			if type(targetUserId) ~= "number" then return { ok = false, error = "invalid" } end
			local target = Players:GetPlayerByUserId(targetUserId)
			if not target or target == player then return { ok = false, error = "no_target" } end
			local partyId = self._memberOf[player.UserId] or self:Create(player)
			if self._parties[partyId].Leader ~= player.UserId then return { ok = false, error = "not_leader" } end
			self._invites[targetUserId] = self._invites[targetUserId] or {}
			self._invites[targetUserId][player.UserId] = partyId
			Remotes:Fire("Announcement", target, { Text = player.DisplayName .. " invited you to a party.", Duration = 6, Kind = "Info", Priority = 1 })
			return { ok = true }
		elseif action == "accept" then
			local inv = self._invites[player.UserId] and self._invites[player.UserId][targetUserId]
			if not inv or not self._parties[inv] then return { ok = false, error = "no_invite" } end
			self:Leave(player)
			table.insert(self._parties[inv].Members, player.UserId)
			self._memberOf[player.UserId] = inv
			self._invites[player.UserId] = nil
			return { ok = true, party = self._parties[inv] }
		elseif action == "leave" then
			self:Leave(player)
			return { ok = true }
		elseif action == "get" then
			local id = self._memberOf[player.UserId]
			return { ok = true, party = id and self._parties[id] or nil }
		end
		return { ok = false, error = "unknown_action" }
	end)
end

function PartyService:Create(leader: Player): string
	local id = newId()
	self._parties[id] = { Leader = leader.UserId, Members = { leader.UserId } }
	self._memberOf[leader.UserId] = id
	return id
end

function PartyService:Leave(player: Player)
	local id = self._memberOf[player.UserId]
	if not id then return end
	local party = self._parties[id]
	self._memberOf[player.UserId] = nil
	if party then
		local idx = table.find(party.Members, player.UserId)
		if idx then table.remove(party.Members, idx) end
		if #party.Members == 0 then self._parties[id] = nil elseif party.Leader == player.UserId then party.Leader = party.Members[1] end
	end
end

function PartyService:PartyOf(player: Player): string? return self._memberOf[player.UserId] end

return PartyService
