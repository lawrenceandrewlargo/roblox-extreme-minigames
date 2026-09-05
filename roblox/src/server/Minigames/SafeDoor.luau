--!strict
-- Rooms of 5 doors. A 3s hint (symbol above the safe door) shows, then all doors look identical. Wrong door = trapdoor.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local M = { Id = "SafeDoor", EndsWhenAllFinished = true }
local SYMBOLS = { "Circle", "Square", "Triangle", "Star", "Moon" }

function M.LoadMap(ctx)
	ctx.Rooms = {}
	for room = 1, 4 do
		local z = 480 + room * 30
		Arena.Part(ctx, { Name = "RoomFloor" .. room, Size = Vector3.new(40, 1, 20), Position = Vector3.new(0, 2, z), Color = Color3.fromRGB(100, 100, 120) })
		local safeIdx = ctx.Rng:NextInteger(1, 5)
		local doors = {}
		for d = 1, 5 do
			local door = Arena.Part(ctx, { Name = "Door", Size = Vector3.new(6, 8, 1), Position = Vector3.new((d - 3) * 8, 6, z + 10), Color = Color3.fromRGB(140, 90, 50), CanCollide = d ~= safeIdx })
			door:SetAttribute("Safe", d == safeIdx)
			doors[d] = door
		end
		local hint = Arena.Part(ctx, { Name = "Hint", Size = Vector3.new(4, 4, 0.5), Position = doors[safeIdx].Position + Vector3.new(0, 7, 0), Color = Color3.fromRGB(255, 230, 0), Material = Enum.Material.Neon, CanCollide = false })
		hint:SetAttribute("Symbol", SYMBOLS[ctx.Rng:NextInteger(1, #SYMBOLS)])
		ctx.Rooms[room] = { Doors = doors, Hint = hint, Safe = safeIdx, Z = z }
	end
	ctx.FinishPad = Arena.Part(ctx, { Name = "FinishPad", Size = Vector3.new(40, 1, 12), Position = Vector3.new(0, 2, 480 + 5 * 30), Color = Color3.fromRGB(255, 230, 0), Material = Enum.Material.Neon })
end
function M.PreparePlayers(ctx) for _, p in ctx.Players do Arena.Teleport(p, CFrame.new(ctx.Rng:NextNumber(-15, 15), 5, 500)) end end
function M.Start(ctx)
	ctx.Broadcast("Memorize", 3)
	ctx.Janitor:AddThread(task.delay(3, function() for _, room in ctx.Rooms do room.Hint:Destroy() end; ctx.Broadcast("Go") end))
	for _, room in ctx.Rooms do
		for d, door in room.Doors do
			if d ~= room.Safe then
				ctx.Janitor:Add(door.Touched:Connect(function(hit)
					local p = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
					if p and table.find(ctx.AlivePlayers(), p) and ctx.Elapsed() > 3 then
						Arena.Teleport(p, CFrame.new(ctx.Rng:NextNumber(-15, 15), 5, 500)); ctx.AddScore(p, -10); ctx.Send(p, "WrongDoor")
					end
				end))
			end
		end
	end
end
function M.Update(ctx)
	for _, p in ctx.AlivePlayers() do local r = Arena.Root(p) if r and Arena.InZone(ctx.FinishPad, r.Position) then ctx.Finish(p, math.floor(100000 / math.max(1, ctx.Elapsed()))) end end
	if #ctx._finishOrder >= 3 and ctx.Elapsed() > 15 then ctx.End("podium_full") end
end
function M.AdminHook(ctx, action) if action == "Reveal" then for _, room in ctx.Rooms do room.Doors[room.Safe].Color = Color3.new(0, 1, 0) end return "revealed" end return "unsupported" end
return M
