--!strict
-- Disaster/hazard library. Each hazard is a function(ctx, opts) that schedules itself via ctx.Janitor and returns a stop function.
local TweenService = game:GetService("TweenService")
local Arena = require(script.Parent.Arena)

local Hazards = {}

local function warn_(ctx, text: string) ctx.Broadcast("HazardWarning", text) end

function Hazards.Flood(ctx, opts: { RiseSpeed: number, MaxHeight: number, Base: Vector3 })
	warn_(ctx, "Flood incoming! Get high!")
	local water = Arena.Part(ctx, { Name = "Flood", Size = Vector3.new(400, 1, 400), Position = opts.Base, Transparency = 0.4, Color = Color3.fromRGB(40, 120, 220), Material = Enum.Material.Glass, CanCollide = false })
	local level = opts.Base.Y
	local running = true
	ctx.Janitor:AddThread(task.spawn(function()
		while running and level < opts.Base.Y + opts.MaxHeight do
			task.wait(0.1)
			level += opts.RiseSpeed * 0.1
			water.Size = Vector3.new(400, math.max(1, (level - opts.Base.Y) * 2), 400)
			water.Position = Vector3.new(opts.Base.X, (level + opts.Base.Y) / 2, opts.Base.Z)
			for _, p in ctx.AlivePlayers() do
				local r = Arena.Root(p)
				if r and r.Position.Y < level - 1 then ctx.Eliminate(p, "drowned") end
			end
		end
	end))
	return function() running = false end
end

function Hazards.Meteors(ctx, opts: { Interval: number, Radius: number, Center: Vector3, Range: number, Destroys: boolean? })
	warn_(ctx, "Meteor shower! Watch the shadows!")
	local running = true
	ctx.Janitor:AddThread(task.spawn(function()
		while running do
			local target = opts.Center + Vector3.new(ctx.Rng:NextNumber(-opts.Range, opts.Range), 0, ctx.Rng:NextNumber(-opts.Range, opts.Range))
			local shadow = Arena.Part(ctx, { Name = "Shadow", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, opts.Radius * 2, opts.Radius * 2), CFrame = CFrame.new(target + Vector3.new(0, 0.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.new(1, 0.2, 0.2), Transparency = 0.4, CanCollide = false })
			task.wait(1.5)
			if not running then break end
			shadow:Destroy()
			local boom = Arena.Part(ctx, { Name = "Boom", Shape = Enum.PartType.Ball, Size = Vector3.one * opts.Radius * 2, Position = target, Color = Color3.new(1, 0.5, 0.1), Material = Enum.Material.Neon, CanCollide = false })
			for _, p in ctx.AlivePlayers() do
				local r = Arena.Root(p)
				if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(target.X, 0, target.Z)).Magnitude <= opts.Radius then
					Arena.Knockback(p, (r.Position - target + Vector3.new(0, 4, 0)), 45, ctx)
					local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
					if h then h:TakeDamage(60) end
				end
			end
			if opts.Destroys then
				local params = OverlapParams.new()
				for _, part in workspace:GetPartBoundsInRadius(target, opts.Radius, params) do
					if part:GetAttribute("Destructible") then part:Destroy() end
				end
			end
			task.delay(0.5, function() if boom.Parent then boom:Destroy() end end)
			task.wait(opts.Interval)
		end
	end))
	return function() running = false end
end

function Hazards.Tornado(ctx, opts: { Center: Vector3, Range: number, Duration: number })
	warn_(ctx, "Tornado! Stay away from the funnel!")
	local funnel = Arena.Part(ctx, { Name = "Tornado", Shape = Enum.PartType.Cylinder, Size = Vector3.new(60, 18, 18), CFrame = CFrame.new(opts.Center + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.rad(90)), Transparency = 0.5, Color = Color3.fromRGB(150, 150, 160), CanCollide = false })
	local running = true
	local pos = opts.Center
	local dir = Vector3.new(ctx.Rng:NextNumber(-1, 1), 0, ctx.Rng:NextNumber(-1, 1)).Unit
	ctx.Janitor:AddThread(task.spawn(function()
		local t = 0
		while running and t < opts.Duration do
			task.wait(0.1); t += 0.1
			pos += dir * 1.2
			if (pos - opts.Center).Magnitude > opts.Range then dir = -dir end
			funnel.CFrame = CFrame.new(pos + Vector3.new(0, 30, 0)) * CFrame.Angles(0, t, math.rad(90))
			for _, p in ctx.AlivePlayers() do
				local r = Arena.Root(p)
				if r and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude < 14 then
					Arena.Knockback(p, Vector3.new(ctx.Rng:NextNumber(-1, 1), 3, ctx.Rng:NextNumber(-1, 1)), 35, ctx)
				end
			end
		end
		funnel:Destroy()
	end))
	return function() running = false end
end

function Hazards.Earthquake(ctx, opts: { Duration: number })
	warn_(ctx, "Earthquake! Buildings are collapsing!")
	local running = true
	ctx.Janitor:AddThread(task.spawn(function()
		local t = 0
		local map = ctx.Map
		local destructibles = {}
		if map then for _, d in map:GetDescendants() do if d:IsA("BasePart") and d:GetAttribute("Destructible") then table.insert(destructibles, d) end end end
		while running and t < opts.Duration do
			task.wait(0.5); t += 0.5
			for _, p in ctx.AlivePlayers() do
				local r = Arena.Root(p)
				if r then r:ApplyImpulse(Vector3.new(ctx.Rng:NextNumber(-1, 1), 0.3, ctx.Rng:NextNumber(-1, 1)) * r.AssemblyMass * 8) end
			end
			if #destructibles > 0 and ctx.Rng:NextNumber() < 0.4 then
				local part = table.remove(destructibles, ctx.Rng:NextInteger(1, #destructibles)) :: BasePart
				if part and part.Parent then part.Anchored = false end
			end
		end
	end))
	return function() running = false end
end

function Hazards.Lightning(ctx, opts: { Interval: number, Duration: number })
	warn_(ctx, "Lightning storm! Get under cover!")
	local running = true
	ctx.Janitor:AddThread(task.spawn(function()
		local t = 0
		while running and t < opts.Duration do
			task.wait(opts.Interval); t += opts.Interval
			local alive = ctx.AlivePlayers()
			if #alive == 0 then continue end
			local p = alive[ctx.Rng:NextInteger(1, #alive)]
			local r = Arena.Root(p)
			if not r then continue end
			local covered = workspace:Raycast(r.Position, Vector3.new(0, 200, 0)) ~= nil
			local bolt = Arena.Part(ctx, { Name = "Bolt", Size = Vector3.new(1, 200, 1), Position = r.Position + Vector3.new(0, 100, 0), Color = Color3.new(1, 1, 0.6), Material = Enum.Material.Neon, CanCollide = false })
			task.delay(0.3, function() if bolt.Parent then bolt:Destroy() end end)
			if not covered then ctx.Eliminate(p, "lightning") end
		end
	end))
	return function() running = false end
end

function Hazards.Lava(ctx, opts: { Base: Vector3, RiseSpeed: number, MaxHeight: number })
	local stop = Hazards.Flood(ctx, opts)
	local f = ctx.Map and ctx.Map:FindFirstChild("Flood")
	if f and f:IsA("BasePart") then f.Name = "Lava"; f.Color = Color3.fromRGB(255, 90, 0); f.Material = Enum.Material.Neon; f.Transparency = 0.1 end
	return stop
end

Hazards.List = { "Flood", "Meteors", "Tornado", "Earthquake", "Lightning", "Lava" }

return Hazards
