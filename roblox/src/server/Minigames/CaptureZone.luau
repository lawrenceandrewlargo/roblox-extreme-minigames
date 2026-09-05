--!strict
-- 3 zones; a team holding a zone uncontested earns 1 point/sec. Zones rotate every 30s. First to 150 or highest on time.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Teams = require(Systems.Teams)
local MapService = require(script.Parent.Parent.Services.MapService)
local M = { Id = "CaptureZone", EndsWhenOneRemains = false }

local function placeZones(ctx)
	for _, z in ctx.Zones do z:Destroy() end
	ctx.Zones = {}
	local marks = MapService:Markers("Objectives")
	if #marks == 0 then marks = MapService:Markers("Spawns") end
	local TableUtil = require(game:GetService("ReplicatedStorage").Shared.Utilities.TableUtil)
	local picks = TableUtil.Shuffle(marks, ctx.Rng)
	for i = 1, 3 do
		local m = picks[i]
		local pos = m and m.Position or Vector3.new(i * 25 - 50, 2, 500)
		ctx.Zones[i] = Arena.Part(ctx, { Name = "Zone" .. i, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 16, 16), CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.new(1, 1, 1), Transparency = 0.3, CanCollide = false })
	end
	ctx.Broadcast("ZonesMoved")
end

function M.PreparePlayers(ctx)
	local t = Teams.Assign(ctx, { "Red", "Blue" })
	Arena.SpawnTeam(t.Red, "Red"); Arena.SpawnTeam(t.Blue, "Blue")
	ctx.TeamScore = { Red = 0, Blue = 0 }
	ctx.Zones = {}
end
function M.Start(ctx) placeZones(ctx); ctx.NextRotate = 30 end
function M.Update(ctx, dt)
	ctx.NextRotate -= dt
	if ctx.NextRotate <= 0 then ctx.NextRotate = 30; placeZones(ctx) end
	for _, z in ctx.Zones do
		local red, blue = 0, 0
		for _, p in ctx.AlivePlayers() do
			local r = Arena.Root(p)
			if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(z.Position.X, 0, z.Position.Z)).Magnitude < 8 then
				local team = Teams.Of(ctx, p)
				if team == "Red" then red += 1 elseif team == "Blue" then blue += 1 end
				ctx.AddScore(p, 1)
			end
		end
		if red > 0 and blue == 0 then ctx.TeamScore.Red += dt; z.Color = Color3.fromRGB(255, 80, 80) elseif blue > 0 and red == 0 then ctx.TeamScore.Blue += dt; z.Color = Color3.fromRGB(80, 120, 255) elseif red > 0 and blue > 0 then z.Color = Color3.fromRGB(255, 200, 80) end
	end
	ctx.Broadcast("TeamScore", math.floor(ctx.TeamScore.Red), math.floor(ctx.TeamScore.Blue))
	if ctx.TeamScore.Red >= 150 then Teams.FinishTeam(ctx, "Red") elseif ctx.TeamScore.Blue >= 150 then Teams.FinishTeam(ctx, "Blue") end
end
function M.Finish(ctx) if ctx.Reason == "time_up" then Teams.FinishTeam(ctx, ctx.TeamScore.Red >= ctx.TeamScore.Blue and "Red" or "Blue") end return nil end
return M
