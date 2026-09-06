--!strict
-- Server-spawned karts (VehicleSeat based, physics owned by the seated player for responsiveness).
-- Drift boost + ramp boost are validated server-side by tracking speed envelopes.
local Arena = require(script.Parent.Arena)

local Karts = {}

function Karts.Spawn(ctx, p: Player, cf: CFrame, opts: { MaxSpeed: number, Torque: number }?): Model?
	local o = opts or { MaxSpeed = 70, Torque = 12000 }
	local model = Instance.new("Model")
	model.Name = "Kart_" .. p.UserId
	local body = Instance.new("Part"); body.Name = "Body"; body.Size = Vector3.new(6, 1.5, 9); body.CFrame = cf; body.Color = Color3.fromHSV(ctx.Rng:NextNumber(), 0.7, 1); body.Parent = model
	local seat = Instance.new("VehicleSeat"); seat.Name = "Seat"; seat.Size = Vector3.new(2, 1, 2); seat.CFrame = cf * CFrame.new(0, 1.25, 0); seat.MaxSpeed = o.MaxSpeed; seat.Torque = o.Torque; seat.TurnSpeed = 1.5; seat.HeadsUpDisplay = false; seat.Parent = model
	local weld = Instance.new("WeldConstraint"); weld.Part0 = body; weld.Part1 = seat; weld.Parent = body
	for i, off in { Vector3.new(-3, -0.75, -3), Vector3.new(3, -0.75, -3), Vector3.new(-3, -0.75, 3), Vector3.new(3, -0.75, 3) } do
		local wheel = Instance.new("Part"); wheel.Name = "Wheel" .. i; wheel.Shape = Enum.PartType.Cylinder; wheel.Size = Vector3.new(1, 2.5, 2.5); wheel.CFrame = cf * CFrame.new(off) * CFrame.Angles(0, 0, math.rad(90)); wheel.Parent = model
		local att0 = Instance.new("Attachment"); att0.CFrame = CFrame.new(off) * CFrame.Angles(0, 0, math.rad(90)); att0.Parent = body
		local att1 = Instance.new("Attachment"); att1.Parent = wheel
		local hinge = Instance.new("HingeConstraint"); hinge.Attachment0 = att0; hinge.Attachment1 = att1; hinge.ActuatorType = Enum.ActuatorType.Motor
		hinge.MotorMaxTorque = o.Torque; hinge.Parent = body
		wheel:SetAttribute("Powered", i >= 3)
		wheel:SetAttribute("Steer", i <= 2)
	end
	model.PrimaryPart = body
	model.Parent = ctx.Map
	ctx.Janitor:Add(model)
	body:SetNetworkOwner(p)
	-- Simple drive loop: seat.Throttle/Steer -> hinges. Runs on the server at 20Hz which is fine for arcade karts.
	ctx.Janitor:AddThread(task.spawn(function()
		while model.Parent do
			local throttle, steer = seat.Throttle, seat.Steer
			local boost = model:GetAttribute("Boost") or 1
			for _, h in body:GetChildren() do
				if h:IsA("HingeConstraint") and h.Attachment1 then
					local wheel = h.Attachment1.Parent
					if wheel and wheel:GetAttribute("Powered") then h.AngularVelocity = -throttle * 30 * boost end
					if wheel and wheel:GetAttribute("Steer") then h.Attachment0.CFrame = CFrame.new(h.Attachment0.Position) * CFrame.Angles(0, -steer * math.rad(25), 0) * CFrame.Angles(0, 0, math.rad(90)) end
				end
			end
			task.wait(0.05)
		end
	end))
	local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if hum then task.defer(function() seat:Sit(hum) end) end
	return model
end

function Karts.SpawnAll(ctx, markers: { BasePart })
	ctx.Karts = {}
	for i, p in ctx.Players do
		local m = markers[(i - 1) % math.max(1, #markers) + 1]
		local cf = m and (m.CFrame + Vector3.new(0, 4, 0)) or CFrame.new(i * 8, 10, 500)
		Arena.Teleport(p, cf + Vector3.new(0, 3, 0))
		ctx.Karts[p.UserId] = Karts.Spawn(ctx, p, cf)
	end
end

function Karts.Of(ctx, p: Player): Model? return ctx.Karts and ctx.Karts[p.UserId] end

-- Boost pads / ramps listed in map "Objectives" folder with attribute Boost=true.
function Karts.ApplyBoostPads(ctx, MapService)
	for _, pad in MapService:Markers("Objectives") do
		if pad:GetAttribute("Boost") then
			ctx.Janitor:Add(pad.Touched:Connect(function(hit)
				local model = hit:FindFirstAncestorOfClass("Model")
				if model and model.Name:sub(1, 5) == "Kart_" and not model:GetAttribute("Boosting") then
					model:SetAttribute("Boosting", true); model:SetAttribute("Boost", 1.8)
					task.delay(2, function() if model.Parent then model:SetAttribute("Boost", 1); model:SetAttribute("Boosting", nil) end end)
				end
			end))
		end
	end
end

return Karts
