--!strict
-- Narrow bridge with handhold pads. Fans switch direction every 4-7s with a 1.5s warning; players on a handhold pad are immune.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local M = { Id = "FanSurvival" }

function M.LoadMap(ctx)
	ctx.Bridge = Arena.Part(ctx, { Name = "Bridge", Size = Vector3.new(14, 1, 120), Position = Vector3.new(0, 30, 500), Color = Color3.fromRGB(150, 150, 160) })
	ctx.Holds = {}
	for i = 1, 8 do table.insert(ctx.Holds, Arena.Part(ctx, { Name = "Handhold", Size = Vector3.new(3, 0.3, 3), Position = Vector3.new((i % 2 == 0) and 5 or -5, 30.65, 445 + i * 13), Color = Color3.fromRGB(255, 200, 60) })) end
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Rng:NextNumber(-5, 5), 34, 500 + ctx.Rng:NextNumber(-50, 50))) end end
function M.Start(ctx)
	ctx.Wind = Vector3.zero
	ctx.Janitor:AddThread(task.spawn(function()
		while not ctx.Finished do
			task.wait(ctx.Rng:NextNumber(4, 7))
			local dir = (ctx.Rng:NextNumber() < 0.5) and Vector3.new(1, 0, 0) or Vector3.new(-1, 0, 0)
			ctx.Broadcast("WindWarning", dir); task.wait(1.5)
			ctx.Wind = dir * ctx.Rng:NextNumber(18, 32); ctx.Broadcast("Wind", ctx.Wind)
			task.wait(3); ctx.Wind = Vector3.zero; ctx.Broadcast("Wind", ctx.Wind)
			for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 10) end
		end
	end))
end
function M.Update(ctx, dt)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if not r then continue end
		if r.Position.Y < 10 then ctx.Eliminate(p, "blown_off") continue end
		if ctx.Wind.Magnitude > 0 then
			local holding = false
			for _, h in ctx.Holds do if Arena.InZone(h, r.Position - Vector3.new(0, 3, 0)) then holding = true break end end
			if not holding then r:ApplyImpulse(ctx.Wind * r.AssemblyMass * dt) end
		end
	end
end
return M
