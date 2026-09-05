--!strict
--[[
	Minigame module contract (all functions optional except Id + Start):
	Id: string                         -- must exist in Shared/MinigameCatalog
	Initialize(ctx)                    -- allocate state on ctx (never module-level state!)
	CanStart(ctx) -> boolean
	LoadMap(ctx)                       -- map already loaded into ctx.Map; build procedural extras here
	PreparePlayers(ctx)                -- spawn / assign roles / teams
	Start(ctx)                         -- gameplay begins
	Update(ctx, dt)                    -- ~10Hz server tick
	Finish(ctx) -> MinigameResult?     -- return nil to use default ranking (finish order > survivors by score > eliminated reverse)
	Cleanup(ctx)                       -- extra cleanup; ctx.Janitor is destroyed automatically afterwards
	OnPlayerLeft(ctx, player), OnPlayerDied(ctx, player)
	AdminHook(ctx, action, args)       -- GiveBomb / Tag / Reveal / Hazard / Checkpoint
	EndsWhenOneRemains: boolean (default true), EndsWhenAllFinished: boolean (default false)

	Rules:
	- All temporary Instances -> ctx.Janitor:Add(instance) (Arena.Part does this for you)
	- All threads -> ctx.Janitor:AddThread(task.spawn/delay(...))
	- All connections -> ctx.Janitor:Add(conn)
	- Player changes go through PlayerStateService (restored automatically)
]]
return {}
