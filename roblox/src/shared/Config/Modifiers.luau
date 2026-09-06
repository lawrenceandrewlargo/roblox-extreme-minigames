--!strict
-- Data-driven round modifiers. Modifiers are NOT minigames.
export type ModifierDef = {
	Id: string,
	DisplayName: string,
	Description: string,
	Weight: number,
	Incompatible: { string }?,
	Apply: { [string]: any },
}

local Modifiers: { ModifierDef } = {
	{ Id = "None", DisplayName = "Standard", Description = "No modifier.", Weight = 6, Apply = {} },
	{ Id = "TinyPlayers", DisplayName = "Tiny Players", Description = "Everyone is small.", Weight = 1, Incompatible = { "GiantPlayers" }, Apply = { BodyScale = 0.6 } },
	{ Id = "GiantPlayers", DisplayName = "Giant Players", Description = "Everyone is huge.", Weight = 1, Incompatible = { "TinyPlayers" }, Apply = { BodyScale = 1.5 } },
	{ Id = "LowGravity", DisplayName = "Low Gravity", Description = "Float like the moon.", Weight = 1, Apply = { Gravity = 60 } },
	{ Id = "HighSpeed", DisplayName = "High Speed", Description = "Everything is faster.", Weight = 1, Apply = { WalkSpeedMultiplier = 1.5 } },
	{ Id = "Darkness", DisplayName = "Darkness", Description = "Lights out.", Weight = 1, Incompatible = { "Fog" }, Apply = { Lighting = "Dark" } },
	{ Id = "Fog", DisplayName = "Fog", Description = "Limited visibility.", Weight = 1, Incompatible = { "Darkness" }, Apply = { Lighting = "Fog" } },
	{ Id = "Slippery", DisplayName = "Slippery Ground", Description = "Ice physics everywhere.", Weight = 1, Apply = { Friction = 0.05 } },
	{ Id = "DoubleBomb", DisplayName = "Double Bomb", Description = "Two bombs in play.", Weight = 1, Apply = { BombCount = 2 }, },
	{ Id = "NoJump", DisplayName = "No Jump", Description = "Jumping disabled.", Weight = 1, Apply = { JumpHeight = 0 } },
	{ Id = "BigKnockback", DisplayName = "Increased Knockback", Description = "Hits send you flying.", Weight = 1, Apply = { KnockbackMultiplier = 2 } },
	{ Id = "RandomTeleports", DisplayName = "Random Teleports", Description = "Periodic random teleports.", Weight = 1, Apply = { TeleportIntervalSeconds = 15 } },
}

return Modifiers
