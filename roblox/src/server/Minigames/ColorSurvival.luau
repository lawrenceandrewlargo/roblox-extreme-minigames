--!strict
-- Colored tile grid. A color is announced; after a delay every other tile drops. 20% of calls are "fake" (announced color
-- flashes then switches with 1s left). Delay shrinks each round.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local TileGrid = require(Systems.TileGrid)

local M = { Id = "ColorSurvival" }
local COLORS = { { "Red", Color3.fromRGB(255, 70, 70) }, { "Blue", Color3.fromRGB(70, 120, 255) }, { "Green", Color3.fromRGB(80, 220, 100) }, { "Yellow", Color3.fromRGB(255, 230, 60) } }

local function paint(ctx)
	ctx.Grid:ForEach(function(tile) local c = COLORS[ctx.Rng:NextInteger(1, #COLORS)]; tile.Color = c[2]; tile:SetAttribute("ColorName", c[1]); tile.CanCollide = true; tile.Transparency = 0 end)
end

function M.LoadMap(ctx) ctx.Grid = TileGrid.new(ctx, 10, 10, 8, Vector3.new(0, 2, 500)) end
function M.PreparePlayers(ctx) paint(ctx); for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Grid:Center() + Vector3.new(ctx.Rng:NextNumber(-30, 30), 2, ctx.Rng:NextNumber(-30, 30)))) end end

function M.Start(ctx)
	ctx.Delay = 5
	ctx.Janitor:AddThread(task.spawn(function()
		task.wait(2)
		while not ctx.Finished do
			local pick = COLORS[ctx.Rng:NextInteger(1, #COLORS)]
			local fake = ctx.Rng:NextNumber() < 0.2
			ctx.Broadcast("ColorCall", pick[1], ctx.Delay, false)
			task.wait(math.max(0.5, ctx.Delay - 1))
			if fake then
				local other = pick
				while other == pick do other = COLORS[ctx.Rng:NextInteger(1, #COLORS)] end
				pick = other
				ctx.Broadcast("ColorCall", pick[1], 1, true)
			end
			task.wait(1)
			if ctx.Finished then break end
			ctx.Grid:ForEach(function(tile) if tile:GetAttribute("ColorName") ~= pick[1] then tile.CanCollide = false; tile.Transparency = 0.85 end end)
			task.wait(2.5)
			for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 10) end
			paint(ctx)
			ctx.Delay = math.max(1.6, ctx.Delay - 0.35)
			task.wait(1)
		end
	end))
end

function M.Update(ctx) Arena.CheckKillZones(ctx, -10) end
return M
