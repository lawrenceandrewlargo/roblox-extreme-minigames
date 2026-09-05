--!strict
-- Lava pulses: 6s safe, 3s warning, 4s lava. Furniture platforms sink while occupied and rise back when empty.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)

local M = { Id = "FloorIsLava" }

function M.LoadMap(ctx)
	ctx.Floor = Arena.Part(ctx, { Name = "Floor", Size = Vector3.new(90, 1, 90), Position = Vector3.new(0, 0, 500), Color = Color3.fromRGB(140, 110, 80) })
	ctx.Furniture = {}
	for i = 1, 16 do
		local size = Vector3.new(ctx.Rng:NextNumber(4, 9), ctx.Rng:NextNumber(2, 6), ctx.Rng:NextNumber(4, 9))
		local f = Arena.Part(ctx, { Name = "Furniture" .. i, Size = size, Position = Vector3.new(ctx.Rng:NextNumber(-38, 38), size.Y / 2 + 0.5, 500 + ctx.Rng:NextNumber(-38, 38)), Color = Color3.fromHSV(ctx.Rng:NextNumber(), 0.4, 0.9) })
		f:SetAttribute("BaseY", f.Position.Y)
		table.insert(ctx.Furniture, f)
	end
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Rng:NextNumber(-30, 30), 4, 500 + ctx.Rng:NextNumber(-30, 30))) end end

function M.Start(ctx)
	ctx.Lava = false
	ctx.Janitor:AddThread(task.spawn(function()
		local safe = 6
		while not ctx.Finished do
			ctx.Floor.Color = Color3.fromRGB(140, 110, 80); ctx.Lava = false; ctx.Broadcast("LavaState", "Safe", safe)
			task.wait(safe)
			ctx.Floor.Color = Color3.fromRGB(255, 170, 60); ctx.Broadcast("LavaState", "Warning", 3)
			task.wait(3)
			ctx.Floor.Color = Color3.fromRGB(255, 60, 0); ctx.Floor.Material = Enum.Material.Neon; ctx.Lava = true; ctx.Broadcast("LavaState", "Lava", 4)
			task.wait(4)
			ctx.Floor.Material = Enum.Material.SmoothPlastic
			safe = math.max(2.5, safe - 0.5)
			for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 10) end
		end
	end))
end

function M.Update(ctx, dt)
	for _, f in ctx.Furniture do
		local occupied = false
		for _, p in ctx.AlivePlayers() do local r = Arena.Root(p) if r and Arena.InZone(f, r.Position - Vector3.new(0, 2.5, 0)) then occupied = true break end end
		local baseY = f:GetAttribute("BaseY") :: number
		local targetY = occupied and math.max(1, baseY - 3) or baseY
		f.Position = Vector3.new(f.Position.X, f.Position.Y + math.clamp(targetY - f.Position.Y, -1.2 * dt, 1.2 * dt), f.Position.Z)
	end
	if ctx.Lava then
		for _, p in ctx.AlivePlayers() do local r = Arena.Root(p) if r and r.Position.Y < 4 then ctx.Eliminate(p, "lava") end end
	end
end
return M
