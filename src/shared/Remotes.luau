--!strict
-- The ONLY place where messages between client and server are defined.
-- All times are on the shared server clock (workspace:GetServerTimeNow()).
--
-- Client -> Server
--   MeterStartRequested()            first press: "I want to start the meter", no values
--   ThrowRequested(pressTime: number) second press: only WHEN it was pressed, never a factor
--   TrainingLeft()                   the player let go of the training pad; can only stop training
--   RebirthRequested()               "I want to rebirth", no values; the server checks everything
--   WeaponEquipRequested(weaponId: string)  "I want to equip this weapon" (items window). Only the
--                                    id; the server equips it only if the player owns it.
--                                    Nothing can be bought with this message.
--   EggHatchRequested()              "I want to hatch an egg at the egg stand", no values. The server
--                                    checks coins, room and that the player stands at the stand,
--                                    and rolls the pet.
--   PetEquipRequested(uid: number)   "equip this pet of mine, or take it off if it is equipped"
--   PetEquipBestRequested()          "equip my best pets", no values
--   PetDeleteRequested(uid: number)  "delete this pet of mine for good"
-- Server -> Client (only to the player who throws)
--   MeterStarted(startTime: number, startPhase: number)
--   ThrowStarted(throwPower: number, factor: number, perWall: { { currency, strength, zoneBonus } })
--                                    reward of each broken wall, so the client can show it during the flight
--   TrainingThrow(gained: number, lane: number)  a training throw happened on this lane, strength was added
--   EggHatched(petId: string)        this player's egg hatched into this pet (already paid and
--                                    added by the server); only for showing it
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
--   the weapon, equips it, or does nothing. This is the only way to buy a weapon.
--
-- Values the server shows to the client through attributes on the Player (read-only for the client;
-- attributes on a Player are visible to all players):
--   Strength: number
--   Currency: number
--   Rebirths: number
--   EquippedWeapon: string           id of the weapon in use (others need it to draw the right weapon)
--   OwnedWeapons: string             ids of the owned weapons, separated by commas
--   Pets: string                     the owned pets as "uid:id" pairs, separated by commas
--   EquippedPets: string             uids of the equipped pets, separated by commas (others need
--                                    this and Pets to draw the pets that follow a player)
--   EggsHatched: number              eggs hatched so far (decides the price of the next egg)

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
	"WeaponEquipRequested",
	"EggHatchRequested",
	"PetEquipRequested",
	"PetEquipBestRequested",
	"PetDeleteRequested",
	"EggHatched",
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
	WeaponEquipRequested = folder:WaitForChild("WeaponEquipRequested") :: RemoteEvent,
	EggHatchRequested = folder:WaitForChild("EggHatchRequested") :: RemoteEvent,
	PetEquipRequested = folder:WaitForChild("PetEquipRequested") :: RemoteEvent,
	PetEquipBestRequested = folder:WaitForChild("PetEquipBestRequested") :: RemoteEvent,
	PetDeleteRequested = folder:WaitForChild("PetDeleteRequested") :: RemoteEvent,
	EggHatched = folder:WaitForChild("EggHatched") :: RemoteEvent,
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
		Pets = "Pets",
		EquippedPets = "EquippedPets",
		EggsHatched = "EggsHatched",
	},
}
