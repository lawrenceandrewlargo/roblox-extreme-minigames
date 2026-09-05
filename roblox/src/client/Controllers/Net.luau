--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Names = require(ReplicatedStorage.Shared.Net.RemoteNames)
local folder = ReplicatedStorage:WaitForChild("Remotes")
local Net = {}
function Net:On(name: string, fn: (...any) -> ()): RBXScriptConnection
	assert(Names.Events[name], "Unknown event " .. name)
	return (folder:WaitForChild(name) :: RemoteEvent).OnClientEvent:Connect(fn)
end
function Net:Fire(name: string, ...: any) (folder:WaitForChild(name) :: RemoteEvent):FireServer(...) end
function Net:Invoke(name: string, ...: any): any
	assert(Names.Functions[name], "Unknown function " .. name)
	local ok, res = pcall(function(...) return (folder:WaitForChild(name) :: RemoteFunction):InvokeServer(...) end, ...)
	if not ok then return { ok = false, error = tostring(res) } end
	return res
end
return Net
