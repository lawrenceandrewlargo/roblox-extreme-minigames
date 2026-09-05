--!strict
-- 3 lives. Punch (MinigameAction "Punch") applies knockback to nearby players; platform shrinks every 20s.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Remotes = require(script.Parent.Parent.Services.Remotes)

local M = { Id = "KnockbackArena" }

function M.LoadMap(ctx)
	ctx.Center = Vector3.new(0, 2, 500)
	ctx.Radius = 40
	ctx.Platform = Arena.Part(ctx, { Name = "Platform", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 80, 80), CFrame = CFrame.new(ctx.Center) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(200, 200, 220) })
end
function M.PreparePlayers(ctx)
	ctx.Lives, ctx.LastPunch = {}, {}
	for _, p in ctx.Players do ctx.Lives[p.UserId] = 3; local a = ctx.Rng:NextNumber() * math.pi * 2; Arena.Teleport(p, CFrame.new(ctx.Center + Vector3.new(math.cos(a) * 25, 3, math.sin(a) * 25))) end
	local mult = ctx.Modified("KnockbackMultiplier", 1)
	ctx.Janitor:Add(Remotes:OnEvent("MinigameEvent", function(p, action)
		if ctx.Finished or action ~= "Punch" then return end
		if os.clock() - (ctx.LastPunch[p.UserId] or 0) < 0.8 then return end
		local pr = Arena.Root(p)
		if not pr then return end
		ctx.LastPunch[p.UserId] = os.clock()
		for _, other in ctx.AlivePlayers() do
			if other == p then continue end
			local orr = Arena.Root(other)
			if orr and (orr.Position - pr.Position).Magnitude < 6 then
				local dir = (orr.Position - pr.Position) * Vector3.new(1, 0, 1) + Vector3.new(0, 0.6, 0)
				if pr.CFrame.LookVector:Dot(dir.Unit) > 0.2 then Arena.Knockback(other, dir, 55 * mult, ctx); ctx.AddScore(p, 5); ctx.Broadcast("Punch", p.UserId, other.UserId) end
			end
		end
	end))
end
function M.Start(ctx) ctx.NextShrink = 20 end
function M.Update(ctx, dt)
	ctx.NextShrink -= dt
	if ctx.NextShrink <= 0 then ctx.NextShrink = 20; ctx.Radius = math.max(10, ctx.Radius * 0.75); ctx.Platform.Size = Vector3.new(2, ctx.Radius * 2, ctx.Radius * 2); ctx.Broadcast("ArenaShrink", ctx.Radius) end
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if r and r.Position.Y < -15 then
			ctx.Lives[p.UserId] -= 1
			ctx.Send(p, "Lives", ctx.Lives[p.UserId])
			if ctx.Lives[p.UserId] <= 0 then ctx.Eliminate(p, "out_of_lives") else Arena.Teleport(p, CFrame.new(ctx.Center + Vector3.new(0, 6, 0))) end
		end
	end
end
return M
