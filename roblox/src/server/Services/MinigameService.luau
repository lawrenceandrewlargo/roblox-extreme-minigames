--!strict
-- Registry + lifecycle runner. Guarantees cleanup regardless of how a minigame ends.
-- Lifecycle: Initialize -> CanStart -> LoadMap -> PreparePlayers -> Start -> Update(heartbeat) -> Finish -> AwardResults -> Cleanup
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local Catalog = require(Shared.MinigameCatalog)
local Modifiers = require(Shared.Config.Modifiers)
local Janitor = require(Shared.Utilities.Janitor)
local Log = require(Shared.Utilities.Log)
local Signal = require(Shared.Utilities.Signal)

local Remotes = require(script.Parent.Remotes)
local MapService = require(script.Parent.MapService)
local PlayerStateService = require(script.Parent.PlayerStateService)
local SpectatorService = require(script.Parent.SpectatorService)

local MinigameService = {
	_registry = {} :: { [string]: any },
	_current = nil :: any,
	_context = nil :: any,
	_finished = Signal.new(),
	_result = nil :: any,
	Diagnostics = { lastCleanupJanitorCount = 0, lastRunId = "", runs = 0, aborts = 0 },
}

function MinigameService:Register(def: any)
	assert(type(def.Id) == "string", "Minigame definition needs Id")
	assert(Catalog.ById[def.Id], "Minigame " .. def.Id .. " missing from MinigameCatalog")
	assert(self._registry[def.Id] == nil, "Duplicate minigame registration " .. def.Id)
	for _, fn in { "Start" } do assert(type(def[fn]) == "function", def.Id .. " missing " .. fn) end
	self._registry[def.Id] = def
end

function MinigameService:Count(): number
	local n = 0
	for _ in self._registry do n += 1 end
	return n
end

function MinigameService:Get(id: string) return self._registry[id] end
function MinigameService:Ids(): { string } local out = {} for id in self._registry do table.insert(out, id) end table.sort(out) return out end

local function modifierById(id: string)
	for _, m in Modifiers do if m.Id == id then return m end end
	return Modifiers[1]
end

