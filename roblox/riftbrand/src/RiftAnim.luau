--[[
	RIFTBRAND — RiftAnim
	Procedural keyframe animation for R15 rigs. Poses are written to Motor6D.Transform
	every PreSimulation, layered over whatever the Animator is playing, so:
	  • nothing has to be uploaded — the sword works the moment you drop it in
	  • legs keep running under the slashes, and moves chain from wherever the last one ended
	  • every client runs the same keyframes for every sword-holder, so everyone sees them

	Angles are degrees, applied YXZ in the parent joint's space (R15 joints are axis-aligned):
	  X+ swings a limb forward, Y+ turns it toward the character's left, Z+ rolls it outward-right.
	Root also takes a position offset (px, py, pz) in studs.
]]

local RunService = game:GetService("RunService")

local Anim = {}

local JOINTS = {
	Root = { "LowerTorso", "Root" },
	Waist = { "UpperTorso", "Waist" },
	Neck = { "Head", "Neck" },
	RS = { "RightUpperArm", "RightShoulder" },
	RE = { "RightLowerArm", "RightElbow" },
	RW = { "RightHand", "RightWrist" },
	LS = { "LeftUpperArm", "LeftShoulder" },
	LE = { "LeftLowerArm", "LeftElbow" },
	LW = { "LeftHand", "LeftWrist" },
	RH = { "RightUpperLeg", "RightHip" },
	RK = { "RightLowerLeg", "RightKnee" },
	LH = { "LeftUpperLeg", "LeftHip" },
	LK = { "LeftLowerLeg", "LeftKnee" },
}

-- Sword-ready stance, layered on while the Tool is equipped.
local HOLD = {
	RS = { 25, 0, 8 },
	RE = { 55, 0, 0 },
	RW = { -20, 0, 0 },
	LS = { 8, 0, -6 },
	LE = { 20, 0, 0 },
	Waist = { 0, -8, 0 },
}

local READY = {
	Root = { 0, 0, 0, 0, 0, 0 },
	Waist = { 0, -8, 0 },
	Neck = { 0, 0, 0 },
	RS = { 25, 0, 8 },
	RE = { 55, 0, 0 },
	RW = { -20, 0, 0 },
	LS = { 8, 0, -6 },
	LE = { 20, 0, 0 },
	RH = { 0, 0, 0 },
	RK = { 0, 0, 0 },
	LH = { 0, 0, 0 },
	LK = { 0, 0, 0 },
}

local function ready(extra)
	local k = {}
	for j, v in READY do
		k[j] = v
	end
	if extra then
		for j, v in extra do
			k[j] = v
		end
	end
	return k
end

local function key(t, ease, pose)
	pose.t = t
	pose.ease = ease
	return pose
end

