--!strict
-- Central, permission-checked admin command system. GUI buttons call a single remote with { command, args }.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Log = require(Shared.Utilities.Log)
local GameConfig = require(Shared.Config.GameConfig)
local Catalog = require(Shared.MinigameCatalog)
local Modifiers = require(Shared.Config.Modifiers)
local Janitor = require(Shared.Utilities.Janitor)

local AdminConfig = require(script.Parent.AdminConfig)
local Services = script.Parent.Parent.Services
local Remotes = require(Services.Remotes)
local RoundService = require(Services.RoundService)
local VotingService = require(Services.VotingService)
local MinigameService = require(Services.MinigameService)
local MapService = require(Services.MapService)
local PlayerStateService = require(Services.PlayerStateService)
local AnnouncementService = require(Services.AnnouncementService)
local DataService = require(Services.DataService)
local AntiCheatService = require(Services.AntiCheatService)
local SpectatorService = require(Services.SpectatorService)

local AdminService = { _commands = {} :: { [string]: any }, _audit = {} :: { any }, _sessionBans = {} :: { [number]: boolean }, _waypoints = {} :: { [number]: { [string]: CFrame } }, _flying = {} :: { [number]: boolean } }

function AdminService:RoleOf(player: Player): string?
	local role = AdminConfig.Users[player.UserId]
	if role then return role end
	if RunService:IsStudio() and AdminConfig.StudioLocalPlayerIsOwner then return "Owner" end
	return nil
end

function AdminService:Rank(player: Player): number
	local role = self:RoleOf(player)
	return role and AdminConfig.RoleRank[role] or 0
end

function AdminService:Can(player: Player, command: any): boolean
	return self:Rank(player) >= (AdminConfig.CategoryRank[command.Category] or 5)
end

function AdminService:Register(cmd: { Name: string, Category: string, Description: string, Args: { string }?, Dangerous: boolean?, Run: (Player, any) -> any })
	assert(self._commands[cmd.Name] == nil, "Duplicate admin command " .. cmd.Name)
	self._commands[cmd.Name] = cmd
end

function AdminService:Audit(player: Player, command: string, args: any, ok: boolean, detail: any?)
	local entry = { admin = player.UserId, name = player.Name, command = command, args = args, ok = ok, detail = detail, t = os.time() }
	table.insert(self._audit, entry)
	if #self._audit > AdminConfig.AuditBufferSize then table.remove(self._audit, 1) end
	Log.Info("AdminAudit", ("%s %s %s"):format(player.Name, command, ok and "OK" or "FAIL"), { args = args })
end

local function target(args: any): Player?
	local id = args and args.target
	if type(id) == "number" then return Players:GetPlayerByUserId(id) end
	if type(id) == "string" then
		for _, p in Players:GetPlayers() do if p.Name:lower() == id:lower() or p.DisplayName:lower() == id:lower() then return p end end
	end
	return nil
end
local function root(p: Player): BasePart? local c = p.Character return c and c:FindFirstChild("HumanoidRootPart") :: BasePart? end
local function hum(p: Player): Humanoid? local c = p.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function num(v: any, lo: number, hi: number, default: number): number
	if type(v) ~= "number" or v ~= v then return default end
	return math.clamp(v, lo, hi)
end
local function safeTeleport(p: Player, cf: CFrame): boolean
	local r = root(p)
	if not r then return false end
	-- Validate destination is not inside solid geometry by raycasting downward for a floor within 200 studs.
	local ray = Workspace:Raycast(cf.Position + Vector3.new(0, 5, 0), Vector3.new(0, -200, 0))
	local dest = ray and CFrame.new(ray.Position + Vector3.new(0, 3.5, 0)) or cf
	AntiCheatService:MarkTeleport(p)
	p.Character:PivotTo(dest)
	return true
end

