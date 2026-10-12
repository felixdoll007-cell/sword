--!strict
-- Pets on the server: builds the egg stand and handles every wish about pets. The client only
-- states wishes ("hatch an egg", "equip this pet", "equip my best", "delete this pet"). Coins,
-- room in the inventory, ownership and the number of equipped pets are checked here with the
-- server's own values, and the server rolls which pet hatches.
--
-- The egg on the stand, its sign, the HATCH button and the hatching animation are drawn by
-- each client (client/EggStandView, client/HatchView). The pets that follow a player are also
-- drawn by each client (client/PetFollowView); the server only publishes who has which pets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local PetConfig = require(Shared.Config.Pets)
local Ui = require(Shared.Config.Ui)
local Pets = require(Shared.Rules.Pets)
local RateLimit = require(Shared.Rules.RateLimit)
local Visibility = require(Shared.Rules.Visibility)

local PlayerStats = require(script.Parent.PlayerStats)
local ThrowService = require(script.Parent.ThrowService)
local WorldParts = require(script.Parent.WorldParts)

-- Name the client looks for (client/EggStandView).
local STAND_NAME = "EggStand"

local PetService = {}

local random = Random.new()
local requestTimes: { [Player]: { number } } = {}
-- Server clock time of each player's last hatch.
local lastHatchAt: { [Player]: number } = {}

-- One limit for all pet requests of a player together.
local function passesRateLimit(player: Player): boolean
	local allowed, times = RateLimit.check(
		requestTimes[player] or {},
		Workspace:GetServerTimeNow(),
		PetConfig.maxRequests,
		PetConfig.requestWindowSeconds
	)
	requestTimes[player] = times
	return allowed
end

local function isNearEggStand(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	local stand = PetConfig.egg.position
	return Visibility.isNear(PetConfig.useDistance, root.Position.X, root.Position.Z, stand.x, stand.z)
end

local function onEggHatchRequested(player: Player, ...: any)
	-- 1. Rate limit
	if not passesRateLimit(player) then
		return
	end

	-- 2. + 3. This message carries no values.
	if select("#", ...) > 0 then
		return
	end

	-- 4. The player must really stand at the egg stand, must not be in the middle of a meter or
	-- a throw (the reward of that throw is still being shown), and the last hatch must be over.
	local now = Workspace:GetServerTimeNow()
	if not isNearEggStand(player) or ThrowService.isBusy(player) then
		return
	end
	local last = lastHatchAt[player]
	if last and now - last < PetConfig.hatchCooldownSeconds then
		return
	end

	-- 5. PlayerStats checks coins and room with its own values, takes the price and adds the
	-- pet. Which pet it is, is decided here on the server.
	local result = PlayerStats.hatchEgg(player, random:NextNumber())
	if result and result.outcome == "hatched" and result.pet then
		lastHatchAt[player] = now
		Remotes.EggHatched:FireClient(player, result.pet.id)
	end
end

-- Reads the one value of a message that names a pet. nil if the message is not exactly one uid.
local function readUid(...: any): number?
	if select("#", ...) ~= 1 then
		return nil
	end
	local uid = ...
	return if Pets.isUid(uid) then uid else nil
end

local function onPetEquipRequested(player: Player, ...: any)
	-- 1. Rate limit
	if not passesRateLimit(player) then
		return
	end
	-- 2. + 3. Exactly one value: a whole number in the range of pet uids.
	local uid = readUid(...)
	if not uid then
		return
	end
	-- 4. + 5. PlayerStats checks that the player owns the pet and that not too many are equipped.
	PlayerStats.togglePet(player, uid)
end

local function onPetEquipBestRequested(player: Player, ...: any)
	-- 1. Rate limit
	if not passesRateLimit(player) then
		return
	end
	-- 2. + 3. This message carries no values.
	if select("#", ...) > 0 then
		return
	end
	-- 4. + 5. Works only on the player's own pets, with the server's values.
	PlayerStats.equipBestPets(player)
end

local function onPetDeleteRequested(player: Player, ...: any)
	-- 1. Rate limit
	if not passesRateLimit(player) then
		return
	end
	-- 2. + 3. Exactly one value: a whole number in the range of pet uids.
	local uid = readUid(...)
	if not uid then
		return
	end
	-- 4. + 5. PlayerStats checks that the player owns the pet.
	PlayerStats.deletePet(player, uid)
end

-- The top edges of the pedestal as four glowing strips. They stick out a little to the sides
-- and to the top, so none of their faces lies in a face of the pedestal.
local function addTrim(stand: Part)
	local settings = Ui.world.eggStand
	local trim = settings.trim
	local width = settings.pedestalWidth + 2 * trim.outset
	-- From the middle of the pedestal to the middle of a strip, sideways and upwards.
	local sideways = width / 2 - trim.thickness / 2
	local upwards = settings.pedestalHeight / 2 + trim.outset - trim.thickness / 2
	local function strip(size: Vector3, offset: Vector3)
		local part = Instance.new("Part")
		part.Name = "Trim"
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = WorldParts.color(trim.color)
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.Size = size
		part.Position = stand.Position + offset
		part.Parent = stand
	end
	for _, side in { -1, 1 } do
		-- Two strips over the whole width, the other two between them.
		strip(Vector3.new(width, trim.thickness, trim.thickness), Vector3.new(0, upwards, side * sideways))
		strip(
			Vector3.new(trim.thickness, trim.thickness, width - 2 * trim.thickness),
			Vector3.new(side * sideways, upwards, 0)
		)
	end
end

-- The pedestal of the egg stand, in the look of the shop pedestals, with glowing top edges.
-- The egg above it is drawn by each client, because it moves.
local function buildStand()
	local settings = Ui.world.eggStand
	local look = Ui.world.shop.pedestal
	local position = PetConfig.egg.position

	local stand = Instance.new("Part")
	stand.Name = STAND_NAME
	stand.Anchored = true
	stand.TopSurface = Enum.SurfaceType.Smooth
	stand.BottomSurface = Enum.SurfaceType.Smooth
	stand.Size = Vector3.new(settings.pedestalWidth, settings.pedestalHeight, settings.pedestalWidth)
	stand.Position = Vector3.new(position.x, LaneConfig.floorTopY + settings.pedestalHeight / 2, position.z)
	stand.Color = WorldParts.color(look.darkColor)
	for _, face in
		{ Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	do
		WorldParts.addFloorTile(stand, look.lightColor, look.fieldStuds, face)
	end
	addTrim(stand)
	stand.Parent = Workspace
end

function PetService.start()
	buildStand()

	Players.PlayerRemoving:Connect(function(player: Player)
		requestTimes[player] = nil
		lastHatchAt[player] = nil
	end)
	Remotes.EggHatchRequested.OnServerEvent:Connect(onEggHatchRequested)
	Remotes.PetEquipRequested.OnServerEvent:Connect(onPetEquipRequested)
	Remotes.PetEquipBestRequested.OnServerEvent:Connect(onPetEquipBestRequested)
	Remotes.PetDeleteRequested.OnServerEvent:Connect(onPetDeleteRequested)
end

return PetService
