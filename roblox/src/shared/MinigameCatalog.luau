--!strict
-- Metadata for every minigame. Server minigame modules are looked up by Id.
-- Voting, HUD, admin panel and the web command center all consume this file.
local Types = require(script.Parent.Types)
type Meta = Types.MinigameMeta

local FREE = { Sprint = true, Slide = true, Dash = false, Jump = true }
local BASIC = { Sprint = false, Slide = false, Dash = false, Jump = true }
local NOJUMP = { Sprint = false, Slide = false, Dash = false, Jump = false }
local PARKOUR = { Sprint = true, Slide = true, Dash = true, Jump = true }

local function def(t: any): Meta
	t.SecondaryCategory = t.SecondaryCategory or nil
	t.SupportsTeams = t.SupportsTeams or false
	t.AllowsSpectating = if t.AllowsSpectating == nil then true else t.AllowsSpectating
	t.HidesInformation = t.HidesInformation or false
	t.VoteCooldownRounds = t.VoteCooldownRounds or 4
	t.AllowedModifiers = t.AllowedModifiers or { "None", "TinyPlayers", "GiantPlayers", "LowGravity", "HighSpeed", "Darkness", "Fog" }
	t.Movement = t.Movement or BASIC
	t.Icon = t.Icon or ("rbxassetid://0")
	return t
end

