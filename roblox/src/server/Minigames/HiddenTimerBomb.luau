--!strict
-- Distinct from BombTag: unknown fuse (random 8-30s), explosion eliminates holder AND anyone within radius,
-- arena boundary shrinks after each explosion, forcing proximity.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local BombSystem = require(Systems.BombSystem)

local M = { Id = "HiddenTimerBomb" }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

function M.Start(ctx)
	local center = ctx.Map and ctx.Map:FindFirstChild("Floor") and (ctx.Map.Floor :: BasePart).Position or Vector3.new(0, 0, 500)
	ctx.Radius = 55
	ctx.Ring = Arena.Part(ctx, { Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, ctx.Radius * 2, ctx.Radius * 2), CFrame = CFrame.new(center + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.6, Color = Color3.fromRGB(255, 60, 60), CanCollide = false })
	ctx.Center = center
	local function arm()
		local alive = ctx.AlivePlayers()
		if #alive <= 1 or ctx.Finished then return end
		ctx.Bomb:Give(alive[ctx.Rng:NextInteger(1, #alive)])
		ctx.Bomb:Start(ctx.Rng:NextNumber(8, 30))
	end
	ctx.Bomb = BombSystem.new(ctx, { Fuse = 20, HiddenFuse = true, OnExplode = function(victim)
		if victim then
			local vr = Arena.Root(victim)
			for _, p in ctx.AlivePlayers() do
				local r = Arena.Root(p)
				if p ~= victim and vr and r and (r.Position - vr.Position).Magnitude < 9 then ctx.Eliminate(p, "blast") end
			end
			ctx.Eliminate(victim, "exploded")
		end
		ctx.Radius = math.max(14, ctx.Radius * 0.75)
		ctx.Ring.Size = Vector3.new(0.5, ctx.Radius * 2, ctx.Radius * 2)
		ctx.Broadcast("ArenaShrink", ctx.Radius)
		task.delay(2, arm)
	end })
	arm()
end

function M.Update(ctx, dt)
	ctx.Bomb:Update(dt)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if r then
			local flat = Vector3.new(r.Position.X - ctx.Center.X, 0, r.Position.Z - ctx.Center.Z)
			if flat.Magnitude > ctx.Radius then
				local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if h then h:TakeDamage(12 * dt * 10) end
				ctx.AddScore(p, 0)
			else
				ctx.AddScore(p, 1)
			end
		end
	end
	Arena.CheckKillZones(ctx)
end

function M.AdminHook(ctx, action, args)
	if action == "GiveBomb" then ctx.Bomb:Give(args.target) return "given" end
	return "unsupported"
end

function M.Cleanup(ctx) ctx.Bomb:Stop() end
return M
