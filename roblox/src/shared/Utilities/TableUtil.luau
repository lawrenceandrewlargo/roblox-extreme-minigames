--!strict
local TableUtil = {}

function TableUtil.Shuffle<T>(t: { T }, rng: Random): { T }
	local out = table.clone(t)
	for i = #out, 2, -1 do
		local j = rng:NextInteger(1, i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

function TableUtil.Filter<T>(t: { T }, pred: (T) -> boolean): { T }
	local out = {}
	for _, v in t do if pred(v) then table.insert(out, v) end end
	return out
end

function TableUtil.Map<T, U>(t: { T }, fn: (T) -> U): { U }
	local out = {}
	for i, v in t do out[i] = fn(v) end
	return out
end

function TableUtil.Keys<K, V>(t: { [K]: V }): { K }
	local out = {}
	for k in t do table.insert(out, k) end
	return out
end

function TableUtil.Count(t: { [any]: any }): number
	local n = 0
	for _ in t do n += 1 end
	return n
end

function TableUtil.WeightedPick<T>(items: { T }, weights: { number }, rng: Random): (T?, number?)
	local total = 0
	for _, w in weights do total += w end
	if total <= 0 then return nil, nil end
	local r = rng:NextNumber() * total
	for i, w in weights do
		r -= w
		if r <= 0 then return items[i], i end
	end
	return items[#items], #items
end

function TableUtil.DeepCopy<T>(t: T): T
	if typeof(t) ~= "table" then return t end
	local out = {}
	for k, v in t :: any do out[k] = TableUtil.DeepCopy(v) end
	return out :: any
end

return TableUtil
