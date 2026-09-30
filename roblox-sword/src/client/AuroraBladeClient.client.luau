-- Camera shake for Aurora Blade hits and slams. Optional: the sword works without it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remote = ReplicatedStorage:WaitForChild("SwordFX")
local player = Players.LocalPlayer

local shakeId = 0

remote.OnClientEvent:Connect(function(kind, intensity, duration)
	if kind ~= "Shake" then
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then
		return
	end

	shakeId += 1
	local myId = shakeId
	local start = os.clock()

	task.spawn(function()
		while shakeId == myId do
			local t = (os.clock() - start) / duration
			if t >= 1 or hum.Parent == nil then
				break
			end
			local amp = intensity * (1 - t)
			hum.CameraOffset = Vector3.new((math.random() - 0.5) * amp, (math.random() - 0.5) * amp, 0)
			RunService.RenderStepped:Wait()
		end
		if shakeId == myId then
			hum.CameraOffset = Vector3.zero
		end
	end)
end)
