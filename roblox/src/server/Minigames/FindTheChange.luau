--!strict
-- 5 rounds: study objects for 6s, blackout 2s (objects hidden), one object changes (moved/recolored/resized). First touch scores.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local M = { Id = "FindTheChange", EndsWhenOneRemains = false }

function M.LoadMap(ctx)
	Arena.Part(ctx, { Name = "Room", Size = Vector3.new(60, 1, 60), Position = Vector3.new(0, 0, 500), Color = Color3.fromRGB(120, 100, 90) })
	ctx.Objects = {}
	for i = 1, 14 do
		table.insert(ctx.Objects, Arena.Part(ctx, { Name = "Obj" .. i, Size = Vector3.new(ctx.Rng:NextNumber(2, 4), ctx.Rng:NextNumber(2, 5), ctx.Rng:NextNumber(2, 4)), Position = Vector3.new(ctx.Rng:NextNumber(-25, 25), 2.5, 500 + ctx.Rng:NextNumber(-25, 25)), Color = Color3.fromHSV(ctx.Rng:NextNumber(), 0.6, 0.95) }))
	end
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Rng:NextNumber(-20, 20), 4, 500 + ctx.Rng:NextNumber(-20, 20))) end end
function M.Start(ctx)
	ctx.Janitor:AddThread(task.spawn(function()
		for round = 1, 5 do
			if ctx.Finished then return end
			ctx.Changed = nil
			ctx.Broadcast("Study", 6); task.wait(6)
			for _, o in ctx.Objects do o.Transparency = 1 end
			ctx.Broadcast("Blackout", 2); task.wait(2)
			local o = ctx.Objects[ctx.Rng:NextInteger(1, #ctx.Objects)]
			local kind = ctx.Rng:NextInteger(1, 3)
			if kind == 1 then o.Position += Vector3.new(ctx.Rng:NextNumber(-6, 6), 0, ctx.Rng:NextNumber(-6, 6)) elseif kind == 2 then o.Color = Color3.fromHSV(ctx.Rng:NextNumber(), 0.8, 1) else o.Size = o.Size * 1.6; o.Position += Vector3.new(0, o.Size.Y * 0.2, 0) end
			for _, obj in ctx.Objects do obj.Transparency = 0 end
			ctx.Changed = o; ctx.Claimed = false
			ctx.Broadcast("Find", 10)
			local t = 0
			while t < 10 and not ctx.Claimed do task.wait(0.1); t += 0.1 end
			ctx.Broadcast("Answer", o.Name)
			task.wait(2)
		end
		ctx.End("rounds_complete")
	end))
end
function M.Update(ctx)
	if not ctx.Changed or ctx.Claimed then return end
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if r and (r.Position - ctx.Changed.Position).Magnitude < (ctx.Changed.Size.Magnitude / 2 + 3) then ctx.Claimed = true; ctx.AddScore(p, 30); ctx.Broadcast("Found", p.UserId) break end
	end
end
return M
