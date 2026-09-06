--!strict
-- Structured logging with level filtering and ring buffer for admin inspection.
local Log = {}
local LEVELS = { Debug = 1, Info = 2, Warn = 3, Error = 4 }
Log.MinLevel = LEVELS.Info
Log.Buffer = {} :: { { level: string, system: string, message: string, data: any?, t: number } }
Log.BufferSize = 300

local function write(level: string, system: string, message: string, data: any?)
	if LEVELS[level] < Log.MinLevel then return end
	local entry = { level = level, system = system, message = message, data = data, t = os.time() }
	table.insert(Log.Buffer, entry)
	if #Log.Buffer > Log.BufferSize then table.remove(Log.Buffer, 1) end
	local line = string.format("[%s][%s] %s", level, system, message)
	if level == "Error" then error(line, 0) elseif level == "Warn" then warn(line) else print(line) end
end

function Log.Debug(system: string, message: string, data: any?) write("Debug", system, message, data) end
function Log.Info(system: string, message: string, data: any?) write("Info", system, message, data) end
function Log.Warn(system: string, message: string, data: any?) write("Warn", system, message, data) end
function Log.Error(system: string, message: string, data: any?) pcall(write, "Error", system, message, data) end
function Log.Recent(count: number) local out = {} for i = math.max(1, #Log.Buffer - count + 1), #Log.Buffer do table.insert(out, Log.Buffer[i]) end return out end

return Log
