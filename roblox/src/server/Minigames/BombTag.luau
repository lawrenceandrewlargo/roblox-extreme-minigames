--!strict
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local BombSystem = require(Systems.BombSystem)

local BombTag = { Id = "BombTag" }

function BombTag.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

function BombTag.Start(ctx)
	ctx.Bombs = {}
	local count = ctx.Modified("BombCount", 1)
	local function explode(victim: Player?)
		if victim then ctx.Eliminate(victim, "exploded") end
		for _, alive in ctx.AlivePlayers() do ctx.AddScore(alive, 10) end
		if #ctx.AlivePlayers() > 1 then
			task.delay(1.5, function()
				if ctx.Finished then return end
				for _, b in ctx.Bombs do
					if not b.Active then
						local alive = ctx.AlivePlayers()
						b:Give(alive[ctx.Rng:NextInteger(1, #alive)])
						b:Start(math.max(8, 20 - #ctx._elimOrder))
					end
				end
			end)
		end
	end
	local alive = ctx.AlivePlayers()
	for i = 1, math.min(count, #alive) do
		local bomb = BombSystem.new(ctx, { Fuse = 20, OnExplode = explode })
		bomb:Give(alive[((i - 1) % #alive) + 1])
		bomb:Start()
		table.insert(ctx.Bombs, bomb)
	end
end

function BombTag.Update(ctx, dt)
	for _, b in ctx.Bombs do b:Update(dt) end
	Arena.CheckKillZones(ctx)
end

function BombTag.AdminHook(ctx, action, args)
	if action == "GiveBomb" and ctx.Bombs[1] then ctx.Bombs[1]:Give(args.target) return "given" end
	return "unsupported"
end

function BombTag.Cleanup(ctx) for _, b in ctx.Bombs do b:Stop() end end

return BombTag
