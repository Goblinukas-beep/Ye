--[[
	Builds Riftbrand.rbxmx from src/ with Lune (https://lune-org.github.io/docs).
	    lune run build.luau
	Lune's Roblox library checks every property name and type against the engine's reflection
	database, so a file this script writes is a file Studio can open.
]]

local fs = require("@lune/fs")
local roblox = require("@lune/roblox")

local Instance = roblox.Instance
local Vector3 = roblox.Vector3
local Vector2 = roblox.Vector2
local CFrame = roblox.CFrame
local Color3 = roblox.Color3
local NumberRange = roblox.NumberRange
local NumberSequence = roblox.NumberSequence
local NumberSequenceKeypoint = roblox.NumberSequenceKeypoint
local ColorSequence = roblox.ColorSequence
local ColorSequenceKeypoint = roblox.ColorSequenceKeypoint
local Enum = roblox.Enum

local HERE = "."
local SRC = HERE .. "/src/"

local RIFT = Color3.fromRGB(255, 43, 214)
local PRISM = Color3.fromRGB(32, 240, 255)
local SOLAR = Color3.fromRGB(255, 200, 61)
local ULTRA = Color3.fromRGB(123, 59, 255)
local VOID = Color3.fromRGB(6, 4, 14)
local WHITE = Color3.fromRGB(255, 246, 255)
local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"

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
	local kps = {}
	for i, c in a do
		table.insert(kps, ColorSequenceKeypoint.new((i - 1) / (#a - 1), c))
	end
	return ColorSequence.new(kps)
end

local function set(inst, props)
	for k, v in props do
		inst[k] = v
	end
	return inst
end

--------------------------------------------------------------------------------
-- Tool
--------------------------------------------------------------------------------

local tool = Instance.new("Tool")
set(tool, {
	Name = "Riftbrand",
	ToolTip = "Riftbrand — M1 combo · Q Phase Step · E Rift Tear · R Prism Nova",
	RequiresHandle = true,
	CanBeDropped = false,
	ManualActivationOnly = false,
	Grip = CFrame.new(0, 0.2, 0),
})
tool:SetAttribute("Riftbrand", true)

local ORIGIN = CFrame.new(0, 10, 0)

local handle = Instance.new("Part")
set(handle, {
	Name = "Handle",
	Size = Vector3.new(0.3, 1.3, 0.3),
	CFrame = ORIGIN,
	Color = Color3.fromRGB(26, 20, 40),
	Material = Enum.Material.SmoothPlastic,
	CanCollide = false,
	CanTouch = true,
	CanQuery = false,
	Massless = true,
	CastShadow = false,
	TopSurface = Enum.SurfaceType.Smooth,
	BottomSurface = Enum.SurfaceType.Smooth,
})
handle.Parent = tool

-- Every other piece is welded to the Handle; `local` is its CFrame in Handle space.
-- Blade runs along +Y, edges face ±Z, flats face ±X.
local function piece(className, name, localCF, size, color, material, extra)
	local p = Instance.new(className)
	set(p, {
		Name = name,
		Size = size,
		CFrame = ORIGIN * localCF,
		Color = color,
		Material = material,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Massless = true,
		CastShadow = false,
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	})
	if extra then
		set(p, extra)
	end
	local weld = Instance.new("Weld")
	weld.Name = "Weld"
	weld.Part0 = handle
	weld.Part1 = p
	weld.C0 = localCF
	weld.C1 = CFrame.new()
	weld.Parent = p
	p.Parent = tool
	return p
end

local Neon = Enum.Material.Neon
local rad = math.rad

-- Grip wraps
for i, y in { -0.42, -0.12, 0.18, 0.48 } do
	piece("Part", "GripWrap" .. i, CFrame.new(0, y, 0) * CFrame.Angles(0, 0, rad(90)), Vector3.new(0.06, 0.36, 0.36), SOLAR, Neon, {
		Shape = Enum.PartType.Cylinder,
	})
end

-- Pommel: a glass gold gem around a cyan neon core
local gem = CFrame.new(0, -0.88, 0) * CFrame.Angles(rad(45), 0, rad(45))
piece("Part", "PommelShell", gem, Vector3.new(0.42, 0.42, 0.42), SOLAR, Enum.Material.Glass, { Transparency = 0.25 })
piece("Part", "PommelCore", gem, Vector3.new(0.24, 0.24, 0.24), PRISM, Neon)

-- Rift Guard: dark block, gold gem through both flats, magenta + cyan horns
piece("Part", "RiftGuard", CFrame.new(0, 0.8, 0), Vector3.new(0.34, 0.3, 0.95), Color3.fromRGB(35, 27, 56), Enum.Material.Metal)
piece("Part", "GuardGem", CFrame.new(0, 0.8, 0) * CFrame.Angles(rad(45), 0, 0), Vector3.new(0.42, 0.22, 0.22), SOLAR, Neon)
piece("WedgePart", "WingRift", CFrame.new(0, 1.35, 0.475), Vector3.new(0.14, 1.0, 0.55), RIFT, Neon)
piece("WedgePart", "WingPrism", CFrame.new(0, 1.35, -0.475) * CFrame.Angles(0, rad(180), 0), Vector3.new(0.14, 1.0, 0.55), PRISM, Neon)

-- Blade: void core, ultraviolet ForceField shimmer, two neon rails, gold tip
local core = piece("Part", "VoidCore", CFrame.new(0, 2.95, 0), Vector3.new(0.08, 4.0, 0.36), VOID, Enum.Material.Glass, { Reflectance = 0.1 })
piece("Part", "VoidShimmer", CFrame.new(0, 2.95, 0), Vector3.new(0.11, 4.0, 0.34), ULTRA, Enum.Material.ForceField)
piece("Part", "RailRift", CFrame.new(0, 2.95, 0.215), Vector3.new(0.12, 4.0, 0.07), RIFT, Neon)
piece("Part", "RailPrism", CFrame.new(0, 2.95, -0.215), Vector3.new(0.12, 4.0, 0.07), PRISM, Neon)
piece("WedgePart", "TipRift", CFrame.new(0, 5.425, 0.125) * CFrame.Angles(0, rad(180), 0), Vector3.new(0.12, 0.95, 0.25), SOLAR, Neon)
piece("WedgePart", "TipPrism", CFrame.new(0, 5.425, -0.125), Vector3.new(0.12, 0.95, 0.25), SOLAR, Neon)

-- The rift crack: a gold lightning seam zig-zagging up the void
for i = 1, 7 do
	local y = 1.25 + (i - 1) * 0.56
	local sign = i % 2 == 0 and 1 or -1
	piece("Part", "RiftCrack" .. i, CFrame.new(0, y, 0.03 * sign) * CFrame.Angles(rad(15 * sign), 0, 0), Vector3.new(0.1, 0.6, 0.035), Color3.fromRGB(255, 236, 170), Neon)
end

--------------------------------------------------------------------------------
-- Attachments, beams, trails, particles, light
--------------------------------------------------------------------------------

local function attach(name, y)
	local a = Instance.new("Attachment")
	a.Name = name
	a.CFrame = CFrame.new(0, y, 0)
	a.Parent = handle
	return a
end

local base = attach("BladeBase", 1.0)
local tipEnd = attach("BladeTip", 5.75)
local tipFX = attach("TipFX", 5.95)
local coreFX = attach("CoreFX", 3.0)

local function beam(name, props)
	local b = Instance.new("Beam")
	set(b, {
		Name = name,
		Attachment0 = base,
		Attachment1 = tipEnd,
		FaceCamera = true,
		LightEmission = 1,
		LightInfluence = 0,
		Texture = SPARKLE,
		TextureMode = Enum.TextureMode.Wrap,
		Segments = 10,
		ZOffset = 0.05,
	})
	set(b, props)
	b.Parent = handle
end

-- Starlight river: sparkle texture flowing base → tip inside the void
beam("StarRiver", {
	Color = CS(PRISM, WHITE, PRISM),
	Width0 = 0.22,
	Width1 = 0.06,
	TextureLength = 0.8,
	TextureSpeed = 1.6,
	Brightness = 3,
	Transparency = NS(0, 0.15, 0.5, 0.05, 1, 0.4),
})
beam("EmberRiver", {
	Color = CS(RIFT, SOLAR),
	Width0 = 0.16,
	Width1 = 0.04,
	TextureLength = 1.3,
	TextureSpeed = 0.9,
	Brightness = 3,
	Transparency = NS(0, 0.3, 0.5, 0.1, 1, 0.5),
})

-- Chromatic triple trail: three nested ribbons with staggered lifetimes
local TRAILS = {
	{ 1.6, 5.85, 0.16, CS(WHITE, RIFT), NS(0, 0.1, 1, 1) },
	{ 2.3, 5.7, 0.24, CS(PRISM, ULTRA), NS(0, 0.25, 1, 1) },
	{ 3.1, 5.5, 0.34, CS(SOLAR, RIFT), NS(0, 0.45, 1, 1) },
}
for i, t in TRAILS do
	local a0 = attach("TrailA" .. i, t[1])
	local a1 = attach("TrailB" .. i, t[2])
	local trail = Instance.new("Trail")
	set(trail, {
		Name = "PrismTrail" .. i,
		Attachment0 = a0,
		Attachment1 = a1,
		Enabled = false,
		Lifetime = t[3],
		Color = t[4],
		Transparency = t[5],
		WidthScale = NS(0, 1, 1, 0.3),
		LightEmission = 1,
		LightInfluence = 0,
		Brightness = 4,
		MinLength = 0.05,
		FaceCamera = false,
	})
	trail.Parent = handle
end

local function particles(name, parent, props)
	local pe = Instance.new("ParticleEmitter")
	set(pe, {
		Name = name,
		Texture = SPARKLE,
		LightEmission = 1,
		LightInfluence = 0,
	})
	set(pe, props)
	pe.Parent = parent
end

particles("VoidMotes", core, {
	Rate = 18,
	Lifetime = NumberRange.new(0.5, 1.1),
	Speed = NumberRange.new(0.2, 0.8),
	SpreadAngle = Vector2.new(180, 180),
	Size = NS(0, 0.14, 0.5, 0.1, 1, 0),
	Transparency = NS(0, 0.1, 1, 1),
	Color = CS(PRISM, RIFT),
	Acceleration = Vector3.new(0, 1.2, 0),
	Drag = 1.5,
	Rotation = NumberRange.new(0, 360),
	RotSpeed = NumberRange.new(-90, 90),
	Brightness = 2,
})
particles("TipFlare", tipFX, {
	Rate = 5,
	Lifetime = NumberRange.new(0.3, 0.45),
	Speed = NumberRange.new(0, 0),
	Size = NS(0, 0, 0.3, 1.1, 1, 0),
	Transparency = NS(0, 0.1, 1, 0.1),
	Color = CS(SOLAR, WHITE),
	Rotation = NumberRange.new(0, 360),
	RotSpeed = NumberRange.new(-60, 60),
	LockedToPart = true,
	Brightness = 3,
	ZOffset = 0.3,
})
particles("TipBurst", tipFX, {
	Enabled = false,
	Rate = 0,
	Lifetime = NumberRange.new(0.2, 0.4),
	Speed = NumberRange.new(14, 28),
	Drag = 6,
	SpreadAngle = Vector2.new(180, 180),
	Size = NS(0, 0.35, 1, 0),
	Color = CS(RIFT, PRISM),
	Brightness = 3,
})

local light = Instance.new("PointLight")
set(light, {
	Name = "CoreLight",
	Color = Color3.fromRGB(200, 80, 255),
	Brightness = 1.8,
	Range = 8,
	Shadows = false,
})
light.Parent = coreFX

--------------------------------------------------------------------------------
-- Scripts
--------------------------------------------------------------------------------

local function script(className, name, file, disabled)
	local s = Instance.new(className)
	s.Name = name
	s.Source = fs.readFile(SRC .. file)
	if disabled ~= nil then
		s.Disabled = disabled
	end
	s.Parent = tool
	return s
end

script("ModuleScript", "Config", "Config.luau")
script("ModuleScript", "RiftAnim", "RiftAnim.luau")
script("ModuleScript", "RiftFX", "RiftFX.luau")
script("Script", "RiftInstaller", "RiftInstaller.server.luau", false)
script("Script", "RiftbrandServer", "RiftbrandServer.server.luau", true) -- template, enabled by the installer
script("LocalScript", "RiftClient", "RiftClient.client.luau", false)
script("LocalScript", "RiftFXListener", "RiftFXListener.client.luau", true) -- template, enabled per player

--------------------------------------------------------------------------------
-- Write
--------------------------------------------------------------------------------

local xml = roblox.serializeModel({ tool }, true)
fs.writeFile(HERE .. "/Riftbrand.rbxmx", xml)
local bin = roblox.serializeModel({ tool })
fs.writeFile(HERE .. "/Riftbrand.rbxm", bin)
print(("Wrote Riftbrand.rbxmx (%d bytes) and Riftbrand.rbxm (%d bytes), %d instances"):format(#xml, #bin, #tool:GetDescendants() + 1))
