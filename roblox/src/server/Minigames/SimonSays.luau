--!strict
-- Commands: Jump, Crouch (stand still), MoveLeft, MoveRight, Spin. Prefixed "Simon says" = obey; unprefixed = do nothing.
-- Detection is server-side from velocity/jump state. Window shrinks every 3 commands.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)

local M = { Id = "SimonSays" }
local COMMANDS = { "Jump", "Stand Still", "Move Left", "Move Right", "Run Forward" }

function M.PreparePlayers(ctx) Arena.SpawnAll(ctx.Players, "Spawns", ctx.Rng) end

local function measure(ctx, p: Player, window: number): { [string]: boolean }
	local out = { Jump = false, ["Stand Still"] = true, ["Move Left"] = false, ["Move Right"] = false, ["Run Forward"] = false }
	local r = Arena.Root(p)
	local h = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if not r or not h then return out end
	local start = r.Position
	local t = 0
	while t < window do
		task.wait(0.1); t += 0.1
		if not r.Parent then break end
		local v = r.AssemblyLinearVelocity
		if h:GetState() == Enum.HumanoidStateType.Freefall or h:GetState() == Enum.HumanoidStateType.Jumping then out.Jump = true end
		if Vector3.new(v.X, 0, v.Z).Magnitude > 3 then out["Stand Still"] = false end
		local rel = r.CFrame:PointToObjectSpace(start)
		if rel.X > 4 then out["Move Left"] = true end
		if rel.X < -4 then out["Move Right"] = true end
		if rel.Z > 6 then out["Run Forward"] = true end
	end
	return out
end

function M.Start(ctx)
	ctx.Janitor:AddThread(task.spawn(function()
		local window = 3
		local n = 0
		task.wait(2)
		while not ctx.Finished do
			n += 1
			if n % 3 == 0 then window = math.max(1.4, window - 0.3) end
			local cmd = COMMANDS[ctx.Rng:NextInteger(1, #COMMANDS)]
			local simon = ctx.Rng:NextNumber() < 0.7
			ctx.Broadcast("Simon", cmd, simon, window)
			local results = {}
			local alive = ctx.AlivePlayers()
			local pending = #alive
			for _, p in alive do task.spawn(function() results[p] = measure(ctx, p, window); pending -= 1 end) end
			while pending > 0 do task.wait(0.05) end
			if ctx.Finished then break end
			for _, p in alive do
				local did = results[p]
				if not did then continue end
				local performed = did[cmd]
				local ok
				if simon then ok = performed else ok = did["Stand Still"] and not did.Jump end
				if ok then ctx.AddScore(p, 10) else ctx.Eliminate(p, simon and "wrong_action" or "simon_didnt_say") end
			end
			task.wait(1.2)
		end
	end))
end
return M
