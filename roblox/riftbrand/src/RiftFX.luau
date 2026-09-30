--[[
	RIFTBRAND — RiftFX (client only)
	Every transient effect is built here from engine primitives — Beams, Parts, ParticleEmitters,
	PointLights, a ColorCorrection — so there are no meshes or decals to upload.

	Signature effects:
	  Prism Crescents  crescent slashes built from two curved Beams (thin → thick → thin), stacked in
	                   five chromatic layers that peel apart as they expand: magenta / cyan / gold / UV / white core
	  Rift Tear        a hanging black slit with a shimmering ForceField rim and two curved neon lips. Gravity
	                   streams and inward-flying sparks pour into it until it collapses and detonates
	  Phase Step       real-pose neon afterimages of the whole character (sword included) + a light streak
	  Prism Nova       eight crystal shards burst outward and stab into the ground, with neon cracks
	                   racing along the floor, a dome, a light pillar and a flat shockwave ring
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent:WaitForChild("Config"))
local Anim = require(script.Parent:WaitForChild("RiftAnim"))

local FX = {}
FX.Anim = Anim

local P = Config.Palette
local T = Config.Textures
local player = Players.LocalPlayer
local rad = math.rad
local TAU = math.pi * 2
local CYCLE = { P.Rift, P.Prism, P.Solar, P.Ultra }

--------------------------------------------------------------------------------
-- Small helpers
--------------------------------------------------------------------------------

local function NS(...)
	local a = { ... }
	local kps = {}
	for i = 1, #a, 2 do
		table.insert(kps, NumberSequenceKeypoint.new(a[i], a[i + 1]))
	end
	return NumberSequence.new(kps)
end

local function CS(...)
	local a = { ... }
	if #a == 1 then
		return ColorSequence.new(a[1])
	elseif #a == 2 then
		return ColorSequence.new(a[1], a[2])
	end
	local kps = {}
	for i, c in a do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#a - 1), c))
	end
	return ColorSequence.new(kps)
end

local function NR(a, b)
	return NumberRange.new(a, b or a)
end

local function easeOut(x)
	return 1 - (1 - x) ^ 3
end

local function easeOutBack(x)
	local c1 = 1.70158
	return 1 + (c1 + 1) * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local fxFolder
local function folder()
	if not fxFolder or not fxFolder.Parent then
		fxFolder = Instance.new("Folder")
		fxFolder.Name = "RiftbrandFX"
		fxFolder.Parent = Workspace
	end
	return fxFolder
end

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or folder()
	return p
end

local function anchor(cf)
	return part({ Transparency = 1, Size = Vector3.new(0.2, 0.2, 0.2), CFrame = cf })
end

local function emitter(parent, props)
	local pe = Instance.new("ParticleEmitter")
	pe.Enabled = false
	pe.Texture = T.Sparkle
	pe.LightEmission = 1
	pe.LightInfluence = 0
	for k, v in props do
		pe[k] = v
	end
	pe.Parent = parent
	return pe
end

local function burstAt(cf, count, props, life)
	if typeof(cf) == "Vector3" then
		cf = CFrame.new(cf)
	end
	local a = anchor(cf)
	local att = Instance.new("Attachment")
	att.Parent = a
	local pe = emitter(att, props)
	pe:Emit(count)
	Debris:AddItem(a, life or 1.5)
	return pe
end

local function sparks(pos, count, colorA, colorB, speed, size)
	burstAt(pos, count, {
		Color = CS(colorA or P.White, colorB or P.Rift),
		Size = NS(0, size or 0.45, 1, 0),
		Transparency = NS(0, 0, 0.7, 0.2, 1, 1),
		Speed = NR((speed or 40) * 0.5, speed or 40),
		Lifetime = NR(0.18, 0.42),
		Drag = 7,
		SpreadAngle = Vector2.new(180, 180),
		Rotation = NR(0, 360),
		RotSpeed = NR(-300, 300),
		Brightness = 4,
	}, 0.8)
end

local function shockRing(cf, size, color, life, direction)
	burstAt(cf, 1, {
		Texture = T.Shockwave,
		Color = CS(color or P.White),
		Size = NS(0, size * 0.1, 1, size),
		Transparency = NS(0, 0.05, 0.6, 0.3, 1, 1),
		Speed = NR(0.01),
		Lifetime = NR(life or 0.4),
		EmissionDirection = direction or Enum.NormalId.Top,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
		SpreadAngle = Vector2.new(0, 0),
		Brightness = 5,
	}, (life or 0.4) + 0.3)
end

local function glowPuff(pos, size, color, life)
	burstAt(pos, 2, {
		Texture = T.Glow,
		Color = CS(color),
		Size = NS(0, size * 0.4, 1, size),
		Transparency = NS(0, 0.2, 1, 1),
		Speed = NR(0),
		Lifetime = NR(life or 0.3),
		Rotation = NR(0, 360),
		Brightness = 3,
	}, (life or 0.3) + 0.3)
end

local function playSound(def, where, speed)
	if not def or def.id == nil or def.id == "" then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = def.id
	s.Volume = def.volume or 1
	s.PlaybackSpeed = speed or 1
	s.RollOffMaxDistance = 150
	if typeof(where) == "Vector3" then
		local a = anchor(CFrame.new(where))
		s.Parent = a
		Debris:AddItem(a, 5)
	else
		s.Parent = where
		Debris:AddItem(s, 5)
	end
	s:Play()
end
FX.PlaySound = playSound

local function groundBelow(pos, depth)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { folder() }
	for _, plr in Players:GetPlayers() do
		if plr.Character then
			table.insert(ignore, plr.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -(depth or 30), 0), params)
	return hit and hit.Position or (pos - Vector3.new(0, 3, 0)), hit ~= nil
