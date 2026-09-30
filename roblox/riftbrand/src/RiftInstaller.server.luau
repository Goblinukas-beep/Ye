--[[
	RIFTBRAND — RiftInstaller (Script inside the Tool)
	Makes the Tool a true drop-in: the first copy that runs publishes the shared modules and
	RemoteEvent to ReplicatedStorage and starts RiftbrandServer in ServerScriptService.
	Every later copy sees they're already there and does nothing.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local tool = script.Parent

if not ReplicatedStorage:FindFirstChild("RiftbrandShared") then
	local shared = Instance.new("Folder")
	shared.Name = "RiftbrandShared"
	for _, name in { "Config", "RiftAnim", "RiftFX", "RiftFXListener" } do
		tool:WaitForChild(name):Clone().Parent = shared
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = "RiftRemote"
	remote.Parent = shared
	shared.Parent = ReplicatedStorage
end

if not ServerScriptService:FindFirstChild("RiftbrandServer") then
	local server = tool:WaitForChild("RiftbrandServer"):Clone()
	server.Parent = ServerScriptService
	server.Disabled = false
end
