--!strict
-- Body size is a real strategic choice: Small (slow, fits HidingSpots tagged Small), Normal, Large (fast, high jump, can't enter tight spots).
-- Hiders choose during a 12s hide phase via MinigameAction("ChooseSize"); seekers released afterwards.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)
local MapService = require(Services.MapService)
local Remotes = require(Services.Remotes)
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)
local TableUtil = require(game:GetService("ReplicatedStorage").Shared.Utilities.TableUtil)

local M = { Id = "HideAndSeek", EndsWhenOneRemains = false }

local function applySize(p: Player, size: string)
	local cfg = GameConfig.BodySize[size] or GameConfig.BodySize.Normal
	PlayerStateService:SetScale(p, cfg.Scale)
	PlayerStateService:SetMovement(p, cfg.WalkSpeed, cfg.JumpHeight)
	PlayerStateService:SetFlag(p, "Size" .. size, true)
	p:SetAttribute("BodySize", size)
end

function M.PreparePlayers(ctx)
	local shuffled = TableUtil.Shuffle(ctx.Players, ctx.Rng)
	local seekerCount = math.max(1, math.floor(#shuffled / 5))
	ctx.Seekers, ctx.Hiders = {}, {}
	for i, p in shuffled do
		if i <= seekerCount then PlayerStateService:SetRole(p, "Seeker"); table.insert(ctx.Seekers, p) else PlayerStateService:SetRole(p, "Hider"); table.insert(ctx.Hiders, p); applySize(p, "Normal") end
	end
	Arena.SpawnAll(ctx.Hiders, "Spawns", ctx.Rng)
	Arena.SpawnTeam(ctx.Seekers, "Seeker")
	for _, s in ctx.Seekers do local r = Arena.Root(s) if r then r.Anchored = true end end
	-- Tight hiding spots block Large players via a collision gate: parts named "SmallGate" in HidingSpots.
	ctx.Gates = {}
	for _, spot in MapService:Markers("HidingSpots") do
		if spot.Name == "SmallGate" then table.insert(ctx.Gates, spot) end
	end
	ctx.Janitor:Add(Remotes:OnEvent("MinigameEvent", function(p, action, size)
		if ctx.Finished or ctx.Phase ~= "Hide" then return end
		if action == "ChooseSize" and PlayerStateService:Get(p).Role == "Hider" and type(size) == "string" and GameConfig.BodySize[size] then applySize(p, size) end
	end))
end

function M.Start(ctx)
	ctx.Phase = "Hide"
	ctx.Broadcast("Phase", "Hide", 12)
	ctx.Janitor:AddThread(task.delay(12, function()
		if ctx.Finished then return end
		ctx.Phase = "Seek"
		for _, s in ctx.Seekers do local r = Arena.Root(s) if r then r.Anchored = false end; PlayerStateService:SetMovement(s, 18, nil) end
		ctx.Broadcast("Phase", "Seek", ctx.Meta.Duration - 12)
	end))
end

function M.Update(ctx, dt)
	if ctx.Phase ~= "Seek" then return end
	local hiders = {}
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Hider" then table.insert(hiders, p) end end
	if #hiders == 0 then for _, s in ctx.Seekers do if s.Parent then ctx.Finish(s) end end ctx.End("all_found") return end
	for _, h in hiders do
		ctx.AddScore(h, 1)
		local hr = Arena.Root(h)
		-- Large players are pushed out of small gates.
		if hr and h:GetAttribute("BodySize") == "Large" then
			for _, g in ctx.Gates do if Arena.InZone(g, hr.Position) then hr.CFrame = hr.CFrame + g.CFrame.LookVector * 4 end end
		end
		for _, s in ctx.Seekers do
			if s.Parent and PlayerStateService:Get(s).State == "Playing" and Arena.Distance(s, h) < 5 then
				ctx.AddScore(s, 30); ctx.Eliminate(h, "found"); break
			end
		end
	end
end

function M.Finish(ctx)
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Hider" then ctx.Finish(p) end end
	return nil
end

function M.AdminHook(ctx, action, args)
	if action == "Reveal" then for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Hider" then local r = Arena.Root(p) if r then Arena.Part(ctx, { Name = "RevealBeam", Size = Vector3.new(1, 60, 1), Position = r.Position + Vector3.new(0, 30, 0), Color = Color3.new(1, 0, 0), Material = Enum.Material.Neon, CanCollide = false }) end end end return "revealed" end
	return "unsupported"
end

function M.Cleanup(ctx) for _, p in ctx.Players do p:SetAttribute("BodySize", nil) end end
return M