end

--------------------------------------------------------------------------------
-- Frame loop for timed effects
--------------------------------------------------------------------------------

local active = {}

-- fn(alpha 0..1, age, dt) runs every frame for `duration` seconds, then cleanup().
local function run(duration, fn, cleanup)
	table.insert(active, { start = os.clock(), duration = duration, fn = fn, cleanup = cleanup })
end
FX.Run = run

local function flashLight(where, color, brightness, range, duration)
	local holder = where
	if typeof(where) == "Vector3" then
		holder = anchor(CFrame.new(where))
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range
	light.Brightness = brightness
	light.Shadows = false
	light.Parent = holder
	run(duration, function(a)
		light.Brightness = brightness * (1 - a) ^ 2
	end, function()
		if holder ~= where then
			holder:Destroy()
		else
			light:Destroy()
		end
	end)
end

--------------------------------------------------------------------------------
-- Screen: camera shake, colour flash, FOV kick, bloom
--------------------------------------------------------------------------------

local shakes = {}
function FX.Shake(intensity, duration)
	if not Config.CameraShake or intensity <= 0 then
		return
	end
	table.insert(shakes, { i = intensity, d = duration, s = os.clock() })
end

local flashes = {}
local cc
function FX.Flash(tint, brightness, contrast, saturation, duration)
	if not Config.ScreenFlash then
		return
	end
	table.insert(flashes, { c = tint, b = brightness, k = contrast, s = saturation, d = duration, t0 = os.clock() })
end

local fovBase
local fovKicks = {}
function FX.FovKick(amount, duration)
	table.insert(fovKicks, { a = amount, d = duration, t0 = os.clock() })
end

local function updateScreen()
	local now = os.clock()
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end

	-- colour flash
	if #flashes > 0 or (cc and cc.Enabled) then
		if not cc or not cc.Parent then
			cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "RiftbrandFlash"
			cc.Parent = Lighting
		end
		local b, k, s, tint, tw = 0, 0, 0, Color3.new(1, 1, 1), 0
		for i = #flashes, 1, -1 do
			local f = flashes[i]
			local a = (now - f.t0) / f.d
			if a >= 1 then
				table.remove(flashes, i)
			else
				local w = (1 - a) ^ 2
				b += f.b * w
				k += f.k * w
				s += f.s * w
				if w > tw then
					tw = w
					tint = Color3.new(1, 1, 1):Lerp(f.c, w)
				end
			end
		end
		cc.Brightness = b
		cc.Contrast = k
		cc.Saturation = s
		cc.TintColor = tint
		cc.Enabled = #flashes > 0
	end

	-- FOV kick
	if #fovKicks > 0 then
		fovBase = fovBase or cam.FieldOfView
		local add = 0
		for i = #fovKicks, 1, -1 do
			local f = fovKicks[i]
			local a = (now - f.t0) / f.d
			if a >= 1 then
				table.remove(fovKicks, i)
			else
				add += f.a * math.sin(math.min(1, a * 3) * math.pi / 2) * (1 - a)
			end
		end
		cam.FieldOfView = fovBase + add
		if #fovKicks == 0 then
			cam.FieldOfView = fovBase
			fovBase = nil
		end
	end
end

local function applyShake()
	if #shakes == 0 then
		return
	end
	local now = os.clock()
	local mag = 0
	for i = #shakes, 1, -1 do
		local s = shakes[i]
		local a = (now - s.s) / s.d
		if a >= 1 then
			table.remove(shakes, i)
		else
			mag += s.i * (1 - a) ^ 2
		end
	end
	if mag <= 0 then
		return
	end
	local cam = Workspace.CurrentCamera
	local n = now * 38
	local rx = math.noise(n, 0.31) * mag * 0.04
	local ry = math.noise(0.73, n) * mag * 0.04
	local rz = math.noise(n, n * 0.5 + 3.1) * mag * 0.025
	cam.CFrame = cam.CFrame * CFrame.Angles(rx, ry, rz)
end

local function distanceToCamera(pos)
	local cam = Workspace.CurrentCamera
	return cam and (cam.CFrame.Position - pos).Magnitude or 0
end

-- Shake scaled by how close the local player is to the blast.
local function shakeNear(pos, intensity, duration, falloff)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local d = (root.Position - pos).Magnitude
	local k = math.clamp(1 - d / (falloff or 80), 0, 1)
	if k > 0 then
		FX.Shake(intensity * k, duration)
	end
	return k
end

--------------------------------------------------------------------------------
-- Prism Crescent — the signature slash
--------------------------------------------------------------------------------

