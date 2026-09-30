--[[
	AURORA BLADE - a fully procedural Roblox sword with VFX.

	Drop this Script into ServerScriptService and press Play. No assets needed:
	the sword is built from Parts, and every effect is a native Roblox instance
	(Trail, ParticleEmitter, PointLight, Highlight, Tween-driven shockwaves).

	Left click = 3-hit combo (chop, side slash, ground slam).
	Optional: add AuroraBladeClient.client.luau to StarterPlayerScripts for camera shake.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local CONFIG = {
	Name = "Aurora Blade",
	Damage = { 10, 12, 22 }, -- per combo step
	Knockback = { 25, 30, 55 },
	Cooldown = 0.15, -- extra delay after a swing finishes
	ComboReset = 1.2, -- seconds of idle before the combo restarts
	HitRange = 7,
	HitWidth = 6,
	SlamRadius = 14,
	GiveOnSpawn = true,

	Core = Color3.fromRGB(82, 230, 255),
	Accent = Color3.fromRGB(169, 109, 255),
	Hot = Color3.fromRGB(255, 255, 255),

	-- Paste Roblox audio asset ids here ("rbxassetid://123"). Empty = silent.
	Sounds = { Swing = "", Hit = "", Slam = "" },
}

-- Grip offsets relative to the resting grip. If a swing looks mirrored on your
-- rig, flip the sign of the angles.
local POSES = {
	{ windup = 0.14, strike = 0.10, recover = 0.20,
		windupCF = CFrame.Angles(math.rad(-65), 0, 0), strikeCF = CFrame.Angles(math.rad(55), 0, 0) },
	{ windup = 0.14, strike = 0.10, recover = 0.20,
		windupCF = CFrame.Angles(0, math.rad(70), 0), strikeCF = CFrame.Angles(0, math.rad(-70), 0) },
	{ windup = 0.28, strike = 0.12, recover = 0.35,
		windupCF = CFrame.Angles(math.rad(-105), 0, 0), strikeCF = CFrame.Angles(math.rad(70), 0, 0) },
}

--------------------------------------------------------------------------------
-- REMOTE (screen shake on the attacker's client)
--------------------------------------------------------------------------------
local fxRemote = ReplicatedStorage:FindFirstChild("SwordFX")
if not fxRemote then
	fxRemote = Instance.new("RemoteEvent")
	fxRemote.Name = "SwordFX"
	fxRemote.Parent = ReplicatedStorage
end

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------
local function playSound(id, parent, volume)
	if id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume or 0.8
	s.RollOffMaxDistance = 80
	s.Parent = parent
	s.PlayOnRemove = false
	s:Play()
	Debris:AddItem(s, 3)
end

local function newPart(name, size, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material
	p.CanCollide = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(handle, part, offset)
	local w = Instance.new("Weld")
	w.Part0 = handle
	w.Part1 = part
	w.C0 = offset
	w.Parent = part
end

local function fxAnchor(position, lifetime)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = position
	p.Parent = workspace
	Debris:AddItem(p, lifetime)
	return p
end

--------------------------------------------------------------------------------
-- BUILD THE SWORD
--------------------------------------------------------------------------------
local function buildSword()
	local tool = Instance.new("Tool")
	tool.Name = CONFIG.Name
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = "Left click: 3-hit combo"
	-- Blade points along the handle's +Z axis, the hand holds the handle centre.
	tool.GripForward = Vector3.new(0, -1, 0)
	tool.GripRight = Vector3.new(1, 0, 0)
	tool.GripUp = Vector3.new(0, 0, 1)
	tool.GripPos = Vector3.new(0, 0, 0)

	local leather = Color3.fromRGB(40, 32, 44)
	local gold = Color3.fromRGB(226, 178, 84)
	local steel = Color3.fromRGB(214, 224, 236)

	local handle = newPart("Handle", Vector3.new(0.45, 0.45, 1.5), leather, Enum.Material.Fabric, tool)
	handle.Massless = false

	local guard = newPart("Guard", Vector3.new(0.3, 2.2, 0.35), gold, Enum.Material.Metal, tool)
	weld(handle, guard, CFrame.new(0, 0, 0.85))

	local pommel = newPart("Pommel", Vector3.new(0.6, 0.6, 0.6), gold, Enum.Material.Metal, tool)
	pommel.Shape = Enum.PartType.Ball
	weld(handle, pommel, CFrame.new(0, 0, -0.85))

	local gem = newPart("Gem", Vector3.new(0.42, 0.42, 0.42), CONFIG.Core, Enum.Material.Neon, tool)
	gem.Shape = Enum.PartType.Ball
	weld(handle, gem, CFrame.new(0, 0, 0.85))

	local blade = newPart("Blade", Vector3.new(0.12, 0.7, 4.4), steel, Enum.Material.Metal, tool)
	weld(handle, blade, CFrame.new(0, 0, 3.25))

	local tip = newPart("Tip", Vector3.new(0.12, 0.5, 0.5), steel, Enum.Material.Metal, tool)
	weld(handle, tip, CFrame.new(0, 0, 5.45) * CFrame.Angles(math.rad(45), 0, 0))

	-- Glowing fuller down the middle of the blade.
	local fuller = newPart("Fuller", Vector3.new(0.14, 0.14, 3.8), CONFIG.Core, Enum.Material.Neon, tool)
	weld(handle, fuller, CFrame.new(0, 0, 3.1))

	-- VFX -----------------------------------------------------------------
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = Vector3.new(0, 0, -2.0)
	a0.Parent = blade

	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, 0, 2.6)
	a1.Parent = blade

	local trail = Instance.new("Trail")
	trail.Name = "SwingTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.32
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, CONFIG.Hot),
		ColorSequenceKeypoint.new(0.35, CONFIG.Core),
		ColorSequenceKeypoint.new(1, CONFIG.Accent),
	})
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.15),
	})
	trail.Enabled = false
	trail.Parent = blade

	local embers = Instance.new("ParticleEmitter")
	embers.Name = "Embers"
	embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	embers.Shape = Enum.ParticleEmitterShape.Box
	embers.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	embers.Rate = 14
	embers.Lifetime = NumberRange.new(0.6, 1.3)
	embers.Speed = NumberRange.new(1, 3)
	embers.SpreadAngle = Vector2.new(180, 180)
	embers.Acceleration = Vector3.new(0, 2.5, 0)
	embers.Drag = 1
	embers.LightEmission = 1
	embers.LightInfluence = 0
	embers.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	embers.Color = ColorSequence.new(CONFIG.Core, CONFIG.Accent)
	embers.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	embers.Parent = blade

	local aura = Instance.new("ParticleEmitter")
	aura.Name = "Aura"
	aura.Texture = "rbxasset://textures/particles/fire_main.dds"
	aura.Shape = Enum.ParticleEmitterShape.Box
	aura.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	aura.Rate = 9
	aura.Lifetime = NumberRange.new(0.5, 0.9)
	aura.Speed = NumberRange.new(0.2, 0.8)
	aura.LightEmission = 1
	aura.LightInfluence = 0
	aura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.1),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	aura.Color = ColorSequence.new(CONFIG.Core, CONFIG.Accent)
	aura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	aura.Parent = blade

	local light = Instance.new("PointLight")
	light.Name = "BladeLight"
	light.Color = CONFIG.Core
	light.Brightness = 2
	light.Range = 11
	light.Shadows = false
	light.Parent = blade

	return tool
