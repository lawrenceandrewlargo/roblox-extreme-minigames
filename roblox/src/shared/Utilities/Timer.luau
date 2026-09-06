--!strict
-- Server/client agnostic countdown timer with tick + completion signals.
local Signal = require(script.Parent.Signal)

local Timer = {}
Timer.__index = Timer

export type Timer = typeof(setmetatable({} :: {
	Duration: number, Remaining: number, Running: boolean,
	Tick: any, Completed: any, _thread: thread?, _clock: () -> number,
}, Timer))

function Timer.new(duration: number, clock: (() -> number)?): Timer
	local self = setmetatable({
		Duration = duration, Remaining = duration, Running = false,
		Tick = Signal.new(), Completed = Signal.new(), _thread = nil,
		_clock = clock or os.clock,
	}, Timer)
	return self :: any
end

function Timer:Start()
	if self.Running then return end
	self.Running = true
	local startedAt = self._clock()
	local startRemaining = self.Remaining
	self._thread = task.spawn(function()
		local lastWhole = math.ceil(self.Remaining)
		while self.Running do
			self.Remaining = math.max(0, startRemaining - (self._clock() - startedAt))
			local whole = math.ceil(self.Remaining)
			if whole ~= lastWhole then
				lastWhole = whole
				self.Tick:Fire(whole)
			end
			if self.Remaining <= 0 then
				self.Running = false
				self.Completed:Fire()
				break
			end
			task.wait(0.1)
		end
	end)
end

function Timer:AddTime(seconds: number)
	self.Remaining = math.max(0, self.Remaining + seconds)
	if self.Running then
		self:Stop()
		self:Start()
	end
end

function Timer:SetRemaining(seconds: number)
	self.Remaining = math.max(0, seconds)
	if self.Running then
		self:Stop()
		self:Start()
	end
end

function Timer:Stop()
	self.Running = false
	if self._thread then
		pcall(task.cancel, self._thread)
		self._thread = nil
	end
end

function Timer:Destroy()
	self:Stop()
	self.Tick:Destroy()
	self.Completed:Destroy()
end

return Timer
