--!strict
-- Props pick from map "Props" folder templates (3 swaps max). Hunters have 8 shots; hitting a non-prop costs 10 HP.
-- Anti-camp: a prop that hasn't moved 6 studs in 25s emits a chirp (broadcast to hunters). Props auto-taunt every 40s.
local Systems = script.Parent.Parent.Systems
local Arena = require(Systems.Arena)
local Services = script.Parent.Parent.Services
local PlayerStateService = require(Services.PlayerStateService)
local MapService = require(Services.MapService)
local Remotes = require(Services.Remotes)
local AntiCheatService = require(Services.AntiCheatService)
local TableUtil = require(game:GetService("ReplicatedStorage").Shared.Utilities.TableUtil)

local M = { Id = "PropHunt", EndsWhenOneRemains = false }

local PROP_SHAPES = { { "Crate", Vector3.new(4, 4, 4) }, { "Barrel", Vector3.new(3, 4, 3) }, { "Chair", Vector3.new(2, 3, 2) }, { "Lamp", Vector3.new(1, 6, 1) }, { "Plant", Vector3.new(2.5, 3.5, 2.5) } }

local function becomeProp(ctx, p: Player, index: number)
	local char = p.Character
	if not char then return end
	local shape = PROP_SHAPES[index]
	for _, d in char:GetDescendants() do if d:IsA("BasePart") then d.Transparency = 1 elseif d:IsA("Decal") then d.Transparency = 1 end end
	if ctx.PropParts[p.UserId] then ctx.PropParts[p.UserId]:Destroy() end
	local part = Instance.new("Part"); part.Name = "PropBody"; part.Size = shape[2]; part.CanCollide = false; part.Massless = true; part.Color = Color3.fromRGB(150, 110, 70); part:SetAttribute("Temporary", true)
	part.CFrame = (char:FindFirstChild("HumanoidRootPart") :: BasePart).CFrame
	local weld = Instance.new("WeldConstraint"); weld.Part0 = char:FindFirstChild("HumanoidRootPart"); weld.Part1 = part; weld.Parent = part
	part.Parent = char
	ctx.PropParts[p.UserId] = part
	ctx.Janitor:Add(part)
	p:SetAttribute("PropShape", shape[1])
end