-- A crescent lying in `frame`'s XZ plane, centred on frame, bulging toward frame's -Z.
-- Two curved Beams share a middle attachment: width 0 → full → 0 gives the crescent silhouette.
local function crescent(frame, sweepDeg, color, brightness)
	local S = rad(sweepDeg / 2)
	local holder = anchor(frame)
	local atts = {}
	for i = 1, 3 do
		local a = Instance.new("Attachment")
		a.Parent = holder
		atts[i] = a
	end
	local beams = {}
	for i = 1, 2 do
		local b = Instance.new("Beam")
		b.Attachment0 = atts[i]
		b.Attachment1 = atts[i + 1]
		b.FaceCamera = true
		b.Segments = 24
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Brightness = brightness or 4
		b.Color = CS(color)
		b.Parent = holder
		beams[i] = b
	end
	local angles = { -S, 0, S }
	local function layout(r, w, t)
		local k = 4 / 3 * math.tan(S / 4) * r
		for i, th in angles do
			local pos = Vector3.new(r * math.sin(th), 0, -r * math.cos(th))
			local tangent = Vector3.new(math.cos(th), 0, math.sin(th))
			atts[i].CFrame = CFrame.fromMatrix(pos, tangent, Vector3.yAxis)
		end
		local b1, b2 = beams[1], beams[2]
		b1.CurveSize0, b1.CurveSize1 = k, k
		b2.CurveSize0, b2.CurveSize1 = k, k
		b1.Width0, b1.Width1 = w * 0.04, w
		b2.Width0, b2.Width1 = w, w * 0.04
		local edge = math.min(1, t + 0.55)
		b1.Transparency = NS(0, edge, 1, t)
		b2.Transparency = NS(0, t, 1, edge)
	end
	return holder, layout
end

local LAYERS = {
	{ color = P.Ultra, r = 1.15, w = 0.7, delay = 0.045, t = 0.35, life = 0.38 },
	{ color = P.Rift, r = 1.07, w = 0.95, delay = 0.03, t = 0.1, life = 0.33 },
	{ color = P.Prism, r = 0.93, w = 0.85, delay = 0.015, t = 0.1, life = 0.31 },
	{ color = P.Solar, r = 1.0, w = 1.0, delay = 0, t = 0.05, life = 0.27 },
	{ color = P.White, r = 1.0, w = 0.3, delay = 0, t = 0, life = 0.2, bright = 8 },
}

function FX.PrismSlash(frame, radius, sweep, width, spin)
	spin = spin or 25
	for _, L in LAYERS do
		task.delay(L.delay, function()
			local holder, layout = crescent(frame, sweep, L.color, L.bright or 4)
			layout(radius * L.r * 0.85, 0, 1)
			run(L.life, function(a)
				local grow = easeOut(math.min(1, a / 0.28))
				local r = radius * L.r * (0.85 + 0.22 * a)
				local w = width * L.w * grow * (1 - 0.6 * a * a)
				local tr = L.t + (1 - L.t) * a ^ 1.6
				holder.CFrame = frame * CFrame.Angles(0, rad(-spin * a), 0)
				layout(r, w, tr)
			end, function()
				holder:Destroy()
			end)
		end)
	end
	local half = rad(sweep / 2)
	for i = -2, 2 do
		local th = half * i / 2
		local p = frame * Vector3.new(radius * math.sin(th), 0, -radius * math.cos(th))
		burstAt(p, 4, {
			Color = CS(CYCLE[(i + 2) % 4 + 1], P.White),
			Size = NS(0, 0.35, 1, 0),
			Speed = NR(5, 14),
			Lifetime = NR(0.2, 0.45),
			Drag = 4,
			SpreadAngle = Vector2.new(180, 180),
			Brightness = 3,
		}, 0.8)
	end
end

--------------------------------------------------------------------------------
-- Hits
--------------------------------------------------------------------------------

local function starFlare(pos, size, color, life)
	local a = part({ Size = Vector3.new(0.12, 1, 0.12), Color = color, CFrame = CFrame.new(pos) })
	local b = part({ Size = Vector3.new(1, 0.12, 0.12), Color = color, CFrame = CFrame.new(pos) })
	local spin = math.random() * TAU
	run(life, function(t)
		local cam = Workspace.CurrentCamera
		local s = size * math.sin(math.min(1, t * 1.6) * math.pi) + 0.01
		local cf = CFrame.lookAt(pos, cam.CFrame.Position) * CFrame.Angles(0, 0, spin + t * 2)
		a.Size = Vector3.new(0.14 * (1 - t) + 0.02, s, 0.05)
		b.Size = Vector3.new(s * 0.75, 0.14 * (1 - t) + 0.02, 0.05)
		a.CFrame, b.CFrame = cf, cf
	end, function()
		a:Destroy()
		b:Destroy()
	end)
end

local function flashBall(pos, size, color, life, material)
	local ball = part({
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * 0.5,
		Color = color,
		Material = material or Enum.Material.Neon,
		CFrame = CFrame.new(pos),
	})
	run(life, function(a)
		local s = 0.5 + size * easeOut(a)
		ball.Size = Vector3.one * s
		ball.CFrame = CFrame.new(pos)
		ball.Transparency = a ^ 0.7
	end, function()
		ball:Destroy()
	end)
	return ball
end

function FX.DamageNumber(pos, amount, color)
	if not Config.DamageNumbers then
		return
	end
	local a = anchor(CFrame.new(pos + Vector3.new(math.random() * 2 - 1, 1.5, math.random() * 2 - 1)))
	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromScale(4, 2)
	gui.LightInfluence = 0
	gui.Parent = a
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = tostring(math.floor(amount + 0.5))
	label.TextColor3 = color or P.Solar
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2.5
	stroke.Color = P.Void
	stroke.Parent = label
	local start = a.Position
	run(0.75, function(t)
		local pop = t < 0.15 and easeOutBack(t / 0.15) or 1
		label.Size = UDim2.fromScale(pop, pop)
		a.Position = start + Vector3.new(0, 2.5 * easeOut(t), 0)
		local fade = math.clamp((t - 0.6) / 0.4, 0, 1)
		label.TextTransparency = fade
		stroke.Transparency = fade
	end, function()
		a:Destroy()
	end)
end

