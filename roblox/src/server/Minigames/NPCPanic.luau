--!strict
-- Inverse of BlendIn: one Monster; NPCs flee when it approaches. Humans (disguised) must flee like NPCs do —
-- standing still near the monster is a giveaway. Monster catches by touch; catching an NPC slows the monster for 3s.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local NPCCrowd = require(Systems.NPCCrowd)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)

local M = { Id = "NPCPanic", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx)
	local monster = ctx.Players[ctx.Rng:NextInteger(1, #ctx.Players)]
	ctx.Monster = monster
	ctx.Threat = monster
	PlayerStateService:SetRole(monster, "Monster")
	PlayerStateService:SetScale(monster, 1.4)
	PlayerStateService:SetMovement(monster, 15, 7.2)
	for _, p in ctx.Players do if p ~= monster then PlayerStateService:SetRole(p, "Human"); PlayerStateService:SetMovement(p, 16, 0) end end
	Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng)
	ctx.Crowd = NPCCrowd.new(ctx, math.clamp(#ctx.Players * 3, 12, 40))
	ctx.Crowd:SetMode("Panic")
	ctx.Slowed = 0
end

function M.Start(ctx) end

function M.Update(ctx, dt)
	local m = ctx.Monster
	if not m.Parent or PlayerStateService:Get(m).State ~= "Playing" then ctx.End("monster_left") return end
	local mr = Arena.Root(m)
	if not mr then return end
	ctx.Slowed = math.max(0, ctx.Slowed - dt)
	local humans = 0
	for _, p in ctx.AlivePlayers() do
		if PlayerStateService:Get(p).Role == "Human" then
			humans += 1
			ctx.AddScore(p, 1)
			if Arena.Distance(m, p) < 4 and ctx.Slowed <= 0 then ctx.AddScore(m, 40); ctx.Eliminate(p, "caught") end
		end
	end
	if ctx.Slowed <= 0 then
		for _, npc in ctx.Crowd.NPCs do
			if npc.PrimaryPart and (npc.PrimaryPart.Position - mr.Position).Magnitude < 3.5 then
				ctx.Crowd:Remove(npc); ctx.Slowed = 3; ctx.Broadcast("MonsterSlowed", m.UserId)
				local h = m.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed = 8; ctx.Janitor:AddThread(task.delay(3, function() if h.Parent then h.WalkSpeed = 15 end end)) end
				break
			end
		end
	end
	if humans == 0 then ctx.Finish(m); ctx.End("all_caught") end
end

function M.Finish(ctx) for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Human" then ctx.Finish(p) end end return nil end
function M.AdminHook(ctx, action) if action == "Reveal" then for _, p in ctx.AlivePlayers() do if p.Character then p.Character:SetAttribute("Disguised", nil) end end return "revealed" end return "unsupported" end
return M
