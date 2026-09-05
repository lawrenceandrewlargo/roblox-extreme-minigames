--!strict
-- Owner/admin panel. Built dynamically from the server's command list (so permissions are always server-defined).
-- Tabs by category, search, target picker, argument fields, confirmation for dangerous actions, F9 toggle / long-press on mobile.
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UIController)

local A = { Commands = {}, Category = "Round", Target = nil :: number?, Args = {} :: { [string]: string } }

function A:Init()
	local body = UI:CreateWindow("Admin", "Admin Panel", UDim2.fromOffset(760, 520))
	self.Body = body
	self.Tabs = Instance.new("ScrollingFrame"); self.Tabs.Size = UDim2.new(0, 130, 1, 0); self.Tabs.BackgroundTransparency = 1; self.Tabs.AutomaticCanvasSize = Enum.AutomaticSize.Y; self.Tabs.CanvasSize = UDim2.new(); self.Tabs.ScrollBarThickness = 4; self.Tabs.Parent = body
	local tl = Instance.new("UIListLayout"); tl.Padding = UDim.new(0, 4); tl.Parent = self.Tabs
	self.Search = Instance.new("TextBox"); self.Search.PlaceholderText = "Search commands..."; self.Search.Size = UDim2.new(0, 300, 0, 32); self.Search.Position = UDim2.new(0, 140, 0, 0); self.Search.BackgroundColor3 = Color3.fromRGB(40, 44, 60); self.Search.TextColor3 = Color3.new(1, 1, 1); self.Search.Font = Enum.Font.Gotham; self.Search.TextSize = 15; self.Search.ClearTextOnFocus = false; self.Search.Parent = body
	self.Search:GetPropertyChangedSignal("Text"):Connect(function() self:Render() end)
	self.TargetBox = Instance.new("TextBox"); self.TargetBox.PlaceholderText = "Target player name (optional)"; self.TargetBox.Size = UDim2.new(0, 280, 0, 32); self.TargetBox.Position = UDim2.new(0, 450, 0, 0); self.TargetBox.BackgroundColor3 = Color3.fromRGB(40, 44, 60); self.TargetBox.TextColor3 = Color3.new(1, 1, 1); self.TargetBox.Font = Enum.Font.Gotham; self.TargetBox.TextSize = 15; self.TargetBox.ClearTextOnFocus = false; self.TargetBox.Parent = body
	self.List = Instance.new("ScrollingFrame"); self.List.Size = UDim2.new(1, -140, 1, -120); self.List.Position = UDim2.new(0, 140, 0, 40); self.List.BackgroundTransparency = 1; self.List.AutomaticCanvasSize = Enum.AutomaticSize.Y; self.List.CanvasSize = UDim2.new(); self.List.ScrollBarThickness = 6; self.List.Parent = body
	local ll = Instance.new("UIListLayout"); ll.Padding = UDim.new(0, 4); ll.Parent = self.List
	self.Output = UI:Label(body, "", UDim2.new(1, -140, 0, 72), UDim2.new(0, 140, 1, -74), 13); self.Output.Font = Enum.Font.Code; self.Output.TextYAlignment = Enum.TextYAlignment.Top; self.Output.BackgroundColor3 = Color3.fromRGB(15, 16, 22); self.Output.BackgroundTransparency = 0.2; self.Output.TextWrapped = true
	self.ArgBoxes = {}
	for i = 1, 3 do
		local b = Instance.new("TextBox"); b.PlaceholderText = "arg " .. i; b.Size = UDim2.new(0, 190, 0, 26); b.Position = UDim2.new(0, 140 + (i - 1) * 198, 1, -104); b.BackgroundColor3 = Color3.fromRGB(40, 44, 60); b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.Gotham; b.TextSize = 14; b.ClearTextOnFocus = false; b.Parent = body
		self.ArgBoxes[i] = b
	end
end

local function coerce(v: string): any
	if v == "" then return nil end
	if v == "true" then return true elseif v == "false" then return false end
	local n = tonumber(v) if n then return n end
	return v
end

function A:Run(cmd)
	local args = {}
	if self.TargetBox.Text ~= "" then args.target = self.TargetBox.Text end
	for i, name in cmd.Args do
		if name == "target" then continue end
		local box = self.ArgBoxes[i - (cmd.Args[1] == "target" and 1 or 0)]
		if box then args[name] = coerce(box.Text) end
	end
	local function send(confirmed: boolean)
		local res = Net:Invoke("AdminAction", { command = cmd.Name, args = args, confirmed = confirmed })
		local text = res and res.ok and (type(res.result) == "table" and HttpService:JSONEncode(res.result) or tostring(res.result)) or ("ERROR: " .. tostring(res and res.error))
		self.Output.Text = ("[%s] %s"):format(cmd.Name, text:sub(1, 900))
	end
	if cmd.Dangerous then UI:Confirm(("Run %s%s? This cannot be undone."):format(cmd.Name, args.target and (" on " .. args.target) or ""), function() send(true) end) else send(false) end
end

function A:Render()
	for _, c in self.List:GetChildren() do if c:IsA("TextButton") then c:Destroy() end end
	for _, c in self.Tabs:GetChildren() do if c:IsA("TextButton") then c:Destroy() end end
	local cats, seen = {}, {}
	for _, cmd in self.Commands do if not seen[cmd.Category] then seen[cmd.Category] = true; table.insert(cats, cmd.Category) end end
	table.sort(cats)
	for _, cat in cats do
		local b = UI:Button(self.Tabs, cat, UDim2.new(1, -6, 0, 32), UDim2.new(), function() self.Category = cat; self:Render() end)
		if cat == self.Category then b.BackgroundColor3 = Color3.fromRGB(120, 90, 220) end
	end
	local q = self.Search.Text:lower()
	for _, cmd in self.Commands do
		if (q == "" and cmd.Category ~= self.Category) or (q ~= "" and not (cmd.Name:lower():find(q, 1, true) or cmd.Description:lower():find(q, 1, true))) then continue end
		local label = ("%s%s  —  %s%s"):format(cmd.Dangerous and "⚠ " or "", cmd.Name, cmd.Description, #cmd.Args > 0 and ("   (" .. table.concat(cmd.Args, ", ") .. ")") or "")
		UI:Button(self.List, label, UDim2.new(1, -8, 0, 36), UDim2.new(), function() self:Run(cmd) end, cmd.Dangerous).TextXAlignment = Enum.TextXAlignment.Left
	end
end

function A:Start()
	Net:On("AdminPanelState", function(state)
		if state.Commands then
			self.Commands = state.Commands
			self:Render()
			ContextActionService:BindAction("ToggleAdmin", function(_, s) if s == Enum.UserInputState.Begin then UI:Toggle("Admin") end return Enum.ContextActionResult.Sink end, true, Enum.KeyCode.F9, Enum.KeyCode.DPadUp)
			ContextActionService:SetTitle("ToggleAdmin", "Admin")
			ContextActionService:SetPosition("ToggleAdmin", UDim2.new(0.72, 0, 0.1, 0))
		end
	end)
end

return A