-- pos: where the victim was struck. mine: the local player dealt it.
function FX.Hit(pos, moveName, mine, damage)
	if typeof(pos) ~= "Vector3" or distanceToCamera(pos) > Config.MaxVFXDistance then
		return
	end
	local big = moveName == "Slash3" or moveName == "RiftTear" or moveName == "PrismNova"
	local color = CYCLE[math.random(1, 3)]
	flashBall(pos, big and 6 or 3.5, P.White, 0.14)
	starFlare(pos, big and 9 or 6, P.Solar, 0.2)
	sparks(pos, big and 34 or 18, P.White, color, big and 60 or 42)
	glowPuff(pos, big and 9 or 6, color, 0.25)
	flashLight(pos, color, big and 10 or 6, big and 18 or 12, 0.22)
	if mine then
		local char = player.Character
		if char then
			Anim.HitStop(char, big and 0.08 or 0.05)
		end
		FX.Shake(big and 0.9 or 0.45, big and 0.28 or 0.16)
		FX.DamageNumber(pos, damage or 0, big and P.Rift or P.Solar)
	end
end

-- Knockback on the local character (the server can't move client-owned characters directly).
function FX.Knock(velocity)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not root or not hum or typeof(velocity) ~= "Vector3" then
		return
	end
	if velocity.Y > 5 then
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
	root.AssemblyLinearVelocity = velocity
end

--------------------------------------------------------------------------------
-- Equipped swords: idle glow, orbiting shards, trails, hold stance
--------------------------------------------------------------------------------

local swords = {}

local function swordState(tool)
	local st = swords[tool]
	if st then
		return st
	end
	local handle = tool:FindFirstChild("Handle")
	if not handle then
		return nil
	end
	st = {
		tool = tool,
		handle = handle,
		tip = handle:FindFirstChild("TipFX"),
		light = handle:FindFirstChild("CoreLight", true),
		burst = handle:FindFirstChild("TipBurst", true),
		trails = {},
		trailUntil = 0,
		chargeUntil = 0,
		shards = {},
		equippedBy = nil,
	}
	for _, c in handle:GetChildren() do
		if c:IsA("Trail") then
			table.insert(st.trails, c)
		end
	end
	swords[tool] = st
	return st
end

local function findSword(character)
	if not character then
		return nil
	end
	for _, c in character:GetChildren() do
		if c:IsA("Tool") and c:GetAttribute(Config.Attribute) then
			return swordState(c)
		end
	end
	return nil
end
FX.FindSword = findSword

local function clearShards(st)
	for _, s in st.shards do
		s:Destroy()
	end
	table.clear(st.shards)
end

local function equipFlourish(st)
	if st.burst then
		st.burst:Emit(26)
	end
	if st.tip then
		flashLight(st.tip.WorldPosition, P.Rift, 6, 14, 0.4)
		glowPuff(st.tip.WorldPosition, 6, P.Prism, 0.35)
	end
	playSound(Config.Sounds.Equip, st.handle, 1.05)
end

local function setEquipped(st, character)
	if st.equippedBy == character then
		return
	end
	if st.equippedBy then
		Anim.SetHold(st.equippedBy, false)
	end
	clearShards(st)
	st.equippedBy = character
	if character then
		Anim.SetHold(character, true)
		for i = 1, 3 do
			st.shards[i] = part({
				Size = Vector3.new(0.16, 0.34, 0.16),
				Color = CYCLE[i],
			})
		end
		equipFlourish(st)
	end
end

local function updateSwords(now)
	for tool, st in swords do
		local parent = tool.Parent
		local char = parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") and parent or nil
		if not parent or not st.handle.Parent then
			setEquipped(st, nil)
			for _, tr in st.trails do
				tr.Enabled = false
			end
			swords[tool] = nil
			continue
		end
		setEquipped(st, char)

		local trailsOn = now < st.trailUntil
		for _, tr in st.trails do
			if tr.Enabled ~= trailsOn then
				tr.Enabled = trailsOn
			end
		end

		if char then
			local charge = now < st.chargeUntil and 1 or 0
			if st.light then
				st.light.Brightness = 1.6 + 0.5 * math.sin(now * 3) + charge * 5
				st.light.Range = 8 + charge * 8
			end
			if st.tip and #st.shards > 0 then
				local tip = st.tip.WorldCFrame
				local hcf = st.handle.CFrame
				local spd = 3.2 + charge * 9
				local rr = 0.6 + charge * 0.5
				for i, s in st.shards do
					local ang = now * spd + i * TAU / 3
					local offset = (hcf.RightVector * math.cos(ang) + hcf.LookVector * math.sin(ang)) * rr
					local bob = hcf.UpVector * (math.sin(now * 2 + i) * 0.18)
					s.CFrame = CFrame.new(tip.Position + offset + bob) * CFrame.Angles(now * 4 + i, now * 3, i)
				end
			end
		end
	end
end

local function scanSwords()
	for _, plr in Players:GetPlayers() do
		local char = plr.Character
		if char then
			for _, c in char:GetChildren() do
				if c:IsA("Tool") and c:GetAttribute(Config.Attribute) then
					swordState(c)
				end
			end
		end
	end
end

function FX.Trails(character, duration)
	local st = findSword(character)
	if st then
		st.trailUntil = math.max(st.trailUntil, os.clock() + duration)
	end
end

function FX.Charge(character, duration)
	local st = findSword(character)
	if st then
		st.chargeUntil = math.max(st.chargeUntil, os.clock() + duration)
	end
end

--------------------------------------------------------------------------------
-- Afterimages
--------------------------------------------------------------------------------

local function afterimage(character, color, life)
	local model = Instance.new("Folder")
	model.Name = "Afterimage"
	local parts = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" and d.Transparency < 0.95 then
			local wasArchivable = d.Archivable
			d.Archivable = true
			local ok, c = pcall(d.Clone, d)
			d.Archivable = wasArchivable
			if ok and c then
				for _, ch in c:GetChildren() do
					if ch:IsA("SpecialMesh") then
						ch.TextureId = ""
					else
						ch:Destroy()
					end
				end
				if c:IsA("MeshPart") then
					pcall(function()
						c.TextureID = ""
					end)
				end
				c.Anchored = true
				c.CanCollide = false
				c.CanQuery = false
				c.CanTouch = false
				c.CastShadow = false
				c.Massless = true
				c.Material = Enum.Material.Neon
				c.Color = color
				c.Transparency = 0.35
				c.CFrame = d.CFrame
				c.Parent = model
				table.insert(parts, c)
			end
		end
	end
	model.Parent = folder()
	run(life, function(a)
		local t = 0.35 + 0.65 * a
		for _, c in parts do
			c.Transparency = t
		end
	end, function()
		model:Destroy()
	end)
end

local function streak(from, to, width, colorA, colorB, life)
	local a0 = anchor(CFrame.new(from))
	local a1 = anchor(CFrame.new(to))
	local att0 = Instance.new("Attachment")
	att0.Parent = a0
	local att1 = Instance.new("Attachment")
	att1.Parent = a1
	local b = Instance.new("Beam")
	b.Attachment0 = att0
	b.Attachment1 = att1
	b.FaceCamera = true
	b.LightEmission = 1
	b.LightInfluence = 0
	b.Brightness = 5
	b.Color = CS(colorA, P.White, colorB)
	b.Texture = T.Sparkle
	b.TextureMode = Enum.TextureMode.Wrap
	b.TextureLength = 3
	b.TextureSpeed = 4
	b.Parent = a0
	run(life, function(a)
		local w = width * (1 - easeOut(a))
		b.Width0 = w * 0.3
		b.Width1 = w
		b.Transparency = NS(0, 0.5 + 0.5 * a, 1, a)
	end, function()
		a0:Destroy()
		a1:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- Rift Tear
--------------------------------------------------------------------------------

local function meshPart(cf, color, material, transparency)
	local p = part({
		Size = Vector3.one,
		Color = color,
		Material = material,
		Transparency = transparency or 0,
		CFrame = cf,
	})
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Scale = Vector3.new(0.01, 0.01, 0.01)
	m.Parent = p
	return p, m
end

function FX.RiftTear(cf, openTime, radius)
	if distanceToCamera(cf.Position) > Config.MaxVFXDistance then
		return
	end
	local HEIGHT = 12
	local WIDTH = 3.2

	local core, coreMesh = meshPart(cf, Color3.new(0, 0, 0), Enum.Material.Neon)
	local rim, rimMesh = meshPart(cf, P.Rift, Enum.Material.ForceField)
	local halo, haloMesh = meshPart(cf, P.Ultra, Enum.Material.Neon, 0.6)

	-- The two glowing lips of the tear
	local lipHolder = anchor(cf)
	local top = Instance.new("Attachment")
	top.Parent = lipHolder
	local bottom = Instance.new("Attachment")
	bottom.Parent = lipHolder
	local lips = {}
	for i, color in { P.Rift, P.Prism } do
		local b = Instance.new("Beam")
		b.Attachment0 = top
		b.Attachment1 = bottom
		b.FaceCamera = true
		b.Segments = 30
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Brightness = 6
		b.Color = CS(P.White, color, P.White)
		b.Width0 = 0.1
		b.Width1 = 0.1
		b.Parent = lipHolder
		lips[i] = b
	end

	-- Sparks pouring inward from a sphere around it
	local well = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * (radius * 1.1), Transparency = 1, CFrame = cf })
	local inflow = emitter(well, {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Color = CS(P.Prism, P.Rift, P.White),
		Size = NS(0, 0.1, 0.3, 0.45, 1, 0),
		Transparency = NS(0, 1, 0.2, 0, 1, 0.2),
		Speed = NR(radius * 1.5, radius * 2),
		Lifetime = NR(0.26, 0.3),
		Rate = 220,
		Rotation = NR(0, 360),
		Brightness = 3,
	})
	inflow.Enabled = true

	-- Gravity streams: curved beams whose texture flows into the tear
	local streams = {}
	local centerAtt = Instance.new("Attachment")
	centerAtt.Parent = lipHolder
	for i = 1, 10 do
		local dir = Vector3.new(math.random() - 0.5, (math.random() - 0.5) * 0.9, math.random() - 0.5)
		if dir.Magnitude < 0.05 then
			dir = Vector3.xAxis
		end
		local outer = anchor(CFrame.new(cf.Position + dir.Unit * (radius * 0.7 + math.random() * radius * 0.35)))
		local oa = Instance.new("Attachment")
		oa.Parent = outer
		local b = Instance.new("Beam")
		b.Attachment0 = oa
		b.Attachment1 = centerAtt
		b.FaceCamera = true
		b.Segments = 16
		b.CurveSize0 = (math.random() - 0.5) * 8
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Brightness = 3
		b.Texture = T.Sparkle
		b.TextureMode = Enum.TextureMode.Wrap
		b.TextureLength = 2
		b.TextureSpeed = 3.5
		b.Color = CS(CYCLE[i % 4 + 1])
		b.Width0 = 0
		b.Width1 = 0
		b.Parent = outer
		streams[i] = { beam = b, holder = outer }
	end

	local light = Instance.new("PointLight")
	light.Color = P.Rift
	light.Range = radius * 1.4
	light.Brightness = 0
	light.Shadows = false
	light.Parent = core

	local near = shakeNear(cf.Position, 0.2, openTime, 60)
	if near and near > 0 then
		FX.Flash(P.Rift, -0.05, 0.15, 0.35 * near, openTime)
	end

	local function setOpen(w, h, lipW, jitter)
		coreMesh.Scale = Vector3.new(w, h, 0.25)
		rimMesh.Scale = Vector3.new(w + 0.8 + jitter, h + 1.4, 0.45)
		haloMesh.Scale = Vector3.new(w * 1.6 + 2, h + 3.2, 0.12)
		top.Position = Vector3.new(0, h / 2, 0)
		bottom.Position = Vector3.new(0, -h / 2, 0)
		local c = (w / 2 + 0.1) * 1.33
		lips[1].CurveSize0, lips[1].CurveSize1 = c, -c
		lips[2].CurveSize0, lips[2].CurveSize1 = -c, c
		for _, b in lips do
			b.Width0 = lipW
			b.Width1 = lipW
		end
	end

	-- Open, breathe, collapse
	run(openTime, function(a, age)
		local open = easeOutBack(math.min(1, age / 0.12))
		local h = 1 + (HEIGHT - 1) * math.min(1, open)
		local jitter = math.sin(age * 55) * 0.12 + math.sin(age * 31) * 0.08
		local w = math.max(0.02, WIDTH * open + jitter)
		if a > 0.88 then
			local c = (a - 0.88) / 0.12
			w = w * (1 - c) ^ 2
			h = h * (1 - 0.35 * c)
		end
		setOpen(w, h, 0.35 + 0.15 * math.sin(age * 20), jitter)
		light.Brightness = 3 + 6 * a
		local sw = math.min(1, age / 0.15)
		for _, s in streams do
			s.beam.Width0 = 0.9 * sw
			s.beam.Width1 = 0.05
			s.beam.Transparency = NS(0, 1, 0.3, 0.2, 1, 0)
		end
	end, function()
		inflow.Enabled = false
		for _, s in streams do
			s.holder:Destroy()
		end
		core:Destroy()
		rim:Destroy()
		halo:Destroy()
		lipHolder:Destroy()
		Debris:AddItem(well, 0.5)
		FX.RiftDetonate(cf, radius)
	end)
