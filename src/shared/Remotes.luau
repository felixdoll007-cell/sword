--!strict
-- The ONLY place where messages between client and server are defined.
--
-- Client -> Server
--   ThrowRequested()               only the intent, no values
-- Server -> Client (only to the player who threw)
--   ThrowStarted(throwPower: number)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"
local EVENT_NAMES = { "ThrowRequested", "ThrowStarted" }

local folder: Instance
if RunService:IsServer() then
	folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in EVENT_NAMES do
		local event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = folder
	end
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild(FOLDER_NAME)
end

return {
	ThrowRequested = folder:WaitForChild("ThrowRequested") :: RemoteEvent,
	ThrowStarted = folder:WaitForChild("ThrowStarted") :: RemoteEvent,
}
