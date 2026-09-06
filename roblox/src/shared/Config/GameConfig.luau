--!strict
-- Central gameplay configuration. No magic numbers elsewhere.
local GameConfig = {
	MaxPlayers = 24,
	MinPlayersToStart = 2,

	Lobby = {
		IntermissionSeconds = 12,
		VotingSeconds = 20,
		ResultsSeconds = 8,
		RewardsSeconds = 4,
		IntroSeconds = 5,
		CountdownSeconds = 3,
		MapLoadTimeoutSeconds = 10,
	},

	Voting = {
		CandidateCount = 3,
		DefaultCooldownRounds = 4,
		UnderplayedBonus = 0.75,
		OverplayedPenalty = 0.45,
		OverplayedThresholdMultiplier = 1.5,
		MysteryPlatformChance = 0.15,
		-- Rule: leaving all platforms removes the player's vote.
		LeavingPlatformClearsVote = true,
		PlatformDebounceSeconds = 0.2,
	},

	Movement = {
		DefaultWalkSpeed = 16,
		DefaultJumpPower = 50,
		DefaultJumpHeight = 7.2,
		SprintMultiplier = 1.45,
		SlideSpeed = 34,
		SlideDurationSeconds = 0.7,
		DashImpulse = 60,
		DashCooldownSeconds = 2,
	},

	BodySize = {
		Small = { Scale = 0.55, WalkSpeed = 12, JumpHeight = 6 },
		Normal = { Scale = 1.0, WalkSpeed = 16, JumpHeight = 7.2 },
		Large = { Scale = 1.6, WalkSpeed = 20, JumpHeight = 9.5 },
	},

	Rewards = {
		ParticipationXP = 25,
		ParticipationCoins = 10,
		WinXP = 120,
		WinCoins = 60,
		PlacementXP = { 100, 70, 50 },
		PlacementCoins = { 50, 30, 20 },
		CrownForWin = 1,
		XPPerLevelBase = 250,
		XPPerLevelGrowth = 1.12,
	},

	AntiCheat = {
		MaxHorizontalSpeedTolerance = 1.35,
		TeleportDistanceThreshold = 80,
		RemoteRateLimitPerSecond = 12,
		MaxCheckpointSkip = 1,
		BombTransferMaxDistance = 12,
	},

	Data = {
		StoreName = "PlayerProfile_v1",
		SchemaVersion = 3,
		SaveIntervalSeconds = 120,
		MaxRetries = 5,
	},
}

return GameConfig
