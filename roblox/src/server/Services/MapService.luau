--!strict
-- Loads/unloads map models from ReplicatedStorage.Assets.Maps into Workspace.ActiveMap.
-- Provides marker lookup (Spawns, TeamSpawns, Checkpoints, Hazards, Objectives, HidingSpots, NPCNodes, SafeZones, KillZones).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Utilities.Log)
local Janitor = require(Shared.Utilities.Janitor)
local GameConfig = require(Shared.Config.GameConfig)

local MapService = { _current = nil :: Model?, _janitor = nil :: any, _currentId = nil :: string? }

local function container(): Folder
	local f = Workspace:FindFirstChild("ActiveMap")
	if not f then f = Instance.new("Folder"); f.Name = "ActiveMap"; f.Parent = Workspace end
	return f :: Folder
end

function MapService:Init()
	container()
end

-- Returns a fallback procedural map when the asset is missing so a round never hard-fails.
local function buildFallback(mapId: string): Model
	local model = Instance.new("Model")
	model.Name = mapId .. "_Fallback"
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Size = Vector3.new(120, 2, 120)
	floor.Position = Vector3.new(0, 0, 500)
	floor.Anchored = true
	floor.Parent = model
	local spawns = Instance.new("Folder"); spawns.Name = "Spawns"; spawns.Parent = model
	for i = 1, 24 do
		local a = Instance.new("Part")
		a.Name = "Spawn" .. i
		a.Size = Vector3.new(2, 1, 2)
		a.Transparency = 1
		a.CanCollide = false
		a.Anchored = true
		local angle = (i / 24) * math.pi * 2
		a.Position = Vector3.new(math.cos(angle) * 30, 3, 500 + math.sin(angle) * 30)
		a.Parent = spawns
	end
	local teamSpawns = Instance.new("Folder"); teamSpawns.Name = "TeamSpawns"; teamSpawns.Parent = model
	for i, name in { "Red", "Blue" } do
		local f = Instance.new("Folder"); f.Name = name; f.Parent = teamSpawns
		for j = 1, 12 do
			local a = Instance.new("Part"); a.Name = "Spawn" .. j; a.Size = Vector3.new(2,1,2); a.Transparency = 1; a.CanCollide = false; a.Anchored = true
			a.Position = Vector3.new((i == 1 and -40 or 40) + (j % 4) * 3, 3, 500 + math.floor(j / 4) * 3); a.Parent = f
		end
	end
	model:SetAttribute("IsFallback", true)
	return model
end

function MapService:Load(mapId: string): (Model, boolean)
	self:Unload()
	local janitor = Janitor.new()
	self._janitor = janitor
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local maps = assets and assets:FindFirstChild("Maps")
	local source = maps and maps:FindFirstChild(mapId)
	local model: Model
	local isFallback = false
	if source and source:IsA("Model") then
		model = source:Clone()
	else
		Log.Warn("MapService", "Map asset missing, using fallback: " .. mapId)
		model = buildFallback(mapId)
		isFallback = true
	end
	model.Name = mapId
	model.Parent = container()
	janitor:Add(model)
	self._current = model
	self._currentId = mapId
	-- Wait for streaming/physics settle with timeout so a broken map cannot hang the loop.
	local deadline = os.clock() + GameConfig.Lobby.MapLoadTimeoutSeconds
	while os.clock() < deadline and not model:FindFirstChild("Spawns") do task.wait(0.1) end
	Log.Info("MapService", "Loaded map " .. mapId, { fallback = isFallback })
	return model, isFallback
end

function MapService:Unload()
	if self._janitor then
		self._janitor:Destroy()
		self._janitor = nil
	end
	for _, child in container():GetChildren() do child:Destroy() end
	if self._currentId then Log.Info("MapService", "Unloaded map " .. self._currentId) end
	self._current = nil
	self._currentId = nil
end

function MapService:Current(): Model?
	return self._current
end

function MapService:Markers(folderName: string): { BasePart }
	local out = {}
	local m = self._current
	if not m then return out end
	local folder = m:FindFirstChild(folderName)
	if not folder then return out end
	for _, d in folder:GetDescendants() do if d:IsA("BasePart") then table.insert(out, d) end end
	return out
end

function MapService:TeamMarkers(team: string): { BasePart }
	local out = {}
	local m = self._current
	local folder = m and m:FindFirstChild("TeamSpawns")
	local tf = folder and folder:FindFirstChild(team)
	if tf then for _, d in tf:GetDescendants() do if d:IsA("BasePart") then table.insert(out, d) end end end
	if #out == 0 then return self:Markers("Spawns") end
	return out
end

function MapService:Janitor()
	return self._janitor
end

function MapService:LobbySpawn(): CFrame
	local lobby = Workspace:FindFirstChild("Lobby")
	local spawn = lobby and lobby:FindFirstChildWhichIsA("SpawnLocation", true)
	return if spawn then spawn.CFrame + Vector3.new(0, 4, 0) else CFrame.new(0, 10, 0)
end

return MapService
