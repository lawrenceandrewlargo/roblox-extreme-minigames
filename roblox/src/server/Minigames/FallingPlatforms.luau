--!strict
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local TileGrid = require(Systems.TileGrid)

local M = { Id = "FallingPlatforms" }

function M.LoadMap(ctx)
	ctx.Grids = {}
	for layer = 1, 3 do ctx.Grids[layer] = TileGrid.new(ctx, 9, 9, 7, Vector3.new(0, 40 - (layer - 1) * 18, 500), { Color3.fromHSV(layer / 3, 0.5, 1) }) end
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Grids[1]:Center() + Vector3.new(ctx.Rng:NextNumber(-25, 25), 2, ctx.Rng:NextNumber(-25, 25)))) end end
function M.Start(ctx) end
function M.Update(ctx)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if not r then continue end
		for _, g in ctx.Grids do
			local tile = g:TileUnder(r.Position - Vector3.new(0, 3, 0))
			if tile then g:Drop(tile, ctx, 0.9); tile.Color = Color3.new(1, 0.4, 0.4) break end
		end
		ctx.AddScore(p, 1)
	end
	Arena.CheckKillZones(ctx, -5)
end
return M
