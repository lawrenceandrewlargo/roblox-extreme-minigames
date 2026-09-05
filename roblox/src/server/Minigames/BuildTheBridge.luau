--!strict
-- Each team: plank pile -> carry one plank (touch) -> place at the next bridge slot (touch slot). Loose planks (dropped on elimination)
-- can be stolen. First team whose member touches the far pad wins.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Teams = require(Systems.Teams)
local M = { Id = "BuildTheBridge", EndsWhenOneRemains = false }
local SLOTS = 8

function M.LoadMap(ctx)
	ctx.Lanes = {}
	for i, team in { "Red", "Blue" } do
		local x = (i == 1) and -20 or 20
		local color = (i == 1) and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(80, 120, 255)
		Arena.Part(ctx, { Name = team .. "Start", Size = Vector3.new(24, 1, 24), Position = Vector3.new(x, 0, 470), Color = color })
		local pile = Arena.Part(ctx, { Name = team .. "Pile", Size = Vector3.new(5, 3, 5), Position = Vector3.new(x - 8, 2, 462), Color = Color3.fromRGB(160, 110, 60) })
		local farPad = Arena.Part(ctx, { Name = team .. "Goal", Size = Vector3.new(24, 1, 16), Position = Vector3.new(x, 0, 470 + 12 + SLOTS * 8 + 8), Color = color, Material = Enum.Material.Neon })
		local slots = {}
		for s = 1, SLOTS do slots[s] = Arena.Part(ctx, { Name = team .. "Slot" .. s, Size = Vector3.new(8, 0.5, 7.5), Position = Vector3.new(x, 0, 482 + (s - 1) * 8 + 4), Transparency = 0.85, CanCollide = false, Color = color }) end
		ctx.Lanes[team] = { Pile = pile, Goal = farPad, Slots = slots, Built = 0 }
	end
end

function M.PreparePlayers(ctx)
	local t = Teams.Assign(ctx, { "Red", "Blue" })
	for i, p in t.Red do Arena.Teleport(p, CFrame.new(-20 + (i % 4) * 4, 4, 470)) end
	for i, p in t.Blue do Arena.Teleport(p, CFrame.new(20 + (i % 4) * 4, 4, 470)) end
	ctx.Carrying = {}
	ctx.Loose = {}
end
function M.Start(ctx) end

local function dropPlank(ctx, p: Player)
	if not ctx.Carrying[p.UserId] then return end
	ctx.Carrying[p.UserId] = nil
	local r = Arena.Root(p)
	local plank = Arena.Part(ctx, { Name = "LoosePlank", Size = Vector3.new(6, 0.5, 2), Position = (r and r.Position or Vector3.new(0, 5, 500)) + Vector3.new(0, 1, 0), Color = Color3.fromRGB(160, 110, 60) })
	table.insert(ctx.Loose, plank)
	p:SetAttribute("Carrying", nil)
end

function M.Update(ctx)
	for _, p in ctx.AlivePlayers() do
		local r = Arena.Root(p)
		local team = Teams.Of(ctx, p)
		if not r or not team then continue end
		local lane = ctx.Lanes[team]
		if not ctx.Carrying[p.UserId] then
			if (r.Position - lane.Pile.Position).Magnitude < 5 then ctx.Carrying[p.UserId] = true; p:SetAttribute("Carrying", true) end
			for i, plank in ctx.Loose do if plank.Parent and (r.Position - plank.Position).Magnitude < 4 then plank:Destroy(); table.remove(ctx.Loose, i); ctx.Carrying[p.UserId] = true; p:SetAttribute("Carrying", true); ctx.AddScore(p, 5) break end end
		else
			local slot = lane.Slots[lane.Built + 1]
			if slot and (Vector3.new(r.Position.X, 0, r.Position.Z) - Vector3.new(slot.Position.X, 0, slot.Position.Z)).Magnitude < 6 then
				slot.Transparency = 0; slot.CanCollide = true; lane.Built += 1
				ctx.Carrying[p.UserId] = nil; p:SetAttribute("Carrying", nil); ctx.AddScore(p, 15)
				ctx.Broadcast("BridgeProgress", team, lane.Built, SLOTS)
			end
		end
		if r.Position.Y < -15 then dropPlank(ctx, p); Arena.Teleport(p, CFrame.new(team == "Red" and -20 or 20, 4, 470)) end
		if lane.Built >= SLOTS and Arena.InZone(lane.Goal, r.Position) then Teams.FinishTeam(ctx, team) return end
	end
end
function M.OnPlayerLeft(ctx, p) dropPlank(ctx, p) end
function M.Finish(ctx) if ctx.Reason == "time_up" then Teams.FinishTeam(ctx, ctx.Lanes.Red.Built >= ctx.Lanes.Blue.Built and "Red" or "Blue") end return nil end
function M.Cleanup(ctx) for _, p in ctx.Players do p:SetAttribute("Carrying", nil) end end
return M
