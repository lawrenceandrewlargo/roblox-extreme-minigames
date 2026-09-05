--!strict
-- Symmetric payload: cart moves toward whichever team has more players within 10 studs. Deliver to your goal to win.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Teams = require(Systems.Teams)
local M = { Id = "PushThePayload", EndsWhenOneRemains = false }

function M.LoadMap(ctx)
	Arena.Part(ctx, { Name = "Street", Size = Vector3.new(30, 1, 200), Position = Vector3.new(0, 0, 500), Color = Color3.fromRGB(90, 90, 95) })
	ctx.Cart = Arena.Part(ctx, { Name = "Payload", Size = Vector3.new(6, 4, 8), Position = Vector3.new(0, 3, 500), Color = Color3.fromRGB(200, 170, 60) })
	ctx.GoalRed = Arena.Part(ctx, { Name = "GoalRed", Size = Vector3.new(30, 1, 8), Position = Vector3.new(0, 0.6, 596), Color = Color3.fromRGB(255, 80, 80) })
	ctx.GoalBlue = Arena.Part(ctx, { Name = "GoalBlue", Size = Vector3.new(30, 1, 8), Position = Vector3.new(0, 0.6, 404), Color = Color3.fromRGB(80, 120, 255) })
end
function M.PreparePlayers(ctx)
	local t = Teams.Assign(ctx, { "Red", "Blue" })
	for i, p in t.Red do Arena.Teleport(p, CFrame.new((i % 5 - 2) * 4, 4, 470)) end
	for i, p in t.Blue do Arena.Teleport(p, CFrame.new((i % 5 - 2) * 4, 4, 530)) end
end
function M.Start(ctx) end
function M.Update(ctx, dt)
	local red, blue = 0, 0
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if r and (r.Position - ctx.Cart.Position).Magnitude < 10 then
			local team = Teams.Of(ctx, p)
			if team == "Red" then red += 1 elseif team == "Blue" then blue += 1 end
			ctx.AddScore(p, 1)
		end
	end
	local push = 0
	if red > blue then push = math.min(3, red - blue) * 1.5 elseif blue > red then push = -math.min(3, blue - red) * 1.5 end
	ctx.Cart.Position += Vector3.new(0, 0, push * dt)
	ctx.Broadcast("Payload", ctx.Cart.Position.Z, red, blue)
	if Arena.InZone(ctx.GoalRed, ctx.Cart.Position - Vector3.new(0, 2.5, 0)) then Teams.FinishTeam(ctx, "Red") elseif Arena.InZone(ctx.GoalBlue, ctx.Cart.Position - Vector3.new(0, 2.5, 0)) then Teams.FinishTeam(ctx, "Blue") end
end
function M.Finish(ctx) if ctx.Reason == "time_up" then Teams.FinishTeam(ctx, ctx.Cart.Position.Z >= 500 and "Red" or "Blue") end return nil end
return M
