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
--   TrainingThrow(gained: number, lane: number)  a training throw happened on this lane, strength was added
-- Server -> Client (to players NEAR the one who throws, never to the thrower)
--   OtherPlayerThrew(thrower: Player, kind: "Training" | "Main", lane: number?)
--                                    only for showing it; sent by the server from its own training
--                                    rhythm and its own throw check. There is no message a client
--                                    could send to make others see a throw.
--
-- Other ways a client asks the server for something (no RemoteEvent, but the same rules apply:
-- the server checks everything itself):
--   The button at a weapon shop pedestal (a ProximityPrompt made by the server, see
--   server/WeaponService): "I want to use this pedestal". The server decides whether that buys
--   the weapon, equips it, or does nothing.
--
-- Values the server shows to the client through attributes on the Player (read-only for the client;
-- attributes on a Player are visible to all players):
--   Strength: number
--   Currency: number
--   Rebirths: number
--   EquippedWeapon: string           id of the weapon in use (others need it to draw the right weapon)
--   OwnedWeapons: string             ids of the owned weapons, separated by commas

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
	"OtherPlayerThrew",
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
	OtherPlayerThrew = folder:WaitForChild("OtherPlayerThrew") :: RemoteEvent,

	-- Values for the "kind" of OtherPlayerThrew.
	ThrowKind = {
		Training = "Training",
		Main = "Main",
	},

	Attributes = {
		Strength = "Strength",
		Currency = "Currency",
		Rebirths = "Rebirths",
		EquippedWeapon = "EquippedWeapon",
		OwnedWeapons = "OwnedWeapons",
	},
}
