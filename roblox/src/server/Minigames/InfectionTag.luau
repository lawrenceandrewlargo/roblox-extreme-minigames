--!strict
-- One infected at start; touch converts. Infected get faster as their number grows; survivors score per second.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)

local M = { Id = "InfectionTag", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx)
	Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng)
	for _, p in ctx.Players do PlayerStateService:SetRole(p, "Survivor") end
end

local function infect(ctx, p: Player)
	if PlayerStateService:Get(p).Role == "Infected" then return end
	PlayerStateService:SetRole(p, "Infected")
	PlayerStateService:SetMovement(p, 15, nil)
	ctx.Broadcast("Infected", p.UserId)
	ctx.InfectedAt[p.UserId] = ctx.Elapsed()
end

function M.Start(ctx)
	ctx.InfectedAt = {}
	ctx.Janitor:AddThread(task.delay(5, function()
		local alive = ctx.AlivePlayers()
		if #alive > 0 then infect(ctx, alive[ctx.Rng:NextInteger(1, #alive)]) end
	end))
end

function M.Update(ctx, dt)
	local infected, survivors = {}, {}
	for _, p in ctx.AlivePlayers() do
		if PlayerStateService:Get(p).Role == "Infected" then table.insert(infected, p) else table.insert(survivors, p) end
	end
	if #infected == 0 and ctx.Elapsed() > 6 then
		if #survivors > 0 then infect(ctx, survivors[ctx.Rng:NextInteger(1, #survivors)]) end
		return
	end
	local speed = math.min(22, 15 + #infected * 0.6)
	for _, i in infected do
		local h = i.Character and i.Character:FindFirstChildOfClass("Humanoid")
		if h and h.WalkSpeed ~= speed then h.WalkSpeed = speed end
		for _, s in survivors do if Arena.Distance(i, s) < 4.5 then infect(ctx, s); ctx.AddScore(i, 25) end end
	end
	for _, s in survivors do ctx.AddScore(s, 1) end
	if #survivors == 0 and ctx.Elapsed() > 6 then ctx.End("all_infected") end
	Arena.CheckKillZones(ctx)
end

function M.Finish(ctx)
	-- Survivors who lasted the whole round finish first; then rank infected by how long they survived (later infection = better).
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Survivor" then ctx.Finish(p) end end
	local infected = {}
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Infected" then table.insert(infected, p) end end
	table.sort(infected, function(a, b) return (ctx.InfectedAt[a.UserId] or 0) > (ctx.InfectedAt[b.UserId] or 0) end)
	for _, p in infected do ctx.Finish(p) end
	return nil
end

function M.AdminHook(ctx, action, args) if action == "Tag" then infect(ctx, args.target) return "infected" end return "unsupported" end
return M