-- Keyframes. `ease` shapes the curve INTO that key: "outback" snaps and overshoots (strikes),
-- "out" decelerates, "inout" for wind-ups and recoveries, "linear" for holds and spins.
local MOVES = {
	Slash1 = {
		key(0.08, "inout", {
			Root = { 0, -10, 0, 0, -0.1, 0 },
			Waist = { -5, -35, -6 },
			Neck = { 0, 25, 0 },
			RS = { 155, -40, 25 },
			RE = { 65, 0, 0 },
			RW = { 15, 0, 0 },
			LS = { 35, 0, -30 },
			LE = { 45, 0, 0 },
		}),
		key(0.15, "outback", {
			Root = { -6, 12, 0, 0, -0.25, -0.35 },
			Waist = { -12, 40, 8 },
			Neck = { 0, -30, 0 },
			RS = { 45, 60, -5 },
			RE = { 8, 0, 0 },
			RW = { -60, 0, 0 },
			LS = { -20, 0, -40 },
			LE = { 25, 0, 0 },
			RH = { 25, 0, 0 },
			RK = { -30, 0, 0 },
			LH = { -15, 0, 0 },
		}),
		key(0.30, "inout", ready()),
	},
	Slash2 = {
		key(0.07, "inout", {
			Root = { 0, 15, 0, 0, 0, 0 },
			Waist = { -4, 45, 4 },
			Neck = { 0, -20, 0 },
			RS = { 25, 75, -10 },
			RE = { 25, 0, 0 },
			RW = { -55, 0, 0 },
			LS = { 10, 0, -20 },
			LE = { 30, 0, 0 },
		}),
		key(0.16, "outback", {
			Root = { -4, -14, 0, 0, -0.15, -0.35 },
			Waist = { 8, -45, -10 },
			Neck = { 0, 25, 0 },
			RS = { 150, -55, 30 },
			RE = { 12, 0, 0 },
			RW = { 5, 0, 0 },
			LS = { 20, 0, -45 },
			LE = { 15, 0, 0 },
			LH = { 25, 0, 0 },
			LK = { -30, 0, 0 },
			RH = { -10, 0, 0 },
		}),
		key(0.30, "inout", ready()),
	},
	Slash3 = {
		key(0.10, "inout", {
			Root = { 0, 40, 0, 0, -0.3, 0 },
			Waist = { -6, 25, 0 },
			RS = { 90, -85, 0 },
			RE = { 5, 0, 0 },
			RW = { -85, 0, 0 },
			LS = { 60, 40, -10 },
			LE = { 50, 0, 0 },
			RH = { 30, 0, 0 },
			RK = { -45, 0, 0 },
			LH = { 30, 0, 0 },
			LK = { -45, 0, 0 },
		}),
		key(0.18, "linear", {
			Root = { 0, -150, 0, 0, 0.5, 0 },
			Waist = { -4, -10, 0 },
			RH = { 45, 0, 0 },
			RK = { -70, 0, 0 },
			LH = { 45, 0, 0 },
			LK = { -70, 0, 0 },
		}),
		key(0.28, "out", {
			Root = { 0, -340, 0, 0, 0.3, -0.2 },
			Waist = { -10, -20, 0 },
			RS = { 85, -60, 0 },
		}),
		key(0.34, "out", {
			Root = { 0, -360, 0, 0, -0.35, -0.2 },
			Waist = { -15, -10, 0 },
			RS = { 70, -30, 0 },
			RW = { -70, 0, 0 },
			RH = { 35, 0, 0 },
			RK = { -50, 0, 0 },
			LH = { -10, 0, 0 },
			LK = { -20, 0, 0 },
		}),
		key(0.46, "inout", ready({ Root = { 0, -360, 0, 0, 0, 0 } })),
	},
	PhaseStep = {
		key(0.05, "out", {
			Root = { -28, 0, 0, 0, -0.35, 0 },
			Waist = { -10, 0, 0 },
			Neck = { 15, 0, 0 },
			RS = { -55, 0, 20 },
			RE = { 15, 0, 0 },
			RW = { -40, 0, 0 },
			LS = { -50, 0, -20 },
			LE = { 20, 0, 0 },
			RH = { 35, 0, 0 },
			RK = { -60, 0, 0 },
			LH = { -30, 0, 0 },
			LK = { -35, 0, 0 },
		}),
		key(0.20, "linear", {
			Root = { -24, 0, 0, 0, -0.3, 0 },
		}),
		key(0.32, "inout", ready()),
	},
	RiftTear = {
		key(0.22, "inout", {
			Root = { 0, 0, 0, 0, 0.15, 0 },
			Waist = { 18, 0, 0 },
			Neck = { -10, 0, 0 },
			RS = { 170, -10, 10 },
			RE = { 45, 0, 0 },
			RW = { 25, 0, 0 },
			LS = { 165, 15, -10 },
			LE = { 50, 0, 0 },
			RH = { -10, 0, 0 },
			LH = { 15, 0, 0 },
			LK = { -10, 0, 0 },
		}),
		key(0.30, "outback", {
			Root = { -10, 0, 0, 0, -0.7, -0.4 },
			Waist = { -28, 0, 0 },
			Neck = { 15, 0, 0 },
			RS = { 55, 15, 0 },
			RE = { 0, 0, 0 },
			RW = { -75, 0, 0 },
			LS = { 55, 25, 0 },
			LE = { 10, 0, 0 },
			RH = { 55, 0, 0 },
			RK = { -80, 0, 0 },
			LH = { -5, 0, 0 },
			LK = { -50, 0, 0 },
		}),
		key(0.70, "linear", {
			Root = { -8, 0, 0, 0, -0.6, -0.4 },
			Waist = { -24, 0, 0 },
		}),
		key(0.80, "inout", {
			Root = { 0, 0, 0, 0, -0.3, 0 },
			Waist = { -10, 0, 0 },
			RS = { 95, -50, 20 },
			RE = { 20, 0, 0 },
			LS = { 95, 50, -20 },
			LE = { 20, 0, 0 },
		}),
		key(0.95, "inout", ready()),
	},
	PrismNova = {
		key(0.10, "inout", {
			Root = { -15, 0, 0, 0, -0.8, 0 },
			Waist = { -15, 0, 0 },
			RS = { -40, 0, 20 },
			LS = { -40, 0, -20 },
			RH = { 70, 0, 0 },
			RK = { -100, 0, 0 },
			LH = { 70, 0, 0 },
			LK = { -100, 0, 0 },
		}),
		key(0.20, "out", {
			Root = { 10, 0, 0, 0, 0.3, 0 },
			Waist = { 12, 0, 0 },
			RS = { 175, 0, 10 },
			RE = { 10, 0, 0 },
			RW = { 0, 0, 0 },
			LS = { 170, 0, -10 },
			RH = { -10, 0, 0 },
			RK = { -10, 0, 0 },
			LH = { 20, 0, 0 },
			LK = { -30, 0, 0 },
		}),
		key(0.52, "linear", {
			Root = { -20, 720, 0, 0, 0.4, 0 },
			Waist = { -10, 0, 0 },
			RS = { 90, -80, 0 },
			RW = { -85, 0, 0 },
			LS = { 30, 0, 0 },
			RH = { 60, 0, 0 },
			RK = { -90, 0, 0 },
			LH = { 60, 0, 0 },
			LK = { -90, 0, 0 },
		}),
		key(0.62, "out", {
			Root = { 0, 720, 0, 0, 0.4, 0 },
			Waist = { 20, 0, 0 },
			RS = { 175, -10, 10 },
			RE = { 40, 0, 0 },
			RW = { 25, 0, 0 },
			LS = { 170, 15, -10 },
			LE = { 45, 0, 0 },
		}),
		key(0.75, "outback", {
			Root = { -12, 720, 0, 0, -0.9, -0.3 },
			Waist = { -35, 0, 0 },
			RS = { 40, 10, 0 },
			RE = { 0, 0, 0 },
			RW = { -90, 0, 0 },
			LS = { 45, 20, 0 },
			LE = { 10, 0, 0 },
			RH = { 75, 0, 0 },
			RK = { -110, 0, 0 },
			LH = { 10, 0, 0 },
			LK = { -70, 0, 0 },
		}),
		key(0.95, "linear", {
			Root = { -10, 720, 0, 0, -0.8, -0.3 },
		}),
		key(1.15, "inout", ready({ Root = { 0, 720, 0, 0, 0, 0 } })),
	},
}