end

function FX.RiftDetonate(cf, radius)
	local pos = cf.Position
	flashBall(pos, radius * 1.3, P.White, 0.22)
	local dome = flashBall(pos, radius * 2.3, P.Rift, 0.45, Enum.Material.ForceField)
	dome.Transparency = 0
	shockRing(cf, radius * 3.2, P.Prism, 0.45, Enum.NormalId.Front)
	local ground, onGround = groundBelow(pos, 25)
	if onGround then
		shockRing(CFrame.new(ground + Vector3.new(0, 0.2, 0)), radius * 3, P.Rift, 0.5)
	end
	sparks(pos, 120, P.White, P.Rift, 95, 0.7)
	sparks(pos, 60, P.Solar, P.Prism, 60, 0.5)
	glowPuff(pos, radius * 2.2, P.Ultra, 0.4)
	starFlare(pos, radius * 1.8, P.White, 0.3)
	flashLight(pos, P.Rift, 16, radius * 3, 0.5)
	playSound(Config.Sounds.Detonate, pos, 1)
	local k = shakeNear(pos, 1.3, 0.5, 90)
	if k and k > 0 then
		FX.Flash(Color3.fromRGB(255, 220, 255), 0.35 * k, 0.3 * k, 0.2 * k, 0.35)
	end
