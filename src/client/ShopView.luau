--!strict
-- What this player sees of the weapon shop: the weapon standing on each pedestal, the sign
-- floating above it (name, bonus, price, and OWNED / EQUIPPED / LOCKED for this player) and the
-- text on the button at the pedestal.
-- The pedestals and their buttons are made by the server (server/WeaponService). Pressing a button
-- only tells the server "I used this pedestal"; the server decides what happens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local Ui = require(Shared.Config.Ui)
local WeaponConfig = require(Shared.Config.Weapons)
local NumberFormat = require(Shared.Rules.NumberFormat)
local Weapons = require(Shared.Rules.Weapons)

local SwordView = require(script.Parent.SwordView)
local WorldSign = require(script.Parent.Ui.WorldSign)

-- Names given by the server (server/WeaponService).
local SHOP_FOLDER_NAME = "WeaponShop"
local PROMPT_NAME = "UsePrompt"
-- This client's own folder for the weapons and signs.
local MY_FOLDER_NAME = "MyWeaponShop"
-- The rows of a sign, from top to bottom.
local STATUS_ROW = 4

type Stand = {
	weapon: Weapons.Weapon,
	sign: WorldSign.WorldSign,
	prompt: ProximityPrompt?,
}

local ShopView = {}

local player = Players.LocalPlayer
local stands: { Stand } = {}

-- The weapon stands upright above the pedestal, tip up, flat side towards the player.
local function buildWeapon(weaponIndex: number, weapon: Weapons.Weapon, folder: Folder)
	local shop = WeaponConfig.shop
	local position = Weapons.pedestalPosition(WeaponConfig, weaponIndex)
	local pedestalTop = LaneConfig.floorTopY + shop.pedestalHeight
	local tipY = pedestalTop + shop.weaponGap + SwordView.length(1, weapon.id)

	local model = SwordView.create(`ShopWeapon{weaponIndex}`, 1, weapon.id)
	model.Parent = folder
	SwordView.moveTo(model, CFrame.new(position.x, tipY, position.z) * CFrame.Angles(math.rad(90), 0, 0))
end

-- The sign above a pedestal: name, bonus in light green, a pill with the coin symbol and the
-- price, and the status for this player.
local function buildSign(weaponIndex: number, weapon: Weapons.Weapon, folder: Folder): WorldSign.WorldSign
	local settings = Ui.world.signs.shop
	local position = Weapons.pedestalPosition(WeaponConfig, weaponIndex)
	local isFree = weapon.price <= 0

	local sign = WorldSign.new({
		name = `ShopSign{weaponIndex}`,
		parent = folder,
		position = Vector3.new(position.x, LaneConfig.floorTopY + settings.heightAboveFloor, position.z),
		widthStuds = settings.widthStuds,
		heightStuds = settings.heightStuds,
		rows = {
			{ kind = "text", height = settings.nameHeight, text = weapon.name },
			{
				kind = "text",
				height = settings.bonusHeight,
				text = string.format(settings.bonusText, tostring(Weapons.bonusPercent(weapon))),
				color = Ui.colors.positive,
			},
			{
				kind = "pill",
				height = settings.pillHeight,
				icon = "coins",
				text = if isFree then settings.freeText else NumberFormat.abbreviate(NumberFormatConfig, weapon.price),
				color = Ui.colors.coins,
			},
			{ kind = "text", height = settings.statusHeight, text = "" },
		},
	})
	-- The free weapon shows FREE without the coin.
	if isFree then
		sign.setIconShown(STATUS_ROW - 1, false)
	end
	return sign
end

-- Sign state and button text depend on what this player owns, uses and can afford.
local function refresh()
	local shop = WeaponConfig.shop
	local settings = Ui.world.signs.shop
	local owned = Weapons.decodeOwned(player:GetAttribute(Remotes.Attributes.OwnedWeapons))
	local equipped = player:GetAttribute(Remotes.Attributes.EquippedWeapon)
	local coinsValue = player:GetAttribute(Remotes.Attributes.Currency)
	local coins = if typeof(coinsValue) == "number" then coinsValue else 0

	for _, stand in stands do
		local weapon = stand.weapon
		local isOwned = table.find(owned, weapon.id) ~= nil
		local isEquipped = equipped == weapon.id

		if isEquipped then
			stand.sign.setText(STATUS_ROW, settings.equippedText)
			stand.sign.setColor(STATUS_ROW, Ui.colors.confirm)
		elseif isOwned then
			stand.sign.setText(STATUS_ROW, settings.ownedText)
			stand.sign.setColor(STATUS_ROW, Ui.colors.confirm)
		else
			stand.sign.setText(STATUS_ROW, settings.lockedText)
			stand.sign.setColor(STATUS_ROW, Ui.colors.danger)
		end

		-- These changes to the server's button only exist on this client, which is what we want:
		-- every player sees the text that fits their own state.
		local prompt = stand.prompt
		if prompt then
			prompt.Enabled = not isEquipped
			if isOwned then
				prompt.ActionText = shop.equipActionText
			elseif coins >= weapon.price then
				prompt.ActionText = shop.buyActionText
			else
				prompt.ActionText = shop.tooExpensiveActionText
			end
		end
	end
end

function ShopView.start()
	local folder = Instance.new("Folder")
	folder.Name = MY_FOLDER_NAME

	for weaponIndex, weapon in WeaponConfig.list do
		buildWeapon(weaponIndex, weapon, folder)
		table.insert(stands, { weapon = weapon, sign = buildSign(weaponIndex, weapon, folder), prompt = nil })
	end
	folder.Parent = Workspace
	refresh()

	for _, attribute in
		{ Remotes.Attributes.OwnedWeapons, Remotes.Attributes.EquippedWeapon, Remotes.Attributes.Currency }
	do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end

	-- The server's pedestals may arrive a moment later than this script starts.
	task.spawn(function()
		local shopFolder = Workspace:WaitForChild(SHOP_FOLDER_NAME)
		for weaponIndex, stand in stands do
			local pedestal = shopFolder:WaitForChild(`Pedestal{weaponIndex}`)
			local prompt = pedestal:WaitForChild(PROMPT_NAME)
			if prompt:IsA("ProximityPrompt") then
				stand.prompt = prompt
			end
		end
		refresh()
	end)
end

return ShopView
