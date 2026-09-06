--!strict
-- Lightweight, allocation-conscious signal implementation.
local Signal = {}
Signal.__index = Signal

export type Connection = { Disconnect: (self: Connection) -> (), Connected: boolean }
export type Signal<T...> = typeof(setmetatable({} :: { _handlers: { (T...) -> () } }, Signal))

function Signal.new<T...>(): Signal<T...>
	return setmetatable({ _handlers = {} }, Signal) :: any
end

function Signal:Connect(fn: (...any) -> ()): Connection
	local handlers = self._handlers
	table.insert(handlers, fn)
	local conn = { Connected = true }
	function conn.Disconnect(c)
		if not c.Connected then return end
		c.Connected = false
		local idx = table.find(handlers, fn)
		if idx then table.remove(handlers, idx) end
	end
	return conn :: any
end

function Signal:Once(fn: (...any) -> ()): Connection
	local conn
	conn = self:Connect(function(...)
		conn:Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Fire(...: any)
	local snapshot = table.clone(self._handlers)
	for _, fn in snapshot do
		task.spawn(fn, ...)
	end
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	self:Once(function(...) task.spawn(thread, ...) end)
	return coroutine.yield()
end

function Signal:HandlerCount(): number
	return #self._handlers
end

function Signal:Destroy()
	table.clear(self._handlers)
end

return Signal
