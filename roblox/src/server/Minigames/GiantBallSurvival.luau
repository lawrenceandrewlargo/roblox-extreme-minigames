--!strict
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local M = { Id = "GiantBallSurvival" }

function M.LoadMap(ctx)
	ctx.Slope = Arena.Part(ctx, { Name = "Slope", Size = Vector3.new(60, 2, 220), CFrame = CFrame.new(0, 20, 500) * CFrame.Angles(math.rad(-12), 0, 0), Color = Color3.fromRGB(120, 140, 100) })
	Arena.Part(ctx, { Name = "WallL", Size = Vector3.new(2, 16, 220), CFrame = ctx.Slope.CFrame * CFrame.new(-31, 6, 0), Transparency = 0.5 })
	Arena.Part(ctx, { Name = "WallR", Size = Vector3.new(2, 16, 220), CFrame = ctx.Slope.CFrame * CFrame.new(31, 6, 0), Transparency = 0.5 })
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, ctx.Slope.CFrame * CFrame.new(ctx.Rng:NextNumber(-25, 25), 5, 60)) end end
function M.Start(ctx) ctx.Next = 1.5; ctx.Interval = 2.2 end
function M.Update(ctx, dt)
	ctx.Next -= dt
	if ctx.Next <= 0 then
		ctx.Interval = math.max(0.6, ctx.Interval * 0.97); ctx.Next = ctx.Interval
		local size = ctx.Rng:NextNumber(6, 14)
		local ball = Arena.Part(ctx, { Name = "Boulder", Shape = Enum.PartType.Ball, Size = Vector3.one * size, CFrame = ctx.Slope.CFrame * CFrame.new(ctx.Rng:NextNumber(-24, 24), size / 2 + 3, -100), Color = Color3.fromRGB(110, 100, 90), Anchored = false, Material = Enum.Material.Slate })
		ball.AssemblyLinearVelocity = ctx.Slope.CFrame.LookVector * ctx.Rng:NextNumber(20, 40)
		ctx.Janitor:AddThread(task.delay(14, function() if ball.Parent then ball:Destroy() end end))
		ctx.Janitor:Add(ball.Touched:Connect(function(hit)
			local p = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if p and ball.AssemblyLinearVelocity.Magnitude > 8 then Arena.Knockback(p, ball.AssemblyLinearVelocity + Vector3.new(0, 30, 0), 50, ctx); local h = hit.Parent:FindFirstChildOfClass("Humanoid") if h then h:TakeDamage(35) end end
		end))
	end
	for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 1); local r = Arena.Root(p) if r and r.Position.Y < -10 then ctx.Eliminate(p, "fell") end end
end
return M
