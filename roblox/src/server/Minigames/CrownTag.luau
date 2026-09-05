--!strict
-- Hold the crown longest. The crown-holder is slower and glows; parkour movement is enabled for chasers.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)

local M = { Id = "CrownTag", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

local function setKing(ctx, p: Player?)
	if ctx.King then PlayerStateService:SetRole(ctx.King, nil); PlayerStateService:SetMovement(ctx.King, 16, nil) end
	ctx.King = p
	if p then PlayerStateService:SetRole(p, "King"); PlayerStateService:SetMovement(p, 14, nil) end
	ctx.LastSteal = os.clock()
	ctx.Broadcast("Crown", p and p.UserId or nil)
end

function M.Start(ctx)
	local spawns = require(Services.MapService):Markers("Spawns")
	local m = spawns[math.ceil(#spawns / 2)]
	ctx.Crown = Arena.Part(ctx, { Name = "Crown", Size = Vector3.new(2, 1, 2), Position = (m and m.Position or Vector3.new(0, 3, 500)) + Vector3.new(0, 3, 0), Color = Color3.fromRGB(255, 215, 0), Material = Enum.Material.Neon, CanCollide = false })
end

function M.Update(ctx, dt)
	if not ctx.King then
		for _, p in ctx.AlivePlayers() do
			local r = Arena.Root(p)
			if r and (r.Position - ctx.Crown.Position).Magnitude < 4 then setKing(ctx, p) break end
		end
		return
	end
	local king = ctx.King
	if PlayerStateService:Get(king).State ~= "Playing" or not king.Parent then setKing(ctx, nil) return end
	local kr = Arena.Root(king)
	if kr then ctx.Crown.Position = kr.Position + Vector3.new(0, 4.5, 0) end
	ctx.AddScore(king, 1)
	if os.clock() - ctx.LastSteal > 1 then
		for _, p in ctx.AlivePlayers() do
			if p ~= king and Arena.Distance(p, king) < 4.5 then setKing(ctx, p) break end
		end
	end
	Arena.CheckKillZones(ctx)
end

function M.AdminHook(ctx, action, args) if action == "Tag" then setKing(ctx, args.target) return "crowned" end return "unsupported" end
return M