function AdminService:Init()
	self:_registerCommands()
	Remotes:SetCallback("AdminAction", function(player, payload)
		if type(payload) ~= "table" or type(payload.command) ~= "string" then return { ok = false, error = "invalid_payload" } end
		local cmd = self._commands[payload.command]
		if not cmd then return { ok = false, error = "unknown_command" } end
		if not self:Can(player, cmd) then
			self:Audit(player, payload.command, payload.args, false, "unauthorized")
			return { ok = false, error = "unauthorized" }
		end
		if cmd.Dangerous and AdminConfig.DangerousRequiresConfirm and payload.confirmed ~= true then
			return { ok = false, error = "confirm_required" }
		end
		local args = if type(payload.args) == "table" then payload.args else {}
		local ok, result = pcall(cmd.Run, player, args)
		self:Audit(player, payload.command, args, ok, ok and result or tostring(result))
		if not ok then return { ok = false, error = tostring(result) } end
		return { ok = true, result = result }
	end)
	Players.PlayerAdded:Connect(function(p)
		if self._sessionBans[p.UserId] then p:Kick("You are banned from this server.") return end
		task.defer(function() self:_sendPanelState(p) end)
	end)
	for _, p in Players:GetPlayers() do self:_sendPanelState(p) end
end

function AdminService:_sendPanelState(p: Player)
	local rank = self:Rank(p)
	if rank == 0 then return end
	local list = {}
	for name, cmd in self._commands do
		if self:Can(p, cmd) then table.insert(list, { Name = name, Category = cmd.Category, Description = cmd.Description, Args = cmd.Args or {}, Dangerous = cmd.Dangerous or false }) end
	end
	table.sort(list, function(a, b) return a.Category == b.Category and a.Name < b.Name or a.Category < b.Category end)
	Remotes:Fire("AdminPanelState", p, { Role = self:RoleOf(p), Commands = list, Minigames = MinigameService:Ids(), Modifiers = (function() local o = {} for _, m in Modifiers do table.insert(o, m.Id) end return o end)() })
end

