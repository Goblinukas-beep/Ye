--[[
	RIFTBRAND — RiftbrandServer (runs from ServerScriptService; the Tool's installer puts it there)
	Validates every move (equipped, alive, cooldowns, rate limits), resolves hitboxes, deals damage,
	applies knockback and rebroadcasts the move so every other client renders it.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local shared = ReplicatedStorage:WaitForChild("RiftbrandShared")
local Config = require(shared:WaitForChild("Config"))
local remote = shared:WaitForChild("RiftRemote")
local listenerTemplate = shared:WaitForChild("RiftFXListener")

--------------------------------------------------------------------------------
-- Give every player the FX listener (so they see everyone's sword, not just their own)
--------------------------------------------------------------------------------

local function installListener(plr)
	local gui = plr:WaitForChild("PlayerGui", 60)
	if not gui or gui:FindFirstChild("RiftbrandFX") then
		return
	end
	local holder = Instance.new("ScreenGui")
	holder.Name = "RiftbrandFX"
	holder.ResetOnSpawn = false
	local listener = listenerTemplate:Clone()
	listener.Disabled = false
	listener.Parent = holder
	holder.Parent = gui
end

Players.PlayerAdded:Connect(function(plr)
	task.spawn(installListener, plr)
end)
for _, plr in Players:GetPlayers() do
	task.spawn(installListener, plr)
end

--------------------------------------------------------------------------------
-- Combat
--------------------------------------------------------------------------------

local playerState = {}
Players.PlayerRemoving:Connect(function(plr)
	playerState[plr] = nil
end)

local function getState(plr)
	local st = playerState[plr]
	if not st then
		st = { cooldowns = {}, lastSlash = 0 }
		playerState[plr] = st
	end
	return st
end

local function wielding(plr, tool)
	local char = plr.Character
	if not char or tool.Parent ~= char then
		return nil
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health <= 0 then
		return nil
	end
	return char, hum, root
end

local function canHit(attacker, humanoid)
	if humanoid.Health <= 0 then
		return false
	end
	local victim = Players:GetPlayerFromCharacter(humanoid.Parent)
	if victim and not Config.FriendlyFire and not attacker.Neutral and attacker.Team ~= nil and victim.Team == attacker.Team then
		return false
	end
	return true
end

local function collect(parts, attackerChar, attacker)
	local found, list = {}, {}
	for _, p in parts do
		local model = p:FindFirstAncestorOfClass("Model")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if hum and model ~= attackerChar and not found[hum] and canHit(attacker, hum) then
			local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
			if root then
				found[hum] = true
				table.insert(list, { humanoid = hum, root = root })
			end
		end
	end
	return list
end

local function overlapParams(attackerChar)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { attackerChar }
	local fx = Workspace:FindFirstChild("RiftbrandFX")
	if fx then
		table.insert(ignore, fx)
	end
	params.FilterDescendantsInstances = ignore
	return params
end

local function inBox(attacker, char, cf, size)
	return collect(Workspace:GetPartBoundsInBox(cf, size, overlapParams(char)), char, attacker)
end

local function inRadius(attacker, char, pos, radius)
	return collect(Workspace:GetPartBoundsInRadius(pos, radius, overlapParams(char)), char, attacker)
end

local function knock(target, velocity)
	local victim = Players:GetPlayerFromCharacter(target.humanoid.Parent)
	if victim then
		remote:FireClient(victim, "Knock", velocity) -- players own their own physics
	elseif not target.root.Anchored then
		target.root.AssemblyLinearVelocity = velocity
	end
end

local function strike(attacker, targets, damage, center, force, moveName)
	for _, t in targets do
		t.humanoid:TakeDamage(damage)
		if force and force ~= 0 then
			local away = t.root.Position - center
			away = Vector3.new(away.X, 0, away.Z)
			away = away.Magnitude > 0.1 and away.Unit or Vector3.zAxis
			knock(t, away * force + Vector3.new(0, math.abs(force) * 0.35, 0))
		end
		remote:FireAllClients("Hit", t.root.Position, moveName, attacker, damage)
	end
end

local RESOLVE = {}

local function slashResolver(moveName)
	return function(plr, tool, M)
		task.delay(M.hitTime, function()
			local char, _, root = wielding(plr, tool)
			if not char then
				return
			end
			local targets
			if M.radius then
				targets = inRadius(plr, char, root.Position, M.radius)
			else
				targets = inBox(plr, char, root.CFrame * M.offset, M.box)
			end
			strike(plr, targets, M.damage, root.Position, M.knockback, moveName)
		end)
	end
end
RESOLVE.Slash1 = slashResolver("Slash1")
RESOLVE.Slash2 = slashResolver("Slash2")
RESOLVE.Slash3 = slashResolver("Slash3")

function RESOLVE.PhaseStep() end

function RESOLVE.RiftTear(plr, tool, M, extra)
	local center = extra.cf.Position
	task.delay(M.cleaveTime, function()
		local char, _, root = wielding(plr, tool)
		if not char then
			return
		end
		strike(plr, inBox(plr, char, root.CFrame * CFrame.new(0, 0, -4), Vector3.new(6, 8, 8)), M.cleaveDamage, root.Position, 8, "Slash1")
		-- the tear inhales: drag everything nearby toward it
		for _, t in inRadius(plr, char, center, M.radius) do
			local pull = center - t.root.Position
			if pull.Magnitude > 1 then
				knock(t, pull.Unit * 30 + Vector3.new(0, 8, 0))
			end
		end
	end)
	task.delay(M.detonateTime, function()
		local plrChar = plr.Character
		if not plrChar then
			return
		end
		strike(plr, inRadius(plr, plrChar, center, M.radius), M.damage, center, M.knockback, "RiftTear")
	end)
end

function RESOLVE.PrismNova(plr, tool, M)
	task.delay(M.slamTime, function()
		local char, _, root = wielding(plr, tool)
		if not char then
			return
		end
		strike(plr, inRadius(plr, char, root.Position, M.radius), M.damage, root.Position, M.knockback, "PrismNova")
	end)
end

remote.OnServerEvent:Connect(function(plr, action, tool, moveName, arg)
	if action ~= "Move" or typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return
	end
	if tool:GetAttribute(Config.Attribute) ~= true or type(moveName) ~= "string" then
		return
	end
	local M = Config.Moves[moveName]
	local resolve = RESOLVE[moveName]
	if not M or not resolve then
		return
	end
	local char, _, root = wielding(plr, tool)
	if not char then
		return
	end

	local st = getState(plr)
	local now = os.clock()
	if M.cooldown then
		if now < (st.cooldowns[moveName] or 0) - 0.2 then
			return -- small tolerance for latency jitter
		end
		st.cooldowns[moveName] = now + M.cooldown
	end
	if moveName:sub(1, 5) == "Slash" then
		if now - st.lastSlash < 0.2 then
			return
		end
		st.lastSlash = now
	end

	local extra = {}
	if moveName == "RiftTear" then
		local fallback = root.CFrame * CFrame.new(0, 1.5, -M.distance)
		local cf = typeof(arg) == "CFrame" and arg or fallback
		if (cf.Position - fallback.Position).Magnitude > 16 then
			cf = fallback
		end
		extra.cf = cf
	end

	for _, other in Players:GetPlayers() do
		if other ~= plr then
			remote:FireClient(other, "Play", char, moveName, extra)
		end
	end
	resolve(plr, tool, M, extra)
end)