local Catalog: { Meta } = {
	-- BOMB
	def({ Id = "BombTag", DisplayName = "Bomb Tag", Description = "Pass the ticking bomb before it explodes. Last one standing wins.", Category = "Bomb", SecondaryCategory = "Tag", MinimumPlayers = 3, MaximumPlayers = 24, Duration = 120, Maps = { "Courtyard", "Rooftops" }, Movement = FREE, AllowedModifiers = { "None", "DoubleBomb", "HighSpeed", "TinyPlayers", "Fog" } }),
	def({ Id = "HiddenTimerBomb", DisplayName = "Hidden Fuse", Description = "Nobody knows when the bomb blows. The arena shrinks every explosion.", Category = "Bomb", SecondaryCategory = "Chaos", MinimumPlayers = 4, MaximumPlayers = 20, Duration = 120, Maps = { "Courtyard", "IceRing" }, Movement = FREE }),
	def({ Id = "ReverseBomb", DisplayName = "Hot Treasure", Description = "Holding the 'bomb' earns points. Steal it and keep it!", Category = "Bomb", SecondaryCategory = "Chaos", MinimumPlayers = 3, MaximumPlayers = 20, Duration = 90, Maps = { "Courtyard", "Rooftops" }, Movement = FREE }),
	def({ Id = "BombKart", DisplayName = "Bomb Kart", Description = "Karts. One bomb. Ram to pass it. Don't be holding it at zero.", Category = "Kart", SecondaryCategory = "Bomb", MinimumPlayers = 4, MaximumPlayers = 16, Duration = 120, Maps = { "SpeedwayOval", "CanyonTrack" }, Movement = NOJUMP, AllowedModifiers = { "None", "DoubleBomb", "Fog" } }),
	-- TAG
	def({ Id = "FreezeTag", DisplayName = "Freeze Tag", Description = "Taggers freeze runners. Runners thaw friends by touch. Freeze everyone to win.", Category = "Tag", SecondaryCategory = "Team", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 120, Maps = { "Courtyard", "Playground" }, Movement = FREE }),
	def({ Id = "InfectionTag", DisplayName = "Outbreak", Description = "One infected. Every touch spreads it. Survive the longest.", Category = "Tag", SecondaryCategory = "Elimination", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 120, Maps = { "Playground", "Rooftops" }, Movement = FREE }),
	def({ Id = "CrownTag", DisplayName = "Crown Keeper", Description = "Hold the crown the longest. Touch the king to steal it.", Category = "Tag", SecondaryCategory = "Chaos", MinimumPlayers = 3, MaximumPlayers = 20, Duration = 90, Maps = { "Courtyard", "IceRing" }, Movement = PARKOUR }),
	def({ Id = "SafeZoneTag", DisplayName = "Safe Zone Tag", Description = "Safe zones move every 15 seconds. Taggers can't enter... yet.", Category = "Tag", SecondaryCategory = "Movement", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 120, Maps = { "Playground", "Courtyard" }, Movement = FREE }),
	-- HIDE / PROP / DECEPTION
	def({ Id = "HideAndSeek", DisplayName = "Hide & Seek", Description = "Pick your size: small hides, large runs. Seekers hunt after the countdown.", Category = "HideSeek", MinimumPlayers = 4, MaximumPlayers = 20, Duration = 150, HidesInformation = true, Maps = { "MansionHalls", "Warehouse" }, Movement = BASIC, AllowedModifiers = { "None", "Darkness", "Fog" } }),
	def({ Id = "PropHunt", DisplayName = "Prop Hunt", Description = "Become an object and blend in. Hunters have limited ammo — every miss costs them.", Category = "PropHunt", SecondaryCategory = "HideSeek", MinimumPlayers = 4, MaximumPlayers = 20, Duration = 150, HidesInformation = true, Maps = { "MansionHalls", "Warehouse" }, Movement = BASIC, AllowedModifiers = { "None", "Fog" } }),
	def({ Id = "BlendIn", DisplayName = "Blend In", Description = "Humans hide among wandering NPCs. Hunters guess — wrong guesses hurt.", Category = "Deception", SecondaryCategory = "Social", MinimumPlayers = 4, MaximumPlayers = 16, Duration = 120, HidesInformation = true, Maps = { "TownSquare" }, Movement = NOJUMP, AllowedModifiers = { "None" } }),
	def({ Id = "NPCPanic", DisplayName = "NPC Panic", Description = "A monster stalks the plaza. NPCs flee in patterns — imitate them or be caught.", Category = "Deception", SecondaryCategory = "Survival", MinimumPlayers = 4, MaximumPlayers = 16, Duration = 120, HidesInformation = true, Maps = { "TownSquare" }, Movement = NOJUMP, AllowedModifiers = { "None", "Fog" } }),
	-- OBBY / SPEEDRUN
	def({ Id = "SpeedRun", DisplayName = "Speed Run", Description = "A linear course with risky shortcuts. Fastest three take the podium.", Category = "Speedrun", SecondaryCategory = "Obby", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 120, Maps = { "SkyCourse", "CaveRun" }, Movement = PARKOUR }),
	def({ Id = "CollapsingObby", DisplayName = "Collapse", Description = "The course crumbles behind you and lava rises. Don't stop.", Category = "Obby", SecondaryCategory = "Elimination", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 120, Maps = { "SkyCourse", "CaveRun" }, Movement = PARKOUR }),
	def({ Id = "RandomRoute", DisplayName = "Random Route", Description = "Every segment is rolled fresh. Read the course on the fly.", Category = "Obby", SecondaryCategory = "Movement", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 120, Maps = { "ModularObby" }, Movement = PARKOUR }),
	-- KART
	def({ Id = "KartRace", DisplayName = "Kart Race", Description = "Three laps. Drift for boost. Hit the ramps.", Category = "Kart", SecondaryCategory = "Racing", MinimumPlayers = 2, MaximumPlayers = 16, Duration = 150, Maps = { "SpeedwayOval", "CanyonTrack" }, Movement = NOJUMP, AllowedModifiers = { "None", "HighSpeed", "Fog" } }),
	def({ Id = "EliminationKart", DisplayName = "Last Kart", Description = "Every 12 seconds the kart in last place is eliminated.", Category = "Kart", SecondaryCategory = "Elimination", MinimumPlayers = 3, MaximumPlayers = 16, Duration = 150, Maps = { "SpeedwayOval", "CanyonTrack" }, Movement = NOJUMP, AllowedModifiers = { "None", "HighSpeed" } }),
	-- SURVIVAL / DISASTER
	def({ Id = "DisasterSurvival", DisplayName = "Disaster Island", Description = "Two random disasters per round. Read the warning, find shelter.", Category = "Disaster", SecondaryCategory = "Survival", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 120, Maps = { "IslandTown", "MountainVillage" }, Movement = FREE }),
	def({ Id = "RisingFlood", DisplayName = "Rising Flood", Description = "Water rises, platforms sink. Climb higher than everyone else.", Category = "Survival", SecondaryCategory = "Platform", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 120, Maps = { "FloodTower", "IslandTown" }, Movement = FREE }),
	def({ Id = "MeteorShower", DisplayName = "Meteor Shower", Description = "Shadows mark impacts. Every meteor deletes floor forever.", Category = "Disaster", SecondaryCategory = "Reaction", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "CraterField" }, Movement = FREE }),
	-- REACTION
	def({ Id = "ColorSurvival", DisplayName = "Color Rush", Description = "A color is called. Stand on it before the rest vanishes. Sometimes it lies.", Category = "Reaction", SecondaryCategory = "Platform", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "ColorGrid" }, Movement = FREE, AllowedModifiers = { "None", "HighSpeed", "TinyPlayers", "GiantPlayers" } }),
	def({ Id = "RedLightGreenLight", DisplayName = "Red Light, Green Light", Description = "Move on green. Freeze on red. First to the line wins; movers get zapped.", Category = "Reaction", SecondaryCategory = "Racing", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "LongField" }, Movement = BASIC, AllowedModifiers = { "None", "Fog", "Slippery" } }),
	def({ Id = "SimonSays", DisplayName = "Simon Says", Description = "Obey Simon. Ignore impostors. Wrong move, you're out.", Category = "Reaction", SecondaryCategory = "Memory", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "Stage" }, Movement = BASIC, AllowedModifiers = { "None" } }),
	-- PLATFORM
	def({ Id = "FallingPlatforms", DisplayName = "Falling Platforms", Description = "Tiles drop a second after you touch them. Keep moving.", Category = "Platform", SecondaryCategory = "Elimination", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "HexGrid", "ColorGrid" }, Movement = BASIC }),
	def({ Id = "FloorIsLava", DisplayName = "Floor Is Lava", Description = "Lava pulses in waves. Climb the furniture — it sinks under weight.", Category = "Platform", SecondaryCategory = "Survival", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "LivingRoom" }, Movement = FREE }),
	def({ Id = "RotatingArena", DisplayName = "Spin Cycle", Description = "Sweeping bars: jump the low ones, crouch under the high ones. Speed ramps up.", Category = "Platform", SecondaryCategory = "Reaction", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "SpinDisc" }, Movement = BASIC }),
	-- PHYSICS
	def({ Id = "KnockbackArena", DisplayName = "Knockback Arena", Description = "Three lives. Punch people off a shrinking platform.", Category = "Physics", SecondaryCategory = "Elimination", MinimumPlayers = 2, MaximumPlayers = 16, Duration = 120, Maps = { "SkyPlatform" }, Movement = FREE, AllowedModifiers = { "None", "BigKnockback", "LowGravity", "Slippery" } }),
	def({ Id = "GiantBallSurvival", DisplayName = "Boulder Run", Description = "Boulders roll down the slope. Dodge, or get bowled.", Category = "Physics", SecondaryCategory = "Survival", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "SlopeRun" }, Movement = FREE }),
	def({ Id = "FanSurvival", DisplayName = "Wind Tunnel", Description = "Giant fans switch direction. Grab handholds before you're blown off.", Category = "Physics", SecondaryCategory = "Survival", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "WindBridge" }, Movement = BASIC }),
	def({ Id = "RagdollRace", DisplayName = "Ragdoll Downhill", Description = "You're a ragdoll. Fling yourself down the mountain first.", Category = "Physics", SecondaryCategory = "Racing", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "SlopeRun" }, Movement = NOJUMP, AllowedModifiers = { "None", "LowGravity" } }),
	-- MEMORY
	def({ Id = "MemoryTiles", DisplayName = "Memory Path", Description = "The safe path flashes once. Cross the grid from memory.", Category = "Memory", SecondaryCategory = "Platform", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "HexGrid" }, Movement = BASIC, AllowedModifiers = { "None" } }),
	def({ Id = "FindTheChange", DisplayName = "Spot the Change", Description = "Study the room. Lights out. One thing changed — touch it first.", Category = "Memory", SecondaryCategory = "Social", MinimumPlayers = 2, MaximumPlayers = 20, Duration = 100, Maps = { "LivingRoom", "MansionHalls" }, Movement = BASIC, AllowedModifiers = { "None" } }),
	def({ Id = "SafeDoor", DisplayName = "Safe Door", Description = "Five doors, one safe. Memorize the hint before it hides.", Category = "Memory", SecondaryCategory = "Elimination", MinimumPlayers = 2, MaximumPlayers = 24, Duration = 100, Maps = { "DoorHall" }, Movement = BASIC, AllowedModifiers = { "None" } }),
	-- TEAM
	def({ Id = "TugOfWar", DisplayName = "Tug of War", Description = "Pull by completing rhythm prompts. Missed prompts pull for the enemy.", Category = "Team", SecondaryCategory = "Reaction", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 90, SupportsTeams = true, Maps = { "Stage" }, Movement = NOJUMP, AllowedModifiers = { "None" } }),
	def({ Id = "PushThePayload", DisplayName = "Push the Payload", Description = "Stand near the cart to push it. Contest, capture, deliver.", Category = "Team", SecondaryCategory = "Movement", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 150, SupportsTeams = true, Maps = { "PayloadStreet" }, Movement = FREE }),
	def({ Id = "CaptureZone", DisplayName = "Zone Control", Description = "Hold zones to earn points. Zones rotate every 30 seconds.", Category = "Team", SecondaryCategory = "Social", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 120, SupportsTeams = true, Maps = { "Courtyard", "Warehouse" }, Movement = FREE }),
	def({ Id = "BuildTheBridge", DisplayName = "Build the Bridge", Description = "Carry planks, place them, cross the gap. Rival team can steal loose planks.", Category = "Team", SecondaryCategory = "Obby", MinimumPlayers = 4, MaximumPlayers = 24, Duration = 150, SupportsTeams = true, Maps = { "ChasmYard" }, Movement = FREE, AllowedModifiers = { "None", "HighSpeed" } }),
}

local ById: { [string]: Meta } = {}
for _, m in Catalog do
	assert(ById[m.Id] == nil, "Duplicate minigame id " .. m.Id)
	ById[m.Id] = m
end

return { List = Catalog, ById = ById }
