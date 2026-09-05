--!strict
-- Centralized window manager. Rules: every window has a visible close button, Escape/B closes the top window,
-- only one modal at a time, no invisible blockers, windows never trap the player.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")

local UIController = { _windows = {} :: { [string]: { Frame: Frame, Modal: boolean, OnClose: (() -> ())? } }, _stack = {} :: { string }, Screen = nil :: ScreenGui? }

local function theme(frame: Frame)
	frame.BackgroundColor3 = Color3.fromRGB(24, 26, 36)
	frame.BorderSizePixel = 0
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 14); corner.Parent = frame
	local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(90, 95, 130); stroke.Thickness = 1.5; stroke.Parent = frame
end

function UIController:Init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	local screen = Instance.new("ScreenGui"); screen.Name = "PartyUI"; screen.ResetOnSpawn = false; screen.IgnoreGuiInset = true; screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screen.Parent = pg
	self.Screen = screen
	ContextActionService:BindAction("CloseTopWindow", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		if #self._stack == 0 then return Enum.ContextActionResult.Pass end
		self:Close(self._stack[#self._stack])
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Escape, Enum.KeyCode.ButtonB)
end

function UIController:Label(parent: GuiObject, text: string, size: UDim2, pos: UDim2, textSize: number?): TextLabel
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Text = text; l.Size = size; l.Position = pos; l.TextColor3 = Color3.new(1, 1, 1); l.Font = Enum.Font.GothamBold; l.TextSize = textSize or 18; l.TextWrapped = true; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = parent
	return l
end

function UIController:Button(parent: GuiObject, text: string, size: UDim2, pos: UDim2, onClick: () -> (), danger: boolean?): TextButton
	local b = Instance.new("TextButton"); b.Text = text; b.Size = size; b.Position = pos; b.Font = Enum.Font.GothamBold; b.TextSize = 16; b.TextColor3 = Color3.new(1, 1, 1); b.AutoButtonColor = true; b.BorderSizePixel = 0
	b.BackgroundColor3 = danger and Color3.fromRGB(190, 60, 70) or Color3.fromRGB(70, 90, 200)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
	b.Selectable = true
	b.Activated:Connect(onClick)
	b.Parent = parent
	return b
end

function UIController:CreateWindow(id: string, title: string, size: UDim2, opts: { Modal: boolean?, OnClose: (() -> ())? }?): Frame
	assert(self._windows[id] == nil, "Window exists " .. id)
	local o = opts or {}
	local frame = Instance.new("Frame"); frame.Name = id; frame.Size = size; frame.AnchorPoint = Vector2.new(0.5, 0.5); frame.Position = UDim2.fromScale(0.5, 0.5); frame.Visible = false; frame.Active = true
	theme(frame)
	local header = self:Label(frame, title, UDim2.new(1, -110, 0, 40), UDim2.new(0, 16, 0, 6), 22)
	header.Name = "Title"
	self:Button(frame, "✕", UDim2.fromOffset(36, 32), UDim2.new(1, -46, 0, 8), function() self:Close(id) end, true).Name = "Close"
	self:Button(frame, "—", UDim2.fromOffset(36, 32), UDim2.new(1, -90, 0, 8), function() self:Minimize(id) end).Name = "Minimize"
	local body = Instance.new("Frame"); body.Name = "Body"; body.BackgroundTransparency = 1; body.Size = UDim2.new(1, -24, 1, -60); body.Position = UDim2.new(0, 12, 0, 50); body.Parent = frame
	frame.Parent = self.Screen
	self._windows[id] = { Frame = frame, Modal = o.Modal or false, OnClose = o.OnClose }
	return body
end

function UIController:Open(id: string)
	local w = assert(self._windows[id], "no window " .. id)
	if w.Modal then for _, other in self._stack do if self._windows[other].Modal then self:Close(other) end end end
	w.Frame.Visible = true
	w.Frame.Size = w.Frame:GetAttribute("FullSize") or w.Frame.Size
	local idx = table.find(self._stack, id) if idx then table.remove(self._stack, idx) end
	table.insert(self._stack, id)
	w.Frame.ZIndex = #self._stack
	local firstButton = w.Frame:FindFirstChildWhichIsA("TextButton", true)
	if UserInputService.GamepadEnabled and firstButton then GuiService.SelectedObject = firstButton end
end

function UIController:Close(id: string)
	local w = self._windows[id]
	if not w or not w.Frame.Visible then return end
	w.Frame.Visible = false
	local idx = table.find(self._stack, id) if idx then table.remove(self._stack, idx) end
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(w.Frame) then GuiService.SelectedObject = nil end
	if w.OnClose then task.spawn(w.OnClose) end
end

function UIController:Minimize(id: string)
	local w = self._windows[id]
	if not w then return end
	if not w.Frame:GetAttribute("FullSize") then w.Frame:SetAttribute("FullSize", w.Frame.Size) end
	local minimized = w.Frame.Size.Y.Offset <= 48
	w.Frame.Size = minimized and (w.Frame:GetAttribute("FullSize") :: UDim2) or UDim2.new(w.Frame.Size.X.Scale, w.Frame.Size.X.Offset, 0, 48)
	local body = w.Frame:FindFirstChild("Body") if body then (body :: Frame).Visible = minimized end
end

function UIController:Toggle(id: string) local w = self._windows[id] if w and w.Frame.Visible then self:Close(id) else self:Open(id) end end
function UIController:IsOpen(id: string): boolean local w = self._windows[id] return w ~= nil and w.Frame.Visible end
function UIController:CloseAll() for _, id in table.clone(self._stack) do self:Close(id) end end

-- Confirmation dialog for dangerous actions. Returns via callback; never blocks input permanently.
function UIController:Confirm(text: string, onYes: () -> ())
	if not self._windows.Confirm then
		local body = self:CreateWindow("Confirm", "Are you sure?", UDim2.fromOffset(380, 180), { Modal = true })
		self:Label(body, "", UDim2.new(1, 0, 0, 60), UDim2.new(0, 0, 0, 0)).Name = "Text"
		self:Button(body, "Cancel", UDim2.fromOffset(120, 40), UDim2.new(0, 0, 1, -44), function() self:Close("Confirm") end)
		self:Button(body, "Confirm", UDim2.fromOffset(120, 40), UDim2.new(1, -120, 1, -44), function() local cb = self._confirmCb; self:Close("Confirm"); if cb then cb() end end, true).Name = "Yes"
	end
	local body = self._windows.Confirm.Frame:FindFirstChild("Body") :: Frame
	;(body:FindFirstChild("Text") :: TextLabel).Text = text
	self._confirmCb = onYes
	self:Open("Confirm")
end

return UIController
