--!strict
-- Balanced team assignment that keeps parties together when possible.
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)
local PartyService = require(Services.PartyService)

local Teams = {}

function Teams.Assign(ctx, names: { string }): { [string]: { Player } }
	local groups: { [string]: { Player } } = {}
	local order = {}
	for _, p in ctx.Players do
		local key = PartyService:PartyOf(p) or ("solo_" .. p.UserId)
		if not groups[key] then groups[key] = {}; table.insert(order, key) end
		table.insert(groups[key], p)
	end
	table.sort(order, function(a, b) return #groups[a] > #groups[b] end)
	local result: { [string]: { Player } } = {}
	for _, n in names do result[n] = {} end
	for _, key in order do
		local smallest = names[1]
		for _, n in names do if #result[n] < #result[smallest] then smallest = n end end
		for _, p in groups[key] do
			table.insert(result[smallest], p)
			PlayerStateService:SetTeam(p, smallest)
		end
	end
	ctx.Teams = result
	return result
end

function Teams.Of(ctx, p: Player): string? return PlayerStateService:Get(p).Team end

function Teams.FinishTeam(ctx, winningTeam: string)
	local winners, losers = {}, {}
	for _, p in ctx.AlivePlayers() do
		if PlayerStateService:Get(p).Team == winningTeam then table.insert(winners, p) else table.insert(losers, p) end
	end
	for _, p in winners do ctx.Finish(p, (ctx.Scores[p.UserId] or 0) + 100) end
	ctx.End("team_won:" .. winningTeam)
end

return Teams