function AdminService:_registerCommands()
	local R = function(c) self:Register(c) end
	-- SERVER / ROUND
	R({ Name = "SkipPhase", Category = "Round", Description = "Skip the current phase (intermission, voting, results...)", Run = function() RoundService:Skip() return "skipped" end })
	R({ Name = "ForceVoting", Category = "Round", Description = "End intermission and go to voting now", Run = function() RoundService:Skip() return "ok" end })
	R({ Name = "EndRound", Category = "Round", Description = "End the current minigame immediately", Run = function() MinigameService:Abort("admin_end") return "ending" end })
	R({ Name = "AbortRound", Category = "Round", Description = "Cancel the round and return everyone to lobby", Dangerous = true, Run = function() RoundService:Abort() return "aborting" end })
	R({ Name = "ForceMinigame", Category = "Round", Description = "Force the next minigame (optionally map/modifier)", Args = { "gameId", "mapId", "modifierId" }, Run = function(_, a)
		assert(type(a.gameId) == "string" and Catalog.ById[a.gameId], "unknown gameId")
		RoundService:Force(a.gameId, type(a.mapId) == "string" and a.mapId or nil, type(a.modifierId) == "string" and a.modifierId or nil)
		return "forced " .. a.gameId end })
	R({ Name = "RestartMinigame", Category = "Round", Description = "End and immediately replay the current minigame", Run = function()
		local ctx = MinigameService:Context(); if ctx then RoundService:Force(ctx.Meta.Id, ctx.MapId, ctx.Modifier.Id) end
		MinigameService:Abort("admin_restart"); RoundService:Skip(); return "restarting" end })
	R({ Name = "RerollVotes", Category = "Round", Description = "Regenerate voting candidates", Run = function()
		if not VotingService:IsActive() then return "voting_not_active" end
		VotingService:Cancel(); VotingService:StartVoting(RoundService.History, RoundService.Round, #Players:GetPlayers(), RoundService:TimeRemaining()); return "rerolled" end })
	R({ Name = "AddTime", Category = "Round", Description = "Add seconds to the current phase timer", Args = { "seconds" }, Run = function(_, a) RoundService:AddTime(num(a.seconds, -300, 300, 30)) return "ok" end })
	R({ Name = "ReturnAllToLobby", Category = "Server", Description = "Teleport everyone to the lobby", Run = function()
		for _, p in Players:GetPlayers() do safeTeleport(p, MapService:LobbySpawn()) end return "ok" end })
	R({ Name = "ShutdownServer", Category = "Dangerous", Description = "Kick everyone and shut the server down", Dangerous = true, Run = function()
		for _, p in Players:GetPlayers() do p:Kick("Server restarting.") end return "shutdown" end })

	-- PLAYER MANAGEMENT
	R({ Name = "Goto", Category = "Teleport", Description = "Teleport yourself to a player", Args = { "target" }, Run = function(admin, a) local t = assert(target(a), "no target"); local r = assert(root(t), "no character"); safeTeleport(admin, r.CFrame * CFrame.new(0, 0, 3)) return "ok" end })
	R({ Name = "Bring", Category = "Teleport", Description = "Bring a player to you", Args = { "target" }, Run = function(admin, a) local t = assert(target(a), "no target"); local r = assert(root(admin), "no character"); safeTeleport(t, r.CFrame * CFrame.new(0, 0, -3)) return "ok" end })
	R({ Name = "TeleportToLobby", Category = "Teleport", Description = "Send a player (or yourself) to lobby", Args = { "target" }, Run = function(admin, a) safeTeleport(target(a) or admin, MapService:LobbySpawn()) return "ok" end })
	R({ Name = "TeleportToMap", Category = "Teleport", Description = "Send a player to the active map spawn", Args = { "target" }, Run = function(admin, a) local s = MapService:Markers("Spawns")[1]; assert(s, "no active map"); safeTeleport(target(a) or admin, s.CFrame + Vector3.new(0, 3, 0)) return "ok" end })
	R({ Name = "TeleportToPosition", Category = "Teleport", Description = "Teleport to x,y,z", Args = { "x", "y", "z" }, Run = function(admin, a) safeTeleport(admin, CFrame.new(num(a.x, -1e5, 1e5, 0), num(a.y, -1e3, 1e4, 10), num(a.z, -1e5, 1e5, 0))) return "ok" end })
	R({ Name = "SaveWaypoint", Category = "Teleport", Description = "Save current position under a name", Args = { "name" }, Run = function(admin, a) local r = assert(root(admin)); self._waypoints[admin.UserId] = self._waypoints[admin.UserId] or {}; self._waypoints[admin.UserId][tostring(a.name)] = r.CFrame return "saved" end })
	R({ Name = "GotoWaypoint", Category = "Teleport", Description = "Teleport to a saved waypoint", Args = { "name" }, Run = function(admin, a) local w = self._waypoints[admin.UserId]; local cf = assert(w and w[tostring(a.name)], "no such waypoint"); safeTeleport(admin, cf) return "ok" end })
	R({ Name = "Kill", Category = "Player", Description = "Kill a player", Args = { "target" }, Run = function(_, a) local h = assert(hum(assert(target(a)))); h.Health = 0 return "ok" end })
	R({ Name = "Respawn", Category = "Player", Description = "Respawn a player", Args = { "target" }, Run = function(_, a) assert(target(a)):LoadCharacter() return "ok" end })
	R({ Name = "Heal", Category = "Player", Description = "Heal to full", Args = { "target" }, Run = function(admin, a) local h = assert(hum(target(a) or admin)); h.Health = h.MaxHealth return "ok" end })
	R({ Name = "Damage", Category = "Player", Description = "Damage a player", Args = { "target", "amount" }, Run = function(_, a) local h = assert(hum(assert(target(a)))); h:TakeDamage(num(a.amount, 0, 1000, 25)) return "ok" end })
	R({ Name = "Freeze", Category = "Player", Description = "Anchor a player in place", Args = { "target" }, Run = function(_, a) local r = assert(root(assert(target(a)))); r.Anchored = true return "ok" end })
	R({ Name = "Unfreeze", Category = "Player", Description = "Unfreeze a player", Args = { "target" }, Run = function(_, a) local r = assert(root(assert(target(a)))); r.Anchored = false return "ok" end })
	R({ Name = "Ragdoll", Category = "Player", Description = "Toggle ragdoll (PlatformStand)", Args = { "target" }, Run = function(admin, a) local h = assert(hum(target(a) or admin)); h.PlatformStand = not h.PlatformStand return tostring(h.PlatformStand) end })
	R({ Name = "Sit", Category = "Player", Description = "Make a player sit", Args = { "target" }, Run = function(admin, a) local h = assert(hum(target(a) or admin)); h.Sit = true return "ok" end })
	R({ Name = "Stand", Category = "Player", Description = "Make a player stand", Args = { "target" }, Run = function(admin, a) local h = assert(hum(target(a) or admin)); h.Sit = false; h.PlatformStand = false return "ok" end })
	R({ Name = "ForceField", Category = "Player", Description = "Toggle a force field", Args = { "target" }, Run = function(admin, a) local t = target(a) or admin; local c = assert(t.Character); local ff = c:FindFirstChildOfClass("ForceField"); if ff then ff:Destroy() return "off" end; local f = Instance.new("ForceField"); f:SetAttribute("Temporary", true); f.Parent = c return "on" end })
	R({ Name = "Invisible", Category = "Player", Description = "Make a player invisible", Args = { "target" }, Run = function(admin, a) local c = assert((target(a) or admin).Character); for _, d in c:GetDescendants() do if d:IsA("BasePart") then d.Transparency = 1 elseif d:IsA("Decal") then d.Transparency = 1 end end return "ok" end })
	R({ Name = "Visible", Category = "Player", Description = "Make a player visible", Args = { "target" }, Run = function(admin, a) local t = target(a) or admin; PlayerStateService:RestoreCharacter(t); local c = t.Character; if c then for _, d in c:GetDescendants() do if d:IsA("Decal") then d.Transparency = 0 end end end return "ok" end })
	R({ Name = "SetScale", Category = "Player", Description = "Set character scale (0.3 - 4)", Args = { "target", "scale" }, Run = function(admin, a) PlayerStateService:SetScale(target(a) or admin, num(a.scale, 0.3, 4, 1)) return "ok" end })
	R({ Name = "ResetCharacter", Category = "Player", Description = "Reset all temporary character modifications", Args = { "target" }, Run = function(admin, a) local t = target(a) or admin; PlayerStateService:RestoreCharacter(t); self._flying[t.UserId] = nil; AntiCheatService.Exempt[t.UserId] = nil; Remotes:Fire("AdminPanelState", t, { AdminMovement = { Fly = false, Noclip = false, InfiniteJump = false } }) return "ok" end })
	R({ Name = "Spectate", Category = "Player", Description = "Spectate a player", Args = { "target" }, Run = function(admin, a) local t = assert(target(a)); SpectatorService:Begin(admin, false); Remotes:Fire("SpectateTarget", admin, t.UserId) return "ok" end })
	R({ Name = "Unspectate", Category = "Player", Description = "Stop spectating", Run = function(admin) SpectatorService:Stop(admin) return "ok" end })
	R({ Name = "SetTeam", Category = "Gameplay", Description = "Assign a team label", Args = { "target", "team" }, Run = function(_, a) PlayerStateService:SetTeam(assert(target(a)), type(a.team) == "string" and a.team or nil) return "ok" end })
	R({ Name = "SetRole", Category = "Gameplay", Description = "Force a role (Hunter, Seeker, Prop, Tagger...)", Args = { "target", "role" }, Run = function(_, a) PlayerStateService:SetRole(assert(target(a)), type(a.role) == "string" and a.role or nil) return "ok" end })

	-- MOVEMENT (admin-only; server marks the player exempt from anti-cheat and the client applies the local controller)
	local function setMovementFlag(admin: Player, flag: string, enabled: boolean)
		AntiCheatService.Exempt[admin.UserId] = enabled or self._flying[admin.UserId] or nil
		if flag == "Fly" then self._flying[admin.UserId] = enabled or nil end
		Remotes:Fire("AdminPanelState", admin, { AdminMovement = { [flag] = enabled } })
		return enabled and "on" or "off"
	end
	R({ Name = "Fly", Category = "Movement", Description = "Toggle flight for yourself", Args = { "enabled", "speed" }, Run = function(admin, a) Remotes:Fire("AdminPanelState", admin, { FlySpeed = num(a.speed, 10, 400, 60) }) return setMovementFlag(admin, "Fly", a.enabled ~= false) end })
	R({ Name = "Noclip", Category = "Movement", Description = "Toggle noclip for yourself", Args = { "enabled" }, Run = function(admin, a) return setMovementFlag(admin, "Noclip", a.enabled ~= false) end })
	R({ Name = "InfiniteJump", Category = "Movement", Description = "Toggle infinite jump for yourself", Args = { "enabled" }, Run = function(admin, a) return setMovementFlag(admin, "InfiniteJump", a.enabled ~= false) end })
	R({ Name = "WalkSpeed", Category = "Movement", Description = "Set walk speed (self or target)", Args = { "target", "speed" }, Run = function(admin, a) local t = target(a) or admin; AntiCheatService.Exempt[t.UserId] = true; PlayerStateService:SetMovement(t, num(a.speed, 0, 500, 16), nil) return "ok" end })
	R({ Name = "JumpHeight", Category = "Movement", Description = "Set jump height (self or target)", Args = { "target", "height" }, Run = function(admin, a) PlayerStateService:SetMovement(target(a) or admin, nil, num(a.height, 0, 500, 7.2)) return "ok" end })
	R({ Name = "Gravity", Category = "World", Description = "Set workspace gravity", Args = { "value" }, Run = function(_, a) Workspace.Gravity = num(a.value, 0, 1000, 196.2) return "ok" end })
	R({ Name = "ResetMovement", Category = "Movement", Description = "Reset movement to defaults", Args = { "target" }, Run = function(admin, a) local t = target(a) or admin; PlayerStateService:SetMovement(t, GameConfig.Movement.DefaultWalkSpeed, GameConfig.Movement.DefaultJumpHeight); AntiCheatService.Exempt[t.UserId] = nil; self._flying[t.UserId] = nil; Remotes:Fire("AdminPanelState", t, { AdminMovement = { Fly = false, Noclip = false, InfiniteJump = false } }) return "ok" end })

	-- GAMEPLAY (routes into the active minigame through its optional AdminHook)
	local function hook(action: string, a: any)
		local ctx = MinigameService:Context()
		assert(ctx, "no active minigame")
		local def = MinigameService:Get(ctx.Meta.Id)
		if def.AdminHook then return def.AdminHook(ctx, action, a) end
		return "minigame has no admin hook for " .. action
	end
	R({ Name = "EliminatePlayer", Category = "Gameplay", Description = "Eliminate a player from the current minigame", Args = { "target" }, Run = function(_, a) local ctx = assert(MinigameService:Context(), "no minigame"); ctx.Eliminate(assert(target(a)), "admin") return "ok" end })
	R({ Name = "ForceFinish", Category = "Gameplay", Description = "Mark a player as finished", Args = { "target" }, Run = function(_, a) local ctx = assert(MinigameService:Context(), "no minigame"); ctx.Finish(assert(target(a))) return "ok" end })
	R({ Name = "SetScore", Category = "Gameplay", Description = "Set a player's score", Args = { "target", "score" }, Run = function(_, a) local ctx = assert(MinigameService:Context(), "no minigame"); local t = assert(target(a)); ctx.Scores[t.UserId] = num(a.score, -1e6, 1e6, 0) return "ok" end })
	R({ Name = "GiveBomb", Category = "Gameplay", Description = "Give the bomb to a player (bomb games)", Args = { "target" }, Run = function(_, a) return hook("GiveBomb", { target = assert(target(a)) }) end })
	R({ Name = "TagPlayer", Category = "Gameplay", Description = "Tag a player (tag games)", Args = { "target" }, Run = function(_, a) return hook("Tag", { target = assert(target(a)) }) end })
	R({ Name = "RevealHidden", Category = "Gameplay", Description = "Reveal hidden players/props", Run = function(_, a) return hook("Reveal", a) end })
	R({ Name = "TriggerHazard", Category = "Gameplay", Description = "Trigger a hazard/disaster by name", Args = { "name" }, Run = function(_, a) return hook("Hazard", a) end })
	R({ Name = "CompleteCheckpoint", Category = "Gameplay", Description = "Complete next checkpoint for a player", Args = { "target" }, Run = function(_, a) return hook("Checkpoint", { target = assert(target(a)) }) end })

	-- WORLD / DEBUG
	R({ Name = "ShowMarkers", Category = "World", Description = "Toggle visibility of map markers (spawns, checkpoints, zones)", Run = function()
		local m = MapService:Current(); assert(m, "no map")
		local on = not m:GetAttribute("DebugMarkers")
		m:SetAttribute("DebugMarkers", on)
		for _, name in { "Spawns", "TeamSpawns", "Checkpoints", "Objectives", "Hazards", "HidingSpots", "NPCNodes", "SafeZones", "KillZones" } do
			local f = m:FindFirstChild(name)
			if f then for _, d in f:GetDescendants() do if d:IsA("BasePart") then d.Transparency = on and 0.5 or 1 end end end
		end
		return on and "shown" or "hidden" end })
	R({ Name = "ReloadMap", Category = "World", Description = "Reload the active map asset", Run = function() local ctx = assert(MinigameService:Context()); ctx.Map = MapService:Load(ctx.MapId) return "reloaded" end })
	R({ Name = "InspectRound", Category = "Debug", Description = "Dump round state", Run = function() return RoundService:Snapshot() end })
	R({ Name = "InspectMinigame", Category = "Debug", Description = "Dump minigame state & cleanup diagnostics", Run = function() return MinigameService:Snapshot() end })
	R({ Name = "InspectVotes", Category = "Debug", Description = "Dump voting state", Run = function() return VotingService:Snapshot() end })
	R({ Name = "InspectPlayers", Category = "Debug", Description = "Dump player states", Run = function() local o = {} for _, p in Players:GetPlayers() do o[p.Name] = PlayerStateService:Get(p) end return o end })
	R({ Name = "InspectServer", Category = "Debug", Description = "Server health: memory, janitors, anticheat flags, recent logs", Run = function()
		local Stats = game:GetService("Stats")
		return { memoryMB = Stats:GetTotalMemoryUsageMb(), activeJanitors = Janitor.ActiveCount(), flags = AntiCheatService:Flags(), logs = Log.Recent(40), players = #Players:GetPlayers() } end })
	R({ Name = "AuditLog", Category = "Debug", Description = "Recent admin actions", Run = function() local o = {} for i = math.max(1, #self._audit - 50), #self._audit do table.insert(o, self._audit[i]) end return o end })
	R({ Name = "SetLogLevel", Category = "Debug", Description = "Debug/Info/Warn", Args = { "level" }, Run = function(_, a) local map = { Debug = 1, Info = 2, Warn = 3 }; Log.MinLevel = map[tostring(a.level)] or 2 return "ok" end })

	-- TESTING
	R({ Name = "GrantCurrency", Category = "Testing", Description = "Grant test coins/XP to a player", Args = { "target", "coins", "xp" }, Run = function(admin, a) local t = target(a) or admin; local prof = assert(DataService:Get(t), "no profile"); prof.Coins += num(a.coins, 0, 1e6, 100); prof.XP += num(a.xp, 0, 1e6, 0); DataService:MarkDirty(t) return "ok" end })
	R({ Name = "ResetProgression", Category = "Dangerous", Description = "Wipe a player's progression", Args = { "target" }, Dangerous = true, Run = function(admin, a) DataService:ResetProfile(target(a) or admin) return "reset" end })
	R({ Name = "SimulateVictory", Category = "Testing", Description = "End the minigame with a chosen winner", Args = { "target" }, Run = function(admin, a) local ctx = assert(MinigameService:Context()); local t = target(a) or admin; for _, p in ctx.AlivePlayers() do if p ~= t then ctx.Eliminate(p, "sim") end end; ctx.End("simulated_victory") return "ok" end })
	R({ Name = "CleanupDiagnostics", Category = "Testing", Description = "Report active janitors and leaked ActiveMap children", Run = function() return { activeJanitors = Janitor.ActiveCount(), activeMapChildren = #Workspace.ActiveMap:GetChildren(), minigame = MinigameService.Diagnostics } end })

	-- MODERATION
	R({ Name = "Kick", Category = "Moderation", Description = "Kick a player", Args = { "target", "reason" }, Dangerous = true, Run = function(_, a) assert(target(a)):Kick(tostring(a.reason or "Kicked by moderator")) return "ok" end })
	R({ Name = "ServerBan", Category = "Moderation", Description = "Ban a player from this server instance", Args = { "target", "reason" }, Dangerous = true, Run = function(_, a) local t = assert(target(a)); self._sessionBans[t.UserId] = true; t:Kick(tostring(a.reason or "Banned from this server")) return "ok" end })
	R({ Name = "Warn", Category = "Moderation", Description = "Send a warning to a player", Args = { "target", "message" }, Run = function(_, a) AnnouncementService:Send(assert(target(a)), tostring(a.message or "Please follow the rules."), 6, "Warning") return "ok" end })
	R({ Name = "Announce", Category = "Announce", Description = "Broadcast an announcement", Args = { "message", "duration", "kind" }, Run = function(_, a) AnnouncementService:Broadcast(tostring(a.message or ""):sub(1, 300), num(a.duration, 1, 60, 5), type(a.kind) == "string" and a.kind or "System", 3) return "ok" end })
end

function AdminService:Snapshot() return { audit = self._audit, bans = self._sessionBans } end

return AdminService
