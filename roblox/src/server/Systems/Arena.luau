--!strict
-- Spawning, teleport, kill-zone and boundary helpers used by all minigames.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Services = script.Parent.Parent.Services
local MapService = require(Services.MapService)
local AntiCheatService = require(Services.AntiCheatService)

local Arena = {}

function Arena.Teleport(player: Player, cf: CFrame)
	local char = player.Character
	if not char then return end
	AntiCheatService:MarkTeleport(player)
	char:PivotTo(cf)
end

function Arena.SpawnAll(players: { Player }, markerFolder: string?, rng: Random?)
	local markers = MapService:Markers(markerFolder or "Spawns")
	local r = rng or Random.new()
	for i, p in players do
		local m = markers[(i - 1) % math.max(1, #markers) + 1]
		local cf = m and (m.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(0, 10, 500)
		if #markers < #players then cf = cf + Vector3.new(r:NextNumber(-3, 3), 0, r:NextNumber(-3, 3)) end
		Arena.Teleport(p, cf)
	end
end

function Arena.SpawnTeam(players: { Player }, team: string)
	local markers = MapService:TeamMarkers(team)
	for i, p in players do
		local m = markers[(i - 1) % math.max(1, #markers) + 1]
		Arena.Teleport(p, m and (m.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(0, 10, 500))
	end
end

-- Eliminates players who fall below a Y threshold or touch KillZones. Call from Update.
function Arena.CheckKillZones(ctx, minY: number?)
	local kill = MapService:Markers("KillZones")
	local floorY = minY or -50
	for _, p in ctx.AlivePlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then continue end
		if root.Position.Y < floorY then ctx.Eliminate(p, "fell") continue end
		for _, z in kill do
			local rel = z.CFrame:PointToObjectSpace(root.Position)
			local h = z.Size / 2
			if math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y and math.abs(rel.Z) <= h.Z then ctx.Eliminate(p, "killzone") break end
		end
	end
end

function Arena.InZone(part: BasePart, position: Vector3): boolean
	local rel = part.CFrame:PointToObjectSpace(position)
	local h = part.Size / 2
	return math.abs(rel.X) <= h.X and math.abs(rel.Y) <= h.Y + 2 and math.abs(rel.Z) <= h.Z
end

function Arena.Root(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Arena.Distance(a: Player, b: Player): number
	local ra, rb = Arena.Root(a), Arena.Root(b)
	if not ra or not rb then return math.huge end
	return (ra.Position - rb.Position).Magnitude
end

function Arena.Part(ctx, props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do (part :: any)[k] = v end
	part.Parent = ctx.Map or Workspace.ActiveMap
	ctx.Janitor:Add(part)
	return part
end

function Arena.Knockback(target: Player, direction: Vector3, force: number, ctx)
	local root = Arena.Root(target)
	if not root then return end
	local PlayerStateService = require(Services.PlayerStateService)
	PlayerStateService:SetFlag(target, "Launched", true)
	root:ApplyImpulse(direction.Unit * force * root.AssemblyMass)
	ctx.Janitor:AddThread(task.delay(1.5, function() PlayerStateService:SetFlag(target, "Launched", false) end))
end

function Arena.Alive(ctx): { Player } return ctx.AlivePlayers() end
function Arena.Players(): { Player } return Players:GetPlayers() end

return Arena
