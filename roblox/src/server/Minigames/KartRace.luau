--!strict
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Karts = require(Systems.Karts)
local Checkpoints = require(Systems.Checkpoints)
local MapService = require(script.Parent.Parent.Services.MapService)

local M = { Id = "KartRace", EndsWhenOneRemains = false, EndsWhenAllFinished = true }

function M.PreparePlayers(ctx) Karts.SpawnAll(ctx, MapService:Markers("Spawns")) end

function M.Start(ctx)
	ctx.Track = Checkpoints.new(ctx, "Checkpoints", 3)
	Karts.ApplyBoostPads(ctx, MapService)
	ctx.DriftTime = {}
end

function M.Update(ctx, dt)
	ctx.Track:Update()
	-- Drift boost: sustained steering while throttling for 1.2s grants a 1.5s boost.
	for _, p in ctx.AlivePlayers() do
		local kart = Karts.Of(ctx, p)
		local seat = kart and kart:FindFirstChild("Seat") :: VehicleSeat?
		if seat then
			if math.abs(seat.Steer) > 0 and seat.Throttle > 0 and seat.AssemblyLinearVelocity.Magnitude > 25 then
				ctx.DriftTime[p.UserId] = (ctx.DriftTime[p.UserId] or 0) + dt
				if ctx.DriftTime[p.UserId] > 1.2 and not kart:GetAttribute("Boosting") then
					kart:SetAttribute("Boosting", true); kart:SetAttribute("Boost", 1.5)
					ctx.Send(p, "DriftBoost")
					ctx.Janitor:AddThread(task.delay(1.5, function() if kart.Parent then kart:SetAttribute("Boost", 1); kart:SetAttribute("Boosting", nil) end end))
					ctx.DriftTime[p.UserId] = 0
				end
			else
				ctx.DriftTime[p.UserId] = 0
			end
		end
		local r = Arena.Root(p)
		if r and r.Position.Y < -30 then Arena.Teleport(p, ctx.Track:RespawnPoint(p)) end
	end
	if #ctx._finishOrder >= 3 and ctx.Elapsed() > 30 then ctx.End("podium_full") end
end

function M.AdminHook(ctx, action, args) if action == "Checkpoint" then ctx.Track:AdminComplete(args.target) return "ok" end return "unsupported" end
return M
