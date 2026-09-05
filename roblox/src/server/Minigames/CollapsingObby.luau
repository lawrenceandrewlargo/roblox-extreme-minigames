--!strict
-- Course parts tagged Destructible crumble 1.2s after being stood on; lava rises from the start. No respawns.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Checkpoints = require(Systems.Checkpoints)
local Hazards = require(Systems.Hazards)
local MapService = require(script.Parent.Parent.Services.MapService)

local M = { Id = "CollapsingObby", EndsWhenAllFinished = true }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

function M.Start(ctx)
	ctx.Track = Checkpoints.new(ctx, "Checkpoints", 1)
	local map = ctx.Map
	if map then
		for _, d in map:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute("Destructible") then
				ctx.Janitor:Add(d.Touched:Connect(function(hit)
					if d:GetAttribute("Crumbling") then return end
					if not hit.Parent or not hit.Parent:FindFirstChildOfClass("Humanoid") then return end
					d:SetAttribute("Crumbling", true)
					ctx.Janitor:AddThread(task.delay(1.2, function() if d.Parent then d.Anchored = false; d.CanCollide = false; task.delay(2, function() if d.Parent then d:Destroy() end end) end end))
				end))
			end
		end
	end
	local base = MapService:Markers("Spawns")[1]
	ctx.StopLava = Hazards.Lava(ctx, { Base = (base and base.Position or Vector3.new(0, 0, 500)) - Vector3.new(0, 6, 0), RiseSpeed = 0.9, MaxHeight = 300 })
end

function M.Update(ctx) ctx.Track:Update(); Arena.CheckKillZones(ctx, -30) end
function M.AdminHook(ctx, action, args) if action == "Checkpoint" then ctx.Track:AdminComplete(args.target) return "ok" end return "unsupported" end
function M.Cleanup(ctx) if ctx.StopLava then ctx.StopLava() end end
return M
