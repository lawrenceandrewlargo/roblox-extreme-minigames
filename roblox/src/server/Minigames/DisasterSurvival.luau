--!strict
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Hazards = require(Systems.Hazards)
local MapService = require(script.Parent.Parent.Services.MapService)

local M = { Id = "DisasterSurvival" }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

local function center(ctx): Vector3
	local s = MapService:Markers("Spawns")
	if #s == 0 then return Vector3.new(0, 0, 500) end
	local sum = Vector3.zero for _, m in s do sum += m.Position end
	return sum / #s
end

function M.Start(ctx)
	ctx.Stops = {}
	local names = { "Flood", "Meteors", "Tornado", "Earthquake", "Lightning" }
	local first = names[ctx.Rng:NextInteger(1, #names)]
	local second = first
	while second == first do second = names[ctx.Rng:NextInteger(1, #names)] end
	ctx.Janitor:AddThread(task.delay(5, function() if not ctx.Finished then M.Trigger(ctx, first) end end))
	ctx.Janitor:AddThread(task.delay(55, function() if not ctx.Finished then M.Trigger(ctx, second) end end))
end

function M.Trigger(ctx, name: string)
	local c = center(ctx)
	local stop
	if name == "Flood" then stop = Hazards.Flood(ctx, { Base = c - Vector3.new(0, 4, 0), RiseSpeed = 1.1, MaxHeight = 30 })
	elseif name == "Meteors" then stop = Hazards.Meteors(ctx, { Interval = 1.2, Radius = 7, Center = c, Range = 60, Destroys = true })
	elseif name == "Tornado" then stop = Hazards.Tornado(ctx, { Center = c, Range = 50, Duration = 40 })
	elseif name == "Earthquake" then stop = Hazards.Earthquake(ctx, { Duration = 30 })
	elseif name == "Lightning" then stop = Hazards.Lightning(ctx, { Interval = 3, Duration = 40 })
	end
	if stop then table.insert(ctx.Stops, stop); ctx.Janitor:AddThread(task.delay(45, stop)) end
	ctx.Broadcast("Disaster", name)
	return "triggered " .. name
end

function M.Update(ctx) for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 1) end Arena.CheckKillZones(ctx, -40) end
function M.AdminHook(ctx, action, args) if action == "Hazard" then return M.Trigger(ctx, tostring(args.name)) end return "unsupported" end
function M.Cleanup(ctx) for _, s in ctx.Stops do s() end end
return M
