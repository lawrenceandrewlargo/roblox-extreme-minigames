--!strict
-- Cleanup container. Every minigame, map, and temporary system owns one.
-- Tracks connections, instances, threads, tweens, sounds, and callbacks.
local Janitor = {}
Janitor.__index = Janitor

export type Janitor = typeof(setmetatable({} :: { _items: { any }, _destroyed: boolean }, Janitor))

local ActiveJanitors = 0

function Janitor.new(): Janitor
	ActiveJanitors += 1
	return setmetatable({ _items = {}, _destroyed = false }, Janitor) :: any
end

function Janitor.ActiveCount(): number
	return ActiveJanitors
end

function Janitor:Add<T>(item: T, method: string?): T
	assert(not self._destroyed, "Janitor already destroyed")
	table.insert(self._items, { item, method })
	return item
end

function Janitor:AddThread(thread: thread): thread
	return self:Add(thread, "cancel")
end

function Janitor:Count(): number
	return #self._items
end

local function cleanupItem(item: any, method: string?)
	local t = typeof(item)
	if method == "cancel" or t == "thread" then
		pcall(task.cancel, item)
	elseif t == "function" then
		item()
	elseif t == "RBXScriptConnection" then
		item:Disconnect()
	elseif t == "Instance" then
		item:Destroy()
	elseif t == "table" then
		local m = method or (item.Destroy and "Destroy") or (item.Disconnect and "Disconnect") or (item.Cancel and "Cancel")
		if m and item[m] then
			item[m](item)
		end
	end
end

function Janitor:Cleanup()
	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		local entry = items[i]
		local ok, err = pcall(cleanupItem, entry[1], entry[2])
		if not ok then
			warn("[Janitor] cleanup error:", err)
		end
	end
end

function Janitor:Destroy()
	if self._destroyed then return end
	self:Cleanup()
	self._destroyed = true
	ActiveJanitors -= 1
end

return Janitor
