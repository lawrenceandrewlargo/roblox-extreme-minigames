--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Log = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utilities"):WaitForChild("Log"))
local Controllers = script.Parent:WaitForChild("Controllers")
local order = { "Net", "UIController", "HUDController", "VotingHUDController", "SpectatorController", "MovementController", "ProfileController", "AdminPanelController" }
local loaded = {}
for _, name in order do
	local ok, ctrl = pcall(require, Controllers:WaitForChild(name))
	if not ok then Log.Warn("ClientBoot", name .. " failed: " .. tostring(ctrl)) continue end
	loaded[name] = ctrl
	if ctrl.Init then local okI, e = pcall(ctrl.Init, ctrl) if not okI then Log.Warn("ClientBoot", name .. " Init failed: " .. tostring(e)) end end
end
for _, name in order do local c = loaded[name] if c and c.Start then task.spawn(c.Start, c) end end
