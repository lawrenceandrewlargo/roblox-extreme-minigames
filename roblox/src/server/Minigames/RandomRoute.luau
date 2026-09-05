--!strict
-- Builds a fresh procedural course each round from segment generators (gaps, zigzag, pillars, moving pads).
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local TweenService = game:GetService("TweenService")

local M = { Id = "RandomRoute", EndsWhenOneRemains = false, EndsWhenAllFinished = true }

local SEGMENTS = {
	Gaps = function(ctx, cursor: Vector3) for i = 1, 5 do Arena.Part(ctx, { Size = Vector3.new(8, 1, 6), Position = cursor + Vector3.new(0, 0, i * 11), Color = Color3.fromRGB(120, 200, 255) }) end return cursor + Vector3.new(0, 0, 60) end,
	Zigzag = function(ctx, cursor: Vector3) for i = 1, 6 do Arena.Part(ctx, { Size = Vector3.new(6, 1, 6), Position = cursor + Vector3.new((i % 2 == 0) and 7 or -7, 0, i * 9), Color = Color3.fromRGB(255, 200, 120) }) end return cursor + Vector3.new(0, 0, 60) end,
	Pillars = function(ctx, cursor: Vector3) for i = 1, 8 do Arena.Part(ctx, { Size = Vector3.new(3, 1, 3), Position = cursor + Vector3.new(ctx.Rng:NextNumber(-8, 8), (i % 3) * 2, i * 7), Color = Color3.fromRGB(200, 120, 255) }) end return cursor + Vector3.new(0, 0, 62) end,
	Movers = function(ctx, cursor: Vector3)
		for i = 1, 4 do
			local pad = Arena.Part(ctx, { Size = Vector3.new(6, 1, 6), Position = cursor + Vector3.new(-10, 0, i * 14), Color = Color3.fromRGB(255, 120, 120) })
			local tween = TweenService:Create(pad, TweenInfo.new(2 + i * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = pad.Position + Vector3.new(20, 0, 0) })
			tween:Play(); ctx.Janitor:Add(tween, "Cancel")
		end
		return cursor + Vector3.new(0, 0, 66)
	end,
	Stairs = function(ctx, cursor: Vector3) for i = 1, 8 do Arena.Part(ctx, { Size = Vector3.new(10, 1, 5), Position = cursor + Vector3.new(0, i * 2.5, i * 6), Color = Color3.fromRGB(150, 255, 150) }) end return cursor + Vector3.new(0, 20, 54) end,
}

function M.LoadMap(ctx)
	local start = Vector3.new(0, 5, 500)
	Arena.Part(ctx, { Name = "StartPad", Size = Vector3.new(30, 1, 20), Position = start, Color = Color3.fromRGB(80, 80, 90) })
	local cursor = start + Vector3.new(0, 0, 10)
	local keys = {} for k in SEGMENTS do table.insert(keys, k) end table.sort(keys)
	for _ = 1, 5 do cursor = SEGMENTS[keys[ctx.Rng:NextInteger(1, #keys)]](ctx, cursor) end
	ctx.FinishPad = Arena.Part(ctx, { Name = "FinishPad", Size = Vector3.new(30, 1, 20), Position = cursor + Vector3.new(0, 0, 12), Color = Color3.fromRGB(255, 230, 0), Material = Enum.Material.Neon })
	ctx.StartCF = CFrame.new(start + Vector3.new(0, 4, -5))
end

function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, ctx.StartCF * CFrame.new(ctx.Rng:NextNumber(-12, 12), 0, ctx.Rng:NextNumber(-6, 6))) end end
function M.Start(ctx) end
function M.Update(ctx)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if not r then continue end
		if Arena.InZone(ctx.FinishPad, r.Position) then ctx.Finish(p, math.floor(100000 / math.max(1, ctx.Elapsed())))
		elseif r.Position.Y < -20 then Arena.Teleport(p, ctx.StartCF) end
	end
	if #ctx._finishOrder >= 3 and ctx.Elapsed() > 20 then ctx.End("podium_full") end
end
return M
