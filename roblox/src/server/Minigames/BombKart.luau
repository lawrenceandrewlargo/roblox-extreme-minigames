--!strict
-- Karts on a track. Bomb passes on kart-to-kart collision; explosion eliminates holder; survivors keep racing for score.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Karts = require(Systems.Karts)
local Services = script.Parent.Parent.Services
local MapService = require(Services.MapService)
local PlayerStateService = require(Services.PlayerStateService)

local M = { Id = "BombKart" }

function M.PreparePlayers(ctx) Karts.SpawnAll(ctx, MapService:Markers("Spawns")) end

local function give(ctx, p: Player?)
	if ctx.Holder then PlayerStateService:SetRole(ctx.Holder, nil) end
	ctx.Holder = p
	if p then PlayerStateService:SetRole(p, "Bomb") end
	ctx.LastTransfer = os.clock()
	ctx.Broadcast("BombHolder", p and p.UserId or nil, ctx.Fuse)
end

function M.Start(ctx)
	ctx.Fuse = 18
	local alive = ctx.AlivePlayers()
	give(ctx, alive[ctx.Rng:NextInteger(1, #alive)])
end

function M.Update(ctx, dt)
	local holder = ctx.Holder
	if not holder or PlayerStateService:Get(holder).State ~= "Playing" then
		local alive = ctx.AlivePlayers()
		if #alive > 0 then give(ctx, alive[ctx.Rng:NextInteger(1, #alive)]) end
		return
	end
	local hk = Karts.Of(ctx, holder)
	if hk and hk.PrimaryPart and os.clock() - ctx.LastTransfer > 1 then
		for _, p in ctx.AlivePlayers() do
			local k = Karts.Of(ctx, p)
			if p ~= holder and k and k.PrimaryPart and (k.PrimaryPart.Position - hk.PrimaryPart.Position).Magnitude < 9 then give(ctx, p) break end
		end
	end
	for _, p in ctx.AlivePlayers() do ctx.AddScore(p, 1) end
	ctx.Fuse -= dt
	if ctx.Fuse <= 0 then
		ctx.Broadcast("BombExplode", holder.UserId)
		local k = Karts.Of(ctx, holder)
		if k then k:Destroy() end
		ctx.Eliminate(holder, "exploded")
		ctx.Fuse = math.max(8, 18 - #ctx._elimOrder * 1.5)
		local alive = ctx.AlivePlayers()
		if #alive > 0 then give(ctx, alive[ctx.Rng:NextInteger(1, #alive)]) end
	end
	Arena.CheckKillZones(ctx, -30)
end

function M.AdminHook(ctx, action, args) if action == "GiveBomb" then give(ctx, args.target) return "given" end return "unsupported" end
return M