-- Context passed to every minigame. Everything a minigame touches is routed through here.
local function makeContext(meta, mapId: string, modifierId: string, participants: { Player })
	local janitor = Janitor.new()
	local ctx = {
		Meta = meta,
		MapId = mapId,
		Modifier = modifierById(modifierId),
		Players = table.clone(participants),
		Janitor = janitor,
		Map = nil :: Model?,
		Scores = {} :: { [number]: number },
		Finished = false,
		Reason = "",
		_elimOrder = {} :: { number },
		_finishOrder = {} :: { number },
		Rng = Random.new(),
		StartedAt = 0,
	}
	function ctx.AlivePlayers(): { Player }
		local out = {}
		for _, p in ctx.Players do
			if p.Parent and PlayerStateService:Get(p).State == "Playing" then table.insert(out, p) end
		end
		return out
	end
	function ctx.AddScore(p: Player, amount: number)
		ctx.Scores[p.UserId] = (ctx.Scores[p.UserId] or 0) + amount
		Remotes:Fire("HUDUpdate", p, { Score = ctx.Scores[p.UserId] })
	end
	function ctx.Eliminate(p: Player, reason: string?)
		if PlayerStateService:Get(p).State ~= "Playing" then return end
		PlayerStateService:SetState(p, "Eliminated")
		table.insert(ctx._elimOrder, p.UserId)
		Remotes:FireAll("MinigameEvent", "Eliminated", p.UserId, reason)
		if meta.AllowsSpectating then SpectatorService:Begin(p, meta.HidesInformation) end
	end
	function ctx.Finish(p: Player, score: number?)
		if PlayerStateService:Get(p).State ~= "Playing" then return end
		PlayerStateService:SetState(p, "Finished")
		table.insert(ctx._finishOrder, p.UserId)
		if score then ctx.Scores[p.UserId] = score end
		Remotes:FireAll("MinigameEvent", "Finished", p.UserId, #ctx._finishOrder)
	end
	function ctx.Broadcast(event: string, ...: any) Remotes:FireAll("MinigameEvent", event, ...) end
	function ctx.Send(p: Player, event: string, ...: any) Remotes:Fire("MinigameEvent", p, event, ...) end
	function ctx.End(reason: string)
		if ctx.Finished then return end
		ctx.Finished = true
		ctx.Reason = reason
	end
	function ctx.Elapsed(): number return os.clock() - ctx.StartedAt end
	function ctx.Modified(key: string, default: any): any
		local v = ctx.Modifier.Apply[key]
		if v == nil then return default end
		return v
	end
	return ctx
end

function MinigameService:Prepare(meta, mapId: string, modifierId: string, participants: { Player })
	assert(self._current == nil, "A minigame is already active")
	local def = self._registry[meta.Id]
	assert(def, "Minigame not registered: " .. meta.Id)
	local ctx = makeContext(meta, mapId, modifierId, participants)
	self._current = def
	self._context = ctx
	self._result = nil
	self.Diagnostics.runs += 1
	self.Diagnostics.lastRunId = meta.Id

	if def.Initialize then def.Initialize(ctx) end
	if def.CanStart and not def.CanStart(ctx) then error("CanStart rejected") end
	ctx.Map = MapService:Load(mapId)
	if def.LoadMap then def.LoadMap(ctx) end

	-- Apply modifier + movement rules to players, then let the minigame prepare.
	local scale = ctx.Modifier.Apply.BodyScale
	local wsMult = ctx.Modifier.Apply.WalkSpeedMultiplier or 1
	for _, p in participants do
		PlayerStateService:SetState(p, "Playing")
		local ws = (meta.Movement.WalkSpeed or 16) * wsMult
		local jh = if meta.Movement.Jump then (ctx.Modifier.Apply.JumpHeight or meta.Movement.JumpHeight or 7.2) else 0
		PlayerStateService:SetMovement(p, ws, jh)
		if scale then PlayerStateService:SetScale(p, scale) end
		Remotes:Fire("MovementRules", p, meta.Movement)
	end
	if ctx.Modifier.Apply.Gravity then
		local ws = game:GetService("Workspace")
		local original = ws.Gravity
		ws.Gravity = ctx.Modifier.Apply.Gravity
		ctx.Janitor:Add(function() ws.Gravity = original end)
	end
	if def.PreparePlayers then def.PreparePlayers(ctx) end
	for _, p in Players:GetPlayers() do
		if not table.find(participants, p) then
			PlayerStateService:SetState(p, "Spectating")
			if meta.AllowsSpectating then SpectatorService:Begin(p, meta.HidesInformation) end
		end
	end
	-- Late leavers must not break the round.
	ctx.Janitor:Add(Players.PlayerRemoving:Connect(function(p)
		local idx = table.find(ctx.Players, p)
		if idx then
			if def.OnPlayerLeft then pcall(def.OnPlayerLeft, ctx, p) end
			table.remove(ctx.Players, idx)
		end
	end))
	-- Unexpected deaths count as elimination unless the minigame handles death itself.
	for _, p in participants do
		local char = p.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			ctx.Janitor:Add(hum.Died:Connect(function()
				if def.OnPlayerDied then pcall(def.OnPlayerDied, ctx, p) else ctx.Eliminate(p, "died") end
			end))
		end
	end
end

function MinigameService:Run(duration: number)
	local def, ctx = self._current, self._context
	if not def or not ctx then return { Entries = {}, WinnerUserIds = {}, Reason = "no_minigame" } end
	ctx.StartedAt = os.clock()
	local ok, err = pcall(def.Start, ctx)
	if not ok then Log.Warn("Minigame", ctx.Meta.Id .. " Start error: " .. tostring(err)); ctx.End("start_error") end

	if def.Update then
		local acc = 0
		ctx.Janitor:Add(RunService.Heartbeat:Connect(function(dt)
			if ctx.Finished then return end
			acc += dt
			if acc < 0.1 then return end
			local step = acc
			acc = 0
			local okU, errU = pcall(def.Update, ctx, step)
			if not okU then Log.Warn("Minigame", ctx.Meta.Id .. " Update error: " .. tostring(errU)); ctx.End("update_error") end
		end))
	end

	local deadline = os.clock() + duration
	while not ctx.Finished and os.clock() < deadline do
		-- Default end conditions: all participants gone, or (elimination games) <= 1 alive.
		local alive = ctx.AlivePlayers()
		if #ctx.Players == 0 then ctx.End("no_players") break end
		if def.EndsWhenOneRemains ~= false and #alive <= 1 and #ctx._finishOrder == 0 and #ctx._elimOrder > 0 then ctx.End("last_standing") break end
		if def.EndsWhenAllFinished and #alive == 0 then ctx.End("all_finished") break end
		task.wait(0.25)
	end
	if not ctx.Finished then ctx.End("time_up") end
	Remotes:FireAll("MinigameEvent", "RoundOver", ctx.Reason)

	local result
	local okF, res = pcall(function() return def.Finish and def.Finish(ctx) end)
	if okF and type(res) == "table" then
		result = res
	else
		if not okF then Log.Warn("Minigame", ctx.Meta.Id .. " Finish error: " .. tostring(res)) end
		result = self:DefaultResult(ctx)
	end
	result.Reason = ctx.Reason
	result.GameId = ctx.Meta.Id
	self._result = result
	return result
end

-- Default ranking: finish order first, then survivors (by score), then eliminated in reverse order.
function MinigameService:DefaultResult(ctx)
	local entries, placed = {}, {}
	local function push(userId: number)
		if placed[userId] then return end
		placed[userId] = true
		table.insert(entries, { UserId = userId, Placement = #entries + 1, Score = ctx.Scores[userId] or 0, Won = #entries == 0 })
	end
	for _, id in ctx._finishOrder do push(id) end
	local alive = ctx.AlivePlayers()
	table.sort(alive, function(a, b) return (ctx.Scores[a.UserId] or 0) > (ctx.Scores[b.UserId] or 0) end)
	for _, p in alive do push(p.UserId) end
	for i = #ctx._elimOrder, 1, -1 do push(ctx._elimOrder[i]) end
	local winners = {}
	if entries[1] then
		-- Ties on top score among survivors share the win (only when nobody explicitly finished).
		local top = entries[1].Score
		for _, e in entries do
			local player = Players:GetPlayerByUserId(e.UserId)
			local stillPlaying = player ~= nil and PlayerStateService:Get(player).State == "Playing"
			if e.Placement == 1 or (#ctx._finishOrder == 0 and e.Score == top and top > 0 and stillPlaying) then
				e.Won = true
				table.insert(winners, e.UserId)
			end
		end
	end
	return { Entries = entries, WinnerUserIds = winners, Reason = ctx.Reason }
end

function MinigameService:Abort(reason: string)
	local ctx = self._context
	if ctx and not ctx.Finished then
		ctx.End(reason)
		self.Diagnostics.aborts += 1
	end
end

function MinigameService:Cleanup()
	local def, ctx = self._current, self._context
	if not ctx then return end
	if def and def.Cleanup then pcall(def.Cleanup, ctx) end
	ctx.Janitor:Destroy()
	self.Diagnostics.lastCleanupJanitorCount = Janitor.ActiveCount()
	for _, p in Players:GetPlayers() do
		Remotes:Fire("MovementRules", p, { Sprint = false, Slide = false, Dash = false, Jump = true })
	end
	self._current = nil
	self._context = nil
	Log.Info("Minigame", "Cleanup complete", { activeJanitors = Janitor.ActiveCount() })
end

function MinigameService:Context() return self._context end
function MinigameService:Snapshot()
	local ctx = self._context
	return {
		active = ctx and ctx.Meta.Id or nil, map = ctx and ctx.MapId, modifier = ctx and ctx.Modifier.Id,
		alive = ctx and #ctx.AlivePlayers() or 0, scores = ctx and ctx.Scores, janitorItems = ctx and ctx.Janitor:Count(),
		diagnostics = self.Diagnostics, registered = self:Ids(),
	}
end

return MinigameService
