--!strict
-- The weapon shop on the server: builds the pedestals with their button and handles a player
-- using one, and handles a player equipping a weapon from the items window. Both only state a wish:
--   * the button at a pedestal ("I used this pedestal"), only when standing next to it. Whether
--     that buys the weapon, equips it or does nothing is decided here: price, ownership, coins
--     and the distance to the pedestal. Weapons can only be bought this way.
--   * a tile in the items window ("I want to equip this weapon"), from anywhere. That only ever
--     equips a weapon the player already owns.
--
-- The weapon models on the pedestals and the signs are drawn by each client (client/ShopView),
-- because OWNED / EQUIPPED / LOCKED is different for every player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local WeaponConfig = require(Shared.Config.Weapons)
local RateLimit = require(Shared.Rules.RateLimit)
local Visibility = require(Shared.Rules.Visibility)
local Weapons = require(Shared.Rules.Weapons)

local PlayerStats = require(script.Parent.PlayerStats)
local ThrowService = require(script.Parent.ThrowService)
local WorldParts = require(script.Parent.WorldParts)

-- Names the client looks for (client/ShopView).
local FOLDER_NAME = "WeaponShop"
local PROMPT_NAME = "UsePrompt"

local WeaponService = {}

local requestTimes: { [Player]: { number } } = {}

local function isNearPedestal(player: Player, weaponIndex: number): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	local pedestal = Weapons.pedestalPosition(WeaponConfig, weaponIndex)
	return Visibility.isNear(WeaponConfig.useDistance, root.Position.X, root.Position.Z, pedestal.x, pedestal.z)
end

-- One limit for the pedestals and the items window together.
local function passesRateLimit(player: Player): boolean
	local allowed, times = RateLimit.check(
		requestTimes[player] or {},
		Workspace:GetServerTimeNow(),
		WeaponConfig.maxRequests,
		WeaponConfig.requestWindowSeconds
	)
	requestTimes[player] = times
	return allowed
end

local function onPedestalUsed(player: Player, weaponIndex: number)
	-- 1. Rate limit
	if not passesRateLimit(player) then
		return
	end

	-- 2. + 3. The only "value" is which pedestal was used, and that comes from the server's own
	-- button, not from the client. Still make sure the weapon exists.
	local weapon = WeaponConfig.list[weaponIndex]
	if not weapon then
		return
	end

	-- 4. The player must really stand at the pedestal. A cheating client can press a button from far away.
	if not isNearPedestal(player, weaponIndex) then
		return
	end

	-- 5. PlayerStats checks price, ownership and coins with its own values and applies the result.
	PlayerStats.useWeaponPedestal(player, weapon.id)
end

-- A tile in the items window was pressed. Everything the client sends is checked here.
local function onWeaponEquipRequested(player: Player, ...: any)
	-- 1. Rate limit
	if not passesRateLimit(player) then
		return
	end

	-- 2. Exactly one value, and it is a text of sensible length.
	if select("#", ...) ~= 1 then
		return
	end
	local weaponId = ...
	if typeof(weaponId) ~= "string" or #weaponId > WeaponConfig.maxIdLength then
		return
	end

	-- 3. It must name a weapon the game knows.
	local weapon = Weapons.get(WeaponConfig, weaponId)
	if not weapon then
		return
	end

	-- 4. Not in the middle of a meter or a throw: the reward of that throw is still being shown.
	if ThrowService.isBusy(player) then
		return
	end

	-- 5. PlayerStats checks with its own values that the player owns the weapon, and equips it.
	-- Nothing is bought here.
	PlayerStats.equipWeapon(player, weapon.id)
end

local function buildPedestal(folder: Folder, weaponIndex: number)
	local shop = WeaponConfig.shop
	local position = Weapons.pedestalPosition(WeaponConfig, weaponIndex)

	local pedestal = Instance.new("Part")
	pedestal.Name = `Pedestal{weaponIndex}`
	pedestal.Anchored = true
	pedestal.Size = Vector3.new(shop.pedestalWidth, shop.pedestalHeight, shop.pedestalWidth)
	pedestal.Position = Vector3.new(position.x, LaneConfig.floorTopY + shop.pedestalHeight / 2, position.z)
	-- Dark blue-grey with studs on every side that can be seen.
	local look = Ui.world.shop.pedestal
	pedestal.Color = WorldParts.color(look.darkColor)
	for _, face in
		{ Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
	do
		WorldParts.addFloorTile(pedestal, look.lightColor, look.fieldStuds, face)
	end
	pedestal.TopSurface = Enum.SurfaceType.Smooth
	pedestal.BottomSurface = Enum.SurfaceType.Smooth

	-- The button works with touch, keyboard and gamepad by itself.
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = PROMPT_NAME
	prompt.ObjectText = WeaponConfig.list[weaponIndex].name
	prompt.ActionText = shop.buyActionText
	prompt.HoldDuration = shop.holdSeconds
	prompt.MaxActivationDistance = shop.promptDistance
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(player: Player)
		onPedestalUsed(player, weaponIndex)
	end)
	prompt.Parent = pedestal

	pedestal.Parent = folder
end

function WeaponService.start()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for weaponIndex = 1, Weapons.count(WeaponConfig) do
		buildPedestal(folder, weaponIndex)
	end
	folder.Parent = Workspace

	Players.PlayerRemoving:Connect(function(player: Player)
		requestTimes[player] = nil
	end)
	Remotes.WeaponEquipRequested.OnServerEvent:Connect(onWeaponEquipRequested)
end

return WeaponService