end

--------------------------------------------------------------------------------
-- Prism Nova impact
--------------------------------------------------------------------------------

function FX.NovaImpact(center, radius, count)
	local ground = groundBelow(center, 40)
	local base = ground + Vector3.new(0, 0.1, 0)

	-- light pillar
	local pillar = part({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(60, 8, 8),
		Color = P.White,
		CFrame = CFrame.new(base + Vector3.new(0, 30, 0)) * CFrame.Angles(0, 0, math.pi / 2),
	})
	run(0.35, function(a)
		local w = 8 * (1 - easeOut(a)) + 0.05
		pillar.Size = Vector3.new(60, w, w)
		pillar.Transparency = a ^ 0.8
	end, function()
		pillar:Destroy()
	end)

	flashBall(base, radius * 1.1, P.White, 0.2)
	local dome = flashBall(base, radius * 2.2, P.Ultra, 0.5, Enum.Material.ForceField)
	dome.Transparency = 0
	shockRing(CFrame.new(base + Vector3.new(0, 0.3, 0)), radius * 3.4, P.Solar, 0.5)
	shockRing(CFrame.new(base + Vector3.new(0, 0.5, 0)), radius * 2.2, P.Prism, 0.35)
	sparks(base + Vector3.new(0, 1, 0), 140, P.White, P.Prism, 100, 0.8)
	sparks(base + Vector3.new(0, 1, 0), 70, P.Solar, P.Rift, 70, 0.6)
	glowPuff(base + Vector3.new(0, 2, 0), radius * 2.4, P.Rift, 0.45)
	flashLight(base + Vector3.new(0, 3, 0), P.Prism, 18, radius * 3, 0.6)
	playSound(Config.Sounds.Slam, base, 1)
	local k = shakeNear(base, 1.6, 0.6, 110)
	if k and k > 0 then
		FX.Flash(Color3.fromRGB(220, 250, 255), 0.4 * k, 0.35 * k, 0.3 * k, 0.4)
	end

	-- neon cracks racing across the floor
	for i = 1, count * 2 do
		local ang = (i / (count * 2)) * TAU + math.random() * 0.25
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local len = radius * (0.55 + math.random() * 0.45)
		local crack = part({ Size = Vector3.new(0.3, 0.08, 0.1), Color = CYCLE[i % 4 + 1] })
		run(1.1, function(a)
			local grow = easeOut(math.min(1, a / 0.14))
			local l = len * grow
			crack.Size = Vector3.new(0.3 * (1 - a * 0.5), 0.08, math.max(0.05, l))
			crack.CFrame = CFrame.lookAt(base + dir * (l / 2 + 0.6), base + dir * (l + 1))
			crack.Transparency = math.clamp((a - 0.6) / 0.4, 0, 1)
		end, function()
			crack:Destroy()
		end)
	end

	-- crystal shards burst out and stab into the ground
	for i = 1, count do
		local ang = (i / count) * TAU
		local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
		local dist = radius * (0.45 + (i % 2) * 0.15)
		local color = CYCLE[i % 4 + 1]
		local shard = part({ Size = Vector3.new(0.9, 5.5, 0.9), Color = color })
		local core = part({ Size = Vector3.new(0.4, 5.9, 0.4), Color = P.White })
		local tiltAxis = dir:Cross(Vector3.yAxis)
		local rest = CFrame.new(base + dir * dist + Vector3.new(0, 1.6, 0))
			* CFrame.fromAxisAngle(tiltAxis, -rad(32))
			* CFrame.Angles(0, rad(45), 0)
		local from = CFrame.new(base + Vector3.new(0, 2, 0)) * CFrame.Angles(0, rad(45), 0)
		run(1.35, function(a, age)
			local fly = easeOutBack(math.min(1, age / 0.14))
			local cf = from:Lerp(rest, fly)
			local shrink = math.clamp((age - 1.05) / 0.3, 0, 1)
			local s = 1 - shrink
			shard.Size = Vector3.new(0.9 * s + 0.01, 5.5 * (0.6 + 0.4 * math.min(1, fly)) * s + 0.01, 0.9 * s + 0.01)
			core.Size = Vector3.new(0.4 * s + 0.01, 5.9 * (0.6 + 0.4 * math.min(1, fly)) * s + 0.01, 0.4 * s + 0.01)
			shard.CFrame, core.CFrame = cf, cf
			shard.Transparency = 0.15 + 0.2 * math.sin(age * 18) ^ 2
			core.Transparency = 0.3
		end, function()
			sparks(shard.Position, 10, color, P.White, 25, 0.35)
			shard:Destroy()
			core:Destroy()
		end)
	end
