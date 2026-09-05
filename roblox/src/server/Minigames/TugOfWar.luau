--!strict
-- Teams pull a marker by completing rhythm prompts (MinigameAction "Pull" within the prompt window). Missed prompts pull for the enemy.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Teams = require(Systems.Teams)
local Remotes = require(script.Parent.Parent.Services.Remotes)
local M = { Id = "TugOfWar", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx)
	local t = Teams.Assign(ctx, { "Red", "Blue" })
	Arena.SpawnTeam(t.Red, "Red"); Arena.SpawnTeam(t.Blue, "Blue")
	for _, p in ctx.Players do local r = Arena.Root(p) if r then r.Anchored = true end end
	ctx.Position = 0 -- -100 (Blue wins) .. +100 (Red wins)
	ctx.Window = nil
	ctx.Pulled = {}
	ctx.Janitor:Add(Remotes:OnEvent("MinigameEvent", function(p, action)
		if ctx.Finished or action ~= "Pull" or not ctx.Window then return end
		if ctx.Pulled[p.UserId] then return end
		local team = Teams.Of(ctx, p)
		if not team then return end
		ctx.Pulled[p.UserId] = true
		local onTime = os.clock() >= ctx.Window.Open and os.clock() <= ctx.Window.Close
		local delta = onTime and 4 or -3
		ctx.Position += (team == "Red" and delta or -delta)
		ctx.AddScore(p, onTime and 5 or 0)
	end))
end

function M.Start(ctx)
	ctx.Janitor:AddThread(task.spawn(function()
		while not ctx.Finished do
			local lead = ctx.Rng:NextNumber(1, 2.5)
			ctx.Broadcast("PullPrompt", lead, 0.6)
			task.wait(lead)
			ctx.Window = { Open = os.clock(), Close = os.clock() + 0.6 }
			ctx.Pulled = {}
			task.wait(0.6)
			-- Players who never pulled miss: penalty for their team.
			for _, p in ctx.AlivePlayers() do if not ctx.Pulled[p.UserId] then local team = Teams.Of(ctx, p) if team then ctx.Position += (team == "Red" and -2 or 2) end end end
			ctx.Window = nil
			ctx.Position = math.clamp(ctx.Position, -100, 100)
			ctx.Broadcast("TugPosition", ctx.Position)
			if ctx.Position >= 100 then Teams.FinishTeam(ctx, "Red") return elseif ctx.Position <= -100 then Teams.FinishTeam(ctx, "Blue") return end
			task.wait(0.4)
		end
	end))
end
function M.Finish(ctx) if not ctx.Finished or ctx.Reason == "time_up" then Teams.FinishTeam(ctx, ctx.Position >= 0 and "Red" or "Blue") end return nil end
function M.Cleanup(ctx) for _, p in ctx.Players do local r = Arena.Root(p) if r then r.Anchored = false end end end
return M
