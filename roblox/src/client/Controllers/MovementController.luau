--!strict
-- Client-side movement feel (sprint/slide/dash) gated by server-sent MovementRules; plus owner-only fly/noclip/infinite jump
-- which the server enables via AdminPanelState (and anti-cheat exempts). Server still validates outcomes.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Net = require(script.Parent.Net)

local M = { CurrentGame = nil :: string?, Rules = { Sprint = false, Slide = false, Dash = false, Jump = true }, Admin = { Fly = false, Noclip = false, InfiniteJump = false }, FlySpeed = 60, _sprinting = false, _lastDash = 0, _baseSpeed = 16 }

local function hum(): Humanoid? local c = Players.LocalPlayer.Character return c and c:FindFirstChildOfClass("Humanoid") end
local function root(): BasePart? local c = Players.LocalPlayer.Character return c and c:FindFirstChild("HumanoidRootPart") :: BasePart? end

function M:Init()
	ContextActionService:BindAction("Sprint", function(_, state)
		if not self.Rules.Sprint then return Enum.ContextActionResult.Pass end
		self._sprinting = state == Enum.UserInputState.Begin
		local h = hum() if h then h.WalkSpeed = self._sprinting and self._baseSpeed * GameConfig.Movement.SprintMultiplier or self._baseSpeed end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("Sprint", "Sprint")
	ContextActionService:BindAction("SlideDash", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		local r, h = root(), hum()
		if not r or not h then return Enum.ContextActionResult.Pass end
		if self.Rules.Dash and os.clock() - self._lastDash > GameConfig.Movement.DashCooldownSeconds then
			self._lastDash = os.clock(); r:ApplyImpulse(r.CFrame.LookVector * GameConfig.Movement.DashImpulse * r.AssemblyMass)
		elseif self.Rules.Slide and h.MoveDirection.Magnitude > 0 and h.FloorMaterial ~= Enum.Material.Air then
			local original = h.WalkSpeed
			h.WalkSpeed = GameConfig.Movement.SlideSpeed
			task.delay(GameConfig.Movement.SlideDurationSeconds, function() if h.Parent then h.WalkSpeed = self._sprinting and self._baseSpeed * GameConfig.Movement.SprintMultiplier or self._baseSpeed end end)
		end
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.C, Enum.KeyCode.ButtonB)
	ContextActionService:SetTitle("SlideDash", "Slide")
	UserInputService.JumpRequest:Connect(function() if self.Admin.InfiniteJump then local h = hum() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)
end

function M:_flyStep(dt: number)
	local r, h = root(), hum()
	if not r or not h then return end
	if self.Admin.Fly then
		local cam = workspace.CurrentCamera
		local dir = Vector3.zero
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis end
		if dir.Magnitude == 0 and h.MoveDirection.Magnitude > 0 then dir = h.MoveDirection end
		h.PlatformStand = true
		r.AssemblyLinearVelocity = dir.Magnitude > 0 and dir.Unit * self.FlySpeed or Vector3.zero
	end
	if self.Admin.Noclip then
		for _, part in Players.LocalPlayer.Character:GetDescendants() do if part:IsA("BasePart") then part.CanCollide = false end end
	end
end

function M:Start()
	Net:On("MovementRules", function(rules)
		self.Rules = rules
		self._baseSpeed = rules.WalkSpeed or GameConfig.Movement.DefaultWalkSpeed
		self._sprinting = false
	end)
	Net:On("AdminPanelState", function(state)
		if state.AdminMovement then
			for k, v in state.AdminMovement do self.Admin[k] = v end
			if state.AdminMovement.Fly == false then local h = hum() if h then h.PlatformStand = false end end
			if state.AdminMovement.Noclip == false then local c = Players.LocalPlayer.Character if c then for _, part in c:GetDescendants() do if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end end end end
		end
		if state.FlySpeed then self.FlySpeed = state.FlySpeed end
	end)
	RunService.RenderStepped:Connect(function(dt) if self.Admin.Fly or self.Admin.Noclip then self:_flyStep(dt) end end)
	-- Minigame-specific intents routed through the single MinigameEvent remote (server validates everything).
	-- One intent per input, chosen by the active minigame, so the per-remote rate limit is never approached.
	Net:On("MinigameIntro", function(info) self.CurrentGame = info.Id end)
	Net:On("PhaseChanged", function(phase) if phase == "Lobby" then self.CurrentGame = nil end end)
	local PRIMARY: { [string]: { intent: string, direction: boolean } } = {
		KnockbackArena = { intent = "Punch", direction = false }, TugOfWar = { intent = "Pull", direction = false }, BlendIn = { intent = "Accuse", direction = false },
		PropHunt = { intent = "Shoot", direction = true }, RagdollRace = { intent = "Fling", direction = true },
	}
	ContextActionService:BindAction("PrimaryAction", function(_, state)
		if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
		local spec = self.CurrentGame and PRIMARY[self.CurrentGame]
		if not spec then return Enum.ContextActionResult.Pass end
		if spec.direction then Net:Fire("MinigameEvent", spec.intent, workspace.CurrentCamera.CFrame.LookVector) else Net:Fire("MinigameEvent", spec.intent) end
		return Enum.ContextActionResult.Pass
	end, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2, Enum.KeyCode.F)
	ContextActionService:SetTitle("PrimaryAction", "Action")
	for i, key in { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three } do
		ContextActionService:BindAction("Choice" .. i, function(_, state)
			if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
			if self.CurrentGame == "HideAndSeek" then Net:Fire("MinigameEvent", "ChooseSize", ({ "Small", "Normal", "Large" })[i])
			elseif self.CurrentGame == "PropHunt" then Net:Fire("MinigameEvent", "SwapProp", i) end
			return Enum.ContextActionResult.Pass
		end, false, key)
	end
end

return M
