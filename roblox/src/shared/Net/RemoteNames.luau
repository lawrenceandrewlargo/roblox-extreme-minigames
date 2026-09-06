--!strict
-- Single source of remote names. Duplicate names are caught by static tests.
return {
	Events = {
		PhaseChanged = "PhaseChanged",
		VotingState = "VotingState",
		VoteCountsChanged = "VoteCountsChanged",
		MinigameIntro = "MinigameIntro",
		Countdown = "Countdown",
		Results = "Results",
		RewardsGranted = "RewardsGranted",
		Announcement = "Announcement",
		PlayerStateChanged = "PlayerStateChanged",
		HUDUpdate = "HUDUpdate",
		MovementRules = "MovementRules",
		SpectateTarget = "SpectateTarget",
		AdminPanelState = "AdminPanelState",
		MinigameEvent = "MinigameEvent",
	},
	Functions = {
		RequestSpectate = "RequestSpectate",
		AdminAction = "AdminAction",
		GetProfile = "GetProfile",
		EquipCosmetic = "EquipCosmetic",
		PurchaseCosmetic = "PurchaseCosmetic",
		UpdateSettings = "UpdateSettings",
		PartyAction = "PartyAction",
		MinigameAction = "MinigameAction",
	},
}
