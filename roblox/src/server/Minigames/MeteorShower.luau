--!strict
-- Procedural tile floor; meteors permanently delete tiles; interval accelerates.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local TileGrid = require(Systems.TileGrid)

local M = { Id = "MeteorShower" }

function M.LoadMap(ctx) ctx.Grid = TileGrid.new(ctx, 12, 12, 8, Vector3.new(0, 2, 500)) end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Grid:Center() + Vector3.new(ctx.Rng:NextNumber(-30, 30), 2, ctx.Rng:NextNumber(-30, 30)))) end end

function M.Start(ctx) ctx.Next = 2; ctx.Interval = 1.6 end

function M.Update(ctx, dt)
	ctx.Next -= dt
	if ctx.Next <= 0 then
		ctx.Interval = math.max(0.45, ctx.Interval * 0.96)
		ctx.Next = ctx.Interval
		local target = ctx.Grid:Center() + Vector3.new(ctx.Rng:NextNumber(-44, 44), -2, ctx.Rng:NextNumber(-44, 44))
		local shadow = Arena.Part(ctx, { Name = "Shadow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 14, 14), CFrame = CFrame.new(target + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.new(1, 0.2, 0.2), Transparency = 0.4, CanCollide = false })
		ctx.Janitor:AddThread(task.delay(1.3, function()
			if ctx.Finished then return end
			shadow:Destroy()
			for _, p in ctx.AlivePlayers() do
				local r = Arena.Root(p)
				if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude < 7 then ctx.Eliminate(p, "meteor") end
			end
			local tile = ctx.Grid:TileUnder(target + Vector3.new(0, 2, 0))
			if tile then tile:Destroy() end
			for _, off in { Vector3.new(8, 0, 0), Vector3.new(-8, 0, 0), Vector3.new(0, 0, 8), Vector3.new(0, 0, -8) } do
				if ctx.Rng:NextNumber() < 0.4 then local t2 = ctx.Grid:TileUnder(target + off + Vector3.new(0, 2, 0)) if t2 then t2:Destroy() end end
			end
			ctx.Broadcast("MeteorImpact", target)
		end))
	end
	for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 1) end
	Arena.CheckKillZones(ctx, -10)
end
return M
