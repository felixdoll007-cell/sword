--!strict
-- The items window: what the player owns. Opened from the menu (MenuView). It has tabs on its
-- left: WEAPONS (this file) and PETS (client/PetsPage). A further tab is added by naming it in
-- Window.new below and filling its page.
--
-- The WEAPONS tab:
-- Every weapon is a card with its name and a tile showing the real 3D model and its bonus.
--   * Owned: pressing the tile equips it. The one in use has the green check mark.
--   * Not owned: dark with a lock, the price below it and the hint to buy it at the pedestal.
-- Nothing can be bought here; weapons are only bought at the pedestals in the world.
-- Pressing a tile only tells the server "I want to equip this weapon"; whether the player owns
-- it is checked there. What a card shows follows the values the server publishes.

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

local PetsPage = require(script.Parent.PetsPage)
local Draw = require(script.Parent.Ui.Draw)
local OutlinedText = require(script.Parent.Ui.OutlinedText)
local Tile = require(script.Parent.Ui.Tile)
local WeaponPreview = require(script.Parent.Ui.WeaponPreview)
local Window = require(script.Parent.Ui.Window)

-- Places of the tabs among the window's tabs, by the name the menu uses for them.
local WEAPONS_TAB = 1
local PETS_TAB = 2
local TABS: { [string]: number } = { weapons = WEAPONS_TAB, pets = PETS_TAB }

type Card = {
	weapon: Weapons.Weapon,
	frame: Frame,
	name: OutlinedText.OutlinedText,
	tile: Tile.Tile,
	-- Below the tile: EQUIPPED, the invitation to equip, or the price.
	status: OutlinedText.OutlinedText,
	-- Below that, small: where the weapon can be bought.
	hint: OutlinedText.OutlinedText,
	state: Weapons.ShopState,
}

local ItemsWindowView = {}

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

local function onPressed(card: Card)
	-- Only an owned weapon that is not in use can be equipped.
	if card.state ~= "owned" or os.clock() < pressBlockedUntil then
		return
	end
	pressBlockedUntil = os.clock() + Ui.itemsWindow.pressWaitSeconds
	-- Only the wish. The server checks that the player owns the weapon.
	Remotes.WeaponEquipRequested:FireServer(card.weapon.id)
end

local function makeCard(order: number, weapon: Weapons.Weapon): Card
	local settings = Ui.itemsWindow
	local frame = Draw.box(weapon.id, scroll)
	frame.LayoutOrder = order

	local name = OutlinedText.new({ name = "Name", parent = frame, text = weapon.name, color = rarityColor(weapon) })
	local tile = Tile.new("Tile", rarityColor(weapon), frame)
	WeaponPreview.new(weapon.id, tile.content)
	tile.setValue(string.format(settings.valueText, tostring(Weapons.bonusPercent(weapon))))
	local status = OutlinedText.new({ name = "Status", parent = frame })
	local hint = OutlinedText.new({ name = "Hint", parent = frame, text = settings.pedestalHint })

	local card: Card =
		{ weapon = weapon, frame = frame, name = name, tile = tile, status = status, hint = hint, state = "unknown" }
	tile.onActivated(function()
		onPressed(card)
	end)
	return card
end

-- Sizes of the cards for the room the window has right now.
local function layout()
	local settings = Ui.itemsWindow
	local gap = settings.cardGap
	local room = window.contentSize()
	local available = room.X - 2 * gap - settings.scrollBarWidth
	-- A card is its name, the square tile and two lines of text, with a gap around the tile. On
	-- a low screen the cards get narrower, so that a whole card fits into the window's height.
	local heightPerWidth = settings.nameHeight + 1 + settings.statusHeight + settings.hintHeight
	local widestThatFits = (room.Y - 4 * gap) / heightPerWidth
	local widest = math.max(math.min(settings.maxCardWidth, widestThatFits), settings.minCardWidth)
	local fit = UiLayout.grid(available, #cards, settings.minCardWidth, widest, gap)
	local width = math.floor(fit.cellWidth)
	local nameHeight = math.round(width * settings.nameHeight)
	local statusHeight = math.round(width * settings.statusHeight)
	local hintHeight = math.round(width * settings.hintHeight)

	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.CellSize = UDim2.fromOffset(width, nameHeight + gap + width + gap + statusHeight + hintHeight)
	for _, card in cards do
		local y = 0
		card.name.frame.Position = UDim2.fromOffset(0, y)
		card.name.frame.Size = UDim2.fromOffset(width, nameHeight)
		y += nameHeight + gap
		card.tile.frame.Position = UDim2.fromOffset(0, y)
		card.tile.frame.Size = UDim2.fromOffset(width, width)
		y += width + gap
		card.status.frame.Position = UDim2.fromOffset(0, y)
		card.status.frame.Size = UDim2.fromOffset(width, statusHeight)
		y += statusHeight
		card.hint.frame.Position = UDim2.fromOffset(0, y)
		card.hint.frame.Size = UDim2.fromOffset(width, hintHeight)
	end
end

-- What every card shows depends on what this player owns and uses.
local function refresh()
	local settings = Ui.itemsWindow
	local owned = Weapons.decodeOwned(player:GetAttribute(Remotes.Attributes.OwnedWeapons))
	local equippedValue = player:GetAttribute(Remotes.Attributes.EquippedWeapon)
	local equipped = if typeof(equippedValue) == "string" then equippedValue else ""

	for _, card in cards do
		local weapon = card.weapon
		-- Coins do not matter here: nothing is bought in this window.
		local state = Weapons.shopState(WeaponConfig, { owned = owned, equipped = equipped }, 0, weapon.id)
		local isOwned = state == "equipped" or state == "owned"
		card.state = state

		card.tile.setState({ equipped = state == "equipped", locked = not isOwned, dimmed = not isOwned })
		card.hint.frame.Visible = not isOwned
		if state == "equipped" then
			card.status.setText(settings.equippedText)
			card.status.setColor(Ui.colors.confirm)
		elseif state == "owned" then
			card.status.setText(settings.equipText)
			card.status.setColor(Ui.text.color)
		else
			card.status.setText(
				string.format(settings.priceText, NumberFormat.abbreviate(NumberFormatConfig, weapon.price))
			)
			card.status.setColor(Ui.colors.coins)
		end
	end
end

-- Opens the window on this tab ("weapons" or "pets"). If it is already open on that tab, it
-- closes; if it is open on the other tab, it switches.
function ItemsWindowView.toggle(tabName: string)
	local tab = TABS[tabName] or WEAPONS_TAB
	if window.isOpen() and window.selectedTab() == tab then
		window.close()
		return
	end
	window.selectTab(tab)
	window.open()
end

function ItemsWindowView.start()
	local settings = Ui.itemsWindow
	window = Window.new({
		name = "ItemsWindow",
		title = settings.title,
		icon = menuIcon(settings.menuEntry),
		maxWidth = settings.maxWidth,
		maxHeight = settings.maxHeight,
		tabs = { settings.weaponsTab, settings.petsTab },
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
	scroll.Parent = window.pages[WEAPONS_TAB]

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

	PetsPage.build(window, window.pages[PETS_TAB])
	window.onLeave(PetsPage.reset)

	window.onResize(layout)
	refresh()
	for _, attribute in { Remotes.Attributes.OwnedWeapons, Remotes.Attributes.EquippedWeapon } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
end

return ItemsWindowView