local EASE = {
	linear = function(x)
		return x
	end,
	out = function(x)
		return 1 - (1 - x) ^ 3
	end,
	inout = function(x)
		if x < 0.5 then
			return 4 * x ^ 3
		end
		return 1 - (-2 * x + 2) ^ 3 / 2
	end,
	outback = function(x)
		local c1 = 1.70158
		local c3 = c1 + 1
		return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
	end,
}

local rad = math.rad
local FADE_IN = 0.05
local FADE_OUT = 0.10

local function toCF(v)
	local cf = CFrame.fromEulerAnglesYXZ(rad(v[1]), rad(v[2]), rad(v[3]))
	if v[4] then
		cf = CFrame.new(v[4], v[5], v[6]) * cf
	end
	return cf
end

local function wrapNear(value, target)
	return value - 360 * math.floor((value - target) / 360 + 0.5)
end

local rigs = {}

local function getRig(character)
	local st = rigs[character]
	if st then
		return st
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return nil
	end
	st = {
		character = character,
		humanoid = humanoid,
		root = character:FindFirstChild("HumanoidRootPart"),
		motors = {},
		written = {},
		cur = {},
		hold = false,
		holdW = 0,
		track = nil,
		timeScale = 1,
		slowUntil = 0,
	}
	for name, path in JOINTS do
		local part = character:FindFirstChild(path[1])
		local motor = part and part:FindFirstChild(path[2])
		if motor and motor:IsA("Motor6D") then
			st.motors[name] = motor
		end
	end
	rigs[character] = st
	character.Destroying:Connect(function()
		rigs[character] = nil
	end)
	return st
end

