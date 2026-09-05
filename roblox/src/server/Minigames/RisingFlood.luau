--!strict
-- Water rises steadily; procedural platform stack where any platform with 3+ players sinks.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Hazards = require(Systems.Hazards)

local M = { Id = "RisingFlood" }

function M.LoadMap(ctx)
	ctx.Platforms = {}
	local base = Vector3.new(0, 2, 500)
	for i = 1, 30 do
		local angle = i * 2.4
		local radius = 8 + (i % 5) * 6
		local plat = Arena.Part(ctx, { Name = "Plat" .. i, Size = Vector3.new(7, 1, 7), Position = base + Vector3.new(math.cos(angle) * radius, i * 3.2, math.sin(angle) * radius), Color = Color3.fromHSV(i / 30, 0.5, 1) })
		table.insert(ctx.Platforms, plat)
	end
	Arena.Part(ctx, { Name = "Ground", Size = Vector3.new(80, 1, 80), Position = base - Vector3.new(0, 1, 0), Color = Color3.fromRGB(100, 90, 80) })
end

function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(Vector3.new(ctx.Rng:NextNumber(-20, 20), 5, 500 + ctx.Rng:NextNumber(-20, 20)))) end end

function M.Start(ctx)
	ctx.StopFlood = Hazards.Flood(ctx, { Base = Vector3.new(0, -2, 500), RiseSpeed = 1.0, MaxHeight = 120 })
end

function M.Update(ctx, dt)
	for _, plat in ctx.Platforms do
		if not plat.Parent then continue end
		local n = 0
		for _, p in ctx.AlivePlayers() do local r = Arena.Root(p) if r and Arena.InZone(plat, r.Position - Vector3.new(0, 2, 0)) then n += 1 end end
		if n >= 3 then plat.Position -= Vector3.new(0, 4 * dt, 0); plat.Color = Color3.new(1, 0.3, 0.3) end
	end
	for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 1) end
end

function M.Cleanup(ctx) if ctx.StopFlood then ctx.StopFlood() end end
return M