end

--------------------------------------------------------------------------------
-- Move choreography (identical on every client)
--------------------------------------------------------------------------------

local MOVE_FX = {}

local function slashFX(style)
	return function(character, root, M)
		FX.Trails(character, M.duration)
		playSound(Config.Sounds.Swing, root, 0.92 + math.random() * 0.22 + (style == 3 and -0.12 or 0))
		task.delay(M.hitTime * 0.7, function()
			if not root.Parent then
				return
			end
			local cf = root.CFrame
			if style == 1 then
				FX.PrismSlash(cf * CFrame.new(0, 0.8, -0.6) * CFrame.Angles(0, 0, rad(40)), 6.5, 150, 1.9, 25)
			elseif style == 2 then
				FX.PrismSlash(cf * CFrame.new(0, 0.7, -0.6) * CFrame.Angles(0, 0, rad(-35)), 6.5, 150, 1.9, -25)
			else
				for i = 0, 2 do
					FX.PrismSlash(cf * CFrame.new(0, 0.1, 0) * CFrame.Angles(0, i * TAU / 3, 0), 7.5, 125, 2.4, 40)
				end
				local ground, hit = groundBelow(root.Position, 8)
				if hit then
					shockRing(CFrame.new(ground + Vector3.new(0, 0.2, 0)), 22, P.Prism, 0.35)
				end
				flashLight(root.Position, P.Prism, 6, 16, 0.3)
			end
		end)
	end
end
MOVE_FX.Slash1 = slashFX(1)
MOVE_FX.Slash2 = slashFX(2)
MOVE_FX.Slash3 = slashFX(3)

function MOVE_FX.PhaseStep(character, root, M, _extra, isLocal)
	local from = root.Position
	playSound(Config.Sounds.Lunge, root, 1.15)
	glowPuff(from, 7, P.Prism, 0.3)
	local ground, hit = groundBelow(from, 8)
	if hit then
		shockRing(CFrame.new(ground + Vector3.new(0, 0.2, 0)), 12, P.Prism, 0.3)
	end
	FX.Trails(character, M.duration)
	if isLocal then
		FX.FovKick(12, 0.4)
	end
	local count = M.afterimages
	local made = 0
	run(M.dashTime, function(a)
		local want = math.floor(a * count + 0.001)
		while made < want and character.Parent do
			made += 1
			afterimage(character, CYCLE[(made - 1) % 4 + 1], 0.32 + made * 0.03)
		end
	end, function()
		if root.Parent then
			streak(from + Vector3.new(0, 0.5, 0), root.Position + Vector3.new(0, 0.5, 0), 3.5, P.Rift, P.Prism, 0.3)
			glowPuff(root.Position, 5, P.Rift, 0.25)
		end
	end)
