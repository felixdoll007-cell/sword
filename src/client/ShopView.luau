--!strict
-- What this player sees of the weapon shop: the weapon standing on each pedestal, the sign above
-- it (name, bonus, price, and OWNED / EQUIPPED / LOCKED for this player) and the text on the
-- button at the pedestal.
-- The pedestals and their buttons are made by the server (server/WeaponService). Pressing a button
-- only tells the server "I used this pedestal"; the server decides what happens.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local WeaponConfig = require(Shared.Config.Weapons)
local NumberFormat = require(Shared.Rules.NumberFormat)
local Weapons = require(Shared.Rules.Weapons)

local SwordView = require(script.Parent.SwordView)

-- Names given by the server (server/WeaponService).
local SHOP_FOLDER_NAME = "WeaponShop"
local PROMPT_NAME = "UsePrompt"
-- This client's own folder for the weapons and signs.
local MY_FOLDER_NAME = "MyWeaponShop"

type Stand = {
	weapon: Weapons.Weapon,
	stateLine: TextLabel,
	prompt: ProximityPrompt?,
}

local ShopView = {}

local player = Players.LocalPlayer
local stands: { Stand } = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function makeLine(heightShare: number, yShare: number, text: string, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, heightShare)
	label.Position = UDim2.fromScale(0, yShare)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color(WeaponConfig.shop.signTextColor)
	label.Text = text
	label.Parent = parent
	return label
end

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

local function buildSign(weaponIndex: number, weapon: Weapons.Weapon, folder: Folder): TextLabel
	local shop = WeaponConfig.shop
	local position = Weapons.pedestalPosition(WeaponConfig, weaponIndex)

	local board = Instance.new("Part")
	board.Name = `ShopSign{weaponIndex}`
	board.Anchored = true
	board.CanCollide = false
	board.CanTouch = false
	board.CanQuery = false
	board.TopSurface = Enum.SurfaceType.Smooth
	board.BottomSurface = Enum.SurfaceType.Smooth
	board.Size = Vector3.new(shop.signWidth, shop.signBoardHeight, shop.signBoardThickness)
	board.Position =
		Vector3.new(position.x, LaneConfig.floorTopY + shop.signHeightAboveFloor + shop.signBoardHeight / 2, position.z)
	board.Color = color(shop.signBoardColor)
	board.Parent = folder

	local gui = Instance.new("SurfaceGui")
	-- Players stand in front of the row on the positive Z side: that is the board's back face.
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = board

	local heights = shop.signLineHeights
	local priceText = if weapon.price > 0
		then string.format(shop.priceText, NumberFormat.abbreviate(NumberFormatConfig, weapon.price))
		else shop.freeText
	makeLine(heights[1], 0, weapon.name, gui)
	makeLine(heights[2], heights[1], string.format(shop.bonusText, tostring(Weapons.bonusPercent(weapon))), gui)
	makeLine(heights[3], heights[1] + heights[2], priceText, gui)
	return makeLine(heights[4], heights[1] + heights[2] + heights[3], "", gui)
end

-- Sign state and button text depend on what this player owns, uses and can afford.
local function refresh()
	local shop = WeaponConfig.shop
	local owned = Weapons.decodeOwned(player:GetAttribute(Remotes.Attributes.OwnedWeapons))
	local equipped = player:GetAttribute(Remotes.Attributes.EquippedWeapon)
	local coinsValue = player:GetAttribute(Remotes.Attributes.Currency)
	local coins = if typeof(coinsValue) == "number" then coinsValue else 0

	for _, stand in stands do
		local weapon = stand.weapon
		local isOwned = table.find(owned, weapon.id) ~= nil
		local isEquipped = equipped == weapon.id

		if isEquipped then
			stand.stateLine.Text = shop.equippedText
			stand.stateLine.TextColor3 = color(shop.equippedColor)
		elseif isOwned then
			stand.stateLine.Text = shop.ownedText
			stand.stateLine.TextColor3 = color(shop.ownedColor)
		else
			stand.stateLine.Text = shop.lockedText
			stand.stateLine.TextColor3 = color(shop.lockedColor)
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
		table.insert(stands, { weapon = weapon, stateLine = buildSign(weaponIndex, weapon, folder), prompt = nil })
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