function M.PreparePlayers(ctx)
	ctx.PropParts, ctx.Swaps, ctx.Ammo, ctx.LastPos, ctx.StillTime = {}, {}, {}, {}, {}
	local shuffled = TableUtil.Shuffle(ctx.Players, ctx.Rng)
	local hunterCount = math.max(1, math.floor(#shuffled / 4))
	ctx.Hunters, ctx.Props = {}, {}
	for i, p in shuffled do
		if i <= hunterCount then PlayerStateService:SetRole(p, "Hunter"); table.insert(ctx.Hunters, p); ctx.Ammo[p.UserId] = 8
		else PlayerStateService:SetRole(p, "Prop"); table.insert(ctx.Props, p); ctx.Swaps[p.UserId] = 3; becomeProp(ctx, p, ctx.Rng:NextInteger(1, #PROP_SHAPES)); ctx.Swaps[p.UserId] -= 1 end
	end
	Arena.SpawnAll(ctx.Props, "Spawns", ctx.Rng)
	Arena.SpawnTeam(ctx.Hunters, "Hunter")
	for _, h in ctx.Hunters do local r = Arena.Root(h) if r then r.Anchored = true end end
	ctx.Janitor:Add(Remotes:OnEvent("MinigameEvent", function(p, action, arg)
		if ctx.Finished then return end
		local role = PlayerStateService:Get(p).Role
		if action == "SwapProp" and role == "Prop" and (ctx.Swaps[p.UserId] or 0) > 0 and type(arg) == "number" and PROP_SHAPES[arg] then
			ctx.Swaps[p.UserId] -= 1; becomeProp(ctx, p, arg); ctx.Send(p, "SwapsLeft", ctx.Swaps[p.UserId])
		elseif action == "Shoot" and role == "Hunter" and ctx.Phase == "Hunt" and (ctx.Ammo[p.UserId] or 0) > 0 then
			-- Server raycasts from hunter head along the direction the client claims (direction only; origin is server-side).
			if typeof(arg) ~= "Vector3" or arg.Magnitude == 0 then return end
			ctx.Ammo[p.UserId] -= 1
			local head = p.Character and p.Character:FindFirstChild("Head") :: BasePart?
			if not head then return end
			local params = RaycastParams.new(); params.FilterDescendantsInstances = { p.Character }; params.FilterType = Enum.RaycastFilterType.Exclude
			local hit = workspace:Raycast(head.Position, arg.Unit * 80, params)
			local victim = hit and hit.Instance and game:GetService("Players"):GetPlayerFromCharacter(hit.Instance:FindFirstAncestorOfClass("Model"))
			if victim and PlayerStateService:Get(victim).Role == "Prop" and PlayerStateService:Get(victim).State == "Playing" then
				ctx.AddScore(p, 40); ctx.Eliminate(victim, "shot")
			else
				local h = p.Character:FindFirstChildOfClass("Humanoid")
				if h then h:TakeDamage(10) end
			end
			ctx.Send(p, "Ammo", ctx.Ammo[p.UserId])
			if ctx.Ammo[p.UserId] <= 0 then ctx.Janitor:AddThread(task.delay(6, function() if not ctx.Finished then ctx.Ammo[p.UserId] = 4; ctx.Send(p, "Ammo", 4) end end)) end
		end
	end))
end

function M.Start(ctx)
	ctx.Phase = "Hide"
	ctx.Broadcast("Phase", "Hide", 20)
	ctx.Janitor:AddThread(task.delay(20, function()
		if ctx.Finished then return end
		ctx.Phase = "Hunt"
		for _, h in ctx.Hunters do local r = Arena.Root(h) if r then r.Anchored = false end end
		ctx.Broadcast("Phase", "Hunt", ctx.Meta.Duration - 20)
	end))
	ctx.TauntTimer = 40
end

function M.Update(ctx, dt)
	if ctx.Phase ~= "Hunt" then return end
	local props = {}
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Prop" then table.insert(props, p) end end
	if #props == 0 then for _, h in ctx.Hunters do if h.Parent then ctx.Finish(h) end end ctx.End("all_props_found") return end
	local hunterAlive = false
	for _, h in ctx.Hunters do if h.Parent and PlayerStateService:Get(h).State == "Playing" then hunterAlive = true end end
	if not hunterAlive then ctx.End("hunters_gone") return end
	ctx.TauntTimer -= dt
	local taunt = ctx.TauntTimer <= 0
	if taunt then ctx.TauntTimer = 40 end
	for _, p in props do
		ctx.AddScore(p, 1)
		local r = Arena.Root(p)
		if r then
			local last = ctx.LastPos[p.UserId]
			if last and (r.Position - last).Magnitude < 6 then
				ctx.StillTime[p.UserId] = (ctx.StillTime[p.UserId] or 0) + dt
				if ctx.StillTime[p.UserId] > 25 then ctx.StillTime[p.UserId] = 0; ctx.Broadcast("PropChirp", r.Position) end
			else
				ctx.LastPos[p.UserId] = r.Position; ctx.StillTime[p.UserId] = 0
			end
			if taunt then ctx.Broadcast("PropTaunt", r.Position) end
		end
	end
end

function M.Finish(ctx)
	for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Prop" then ctx.Finish(p) end end
	return nil
end

function M.AdminHook(ctx, action, args)
	if action == "Reveal" then for _, p in ctx.AlivePlayers() do if PlayerStateService:Get(p).Role == "Prop" then local part = ctx.PropParts[p.UserId] if part then part.Color = Color3.new(1, 0, 0) end end end return "revealed" end
	return "unsupported"
end

function M.Cleanup(ctx) for _, p in ctx.Players do p:SetAttribute("PropShape", nil) end end
return M
