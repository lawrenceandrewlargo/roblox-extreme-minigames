--!strict
-- Two sweeping arms on a disc: a low arm (jump) and a high arm (crouch = must be below 2.5 studs -> walk under: players
-- must stand in a "duck zone" ring). Speed ramps. Getting hit applies knockback off the disc.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)

local M = { Id = "RotatingArena" }

function M.LoadMap(ctx)
	ctx.Center = Vector3.new(0, 2, 500)
	Arena.Part(ctx, { Name = "Disc", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 70, 70), CFrame = CFrame.new(ctx.Center) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 90, 110) })
	ctx.LowArm = Arena.Part(ctx, { Name = "LowArm", Size = Vector3.new(70, 1.5, 2), Position = ctx.Center + Vector3.new(0, 1.5, 0), Color = Color3.fromRGB(255, 80, 80), CanCollide = false })
	ctx.HighArm = Arena.Part(ctx, { Name = "HighArm", Size = Vector3.new(70, 1.5, 2), Position = ctx.Center + Vector3.new(0, 4.5, 0), Color = Color3.fromRGB(80, 160, 255), CanCollide = false })
	-- Duck pads: standing on one lowers your effective height (server treats you as crouched).
	ctx.DuckPads = {}
	for i = 1, 6 do local a = i / 6 * math.pi * 2; table.insert(ctx.DuckPads, Arena.Part(ctx, { Name = "DuckPad", Size = Vector3.new(6, 0.4, 6), Position = ctx.Center + Vector3.new(math.cos(a) * 22, 0.7, math.sin(a) * 22), Color = Color3.fromRGB(80, 255, 140) })) end
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do local a = ctx.Rng:NextNumber() * math.pi * 2; local r = ctx.Rng:NextNumber(8, 30); Arena.Teleport(p, CFrame.new(ctx.Center + Vector3.new(math.cos(a) * r, 3, math.sin(a) * r))) end end
function M.Start(ctx) ctx.Angle = 0; ctx.Speed = 0.8; ctx.HitCooldown = {} end

function M.Update(ctx, dt)
	ctx.Speed = math.min(3.2, ctx.Speed + dt * 0.03)
	ctx.Angle += ctx.Speed * dt
	ctx.LowArm.CFrame = CFrame.new(ctx.Center + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, ctx.Angle, 0)
	ctx.HighArm.CFrame = CFrame.new(ctx.Center + Vector3.new(0, 4.5, 0)) * CFrame.Angles(0, -ctx.Angle * 0.7 + math.pi / 2, 0)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if not r then continue end
		if r.Position.Y < -5 then ctx.Eliminate(p, "fell") continue end
		if os.clock() - (ctx.HitCooldown[p.UserId] or 0) < 1 then continue end
		local ducked = false
		for _, pad in ctx.DuckPads do if Arena.InZone(pad, r.Position - Vector3.new(0, 2.5, 0)) then ducked = true break end end
		local feetY = r.Position.Y - 3
		local lowHit = Arena.InZone(ctx.LowArm, Vector3.new(r.Position.X, ctx.LowArm.Position.Y, r.Position.Z)) and feetY < ctx.LowArm.Position.Y + 0.8
		local highHit = Arena.InZone(ctx.HighArm, Vector3.new(r.Position.X, ctx.HighArm.Position.Y, r.Position.Z)) and not ducked
		if lowHit or highHit then
			ctx.HitCooldown[p.UserId] = os.clock()
			Arena.Knockback(p, (r.Position - ctx.Center) + Vector3.new(0, 6, 0), 40, ctx)
			ctx.Broadcast("ArmHit", p.UserId)
		else
			ctx.AddScore(p, 1)
		end
	end
end
return M
