--!strict
export type Category = "Tag" | "Bomb" | "HideSeek" | "PropHunt" | "Deception" | "Obby" | "Speedrun" | "Racing" | "Kart"
	| "Survival" | "Disaster" | "Physics" | "Reaction" | "Memory" | "Team" | "Social" | "Elimination" | "Movement" | "Platform" | "Chaos"

export type MovementRules = {
	Sprint: boolean,
	Slide: boolean,
	Dash: boolean,
	Jump: boolean,
	WalkSpeed: number?,
	JumpHeight: number?,
}

export type MinigameMeta = {
	Id: string,
	DisplayName: string,
	Description: string,
	Category: Category,
	SecondaryCategory: Category?,
	MinimumPlayers: number,
	MaximumPlayers: number,
	Duration: number,
	VoteCooldownRounds: number,
	SupportsTeams: boolean,
	AllowsSpectating: boolean,
	HidesInformation: boolean, -- spectators must not leak
	Maps: { string },
	AllowedModifiers: { string },
	Movement: MovementRules,
	Icon: string,
}

export type PlayerState = "Lobby" | "Voting" | "Playing" | "Eliminated" | "Spectating" | "Finished"

export type RoundPhase = "Lobby" | "Intermission" | "Voting" | "MapSelection" | "Intro" | "Countdown" | "Gameplay" | "Results" | "Rewards"

export type ResultEntry = { UserId: number, Placement: number, Score: number, Won: boolean }

export type MinigameResult = {
	Entries: { ResultEntry },
	WinnerUserIds: { number },
	Reason: string,
}

export type HistoryEntry = { GameId: string, Round: number, MapId: string?, ModifierId: string? }

return {}
