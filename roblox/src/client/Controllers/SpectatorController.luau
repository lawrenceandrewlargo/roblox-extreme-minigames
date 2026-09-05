--!strict
-- Camera follows the server-approved target. Buttons/keys cycle targets via server validation (no hidden info leaks).
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local Net = require(script.Parent.Net)
local UI = require(script.Parent.UIController)

local S = { Target = nil :: number? }

function S:Init()
	local screen = UI.Screen :: ScreenGui
	self.Bar = Instance.new("Frame"); self.Bar.Size = UDim2.new(0, 360, 0, 50); self.Bar.Position = UDim2.new(0.5, -180, 1, -70); self.Bar.BackgroundColor3 = Color3.fromRGB(24, 26, 36); self.Bar.BackgroundTransparency = 0.2; self.Bar.Visible = false; self.Bar.Parent = screen
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = self.Bar
	UI:Button(self.Bar, "◀", UDim2.fromOffset(44, 36), UDim2.new(0, 8, 0, 7), function() self:Cycle("prev") end)
	UI:Button(self.Bar, "▶", UDim2.fromOffset(44, 36), UDim2.new(1, -52, 0, 7), function() self:Cycle("next") end)
	self.Name = UI:Label(self.Bar, "Spectating", UDim2.new(1, -120, 1, 0), UDim2.new(0, 60, 0, 0), 16); self.Name.TextXAlignment = Enum.TextXAlignment.Center
end

function S:Cycle(dir: string) Net:Invoke("RequestSpectate", dir) end

function S:Apply()
	local cam = workspace.CurrentCamera
	local target = self.Target and Players:GetPlayerByUserId(self.Target)
	local hum = target and target.Character and target.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum; self.Name.Text = "Spectating " .. target.DisplayName; self.Bar.Visible = true
	else
		local me = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if me then cam.CameraSubject = me end
		self.Bar.Visible = false
	end
end

function S:Start()
	Net:On("SpectateTarget", function(userId: number?) self.Target = userId; self:Apply() end)
	Net:On("PhaseChanged", function(phase) if phase == "Lobby" or phase == "Intermission" then self.Target = nil; self:Apply() end end)
	ContextActionService:BindAction("SpectateCycle", function(_, state, input)
		if state ~= Enum.UserInputState.Begin or not self.Bar.Visible then return Enum.ContextActionResult.Pass end
		self:Cycle((input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonL1) and "prev" or "next")
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Q, Enum.KeyCode.E, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
	Players.LocalPlayer.CharacterAdded:Connect(function() task.wait(0.3); self:Apply() end)
end

return S