end

--------------------------------------------------------------------------------
-- HIT EFFECTS
--------------------------------------------------------------------------------
local function hitBurst(position, big)
	local anchor = fxAnchor(position, 2)

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 0
	sparks.Lifetime = NumberRange.new(0.3, 0.6)
	sparks.Speed = NumberRange.new(18, big and 48 or 32)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Drag = 4
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, big and 0.9 or 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Color = ColorSequence.new(CONFIG.Hot, CONFIG.Core)
	sparks.Parent = anchor
	sparks:Emit(big and 40 or 22)

	local flash = Instance.new("Part")
	flash.Shape = Enum.PartType.Ball
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CanTouch = false
	flash.Material = Enum.Material.Neon
	flash.Color = CONFIG.Hot
	flash.Transparency = 0.2
	flash.Size = Vector3.new(1, 1, 1)
	flash.Position = position
	flash.Parent = workspace
	local grow = big and 9 or 5
	TweenService:Create(
		flash,
		TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(grow, grow, grow), Transparency = 1, Color = CONFIG.Core }
	):Play()
	Debris:AddItem(flash, 0.3)
end

local function shockwave(position, radius, color)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.2
	ring.Size = Vector3.new(0.3, 1, 1)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(
		ring,
		TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Size = Vector3.new(0.3, radius * 2, radius * 2), Transparency = 1 }
	):Play()
	Debris:AddItem(ring, 0.65)
end