-- Plays a move on any R15 character. Returns the move's duration, or nil if the rig can't be animated.
function Anim.Play(character, moveName, speed)
	local keys = MOVES[moveName]
	local st = character and getRig(character)
	if not keys or not st then
		return nil
	end

	-- Every joint any key touches is driven for the whole move; missing values carry forward.
	local joints = {}
	for _, k in keys do
		for j, v in k do
			if type(v) == "table" then
				joints[j] = true
			end
		end
	end

	local first = keys[1]
	local k0 = { t = 0, ease = "linear" }
	for j in joints do
		local start = st.cur[j] or HOLD[j] or READY[j] or { 0, 0, 0 }
		local target = first[j]
		local s = table.clone(start)
		if target then
			for i = 1, 3 do
				s[i] = wrapNear(s[i], target[i] or 0)
			end
		end
		k0[j] = s
	end

	local filled = { k0 }
	local prev = k0
	for _, k in keys do
		local f = { t = k.t, ease = k.ease }
		for j in joints do
			f[j] = k[j] or prev[j]
		end
		table.insert(filled, f)
		prev = f
	end

	st.track = {
		keys = filled,
		joints = joints,
		t = 0,
		duration = keys[#keys].t,
		speed = speed or 1,
	}
	return st.track.duration / (speed or 1)
end

function Anim.Stop(character)
	local st = rigs[character]
	if st then
		st.track = nil
	end
end

function Anim.SetHold(character, on)
	local st = character and getRig(character)
	if st then
		st.hold = on
	end
end

-- Freezes the move for a few frames on impact. Tiny, but it's what makes hits feel heavy.
function Anim.HitStop(character, duration)
	local st = rigs[character]
	if st then
		st.slowUntil = os.clock() + (duration or 0.06)
	end
end

function Anim.IsPlaying(character)
	local st = rigs[character]
	return st ~= nil and st.track ~= nil
end

local function sample(track)
	local keys = track.keys
	local t = track.t
	local a, b = keys[1], keys[#keys]
	for i = 1, #keys - 1 do
		if t <= keys[i + 1].t then
			a, b = keys[i], keys[i + 1]
			break
		end
	end
	local span = b.t - a.t
	local x = span > 0 and math.clamp((t - a.t) / span, 0, 1) or 1
	local e = (EASE[b.ease] or EASE.inout)(x)
	local out = {}
	for j in track.joints do
		local va, vb = a[j], b[j]
		local v = {}
		for i = 1, 6 do
			local p, q = va[i], vb[i]
			if p or q then
				p = p or 0
				q = q or 0
				v[i] = p + (q - p) * e
			end
		end
		if v[4] or v[5] or v[6] then
			v[4], v[5], v[6] = v[4] or 0, v[5] or 0, v[6] or 0
		end
		out[j] = v
	end
	return out
end

local function step(dt)
	local now = os.clock()
	for character, st in rigs do
		if not character.Parent or st.humanoid.Health <= 0 then
			st.track = nil
			continue
		end

		st.holdW = math.clamp(st.holdW + (st.hold and dt or -dt) * 8, 0, 1)

		local track = st.track
		local values, w
		if track then
			local scale = now < st.slowUntil and 0.06 or track.speed
			track.t += dt * scale
			if track.t >= track.duration then
				for j, v in sample(track) do
					st.cur[j] = { wrapNear(v[1], 0), wrapNear(v[2], 0), wrapNear(v[3], 0) }
				end
				st.track = nil
				track = nil
			else
				values = sample(track)
				w = math.min(1, track.t / FADE_IN)
				local left = track.duration - track.t
				if left < FADE_OUT then
					w = math.min(w, left / FADE_OUT)
				end
			end
		end

		if not track and st.holdW <= 0 then
			if next(st.written) then
				table.clear(st.written)
				table.clear(st.cur)
			end
			continue
		end

		-- Breathing + a forward lean that grows with run speed keeps the idle stance alive.
		local breath = math.sin(now * 2.4)
		local lean = 0
		if st.root then
			local v = st.root.AssemblyLinearVelocity
			lean = math.clamp(Vector3.new(v.X, 0, v.Z).Magnitude / 24, 0, 1)
		end

		for name, motor in st.motors do
			local base = motor.Transform
			local last = st.written[name]
			if last and base == last then
				base = CFrame.identity -- the Animator didn't touch this joint this frame
			end

			local target = base
			local touched = false
			local hv = HOLD[name]
			if hv and st.holdW > 0 then
				local h = hv
				if name == "RS" then
					h = { hv[1] + breath * 2, hv[2], hv[3] }
				elseif name == "Waist" then
					h = { hv[1] - lean * 9 + breath * 0.8, hv[2], hv[3] }
				end
				target = target:Lerp(toCF(h), st.holdW)
				st.cur[name] = h
				touched = true
			end

			local v = values and values[name]
			if v then
				target = target:Lerp(toCF(v), w)
				st.cur[name] = v
				touched = true
			end

			if touched then
				motor.Transform = target
				st.written[name] = target
			else
				st.written[name] = nil
			end
		end
	end
end

RunService.PreSimulation:Connect(step)

Anim.Moves = MOVES
return Anim
