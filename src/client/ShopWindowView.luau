--!strict
-- The shop window: every weapon as a card with its name, a tile showing the real 3D model and
-- its bonus, and a button to buy or equip it. Opened from the menu (MenuView).
-- Buying and equipping work like at the pedestals in the world: the button only tells the
-- server "I pressed the button of this weapon"; price, ownership and coins are checked there.
-- What a card shows follows the values the server publishes (attributes on the Player).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local Ui = require(Shared.Config.Ui)
local WeaponConfig = require(Shared.Config.Weapons)
local NumberFormat = require(Shared.Rules.NumberFormat)
local UiLayout = require(Shared.Rules.UiLayout)
local Weapons = require(Shared.Rules.Weapons)

local Button = require(script.Parent.Ui.Button)
local Draw = require(script.Parent.Ui.Draw)
local OutlinedText = require(script.Parent.Ui.OutlinedText)
local Tile = require(script.Parent.Ui.Tile)
local WeaponPreview = require(script.Parent.Ui.WeaponPreview)
local Window = require(script.Parent.Ui.Window)

type Card = {
	weapon: Weapons.Weapon,
	frame: Frame,
	name: OutlinedText.OutlinedText,
	tile: Tile.Tile,
	button: Button.Button,
}

local ShopWindowView = {}

local player = Players.LocalPlayer

local window: Window.Window
local scroll: ScrollingFrame
local grid: UIGridLayout
local cards: { Card } = {}
-- os.clock() until which presses are ignored after a press.
local pressBlockedUntil = 0

local function rarityColor(weapon: Weapons.Weapon): { number }
	local colors = Ui.rarity :: { [string]: { number } }
	return colors[weapon.rarity or Ui.defaultRarity] or colors[Ui.defaultRarity]
end

local function menuIcon(id: string): string?
	for _, entry in Ui.menu.entries do
		if entry.id == id then
			return entry.icon
		end
	end
	return nil
end

local function onPressed(weapon: Weapons.Weapon)
	if os.clock() < pressBlockedUntil then
		return
	end
	pressBlockedUntil = os.clock() + Ui.shopWindow.pressWaitSeconds
	-- Only the wish. The server decides whether this buys, equips or does nothing.
	Remotes.WeaponUseRequested:FireServer(weapon.id)
end

local function makeCard(order: number, weapon: Weapons.Weapon): Card
	local frame = Draw.box(weapon.id, scroll)
	frame.LayoutOrder = order

	local name = OutlinedText.new({ name = "Name", parent = frame, text = weapon.name, color = rarityColor(weapon) })
	local tile = Tile.new("Tile", rarityColor(weapon), frame)
	WeaponPreview.new(weapon.id, tile.content)
	tile.setValue(string.format(Ui.shopWindow.valueText, tostring(Weapons.bonusPercent(weapon))))

	local button = Button.new({ name = "Button", parent = frame, text = "", color = Ui.colors.confirm })
	button.onActivated(function()
		onPressed(weapon)
	end)
	return { weapon = weapon, frame = frame, name = name, tile = tile, button = button }
end

-- Sizes of the cards for the room the window has right now.
local function layout()
	local settings = Ui.shopWindow
	local gap = settings.cardGap
	local room = window.contentSize()
	local available = room.X - 2 * gap - settings.scrollBarWidth
	-- A card is its name, the square tile and the button, with a gap between them. On a low
	-- screen the cards get narrower, so that a whole card fits into the window's height.
	local heightPerWidth = settings.nameHeight + 1 + settings.buttonHeight
	local widestThatFits = (room.Y - 4 * gap) / heightPerWidth
	local widest = math.max(math.min(settings.maxCardWidth, widestThatFits), settings.minCardWidth)
	local fit = UiLayout.grid(available, #cards, settings.minCardWidth, widest, gap)
	local width = math.floor(fit.cellWidth)
	local nameHeight = math.round(width * settings.nameHeight)
	local buttonHeight = math.round(width * settings.buttonHeight)

	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.CellSize = UDim2.fromOffset(width, nameHeight + gap + width + gap + buttonHeight)
	for _, card in cards do
		card.name.frame.Position = UDim2.fromOffset(0, 0)
		card.name.frame.Size = UDim2.fromOffset(width, nameHeight)
		card.tile.frame.Position = UDim2.fromOffset(0, nameHeight + gap)
		card.tile.frame.Size = UDim2.fromOffset(width, width)
		card.button.frame.Position = UDim2.fromOffset(0, nameHeight + gap + width + gap)
		card.button.frame.Size = UDim2.fromOffset(width, buttonHeight)
	end
end

-- What every card shows depends on what this player owns, uses and can afford.
local function refresh()
	local settings = Ui.shopWindow
	local owned = Weapons.decodeOwned(player:GetAttribute(Remotes.Attributes.OwnedWeapons))
	local equippedValue = player:GetAttribute(Remotes.Attributes.EquippedWeapon)
	local equipped = if typeof(equippedValue) == "string" then equippedValue else ""
	local coinsValue = player:GetAttribute(Remotes.Attributes.Currency)
	local coins = if typeof(coinsValue) == "number" then coinsValue else 0

	for _, card in cards do
		local weapon = card.weapon
		local state = Weapons.shopState(WeaponConfig, { owned = owned, equipped = equipped }, coins, weapon.id)
		local price = if weapon.price > 0
			then string.format(settings.buyText, NumberFormat.abbreviate(NumberFormatConfig, weapon.price))
			else settings.freeText

		card.tile.setState({
			equipped = state == "equipped",
			locked = state == "canBuy" or state == "tooExpensive",
			dimmed = state == "tooExpensive",
		})
		if state == "equipped" then
			card.button.setText(settings.equippedText)
		elseif state == "owned" then
			card.button.setText(settings.equipText)
		else
			card.button.setText(price)
		end
		card.button.setEnabled(state == "owned" or state == "canBuy")
	end
end

-- Opens the window, or closes it if it is open.
function ShopWindowView.toggle()
	window.toggle()
end

function ShopWindowView.start()
	local settings = Ui.shopWindow
	window = Window.new({
		name = "ShopWindow",
		title = settings.title,
		icon = menuIcon(settings.menuEntry),
		maxWidth = settings.maxWidth,
		maxHeight = settings.maxHeight,
	})

	-- The cards can be scrolled when they do not all fit (phone held upright).
	scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Cards"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = settings.scrollBarWidth
	scroll.Parent = window.content

	-- Room around the cards, so the check mark on a tile's corner is not cut off.
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, settings.cardGap)
	padding.PaddingBottom = UDim.new(0, settings.cardGap)
	padding.PaddingLeft = UDim.new(0, settings.cardGap)
	padding.PaddingRight = UDim.new(0, settings.cardGap)
	padding.Parent = scroll

	grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.Parent = scroll

	for order, weapon in WeaponConfig.list do
		table.insert(cards, makeCard(order, weapon))
	end

	window.onResize(layout)
	refresh()
	for _, attribute in
		{ Remotes.Attributes.OwnedWeapons, Remotes.Attributes.EquippedWeapon, Remotes.Attributes.Currency }
	do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
end

return ShopWindowView
