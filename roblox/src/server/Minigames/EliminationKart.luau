--!strict
-- Continuous laps; every 12 seconds the last-place kart is eliminated until one remains.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Karts = require(Systems.Karts)
local Checkpoints = require(Systems.Checkpoints)
local MapService = require(script.Parent.Parent.Services.MapService)

local M = { Id = "EliminationKart" }

function M.PreparePlayers(ctx) Karts.SpawnAll(ctx, MapService:Markers("Spawns")) end

function M.Start(ctx)
	ctx.Track = Checkpoints.new(ctx, "Checkpoints", 99)
	ctx.NextCut = 15
	Karts.ApplyBoostPads(ctx, MapService)
end

function M.Update(ctx, dt)
	ctx.Track:Update()
	ctx.NextCut -= dt
	if math.ceil(ctx.NextCut + dt) ~= math.ceil(ctx.NextCut) then ctx.Broadcast("CutTimer", math.ceil(ctx.NextCut)) end
	if ctx.NextCut <= 0 then
		ctx.NextCut = 12
		local ranked = ctx.Track:Rank()
		local last = ranked[#ranked]
		if last and #ranked > 1 then
			local k = Karts.Of(ctx, last)
			if k then k:Destroy() end
			ctx.Eliminate(last, "last_place")
		end
	end
	for _, p in ctx.AlivePlayers() do
		ctx.AddScore(p, 1)
		local r = Arena.Root(p)
		if r and r.Position.Y < -30 then Arena.Teleport(p, ctx.Track:RespawnPoint(p)) end
	end
end

function M.AdminHook(ctx, action, args) if action == "Checkpoint" then ctx.Track:AdminComplete(args.target) return "ok" end return "unsupported" end
return M
