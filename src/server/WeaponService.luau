--!strict
-- The weapon shop on the server: builds the pedestals with their button and handles a player
-- using one. The client only says "I used this pedestal". Whether that buys the weapon, equips
-- it or does nothing is decided here: price, ownership, coins and the distance to the pedestal.
--
-- The weapon models on the pedestals and the signs are drawn by each client (client/ShopView),
-- because OWNED / EQUIPPED / LOCKED is different for every player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local WeaponConfig = require(Shared.Config.Weapons)
local RateLimit = require(Shared.Rules.RateLimit)
local Visibility = require(Shared.Rules.Visibility)
local Weapons = require(Shared.Rules.Weapons)

local PlayerStats = require(script.Parent.PlayerStats)

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

local function onPedestalUsed(player: Player, weaponIndex: number)
	-- 1. Rate limit
	local allowed, times = RateLimit.check(
		requestTimes[player] or {},
		Workspace:GetServerTimeNow(),
		WeaponConfig.maxRequests,
		WeaponConfig.requestWindowSeconds
	)
	requestTimes[player] = times
	if not allowed then
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

local function buildPedestal(folder: Folder, weaponIndex: number)
	local shop = WeaponConfig.shop
	local position = Weapons.pedestalPosition(WeaponConfig, weaponIndex)

	local pedestal = Instance.new("Part")
	pedestal.Name = `Pedestal{weaponIndex}`
	pedestal.Anchored = true
	pedestal.Size = Vector3.new(shop.pedestalWidth, shop.pedestalHeight, shop.pedestalWidth)
	pedestal.Position = Vector3.new(position.x, LaneConfig.floorTopY + shop.pedestalHeight / 2, position.z)
	pedestal.Color = Color3.fromRGB(shop.pedestalColor[1], shop.pedestalColor[2], shop.pedestalColor[3])
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
end

return WeaponService
