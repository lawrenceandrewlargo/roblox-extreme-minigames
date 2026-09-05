--!strict
-- Server checks horizontal velocity during red; movers are zapped (eliminated). Green durations randomized; fake "yellow" warnings.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local MapService = require(script.Parent.Parent.Services.MapService)

local M = { Id = "RedLightGreenLight", EndsWhenAllFinished = true }

function M.LoadMap(ctx)
	local hasMap = #MapService:Markers("Objectives") > 0
	if not hasMap then
		Arena.Part(ctx, { Name = "Field", Size = Vector3.new(60, 1, 240), Position = Vector3.new(0, 0, 600), Color = Color3.fromRGB(120, 180, 90) })
		ctx.FinishLine = Arena.Part(ctx, { Name = "FinishLine", Size = Vector3.new(60, 1, 6), Position = Vector3.new(0, 0.6, 712), Color = Color3.new(1, 1, 1) })
		ctx.StartCF = CFrame.new(0, 4, 490)
	else
		ctx.FinishLine = MapService:Markers("Objectives")[1]
	end
end

function M.PreparePlayers(ctx)
	if ctx.StartCF then for _, p in ctx.Players do Arena.Teleport(p, ctx.StartCF * CFrame.new(ctx.Rng:NextNumber(-25, 25), 0, ctx.Rng:NextNumber(-4, 4))) end
	else Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end
end

function M.Start(ctx)
	ctx.Light = "Green"
	ctx.GraceUntil = 0
	ctx.Janitor:AddThread(task.spawn(function()
		while not ctx.Finished do
			ctx.Light = "Green"; ctx.Broadcast("Light", "Green")
			task.wait(ctx.Rng:NextNumber(2, 5))
			if ctx.Rng:NextNumber() < 0.3 then ctx.Broadcast("Light", "Yellow"); task.wait(ctx.Rng:NextNumber(0.5, 1.5)) end
			ctx.Broadcast("Light", "Red")
			ctx.GraceUntil = os.clock() + 0.6
			ctx.Light = "Red"
			task.wait(ctx.Rng:NextNumber(2, 4))
		end
	end))
end

function M.Update(ctx)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if not r then continue end
		if Arena.InZone(ctx.FinishLine, r.Position) then ctx.Finish(p, math.floor(100000 / math.max(1, ctx.Elapsed()))) continue end
		if ctx.Light == "Red" and os.clock() > ctx.GraceUntil then
			local v = r.AssemblyLinearVelocity
			if Vector3.new(v.X, 0, v.Z).Magnitude > 2 then ctx.Broadcast("Zapped", p.UserId); ctx.Eliminate(p, "moved") end
		end
	end
	if #ctx._finishOrder >= 3 and ctx.Elapsed() > 15 then ctx.End("podium_full") end
end
return M
