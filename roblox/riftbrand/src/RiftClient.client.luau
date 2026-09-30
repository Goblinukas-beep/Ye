--[[
	RIFTBRAND — RiftClient (LocalScript inside the Tool)
	Input, combo logic, movement (lunges, dash, leap) and the ability HUD for the wielder.
	Moves play locally the instant you press (no waiting on the server), then the server
	validates, deals damage and replays them for everyone else.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local tool = script.Parent
local player = Players.LocalPlayer

local shared = ReplicatedStorage:WaitForChild("RiftbrandShared")
local Config = require(shared:WaitForChild("Config"))
local FX = require(shared:WaitForChild("RiftFX"))
local remote = shared:WaitForChild("RiftRemote")

FX.Init()

local P = Config.Palette
local ABILITIES = {
	{ name = "PhaseStep", label = "PHASE STEP", key = "Q", color = P.Prism },
	{ name = "RiftTear", label = "RIFT TEAR", key = "E", color = P.Solar },
	{ name = "PrismNova", label = "PRISM NOVA", key = "R", color = P.Ultra },
}

local state = {
	equipped = false,
	busyUntil = 0,
	cancelAt = math.huge, -- slashes can be dash-cancelled after they connect
	combo = 0,
	lastSlashEnd = 0,
	buffered = nil,
	m1Held = false,
	cooldowns = {},
	walkRestore = nil,
}

local hud -- { gui, slots = { [name] = { fill, timer } }, pips = {} }

local function getCharacter()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return nil
	end
	return char, hum, root
end

local function flatLook(v)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.05 and f.Unit or nil
end

local function faceDirection(root, dir)
	if dir then
		root.CFrame = CFrame.lookAt(root.Position, root.Position + dir)
	end
end

-- Drives horizontal velocity for `duration` seconds. Keeps vertical unless `lockY` is given.
local function drive(root, velocity, duration, lockY)
	local stop = os.clock() + duration
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if os.clock() >= stop or not root.Parent then
			conn:Disconnect()
			return
		end
		local y = lockY or root.AssemblyLinearVelocity.Y
		root.AssemblyLinearVelocity = Vector3.new(velocity.X, y, velocity.Z)
	end)
end

local function slowWalk(hum, factor, duration)
	if not state.walkRestore then
		state.walkRestore = hum.WalkSpeed
	end
	hum.WalkSpeed = state.walkRestore * factor
	task.delay(duration, function()
		if state.walkRestore and hum.Parent then
			hum.WalkSpeed = state.walkRestore
		end
		state.walkRestore = nil
	end)
end

--------------------------------------------------------------------------------
-- Moves
--------------------------------------------------------------------------------

local function execute(moveName)
	local char, hum, root = getCharacter()
	if not char or tool.Parent ~= char then
		return false
	end
	local M = Config.Moves[moveName]
	local now = os.clock()
	if M.cooldown and now < (state.cooldowns[moveName] or 0) then
		return false
	end

	local camLook = flatLook(Workspace.CurrentCamera.CFrame.LookVector)
	local extra = {}

	if moveName == "PhaseStep" then
		local dir = hum.MoveDirection.Magnitude > 0.1 and flatLook(hum.MoveDirection) or flatLook(root.CFrame.LookVector)
		faceDirection(root, dir)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char, Workspace:FindFirstChild("RiftbrandFX") }
		local hit = Workspace:Raycast(root.Position, dir * M.distance, params)
		local dist = hit and math.max(0, (hit.Position - root.Position).Magnitude - 2) or M.distance
		drive(root, dir * (dist / M.dashTime), M.dashTime, 0)
		task.delay(M.dashTime, function()
			if root.Parent then
				root.AssemblyLinearVelocity = dir * 22 + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			end
		end)
	else
		if Config.FaceCameraOnAttack then
			faceDirection(root, camLook)
		end
	end

	if moveName == "RiftTear" then
		extra.cf = root.CFrame * CFrame.new(0, 1.5, -M.distance)
		slowWalk(hum, 0.3, M.duration)
	elseif moveName == "PrismNova" then
		slowWalk(hum, 0.4, M.duration)
		task.delay(M.leapTime, function()
			if root.Parent then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				root.AssemblyLinearVelocity = Vector3.new(0, M.leapVelocity, 0) + root.CFrame.LookVector * 8
			end
		end)
		task.delay(M.diveTime, function()
			if root.Parent then
				root.AssemblyLinearVelocity = Vector3.new(0, M.diveVelocity, 0)
			end
		end)
	elseif M.lunge then
		task.delay(0.06, function()
			if root.Parent then
				drive(root, root.CFrame.LookVector * M.lunge, 0.1)
			end
		end)
	end

	FX.PlayMove(char, moveName, extra)
	remote:FireServer("Move", tool, moveName, extra.cf)

	state.busyUntil = now + M.duration + (M.endLag or 0)
	state.cancelAt = M.hitTime and (now + M.hitTime + 0.04) or math.huge
	if M.cooldown then
		state.cooldowns[moveName] = now + M.cooldown
	end
	if moveName:sub(1, 5) == "Slash" then
		state.lastSlashEnd = state.busyUntil
	end
	return true
