--!strict
-- Ordered checkpoint tracking with skip protection (anti-cheat: cannot skip more than MaxCheckpointSkip).
local Arena = require(script.Parent.Arena)
local Services = script.Parent.Parent.Services
local MapService = require(Services.MapService)
local AntiCheatService = require(Services.AntiCheatService)
local GameConfig = require(game:GetService("ReplicatedStorage").Shared.Config.GameConfig)

local Checkpoints = {}
Checkpoints.__index = Checkpoints

function Checkpoints.new(ctx, folder: string?, laps: number?)
	local marks = MapService:Markers(folder or "Checkpoints")
	table.sort(marks, function(a, b) return a.Name < b.Name end)
	return setmetatable({ ctx = ctx, Marks = marks, Progress = {} :: { [number]: number }, Laps = {} :: { [number]: number }, TotalLaps = laps or 1, Times = {} :: { [number]: number } }, Checkpoints)
end

function Checkpoints:Update()
	if #self.Marks == 0 then return end
	for _, p in self.ctx.AlivePlayers() do
		local root = Arena.Root(p)
		if not root then continue end
		local progress = self.Progress[p.UserId] or 0
		local nextIdx = progress + 1
		for i = nextIdx, math.min(#self.Marks, nextIdx + GameConfig.AntiCheat.MaxCheckpointSkip) do
			if Arena.InZone(self.Marks[i], root.Position) then
				if i > nextIdx then AntiCheatService:Flag(p, "checkpoint_skip", { from = progress, to = i }) end
				self.Progress[p.UserId] = i
				self.ctx.Send(p, "Checkpoint", i, #self.Marks)
				if i == #self.Marks then
					self.Laps[p.UserId] = (self.Laps[p.UserId] or 0) + 1
					if self.Laps[p.UserId] >= self.TotalLaps then
						self.Times[p.UserId] = self.ctx.Elapsed()
						self.ctx.Finish(p, math.floor(100000 / math.max(1, self.ctx.Elapsed())))
					else
						self.Progress[p.UserId] = 0
						self.ctx.Send(p, "Lap", self.Laps[p.UserId], self.TotalLaps)
					end
				end
				break
			end
		end
	end
end

function Checkpoints:RespawnPoint(p: Player): CFrame
	local idx = self.Progress[p.UserId] or 0
	local m = idx > 0 and self.Marks[idx] or MapService:Markers("Spawns")[1]
	return m and (m.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(0, 10, 500)
end

-- Ranking helper for elimination racing: lower is further ahead.
function Checkpoints:Rank(): { Player }
	local alive = self.ctx.AlivePlayers()
	table.sort(alive, function(a, b)
		local la, lb = self.Laps[a.UserId] or 0, self.Laps[b.UserId] or 0
		if la ~= lb then return la > lb end
		local pa, pb = self.Progress[a.UserId] or 0, self.Progress[b.UserId] or 0
		if pa ~= pb then return pa > pb end
		local ma = self.Marks[pa + 1] or self.Marks[1]
		local ra, rb = Arena.Root(a), Arena.Root(b)
		if not ra or not rb or not ma then return false end
		return (ra.Position - ma.Position).Magnitude < (rb.Position - ma.Position).Magnitude
	end)
	return alive
end

function Checkpoints:AdminComplete(p: Player)
	local progress = self.Progress[p.UserId] or 0
	local m = self.Marks[progress + 1]
	if m then Arena.Teleport(p, m.CFrame + Vector3.new(0, 3, 0)) end
end

return Checkpoints
