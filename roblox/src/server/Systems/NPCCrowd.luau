--!strict
-- Wandering NPC crowd for deception games. NPCs walk between NPCNodes with a small set of behaviours
-- that players must imitate. Server drives movement via Humanoid:MoveTo (cheap, no per-frame work).
local Players = game:GetService("Players")
local Services = script.Parent.Parent.Services
local MapService = require(Services.MapService)

local NPCCrowd = {}
NPCCrowd.__index = NPCCrowd

local BEHAVIOURS = { "Wander", "Idle", "Panic" }

local function makeDummy(ctx, cf: CFrame): Model
	local model = Instance.new("Model"); model.Name = "NPC"
	local root = Instance.new("Part"); root.Name = "HumanoidRootPart"; root.Size = Vector3.new(2, 2, 1); root.Transparency = 1; root.CFrame = cf; root.Parent = model
	local torso = Instance.new("Part"); torso.Name = "Torso"; torso.Size = Vector3.new(2, 2, 1); torso.CFrame = cf; torso.Color = Color3.fromRGB(90, 130, 200); torso.Parent = model
	local head = Instance.new("Part"); head.Name = "Head"; head.Size = Vector3.new(1.2, 1.2, 1.2); head.CFrame = cf * CFrame.new(0, 1.6, 0); head.Color = Color3.fromRGB(240, 200, 160); head.Parent = model
	for _, p in { torso, head } do local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = p; w.Parent = root end
	local hum = Instance.new("Humanoid"); hum.WalkSpeed = 10; hum.Parent = model
	model.PrimaryPart = root
	model:SetAttribute("IsNPC", true)
	model.Parent = ctx.Map
	ctx.Janitor:Add(model)
	return model
end

function NPCCrowd.new(ctx, count: number)
	local nodes = MapService:Markers("NPCNodes")
	if #nodes == 0 then nodes = MapService:Markers("Spawns") end
	local self = setmetatable({ ctx = ctx, NPCs = {} :: { Model }, Nodes = nodes, Mode = "Wander" }, NPCCrowd)
	for i = 1, count do
		local n = nodes[ctx.Rng:NextInteger(1, math.max(1, #nodes))]
		local cf = n and (n.CFrame + Vector3.new(0, 3, 0)) or CFrame.new(i * 3, 5, 500)
		table.insert(self.NPCs, makeDummy(ctx, cf))
	end
	-- Player disguise: humans look like NPCs (server sets appearance attributes; client renders uniformly).
	for _, p in ctx.Players do
		if p.Character then p.Character:SetAttribute("Disguised", true) end
	end
	ctx.Janitor:Add(function()
		for _, p in Players:GetPlayers() do if p.Character then p.Character:SetAttribute("Disguised", nil) end end
	end)
	ctx.Janitor:AddThread(task.spawn(function() self:_loop() end))
	return self
end

function NPCCrowd:_loop()
	local ctx = self.ctx
	while true do
		for _, npc in self.NPCs do
			if not npc.Parent then continue end
			local hum = npc:FindFirstChildOfClass("Humanoid")
			if not hum then continue end
			if self.Mode == "Panic" then
				local threat = ctx.Threat and ctx.Threat.Character and ctx.Threat.Character:FindFirstChild("HumanoidRootPart")
				if threat and npc.PrimaryPart then
					local away = (npc.PrimaryPart.Position - (threat :: BasePart).Position)
					if away.Magnitude < 30 then hum.WalkSpeed = 16; hum:MoveTo(npc.PrimaryPart.Position + away.Unit * 20) else hum.WalkSpeed = 10 end
				end
			elseif ctx.Rng:NextNumber() < 0.3 then
				local behaviour = BEHAVIOURS[ctx.Rng:NextInteger(1, 2)]
				if behaviour == "Wander" and #self.Nodes > 0 then
					local n = self.Nodes[ctx.Rng:NextInteger(1, #self.Nodes)]
					hum:MoveTo(n.Position + Vector3.new(ctx.Rng:NextNumber(-3, 3), 0, ctx.Rng:NextNumber(-3, 3)))
				end
			end
		end
		task.wait(1.5)
	end
end

function NPCCrowd:SetMode(mode: string) self.Mode = mode end

function NPCCrowd:Remove(npc: Model)
	local idx = table.find(self.NPCs, npc)
	if idx then table.remove(self.NPCs, idx) end
	npc:Destroy()
end

return NPCCrowd