end

local function nextSlash()
	local now = os.clock()
	if state.combo >= 3 or now - state.lastSlashEnd > Config.ComboWindow then
		state.combo = 0
	end
	state.combo += 1
	return "Slash" .. state.combo
end

local function request(moveName)
	if not state.equipped then
		return
	end
	local now = os.clock()
	local canDashCancel = moveName == "PhaseStep" and now >= state.cancelAt
	if now >= state.busyUntil or canDashCancel then
		state.buffered = nil
		if moveName == "M1" then
			local slash = nextSlash()
			if not execute(slash) then
				state.combo -= 1
			end
		else
			execute(moveName)
		end
	elseif state.busyUntil - now <= Config.InputBuffer then
		state.buffered = moveName
	end
end

--------------------------------------------------------------------------------
-- HUD
--------------------------------------------------------------------------------

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function buildHud()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RiftbrandHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -18)
	bar.Size = UDim2.fromOffset(3 * 76 + 2 * 10, 104)
	bar.BackgroundTransparency = 1
	bar.Parent = gui

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.Padding = UDim.new(0, 10)
	list.Parent = bar

	local slots = {}
	for _, a in ABILITIES do
		local slot = Instance.new("Frame")
		slot.Size = UDim2.fromOffset(76, 76)
		slot.BackgroundColor3 = Color3.fromRGB(17, 14, 31)
		slot.BackgroundTransparency = 0.1
		slot.ClipsDescendants = true
		slot.Parent = bar
		corner(slot, 14)
		local stroke = Instance.new("UIStroke")
		stroke.Color = a.color
		stroke.Thickness = 2
		stroke.Parent = slot

		local fill = Instance.new("Frame")
		fill.AnchorPoint = Vector2.new(0, 1)
		fill.Position = UDim2.fromScale(0, 1)
		fill.Size = UDim2.fromScale(1, 0)
		fill.BackgroundColor3 = Color3.new(0, 0, 0)
		fill.BackgroundTransparency = 0.35
		fill.BorderSizePixel = 0
		fill.ZIndex = 3
		fill.Parent = slot

		local key = Instance.new("TextLabel")
		key.BackgroundColor3 = a.color
		key.Size = UDim2.fromOffset(24, 20)
		key.Position = UDim2.fromOffset(6, 6)
		key.Font = Enum.Font.GothamBlack
		key.Text = a.key
		key.TextSize = 13
		key.TextColor3 = Color3.fromRGB(7, 6, 15)
		key.ZIndex = 2
		key.Parent = slot
		corner(key, 5)

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 1)
		label.Position = UDim2.new(0.5, 0, 1, -6)
		label.Size = UDim2.new(1, -8, 0, 26)
		label.Font = Enum.Font.GothamBold
		label.Text = a.label
		label.TextWrapped = true
		label.TextSize = 11
		label.TextColor3 = Color3.fromRGB(243, 238, 255)
		label.ZIndex = 2
		label.Parent = slot

		local timer = Instance.new("TextLabel")
		timer.BackgroundTransparency = 1
		timer.Size = UDim2.fromScale(1, 1)
		timer.Font = Enum.Font.GothamBlack
		timer.TextSize = 24
		timer.TextColor3 = Color3.fromRGB(255, 255, 255)
		timer.Text = ""
		timer.ZIndex = 4
		timer.Parent = slot

		slots[a.name] = { fill = fill, timer = timer, stroke = stroke, color = a.color }
	end

	local pipRow = Instance.new("Frame")
	pipRow.AnchorPoint = Vector2.new(0.5, 1)
	pipRow.Position = UDim2.new(0.5, 0, 1, -104)
	pipRow.Size = UDim2.fromOffset(90, 10)
	pipRow.BackgroundTransparency = 1
	pipRow.Parent = gui
	local pipList = Instance.new("UIListLayout")
	pipList.FillDirection = Enum.FillDirection.Horizontal
	pipList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pipList.Padding = UDim.new(0, 8)
	pipList.Parent = pipRow
	local pips = {}
	for i = 1, 3 do
		local pip = Instance.new("Frame")
		pip.Size = UDim2.fromOffset(22, 6)
		pip.BackgroundColor3 = Color3.fromRGB(60, 52, 90)
		pip.BorderSizePixel = 0
		pip.Parent = pipRow
		corner(pip, 3)
		pips[i] = pip
	end

	gui.Parent = player:WaitForChild("PlayerGui")
	return { gui = gui, slots = slots, pips = pips }