end

function MOVE_FX.RiftTear(character, root, M, extra)
	local cf = typeof(extra.cf) == "CFrame" and extra.cf or root.CFrame * CFrame.new(0, 1.5, -M.distance)
	FX.Charge(character, M.cleaveTime)
	FX.Trails(character, 0.5)
	local st = findSword(character)
	if st and st.tip then
		local tipPos = st.tip.WorldPosition
		burstAt(tipPos, 30, {
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
			Color = CS(P.Rift, P.White),
			Size = NS(0, 0.4, 1, 0),
			Speed = NR(10, 14),
			Lifetime = NR(0.2, 0.25),
			Brightness = 3,
		}, 0.6)
	end
	task.delay(M.cleaveTime * 0.8, function()
		if not root.Parent then
			return
		end
		playSound(Config.Sounds.Swing, root, 0.75)
		FX.PrismSlash(root.CFrame * CFrame.new(0, 1, -1) * CFrame.Angles(0, 0, rad(90)), 7, 160, 2.6, 30)
	end)
	task.delay(M.cleaveTime, function()
		FX.RiftTear(cf, M.detonateTime - M.cleaveTime, M.radius)
	end)
end

function MOVE_FX.PrismNova(character, root, M)
	FX.Trails(character, M.duration)
	FX.Charge(character, M.slamTime)
	burstAt(root.Position, 50, {
		Shape = Enum.ParticleEmitterShape.Sphere,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
		ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		Color = CS(P.Prism, P.Rift, P.Solar),
		Size = NS(0, 0.5, 1, 0),
		Speed = NR(24, 30),
		Lifetime = NR(0.12, 0.16),
		Brightness = 3,
	}, 0.5)

	task.delay(M.leapTime, function()
		if not root.Parent then
			return
		end
		playSound(Config.Sounds.Lunge, root, 0.85)
		local ground, hit = groundBelow(root.Position, 8)
		if hit then
			shockRing(CFrame.new(ground + Vector3.new(0, 0.2, 0)), 16, P.Rift, 0.35)
		end
		streak(root.Position - Vector3.new(0, 3, 0), root.Position + Vector3.new(0, 10, 0), 2.5, P.Rift, P.Solar, 0.35)
		-- spiral of prism sparks while airborne
		local att = Instance.new("Attachment")
		att.Parent = root
		local spiral = emitter(att, {
			Color = CS(P.Rift, P.Prism, P.Solar),
			Size = NS(0, 0.5, 1, 0),
			Speed = NR(6, 10),
			Lifetime = NR(0.25, 0.4),
			SpreadAngle = Vector2.new(180, 180),
			Rate = 140,
			Brightness = 3,
		})
		spiral.Enabled = true
		task.delay(M.diveTime - M.leapTime, function()
			spiral.Enabled = false
			Debris:AddItem(att, 0.5)
		end)
	end)

	task.delay(M.diveTime, function()
		if not root.Parent then
			return
		end
		playSound(Config.Sounds.Swing, root, 0.7)
		FX.PrismSlash(root.CFrame * CFrame.new(0, 0, -1) * CFrame.Angles(0, 0, rad(90)), 8, 170, 3, 40)
	end)

	task.delay(M.slamTime, function()
		if not root.Parent then
			return
		end
		FX.NovaImpact(root.Position, M.radius, M.shards)
	end)
end

--------------------------------------------------------------------------------
-- Public entry points
--------------------------------------------------------------------------------

-- Plays a move's animation and VFX on any character. Called directly by the wielder (instant)
-- and via the server broadcast on every other client.
function FX.PlayMove(character, moveName, extra)
	if typeof(character) ~= "Instance" or not character.Parent then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	local M = Config.Moves[moveName]
	if not root or not M then
		return
	end
	local isLocal = character == player.Character
	if not isLocal and distanceToCamera(root.Position) > Config.MaxVFXDistance then
		return
	end
	FX.Init()
	scanSwords()
	Anim.Play(character, moveName)
	local handler = MOVE_FX[moveName]
	if handler then
		handler(character, root, M, type(extra) == "table" and extra or {}, isLocal)
	end
end

local started = false
function FX.Init()
	if started then
		return
	end
	started = true

	if Config.AddBloom and not Lighting:FindFirstChildOfClass("BloomEffect") then
		local bloom = Instance.new("BloomEffect")
		bloom.Name = "RiftbrandBloom"
		bloom.Intensity = 0.7
		bloom.Size = 26
		bloom.Threshold = 0.95
		bloom.Parent = Lighting
	end

	RunService.RenderStepped:Connect(function(dt)
		local now = os.clock()
		for i = #active, 1, -1 do
			local e = active[i]
			local age = now - e.start
			local a = math.clamp(age / e.duration, 0, 1)
			local ok, err = pcall(e.fn, a, age, dt)
			if a >= 1 or not ok then
				table.remove(active, i)
				if e.cleanup then
					local ok2, err2 = pcall(e.cleanup)
					if not ok2 then
						warn("[Riftbrand] cleanup:", err2)
					end
				end
				if not ok then
					warn("[Riftbrand] effect:", err)
				end
			end
		end
		updateSwords(now)
		updateScreen()
	end)

	RunService:BindToRenderStep("RiftbrandShake", Enum.RenderPriority.Camera.Value + 1, applyShake)

	task.spawn(function()
		while true do
			scanSwords()
			task.wait(0.3)
		end
	end)
end

return FX