local function flashCharacter(model)
	local h = Instance.new("Highlight")
	h.FillColor = CONFIG.Hot
	h.OutlineColor = CONFIG.Core
	h.FillTransparency = 0.1
	h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = model
	TweenService:Create(h, TweenInfo.new(0.35), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	Debris:AddItem(h, 0.45)
end

--------------------------------------------------------------------------------
-- DAMAGE
--------------------------------------------------------------------------------
local function strikeTargets(player, char, root, combo)
	local slam = combo == 3
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }

	local parts
	if slam then
		parts = workspace:GetPartBoundsInRadius(root.Position, CONFIG.SlamRadius, params)
	else
		local cf = root.CFrame * CFrame.new(0, 0, -(CONFIG.HitRange / 2 + 1))
		parts = workspace:GetPartBoundsInBox(cf, Vector3.new(CONFIG.HitWidth, 6, CONFIG.HitRange), params)
	end

	local seen = {}
	local hitCount = 0
	for _, p in ipairs(parts) do
		local model = p:FindFirstAncestorOfClass("Model")
		if model and not seen[model] then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local hrp = model:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				seen[model] = true
				hitCount += 1

				hum:TakeDamage(CONFIG.Damage[combo])

				local away = (hrp.Position - root.Position) * Vector3.new(1, 0, 1)
				local dir = away.Magnitude > 0.01 and away.Unit or root.CFrame.LookVector
				hrp.AssemblyLinearVelocity = dir * CONFIG.Knockback[combo] + Vector3.new(0, slam and 40 or 18, 0)

				hitBurst(hrp.Position, slam)
				flashCharacter(model)
				playSound(CONFIG.Sounds.Hit, hrp, 0.9)
			end
		end
	end

	if slam then
		local ray = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), params)
		local ground = ray and ray.Position or (root.Position - Vector3.new(0, 3, 0))
		local groundPos = ground + Vector3.new(0, 0.2, 0)
		shockwave(groundPos, CONFIG.SlamRadius * 2, CONFIG.Core)
		task.delay(0.08, shockwave, groundPos, CONFIG.SlamRadius * 1.4, CONFIG.Accent)
		hitBurst(groundPos + Vector3.new(0, 1, 0), true)
		playSound(CONFIG.Sounds.Slam, root, 1)
		fxRemote:FireClient(player, "Shake", 0.9, 0.5)
	elseif hitCount > 0 then
		fxRemote:FireClient(player, "Shake", 0.3, 0.2)
	end
end

--------------------------------------------------------------------------------
-- TOOL BEHAVIOUR
--------------------------------------------------------------------------------
local function setupTool(tool)
	local baseGrip = tool.Grip
	local blade = tool:WaitForChild("Blade")
	local fuller = tool:WaitForChild("Fuller")
	local trail = blade:WaitForChild("SwingTrail")
	local light = blade:WaitForChild("BladeLight")

	local busy = false
	local combo = 0
	local lastSwing = 0

	-- Idle pulse: the fuller and blade light breathe.
	local pulse = TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	TweenService:Create(fuller, pulse, { Transparency = 0.35 }):Play()
	TweenService:Create(light, pulse, { Brightness = 0.9 }):Play()

	tool.Unequipped:Connect(function()
		tool.Grip = baseGrip
		trail.Enabled = false
		busy = false
	end)

	tool.Activated:Connect(function()
		if busy then
			return
		end
		local char = tool.Parent
		local player = Players:GetPlayerFromCharacter(char)
		if not player then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or hum.Health <= 0 or not root then
			return
		end

		busy = true
		if os.clock() - lastSwing > CONFIG.ComboReset then
			combo = 0
		end
		combo = combo % 3 + 1
		lastSwing = os.clock()

		local pose = POSES[combo]
		trail.Enabled = true
		playSound(CONFIG.Sounds.Swing, blade, 0.7)

		TweenService:Create(
			tool,
			TweenInfo.new(pose.windup, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Grip = baseGrip * pose.windupCF }
		):Play()
		task.wait(pose.windup)
		if tool.Parent ~= char then
			busy = false
			return
		end

		TweenService:Create(
			tool,
			TweenInfo.new(pose.strike, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Grip = baseGrip * pose.strikeCF }
		):Play()
		task.wait(pose.strike * 0.6)
		strikeTargets(player, char, root, combo)
		task.wait(pose.strike * 0.4)

		TweenService:Create(
			tool,
			TweenInfo.new(pose.recover, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Grip = baseGrip }
		):Play()
		task.wait(pose.recover)
		trail.Enabled = false
		task.wait(CONFIG.Cooldown)
		busy = false
	end)
end

--------------------------------------------------------------------------------
-- DISTRIBUTION
--------------------------------------------------------------------------------
local template = buildSword()
template.Parent = ServerStorage -- also lets you grab it: ServerStorage["Aurora Blade"]

local function giveSword(player)
	local backpack = player:WaitForChild("Backpack")
	local char = player.Character
	if backpack:FindFirstChild(CONFIG.Name) or (char and char:FindFirstChild(CONFIG.Name)) then
		return
	end
	local tool = template:Clone()
	setupTool(tool)
	tool.Parent = backpack
end

if CONFIG.GiveOnSpawn then
	local function onPlayer(player)
		player.CharacterAdded:Connect(function()
			task.defer(giveSword, player)
		end)
		if player.Character then
			task.defer(giveSword, player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayer(player)
	end
end
