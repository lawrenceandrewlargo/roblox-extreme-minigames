--!strict
-- Asymmetric: 1 tagger per 5 players. Tagged runners freeze (anchored, visible ice). Runners unfreeze others by 2s proximity.
-- Taggers win if all runners frozen simultaneously; runners win on time.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)

local M = { Id = "FreezeTag", EndsWhenOneRemains = false }

function M.PreparePlayers(ctx)
	Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng)
	ctx.Frozen = {}
	ctx.Thawing = {}
	local shuffled = require(game:GetService("ReplicatedStorage").Shared.Utilities.TableUtil).Shuffle(ctx.Players, ctx.Rng)
	local taggerCount = math.max(1, math.floor(#shuffled / 5))
	for i, p in shuffled do
		local role = i <= taggerCount and "Tagger" or "Runner"
		PlayerStateService:SetRole(p, role)
		if role == "Tagger" then PlayerStateService:SetMovement(p, 18, nil) end
	end
end

local function freeze(ctx, p: Player)
	if ctx.Frozen[p.UserId] then return end
	ctx.Frozen[p.UserId] = true
	local r = Arena.Root(p)
	if r then r.Anchored = true end
	PlayerStateService:SetFlag(p, "Frozen", true)
	ctx.Broadcast("Frozen", p.UserId, true)
end

local function thaw(ctx, p: Player, by: Player?)
	ctx.Frozen[p.UserId] = nil
	local r = Arena.Root(p)
	if r then r.Anchored = false end
	PlayerStateService:SetFlag(p, "Frozen", false)
	if by then ctx.AddScore(by, 15) end
	ctx.Broadcast("Frozen", p.UserId, false)
end

function M.Start(ctx) ctx.TagCooldown = {} end

function M.Update(ctx, dt)
	local runners, taggers = {}, {}
	for _, p in ctx.AlivePlayers() do
		if PlayerStateService:Get(p).Role == "Tagger" then table.insert(taggers, p) else table.insert(runners, p) end
	end
	if #taggers == 0 then ctx.End("taggers_left") return end
	local anyFree = false
	for _, r in runners do
		if not ctx.Frozen[r.UserId] then
			anyFree = true
			ctx.AddScore(r, 1)
			for _, t in taggers do
				if Arena.Distance(r, t) < 4.5 then freeze(ctx, r); ctx.AddScore(t, 20) break end
			end
			-- Thaw frozen friends by staying close for 2 seconds.
			for _, other in runners do
				if ctx.Frozen[other.UserId] and Arena.Distance(r, other) < 5 then
					ctx.Thawing[other.UserId] = (ctx.Thawing[other.UserId] or 0) + dt
					if ctx.Thawing[other.UserId] >= 2 then ctx.Thawing[other.UserId] = nil; thaw(ctx, other, r) end
				end
			end
		end
	end
	if not anyFree and #runners > 0 then
		for _, t in taggers do ctx.Finish(t, (ctx.Scores[t.UserId] or 0) + 100) end
		ctx.End("all_frozen")
	end
end

function M.Finish(ctx)
	if ctx.Reason == "time_up" then
		for _, p in ctx.AlivePlayers() do
			if PlayerStateService:Get(p).Role == "Runner" and not ctx.Frozen[p.UserId] then ctx.Finish(p) end
		end
	end
	return nil
end

function M.AdminHook(ctx, action, args) if action == "Tag" then freeze(ctx, args.target) return "frozen" end return "unsupported" end

function M.Cleanup(ctx) for _, p in ctx.Players do local r = Arena.Root(p) if r then r.Anchored = false end end end
return M
