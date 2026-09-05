--!strict
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Checkpoints = require(Systems.Checkpoints)

local M = { Id = "SpeedRun", EndsWhenOneRemains = false, EndsWhenAllFinished = true }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end
function M.Start(ctx) ctx.Track = Checkpoints.new(ctx, "Checkpoints", 1) end
function M.Update(ctx)
	ctx.Track:Update()
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		if r and r.Position.Y < -20 then Arena.Teleport(p, ctx.Track:RespawnPoint(p)); ctx.AddScore(p, -5) end
	end
	if #ctx._finishOrder >= 3 and ctx.Elapsed() > 20 then ctx.Janitor:AddThread(task.delay(10, function() ctx.End("podium_full") end)) end
end
function M.OnPlayerDied(ctx, p) ctx.Janitor:AddThread(task.delay(2, function() if p.Parent then p:LoadCharacter(); task.wait(0.5); Arena.Teleport(p, ctx.Track:RespawnPoint(p)) end end)) end
function M.AdminHook(ctx, action, args) if action == "Checkpoint" then ctx.Track:AdminComplete(args.target) return "ok" end return "unsupported" end
return M
