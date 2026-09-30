--[[
	RIFTBRAND — Config
	Every tunable number lives here. Server and clients read the same table,
	so damage, timings and VFX stay in sync.
]]

local Config = {}

Config.ToolName = "Riftbrand"
Config.Attribute = "Riftbrand" -- attribute set on the Tool so every client can find equipped swords

Config.Palette = {
	Rift = Color3.fromRGB(255, 43, 214), -- magenta
	Prism = Color3.fromRGB(32, 240, 255), -- cyan
	Solar = Color3.fromRGB(255, 200, 61), -- gold
	Ultra = Color3.fromRGB(123, 59, 255), -- ultraviolet
	Void = Color3.fromRGB(6, 4, 14),
	White = Color3.fromRGB(255, 246, 255),
}

-- Built-in engine textures (ship with every Roblox client, no upload needed).
-- Swap any of these for your own rbxassetid:// decals if you want a custom look.
Config.Textures = {
	Sparkle = "rbxasset://textures/particles/sparkles_main.dds",
	Fire = "rbxasset://textures/particles/fire_main.dds",
	Smoke = "rbxasset://textures/particles/smoke_main.dds",
	Glow = "rbxasset://textures/particles/forcefield_glow_main.dds",
	Shockwave = "rbxasset://textures/particles/explosion01_shockwave_main.dds",
}

-- Built-in classic sword sounds. Put rbxassetid://... ids in the override slots to use your own.
Config.Sounds = {
	Swing = { id = "rbxasset://sounds/swordslash.wav", volume = 0.7 },
	Lunge = { id = "rbxasset://sounds/swordlunge.wav", volume = 0.8 },
	Equip = { id = "rbxasset://sounds/unsheath.wav", volume = 0.6 },
	Detonate = { id = "", volume = 1 }, -- optional: add an explosion sound id
	Slam = { id = "", volume = 1 }, -- optional: add an impact sound id
}

-- Inputs. M1 / tap / gamepad R2 use Tool.Activated.
Config.Keys = {
	PhaseStep = { Enum.KeyCode.Q, Enum.KeyCode.ButtonX },
	RiftTear = { Enum.KeyCode.E, Enum.KeyCode.ButtonY },
	PrismNova = { Enum.KeyCode.R, Enum.KeyCode.ButtonB },
}

Config.FriendlyFire = false -- same-Team players can't hurt each other
Config.FaceCameraOnAttack = true -- snap facing to camera look on every swing (feels agile)
Config.CameraShake = true
Config.ScreenFlash = true
Config.AddBloom = true -- adds a local BloomEffect if Lighting has none (makes Neon glow)
Config.DamageNumbers = true
Config.MaxVFXDistance = 350 -- other players' VFX beyond this distance are skipped

Config.ComboWindow = 0.7 -- seconds after a slash ends in which the next slash continues the combo
Config.InputBuffer = 0.22 -- presses this close to the end of a move are queued, not dropped

Config.Moves = {
	Slash1 = {
		duration = 0.30,
		hitTime = 0.12,
		damage = 16,
		box = Vector3.new(9, 7, 8),
		offset = CFrame.new(0, 0, -4.5),
		knockback = 18,
		lunge = 18,
	},
	Slash2 = {
		duration = 0.30,
		hitTime = 0.12,
		damage = 16,
		box = Vector3.new(9, 7, 8),
		offset = CFrame.new(0, 0, -4.5),
		knockback = 18,
		lunge = 18,
	},
	Slash3 = {
		duration = 0.46,
		hitTime = 0.22,
		damage = 28,
		radius = 9,
		knockback = 48,
		lunge = 10,
		endLag = 0.25,
	},
	PhaseStep = {
		duration = 0.32,
		dashTime = 0.20,
		distance = 26,
		cooldown = 2.5,
		afterimages = 6,
	},
	RiftTear = {
		duration = 0.95,
		cleaveTime = 0.30,
		cleaveDamage = 12,
		detonateTime = 0.90,
		distance = 9, -- studs in front of you where the tear opens
		radius = 14,
		damage = 38,
		knockback = 70,
		cooldown = 6,
	},
	PrismNova = {
		duration = 1.15,
		leapTime = 0.12,
		diveTime = 0.55,
		slamTime = 0.75,
		leapVelocity = 62,
		diveVelocity = -150,
		radius = 20,
		damage = 55,
		knockback = 90,
		shards = 8,
		cooldown = 14,
	},
}

return Config
