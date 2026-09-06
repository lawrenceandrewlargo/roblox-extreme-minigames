--!strict
-- Pure, deterministic candidate generation + vote tally.
-- Mirrored 1:1 in the web command center (src/lib/sim/candidateSelector.ts) for large-scale simulation.
local Types = require(script.Parent.Types)
local GameConfig = require(script.Parent.Config.GameConfig)
local TableUtil = require(script.Parent.Utilities.TableUtil)

type Meta = Types.MinigameMeta
type History = { Types.HistoryEntry }

local CandidateSelector = {}

export type Stats = { plays: { [string]: number }, lastRound: { [string]: number } }

function CandidateSelector.BuildStats(history: History): Stats
	local plays, lastRound = {}, {}
	for _, h in history do
		plays[h.GameId] = (plays[h.GameId] or 0) + 1
		lastRound[h.GameId] = h.Round
	end
	return { plays = plays, lastRound = lastRound }
end

local function roundsSince(stats: Stats, id: string, currentRound: number): number
	local last = stats.lastRound[id]
	if last == nil then return math.huge end
	return currentRound - last
end

local function cooldownOf(meta: Meta): number
	return meta.VoteCooldownRounds or GameConfig.Voting.DefaultCooldownRounds
end

-- Deterministic order for tie-breaking: least recently played, lowest frequency, then id.
function CandidateSelector.CompareTieBreak(stats: Stats, currentRound: number): (Meta, Meta) -> boolean
	return function(a, b)
		local ra, rb = roundsSince(stats, a.Id, currentRound), roundsSince(stats, b.Id, currentRound)
		if ra ~= rb then return ra > rb end
		local pa, pb = stats.plays[a.Id] or 0, stats.plays[b.Id] or 0
		if pa ~= pb then return pa < pb end
		return a.Id < b.Id
	end
end

function CandidateSelector.Weight(meta: Meta, stats: Stats, currentRound: number, avgPlays: number): number
	local cfg = GameConfig.Voting
	local plays = stats.plays[meta.Id] or 0
	local w = 1.0
	if plays < avgPlays then w *= (1 + cfg.UnderplayedBonus) end
	if avgPlays > 0 and plays > avgPlays * cfg.OverplayedThresholdMultiplier then w *= cfg.OverplayedPenalty end
	local since = roundsSince(stats, meta.Id, currentRound)
	local cd = cooldownOf(meta)
	if since ~= math.huge then
		w *= math.clamp(since / (cd * 2), 0.25, 1)
	end
	return w
end

--[[
	Select `count` candidates.
	Guarantees: player-count compatible, honours cooldown when enough games are eligible,
	never repeats the immediately previous game when any alternative exists,
	prefers primary-category diversity.
]]
function CandidateSelector.Select(library: { Meta }, history: History, playerCount: number, currentRound: number, rng: Random, count: number?): { Meta }
	local wanted = count or GameConfig.Voting.CandidateCount
	local stats = CandidateSelector.BuildStats(history)
	local previous = history[#history] and history[#history].GameId or nil

	local compatible = TableUtil.Filter(library, function(m: Meta)
		return playerCount >= m.MinimumPlayers and playerCount <= m.MaximumPlayers
	end)
	if #compatible == 0 then
		compatible = TableUtil.Filter(library, function(m: Meta) return playerCount >= m.MinimumPlayers end)
	end
	if #compatible == 0 then return {} end

	-- Progressive cooldown relaxation: strict -> half -> none (never previous game unless forced).
	local eligible: { Meta } = {}
	for _, relax in { 1, 0.5, 0 } do
		eligible = TableUtil.Filter(compatible, function(m: Meta)
			if m.Id == previous then return false end
			return roundsSince(stats, m.Id, currentRound) >= cooldownOf(m) * relax
		end)
		if #eligible >= wanted then break end
	end
	if #eligible == 0 then eligible = compatible end

	local total = 0
	for _, m in eligible do total += (stats.plays[m.Id] or 0) end
	local avgPlays = total / math.max(1, #eligible)

	local pool = table.clone(eligible)
	local chosen: { Meta } = {}
	local usedCategories: { [string]: boolean } = {}

	while #chosen < wanted and #pool > 0 do
		local weights = {}
		for i, m in pool do
			local w = CandidateSelector.Weight(m, stats, currentRound, avgPlays)
			if usedCategories[m.Category] then w *= 0.15 end
			weights[i] = w
		end
		local pick, idx = TableUtil.WeightedPick(pool, weights, rng)
		if not pick or not idx then break end
		table.insert(chosen, pick)
		usedCategories[pick.Category] = true
		table.remove(pool, idx)
	end

	return chosen
end

-- votes: { [userId] = candidateIndex }. Returns winning index.
function CandidateSelector.Tally(candidates: { Meta }, votes: { [number]: number }, history: History, currentRound: number, rng: Random): (number, { number })
	local counts = table.create(#candidates, 0)
	for _, idx in votes do
		if candidates[idx] then counts[idx] += 1 end
	end
	local best = -1
	local tied: { number } = {}
	for i, c in counts do
		if c > best then best = c; tied = { i } elseif c == best then table.insert(tied, i) end
	end
	if #tied == 1 then return tied[1], counts end
	local stats = CandidateSelector.BuildStats(history)
	local cmp = CandidateSelector.CompareTieBreak(stats, currentRound)
	-- If a zero-vote round or exact tie, tie-break deterministically, with rng only for identical stats.
	table.sort(tied, function(a, b)
		local ma, mb = candidates[a], candidates[b]
		if cmp(ma, mb) then return true end
		if cmp(mb, ma) then return false end
		return rng:NextNumber() < 0.5
	end)
	return tied[1], counts
end

function CandidateSelector.PickMap(meta: Meta, history: History, rng: Random): string
	if #meta.Maps == 0 then return "Default" end
	local lastMaps: { [string]: number } = {}
	for i, h in history do
		if h.GameId == meta.Id and h.MapId then lastMaps[h.MapId] = i end
	end
	local candidates = table.clone(meta.Maps)
	table.sort(candidates, function(a, b)
		local la, lb = lastMaps[a] or 0, lastMaps[b] or 0
		if la ~= lb then return la < lb end
		return a < b
	end)
	-- Least recently used map, with a small chance of random for variety.
	if rng:NextNumber() < 0.2 and #candidates > 1 then
		return candidates[rng:NextInteger(1, #candidates)]
	end
	return candidates[1]
end

function CandidateSelector.PickModifier(meta: Meta, modifiers: { any }, history: History, rng: Random): string
	local allowed: { [string]: boolean } = {}
	for _, id in meta.AllowedModifiers do allowed[id] = true end
	local recent: { [string]: boolean } = {}
	for i = math.max(1, #history - 2), #history do
		if history[i] and history[i].ModifierId then recent[history[i].ModifierId :: string] = true end
	end
	local items, weights = {}, {}
	for _, m in modifiers do
		if allowed[m.Id] and (m.Id == "None" or not recent[m.Id]) then
			table.insert(items, m.Id)
			table.insert(weights, m.Weight)
		end
	end
	local pick = TableUtil.WeightedPick(items, weights, rng)
	return pick or "None"
end

return CandidateSelector
