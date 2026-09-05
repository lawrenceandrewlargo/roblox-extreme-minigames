--!strict
-- Players are PlatformStand ragdolls the whole race; they steer by "Fling" impulses (limited by a stamina meter, server-side).
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Remotes = require(script.Parent.Parent.Services.Remotes)
local M = { Id = "RagdollRace", EndsWhenOneRemains = false, EndsWhenAllFinished = true }

function M.LoadMap(ctx)
	ctx.Slope = Arena.Part(ctx, { Name = "Slope", Size = Vector3.new(80, 2, 300), CFrame = CFrame.new(0, 40, 500) * CFrame.Angles(math.rad(-18), 0, 0), Color = Color3.fromRGB(230, 240, 255), Material = Enum.Material.Ice })
	for i = 1, 20 do Arena.Part(ctx, { Name = "Bump", Size = Vector3.new(ctx.Rng:NextNumber(4, 10), 3, ctx.Rng:NextNumber(4, 10)), CFrame = ctx.Slope.CFrame * CFrame.new(ctx.Rng:NextNumber(-35, 35), 1.5, ctx.Rng:NextNumber(-120, 120)), Color = Color3.fromRGB(180, 200, 255) }) end
	ctx.FinishPad = Arena.Part(ctx, { Name = "Finish", Size = Vector3.new(80, 2, 12), CFrame = ctx.Slope.CFrame * CFrame.new(0, 0.5, 145), Color = Color3.fromRGB(255, 230, 0), Material = Enum.Material.Neon })
end
function M.PreparePlayers(ctx)
	ctx.Stamina = {}
	for _, p in ctx.Players do
		Arena.Teleport(p, ctx.Slope.CFrame * CFrame.new(ctx.Rng:NextNumber(-35, 35), 4, -140))
		local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = true end
		ctx.Stamina[p.UserId] = 3
	end
	ctx.Janitor:Add(Remotes:OnEvent("MinigameEvent", function(p, action, dir)
		if ctx.Finished or action ~= "Fling" or typeof(dir) ~= "Vector3" or dir.Magnitude == 0 then return end
		if (ctx.Stamina[p.UserId] or 0) < 1 then return end
		ctx.Stamina[p.UserId] -= 1
		Arena.Knockback(p, Vector3.new(dir.X, 0.4, dir.Z), 30, ctx)
		ctx.Send(p, "Stamina", ctx.Stamina[p.UserId])
	end))
end
function M.Start(ctx) end
function M.Update(ctx, dt)
	for _, p in ctx.AlivePlayers() do
		ctx.Stamina[p.UserId] = math.min(3, (ctx.Stamina[p.UserId] or 0) + dt * 0.5)
		local r = Arena.Root(p)
		if r and Arena.InZone(ctx.FinishPad, r.Position) then ctx.Finish(p, math.floor(100000 / math.max(1, ctx.Elapsed()))) elseif r and r.Position.Y < -20 then Arena.Teleport(p, ctx.Slope.CFrame * CFrame.new(0, 4, -140)) end
	end
	if #ctx._finishOrder >= 3 and ctx.Elapsed() > 15 then ctx.End("podium_full") end
end
return M
