--!strict
-- Creates remotes from the shared name list and applies rate limiting on every inbound call.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Names = require(ReplicatedStorage.Shared.Net.RemoteNames)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Log = require(ReplicatedStorage.Shared.Utilities.Log)

local Remotes = { _events = {}, _functions = {}, _rate = {} :: { [number]: { [string]: { n: number, t: number } } } }

function Remotes:Init()
	local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
	for _, name in Names.Events do
		assert(not self._events[name], "Duplicate remote " .. name)
		local ev = Instance.new("RemoteEvent")
		ev.Name = name
		ev.Parent = folder
		self._events[name] = ev
	end
	for _, name in Names.Functions do
		assert(not self._functions[name], "Duplicate remote " .. name)
		local fn = Instance.new("RemoteFunction")
		fn.Name = name
		fn.Parent = folder
		self._functions[name] = fn
	end
	game:GetService("Players").PlayerRemoving:Connect(function(p) self._rate[p.UserId] = nil end)
end

function Remotes:Allow(player: Player, key: string): boolean
	local limit = GameConfig.AntiCheat.RemoteRateLimitPerSecond
	local bucket = self._rate[player.UserId]
	if not bucket then bucket = {}; self._rate[player.UserId] = bucket end
	local now = os.clock()
	local entry = bucket[key]
	if not entry or now - entry.t >= 1 then
		bucket[key] = { n = 1, t = now }
		return true
	end
	entry.n += 1
	if entry.n > limit then
		if entry.n == limit + 1 then Log.Warn("Remotes", ("Rate limit hit %s by %d"):format(key, player.UserId)) end
		return false
	end
	return true
end

function Remotes:Fire(name: string, player: Player, ...: any)
	local ev = self._events[name]
	if ev then ev:FireClient(player, ...) end
end

function Remotes:FireAll(name: string, ...: any)
	local ev = self._events[name]
	if ev then ev:FireAllClients(...) end
end

function Remotes:OnEvent(name: string, handler: (Player, ...any) -> ()): RBXScriptConnection
	local ev = assert(self._events[name], "Unknown remote " .. name)
	return ev.OnServerEvent:Connect(function(player, ...)
		if not self:Allow(player, name) then return end
		handler(player, ...)
	end)
end

function Remotes:SetCallback(name: string, handler: (Player, ...any) -> any)
	local fn = assert(self._functions[name], "Unknown remote function " .. name)
	fn.OnServerInvoke = function(player, ...)
		if not self:Allow(player, name) then return { ok = false, error = "rate_limited" } end
		local ok, result = pcall(handler, player, ...)
		if not ok then
			Log.Warn("Remotes", ("Handler error %s: %s"):format(name, tostring(result)))
			return { ok = false, error = "internal" }
		end
		return result
	end
end

return Remotes
