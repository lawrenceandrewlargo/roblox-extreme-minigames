--!strict
-- 6x10 grid; a safe path is flashed for 4s then hidden. Wrong tiles drop. Reaching the far side finishes.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local TileGrid = require(Systems.TileGrid)
local M = { Id = "MemoryTiles", EndsWhenAllFinished = true }

function M.LoadMap(ctx)
	ctx.Grid = TileGrid.new(ctx, 10, 6, 6, Vector3.new(0, 2, 520))
	Arena.Part(ctx, { Name = "StartPad", Size = Vector3.new(40, 1, 12), Position = Vector3.new(0, 2, 480), Color = Color3.fromRGB(90, 90, 100) })
	ctx.FinishPad = Arena.Part(ctx, { Name = "FinishPad", Size = Vector3.new(40, 1, 12), Position = Vector3.new(0, 2, 560), Color = Color3.fromRGB(255, 230, 0), Material = Enum.Material.Neon })
	ctx.Safe = {}
	local col = ctx.Rng:NextInteger(1, 6)
	for r = 1, 10 do
		ctx.Safe[r] = { [col] = true }
		if ctx.Rng:NextNumber() < 0.5 then local nc = math.clamp(col + (ctx.Rng:NextNumber() < 0.5 and -1 or 1), 1, 6); ctx.Safe[r][nc] = true; col = nc end
	end
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Rng:NextNumber(-18, 18), 5, 480)) end end
function M.Start(ctx)
	ctx.Grid:ForEach(function(t, r, c) if ctx.Safe[r][c] then t.Color = Color3.fromRGB(80, 255, 120) end end)
	ctx.Broadcast("Memorize", 4)
	ctx.Revealed = true
	ctx.Janitor:AddThread(task.delay(4, function() ctx.Revealed = false; ctx.Grid:ForEach(function(t) t.Color = Color3.fromRGB(200, 200, 210) end); ctx.Broadcast("Go") end))
end
function M.Update(ctx)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if not r then continue end
		if Arena.InZone(ctx.FinishPad, r.Position) then ctx.Finish(p, math.floor(100000 / math.max(1, ctx.Elapsed()))) continue end
		if r.Position.Y < -10 then ctx.Eliminate(p, "fell") continue end
		local tile = ctx.Grid:TileUnder(r.Position - Vector3.new(0, 3, 0))
		if tile and not ctx.Revealed then
			local row, col = tile:GetAttribute("Row"), tile:GetAttribute("Col")
			if not ctx.Safe[row][col] then tile.Color = Color3.new(1, 0.3, 0.3); ctx.Grid:Drop(tile, ctx, 0.15) else tile.Color = Color3.fromRGB(80, 255, 120) end
		end
	end
end
function M.AdminHook(ctx, action) if action == "Reveal" then ctx.Grid:ForEach(function(t, r, c) if ctx.Safe[r][c] then t.Color = Color3.fromRGB(80, 255, 120) end end) return "revealed" end return "unsupported" end
return M
