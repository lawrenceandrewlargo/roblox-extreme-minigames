--!strict
-- 2 Hunters vs Humans hidden among NPCs. Humans move at NPC speed and can't jump. Hunters "accuse" by touching:
-- accusing an NPC removes it and costs the hunter 5s freeze; accusing a human eliminates the human.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local NPCCrowd = require(Systems.NPCCrowd)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)
local Remotes = require(Services.Remotes)
local TableUtil = require(game:GetService("ReplicatedStorage").Shared.Utilities.TableUtil)

local M = { Id = "BlendIn", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx)
	local shuffled = TableUtil.Shuffle(ctx.Players, ctx.Rng)
	ctx.Hunters = {}
	for i, p in shuffled do
		if i <= math.max(1, math.floor(#shuffled / 6)) then PlayerStateService:SetRole(p, "Hunter"); table.insert(ctx.Hunters, p) else PlayerStateService:SetRole(p, "Human"); PlayerStateService:SetMovement(p, 10, 0) end
	end
	Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng)
	ctx.Crowd = NPCCrowd.new(ctx, math.clamp(#ctx.Players * 3, 12, 40))
	ctx.Frozen = {}
	ctx.Janitor:Add(Remotes:OnEvent("MinigameEvent", function(p, action, targetModelName)
		if ctx.Finished or action ~= "Accuse" or PlayerStateService:Get(p).Role ~= "Hunter" or ctx.Frozen[p.UserId] then return end
		local pr = Arena.Root(p)
		if not pr then return end
		-- Server resolves the nearest NPC or disguised human within 6 studs (client only sends intent).
		local best, bestD = nil, 6
		for _, npc in ctx.Crowd.NPCs do if npc.PrimaryPart then local d = (npc.PrimaryPart.Position - pr.Position).Magnitude if d < bestD then best, bestD = npc, d end end end
		for _, h in ctx.AlivePlayers() do if PlayerStateService:Get(h).Role == "Human" then local d = Arena.Distance(p, h) if d < bestD then best, bestD = h, d end end end
		if not best then return end
		if typeof(best) == "Instance" then
			ctx.Crowd:Remove(best); ctx.AddScore(p, -10)
			ctx.Frozen[p.UserId] = true; local r = Arena.Root(p) if r then r.Anchored = true end
			ctx.Janitor:AddThread(task.delay(5, function() ctx.Frozen[p.UserId] = nil; local rr = Arena.Root(p) if rr then rr.Anchored = false end end))
			ctx.Broadcast("WrongAccuse", p.UserId)
		else
			ctx.AddScore(p, 50); ctx.Eliminate(best, "caught")
		end
	end))
end

function M.Start(ctx) end

function M.Update(ctx, dt)
	local humans = 0
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Human" then humans += 1; ctx.AddScore(p, 1) end end
	if humans == 0 then for _, h in ctx.Hunters do if h.Parent then ctx.Finish(h) end end ctx.End("all_caught") end
end

function M.Finish(ctx) for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Human" then ctx.Finish(p) end end return nil end
function M.AdminHook(ctx, action) if action == "Reveal" then for _, p in ctx.AlivePlayers() do if p.Character then p.Character:SetAttribute("Disguised", nil) end end return "revealed" end return "unsupported" end
function M.Cleanup(ctx) for _, p in ctx.Players do local r = Arena.Root(p) if r then r.Anchored = false end end end
return M
