--[[
	RIFTBRAND — RiftFXListener (LocalScript; the server copies it into each player's PlayerGui)
	Renders other players' Riftbrand moves, hit impacts and knockback on this client.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("RiftbrandShared")
local FX = require(shared:WaitForChild("RiftFX"))
local remote = shared:WaitForChild("RiftRemote")
local player = Players.LocalPlayer

FX.Init()

remote.OnClientEvent:Connect(function(action, a, b, c, d)
	if action == "Play" then
		FX.PlayMove(a, b, c)
	elseif action == "Hit" then
		FX.Hit(a, b, c == player, d)
	elseif action == "Knock" then
		FX.Knock(a)
	end
end)
