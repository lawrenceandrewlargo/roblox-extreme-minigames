--!strict
-- Classic tag with 2 taggers, but safe zones (glowing discs) relocate every 15s. Runners inside a safe zone can't be tagged,
-- but a zone only holds 3 players; the 4th to enter bumps the earliest out.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)
local MapService = require(Services.MapService)

local M = { Id = "SafeZoneTag", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx)
	Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng)
	local shuffled = require(game:GetService("ReplicatedStorage").Shared.Utilities.TableUtil).Shuffle(ctx.Players, ctx.Rng)
	for i, p in shuffled do PlayerStateService:SetRole(p, i <= math.max(1, math.floor(#shuffled / 6)) and "Tagger" or "Runner") end
end

local function relocate(ctx)
	for _, z in ctx.Zones do z:Destroy() end
	ctx.Zones = {}
	ctx.ZoneOccupants = {}
	local spawns = MapService:Markers("SafeZones")
	if #spawns == 0 then spawns = MapService:Markers("Spawns") end
	for i = 1, 3 do
		local m = spawns[ctx.Rng:NextInteger(1, math.max(1, #spawns))]
		local pos = m and m.Position or Vector3.new(i * 20, 3, 500)
		ctx.Zones[i] = Arena.Part(ctx, { Name = "SafeZone", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 12, 12), CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(80, 255, 120), Material = Enum.Material.Neon, Transparency = 0.4, CanCollide = false })
		ctx.ZoneOccupants[i] = {}
	end
	ctx.Broadcast("SafeZonesMoved")
end

function M.Start(ctx)
	ctx.Zones = {}
	relocate(ctx)
	ctx.NextMove = 15
	ctx.TagCooldown = {}
end

function M.Update(ctx, dt)
	ctx.NextMove -= dt
	if ctx.NextMove <= 0 then ctx.NextMove = 15; relocate(ctx) end
	local safe: { [number]: boolean } = {}
	for i, z in ctx.Zones do
		local occ = ctx.ZoneOccupants[i]
		for _, p in ctx.AlivePlayers() do
			local r = Arena.Root(p)
			if r and PlayerStateService:Get(p).Role == "Runner" then
				local inside = (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(z.Position.X, 0, z.Position.Z)).Magnitude < 6
				local idx = table.find(occ, p.UserId)
				if inside and not idx then table.insert(occ, p.UserId); if #occ > 3 then table.remove(occ, 1) end
				elseif not inside and idx then table.remove(occ, idx) end
			end
		end
		for _, id in occ do safe[id] = true end
	end
	local taggers, runners = {}, {}
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Tagger" then table.insert(taggers, p) else table.insert(runners, p) end end
	if #taggers == 0 then ctx.End("no_taggers") return end
	for _, r in runners do
		if safe[r.UserId] then continue end
		ctx.AddScore(r, 1)
		for _, t in taggers do
			if Arena.Distance(r, t) < 4.5 and os.clock() - (ctx.TagCooldown[t.UserId] or 0) > 1 then
				ctx.TagCooldown[t.UserId] = os.clock()
				ctx.AddScore(t, 20)
				PlayerStateService:SetRole(r, "Tagger")
				PlayerStateService:SetRole(t, "Runner")
				ctx.Broadcast("TagSwap", t.UserId, r.UserId)
				break
			end
		end
	end
	Arena.CheckKillZones(ctx)
end

function M.Finish(ctx)
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Runner" then ctx.Finish(p) end end
	return nil
end
return M
