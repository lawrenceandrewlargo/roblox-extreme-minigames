--!strict
-- SERVER ONLY. Never replicate this module. Edit UserIds here to grant access.
-- Roles: Owner > SuperAdmin > Admin > Moderator > Tester
local AdminConfig = {
	Users = {
		-- [UserId] = "Role"
		-- [123456789] = "Owner",
	} :: { [number]: string },

	-- Studio: the local test player is treated as Owner so the panel can be tested without publishing.
	StudioLocalPlayerIsOwner = true,

	RoleRank = { Tester = 1, Moderator = 2, Admin = 3, SuperAdmin = 4, Owner = 5 },

	-- Minimum role required per command category.
	CategoryRank = {
		Debug = 1, Testing = 1, Movement = 1, Teleport = 2, Player = 2, Moderation = 2,
		Announce = 2, Round = 3, Gameplay = 3, World = 3, Server = 4, Dangerous = 5,
	},

	DangerousRequiresConfirm = true,
	AuditBufferSize = 500,
}
return AdminConfig
