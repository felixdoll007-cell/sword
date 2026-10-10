--!strict
-- The ONLY place where messages between client and server are defined.
-- All times are on the shared server clock (workspace:GetServerTimeNow()).
--
-- Client -> Server
--   MeterStartRequested()            first press: "I want to start the meter", no values
--   ThrowRequested(pressTime: number) second press: only WHEN it was pressed, never a factor
--   TrainingLeft()                   the player let go of the training pad; can only stop training
--   RebirthRequested()               "I want to rebirth", no values; the server checks everything
-- Server -> Client (only to the player who throws)
--   MeterStarted(startTime: number, startPhase: number)
--   ThrowStarted(throwPower: number, factor: number, perWall: { { currency, strength, zoneBonus } })
--                                    reward of each broken wall, so the client can show it during the flight
--   TrainingThrow(gained: number)    a training throw happened, strength was added
--
-- Values the server shows to the client through attributes on the Player (read-only for the client):
--   Strength: number
--   Currency: number
--   Rebirths: number

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"
local EVENT_NAMES = {
	"MeterStartRequested",
	"ThrowRequested",
	"MeterStarted",
	"ThrowStarted",
	"TrainingThrow",
	"TrainingLeft",
	"RebirthRequested",
}

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
	MeterStartRequested = folder:WaitForChild("MeterStartRequested") :: RemoteEvent,
	ThrowRequested = folder:WaitForChild("ThrowRequested") :: RemoteEvent,
	MeterStarted = folder:WaitForChild("MeterStarted") :: RemoteEvent,
	ThrowStarted = folder:WaitForChild("ThrowStarted") :: RemoteEvent,
	TrainingThrow = folder:WaitForChild("TrainingThrow") :: RemoteEvent,
	TrainingLeft = folder:WaitForChild("TrainingLeft") :: RemoteEvent,
	RebirthRequested = folder:WaitForChild("RebirthRequested") :: RemoteEvent,

	Attributes = {
		Strength = "Strength",
		Currency = "Currency",
		Rebirths = "Rebirths",
	},
}