end

local PIP_COLORS = { P.Rift, P.Prism, P.Solar }

local function updateHud(now)
	if not hud then
		return
	end
	for name, s in hud.slots do
		local M = Config.Moves[name]
		local left = (state.cooldowns[name] or 0) - now
		if left > 0 then
			s.fill.Size = UDim2.fromScale(1, left / M.cooldown)
			s.timer.Text = string.format(left >= 1 and "%d" or "%.1f", left >= 1 and math.ceil(left) or left)
			s.stroke.Transparency = 0.6
		else
			s.fill.Size = UDim2.fromScale(1, 0)
			s.timer.Text = ""
			s.stroke.Transparency = 0.15 + 0.15 * math.sin(now * 4)
		end
	end
	local comboLive = now - state.lastSlashEnd <= Config.ComboWindow
	for i, pip in hud.pips do
		local lit = comboLive and i <= state.combo
		pip.BackgroundColor3 = lit and PIP_COLORS[i] or Color3.fromRGB(60, 52, 90)
	end
end

--------------------------------------------------------------------------------
-- Bindings
--------------------------------------------------------------------------------

local function bindAbilities()
	for _, a in ABILITIES do
		local actionName = "Riftbrand" .. a.name
		ContextActionService:BindAction(actionName, function(_, inputState)
			if inputState == Enum.UserInputState.Begin then
				request(a.name)
			end
			return Enum.ContextActionResult.Sink
		end, true, table.unpack(Config.Keys[a.name]))
		ContextActionService:SetTitle(actionName, a.key)
	end
end

local function unbindAbilities()
	for _, a in ABILITIES do
		ContextActionService:UnbindAction("Riftbrand" .. a.name)
	end
end

tool.Equipped:Connect(function()
	state.equipped = true
	bindAbilities()
	if hud then
		hud.gui:Destroy()
	end
	hud = buildHud()
end)

tool.Unequipped:Connect(function()
	state.equipped = false
	state.m1Held = false
	state.buffered = nil
	unbindAbilities()
	if hud then
		hud.gui:Destroy()
		hud = nil
	end
	local char = player.Character
	if char then
		FX.Anim.Stop(char)
	end
end)

tool.Activated:Connect(function()
	state.m1Held = true
	request("M1")
end)

tool.Deactivated:Connect(function()
	state.m1Held = false
end)

RunService.Heartbeat:Connect(function()
	if not state.equipped then
		return
	end
	local now = os.clock()
	if now >= state.busyUntil then
		if state.buffered then
			request(state.buffered)
		elseif state.m1Held then
			request("M1") -- hold to keep the combo flowing
		end
	end
	updateHud(now)
end)

tool.AncestryChanged:Connect(function()
	if not tool:IsDescendantOf(game) then
		unbindAbilities()
		if hud then
			hud.gui:Destroy()
		end
	end
end)
