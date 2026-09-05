--!strict
-- Server entry point. Loads services in dependency order, registers minigames, starts the loop.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Log = require(Shared.Utilities.Log)

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server.Services

local order = {
	"Remotes", "DataService", "PlayerStateService", "AntiCheatService", "AnnouncementService", "MapService",
	"SpectatorService", "RewardService", "ChallengeService", "CosmeticService", "PartyService", "MinigameService", "VotingService",
	"RoundService", "AdminService",
}

local loaded = {}
for _, name in order do
	local module = Services:FindFirstChild(name) or Server.Admin:FindFirstChild(name)
	assert(module, "Missing service module " .. name)
	local ok, svc = pcall(require, module)
	if not ok then
		Log.Warn("Bootstrap", "Failed to require " .. name .. ": " .. tostring(svc))
		continue
	end
	loaded[name] = svc
	if type(svc.Init) == "function" then
		local okInit, err = pcall(svc.Init, svc)
		if not okInit then Log.Warn("Bootstrap", name .. " Init failed: " .. tostring(err)) end
	end
end
for _, name in order do
	local svc = loaded[name]
	if svc and type(svc.Start) == "function" then
		task.spawn(function()
			local ok, err = pcall(svc.Start, svc)
			if not ok then Log.Warn("Bootstrap", name .. " Start failed: " .. tostring(err)) end
		end)
	end
end

-- Register all minigame modules.
local MinigameService = loaded.MinigameService
for _, module in Server.Minigames:GetChildren() do
	if module:IsA("ModuleScript") and module.Name ~= "MinigameBase" then
		local ok, def = pcall(require, module)
		if ok then
			MinigameService:Register(def)
		else
			Log.Warn("Bootstrap", "Minigame failed to load: " .. module.Name .. " " .. tostring(def))
		end
	end
end
Log.Info("Bootstrap", ("Server ready with %d minigames"):format(MinigameService:Count()))
