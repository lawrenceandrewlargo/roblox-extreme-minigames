--!strict
-- Inverted incentive: holding the "treasure" earns points per second; touching the holder steals it.
-- Every 25s the treasure detonates on whoever holds it (stun + lose 30% points), then respawns at a random point.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)

local M = { Id = "ReverseBomb", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

local function drop(ctx)
	local spawns = require(Services.MapService):Markers("Spawns")
	local m = spawns[ctx.Rng:NextInteger(1, math.max(1, #spawns))]
	local pos = m and m.Position + Vector3.new(0, 3, 0) or Vector3.new(0, 5, 500)
	ctx.Holder = nil
	if ctx.Treasure then ctx.Treasure:Destroy() end
	ctx.Treasure = Arena.Part(ctx, { Name = "Treasure", Shape = Enum.PartType.Ball, Size = Vector3.one * 3, Position = pos, Color = Color3.fromRGB(255, 200, 0), Material = Enum.Material.Neon, CanCollide = false })
	ctx.Fuse = 25
	ctx.LastTransfer = os.clock()
	ctx.Broadcast("BombHolder", nil, ctx.Fuse)
end

function M.Start(ctx) drop(ctx) end

function M.Update(ctx, dt)
	if not ctx.Treasure then return end
	if not ctx.Holder then
		for _, p in ctx.AlivePlayers() do
			local r = Arena.Root(p)
			if r and (r.Position - ctx.Treasure.Position).Magnitude < 4 then ctx.Holder = p; ctx.LastTransfer = os.clock(); PlayerStateService:SetRole(p, "Bomb"); ctx.Broadcast("BombHolder", p.UserId, ctx.Fuse) break end
		end
		return
	end
	local holder = ctx.Holder
	if PlayerStateService:Get(holder).State ~= "Playing" or not holder.Parent then drop(ctx) return end
	local hr = Arena.Root(holder)
	if hr then ctx.Treasure.Position = hr.Position + Vector3.new(0, 4, 0) end
	ctx.AddScore(holder, math.floor(dt * 10 * 10) / 10)
	if os.clock() - ctx.LastTransfer > 0.8 then
		for _, p in ctx.AlivePlayers() do
			if p ~= holder and Arena.Distance(p, holder) < 4.5 then
				PlayerStateService:SetRole(holder, nil)
				ctx.Holder = p; ctx.LastTransfer = os.clock(); PlayerStateService:SetRole(p, "Bomb")
				ctx.Broadcast("BombHolder", p.UserId, ctx.Fuse)
				break
			end
		end
	end
	ctx.Fuse -= dt
	if ctx.Fuse <= 0 then
		ctx.Scores[holder.UserId] = math.floor((ctx.Scores[holder.UserId] or 0) * 0.7)
		local h = holder.Character and holder.Character:FindFirstChildOfClass("Humanoid")
		if h then h.PlatformStand = true; ctx.Janitor:AddThread(task.delay(2, function() if h.Parent then h.PlatformStand = false end end)) end
		ctx.Broadcast("BombExplode", holder.UserId)
		PlayerStateService:SetRole(holder, nil)
		drop(ctx)
	end
end

function M.AdminHook(ctx, action, args)
	if action == "GiveBomb" then ctx.Holder = args.target; ctx.LastTransfer = os.clock() return "given" end
	return "unsupported"
end
return M
