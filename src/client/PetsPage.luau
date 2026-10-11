--!strict
-- The PETS tab of the items window: every pet the player owns as a card with its name and a
-- tile showing the real 3D model and its bonus, both in the color of its rarity.
--   * Pressing a tile equips the pet, or takes it off if it is equipped (green check mark).
--   * At the top: how many are equipped and owned, EQUIP BEST, and DELETE.
--   * DELETE: press it, press the pet, answer the question. Only then the pet is deleted.
-- Every press only tells the server a wish; ownership and the number of equipped pets are
-- checked there. What the page shows follows the values the server publishes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local PetConfig = require(Shared.Config.Pets)
local Ui = require(Shared.Config.Ui)
local Pets = require(Shared.Rules.Pets)
local UiLayout = require(Shared.Rules.UiLayout)

local Button = require(script.Parent.Ui.Button)
local Draw = require(script.Parent.Ui.Draw)
local OutlinedText = require(script.Parent.Ui.OutlinedText)
local PetPreview = require(script.Parent.Ui.PetPreview)
local Tile = require(script.Parent.Ui.Tile)
local Toast = require(script.Parent.Ui.Toast)
local Window = require(script.Parent.Ui.Window)

type Card = {
	pet: Pets.OwnedPet,
	frame: Frame,
	name: OutlinedText.OutlinedText,
	tile: Tile.Tile,
}

local PetsPage = {}

local player = Players.LocalPlayer

local window: Window.Window
local header: Frame
local equippedCount: OutlinedText.OutlinedText
local ownedCount: OutlinedText.OutlinedText
local equipBestButton: Button.Button
local deleteButton: Button.Button
local scroll: ScrollingFrame
local grid: UIGridLayout
local emptyText: OutlinedText.OutlinedText
local confirmBar: Frame
local confirmText: OutlinedText.OutlinedText

local cards: { [number]: Card } = {}
local holdings: Pets.Holdings = { pets = {}, equipped = {}, eggsHatched = 0 }
-- Choosing a pet to delete.
local deleting = false
-- The pet the question is about. nil = no question on screen.
local pendingDelete: number? = nil
-- os.clock() until which presses are ignored after a press.
local pressBlockedUntil = 0

local function rarityColor(petId: string): { number }
	local pet = Pets.get(PetConfig, petId)
	local colors = Ui.rarity :: { [string]: { number } }
	return (if pet then colors[pet.rarity] else nil) or colors[Ui.defaultRarity]
end

local function bonusText(petId: string): string
	return string.format(Ui.petsPage.valueText, tostring(Pets.bonusPercent(PetConfig, petId)))
end

-- false while a press came too soon after the one before.
local function pressAllowed(): boolean
	if os.clock() < pressBlockedUntil then
		return false
	end
	pressBlockedUntil = os.clock() + Ui.petsPage.pressWaitSeconds
	return true
end

local function setDeleting(on: boolean)
	local settings = Ui.petsPage
	deleting = on
	pendingDelete = nil
	confirmBar.Visible = false
	deleteButton.setText(if on then settings.cancelText else settings.deleteText)
	if on then
		Toast.show(settings.deleteHintText)
	end
end

local function onTilePressed(uid: number)
	local settings = Ui.petsPage
	local pet = Pets.find(holdings, uid)
	if not pet then
		return
	end
	if deleting then
		-- Ask first. Nothing is sent yet.
		local kind = Pets.get(PetConfig, pet.id)
		pendingDelete = uid
		confirmText.setText(string.format(settings.confirmText, if kind then kind.name else pet.id, bonusText(pet.id)))
		confirmBar.Visible = true
		return
	end
	-- A further pet does not fit: say so instead of asking the server for nothing.
	if not Pets.isEquipped(holdings, uid) and #holdings.equipped >= PetConfig.maxEquipped then
		Toast.show(string.format(settings.limitText, tostring(PetConfig.maxEquipped)))
		return
	end
	if pressAllowed() then
		Remotes.PetEquipRequested:FireServer(uid)
	end
end

local function makeCard(pet: Pets.OwnedPet): Card
	local kind = Pets.get(PetConfig, pet.id)
	local frame = Draw.box(`Pet{pet.uid}`, scroll)
	local color = rarityColor(pet.id)
	local name =
		OutlinedText.new({ name = "Name", parent = frame, text = if kind then kind.name else pet.id, color = color })
	local tile = Tile.new("Tile", color, frame)
	PetPreview.pet(pet.id, tile.content)
	tile.setValue(bonusText(pet.id))
	tile.onActivated(function()
		onTilePressed(pet.uid)
	end)
	return { pet = pet, frame = frame, name = name, tile = tile }
end

-- Sizes for the room the window has right now.
local function layout()
	local settings = Ui.petsPage
	local gap = settings.cardGap
	local room = window.contentSize()
	-- A wide window has counts and buttons in one row; a narrow one (phone held upright) has
	-- the counts above the buttons.
	local narrow = room.X < settings.narrowBelowPixels
	local rows = if narrow then 2 else 1
	local headerHeight = math.round(room.Y * settings.headerHeight * rows)
	header.Position = UDim2.fromOffset(0, 0)
	header.Size = UDim2.new(1, 0, 0, headerHeight)
	local pad = settings.sidePadding
	if narrow then
		local half = (1 - 3 * pad) / 2
		for index, text in { equippedCount, ownedCount } do
			text.frame.Position = UDim2.fromScale(pad + (index - 1) * (half + pad), 0.25)
			text.frame.Size = UDim2.fromScale(half, settings.countHeight / 2)
		end
		for index, button in { deleteButton, equipBestButton } do
			button.frame.Position = UDim2.fromScale(1 - pad - (index - 1) * (half + pad), 0.75)
			button.frame.Size = UDim2.fromScale(half, settings.buttonHeight / 2)
		end
	else
		for index, text in { equippedCount, ownedCount } do
			text.frame.Position = UDim2.fromScale(pad + (index - 1) * settings.countWidth, 0.5)
			text.frame.Size = UDim2.fromScale(settings.countWidth - pad, settings.countHeight)
		end
		for index, button in { deleteButton, equipBestButton } do
			button.frame.Position = UDim2.fromScale(1 - pad - (index - 1) * (settings.buttonWidth + pad), 0.5)
			button.frame.Size = UDim2.fromScale(settings.buttonWidth, settings.buttonHeight)
		end
	end
	scroll.Position = UDim2.fromOffset(0, headerHeight)
	scroll.Size = UDim2.new(1, 0, 1, -headerHeight)

	local available = room.X - 2 * gap - settings.scrollBarWidth
	local fit = UiLayout.grid(available, PetConfig.maxOwned, settings.minCardWidth, settings.maxCardWidth, gap)
	local width = math.floor(fit.cellWidth)
	local nameHeight = math.round(width * settings.nameHeight)
	grid.CellPadding = UDim2.fromOffset(gap, gap)
	grid.CellSize = UDim2.fromOffset(width, nameHeight + width)
	for _, card in cards do
		card.name.frame.Position = UDim2.fromOffset(0, 0)
		card.name.frame.Size = UDim2.fromOffset(width, nameHeight)
		card.tile.frame.Position = UDim2.fromOffset(0, nameHeight)
		card.tile.frame.Size = UDim2.fromOffset(width, width)
	end
end

-- Makes the cards match the pets the server shows: new pets get a card, deleted ones lose
-- theirs, and all are put in order (equipped first, then the best).
local function refresh()
	local settings = Ui.petsPage
	holdings = {
		pets = Pets.decodeOwned(player:GetAttribute(Remotes.Attributes.Pets)),
		equipped = Pets.decodeEquipped(player:GetAttribute(Remotes.Attributes.EquippedPets)),
		eggsHatched = 0,
	}

	local stillThere: { [number]: boolean } = {}
	local added = false
	for order, pet in Pets.sortedForDisplay(PetConfig, holdings) do
		stillThere[pet.uid] = true
		local card = cards[pet.uid]
		if not card then
			card = makeCard(pet)
			cards[pet.uid] = card
			added = true
		end
		card.frame.LayoutOrder = order
		card.tile.setState({ equipped = Pets.isEquipped(holdings, pet.uid), locked = false, dimmed = false })
	end
	for uid, card in cards do
		if not stillThere[uid] then
			card.frame:Destroy()
			cards[uid] = nil
		end
	end
	if added then
		layout()
	end

	equippedCount.setText(
		string.format(settings.equippedText, tostring(#holdings.equipped), tostring(PetConfig.maxEquipped))
	)
	ownedCount.setText(string.format(settings.ownedText, tostring(#holdings.pets), tostring(PetConfig.maxOwned)))
	emptyText.frame.Visible = #holdings.pets == 0
	equipBestButton.setEnabled(#holdings.pets > 0)
	deleteButton.setEnabled(#holdings.pets > 0 or deleting)
	-- The pet the question was about is gone, or there is nothing left to delete.
	if (pendingDelete and not stillThere[pendingDelete]) or (deleting and #holdings.pets == 0) then
		setDeleting(false)
	end
end

local function buildHeader(page: Frame)
	local settings = Ui.petsPage
	header = Draw.box("Header", page)

	local function count(name: string): OutlinedText.OutlinedText
		local text = OutlinedText.new({ name = name, parent = header, alignX = Enum.TextXAlignment.Left })
		text.frame.AnchorPoint = Vector2.new(0, 0.5)
		return text
	end
	equippedCount = count("EquippedCount")
	ownedCount = count("OwnedCount")

	local function button(name: string, text: string, rgb: { number }): Button.Button
		local made = Button.new({ name = name, parent = header, text = text, color = rgb })
		made.frame.AnchorPoint = Vector2.new(1, 0.5)
		return made
	end
	deleteButton = button("DeleteButton", settings.deleteText, Ui.colors.danger)
	equipBestButton = button("EquipBestButton", settings.equipBestText, Ui.colors.confirm)

	equipBestButton.onActivated(function()
		if deleting then
			setDeleting(false)
		end
		if pressAllowed() then
			Remotes.PetEquipBestRequested:FireServer()
		end
	end)
	deleteButton.onActivated(function()
		setDeleting(not deleting)
	end)
end

-- The question before a pet is deleted: a bar over the lower part of the page.
local function buildConfirm(page: Frame)
	local settings = Ui.petsPage
	confirmBar = Draw.panel("Confirm", Ui.colors.card, page)
	confirmBar.AnchorPoint = Vector2.new(0.5, 1)
	confirmBar.Position = UDim2.fromScale(0.5, 1 - settings.confirmInset)
	confirmBar.Size = UDim2.fromScale(1 - 2 * settings.confirmInset, settings.confirmHeight)
	confirmBar.ZIndex = 5
	confirmBar.Visible = false
	-- Takes presses, so they do not reach the tiles below it.
	confirmBar.Active = true
	Draw.corner(confirmBar, Ui.corners.card)
	Draw.border(confirmBar)

	confirmText = OutlinedText.new({ name = "Question", parent = confirmBar })
	confirmText.frame.AnchorPoint = Vector2.new(0.5, 0)
	confirmText.frame.Position = UDim2.fromScale(0.5, settings.confirmPadding)
	confirmText.frame.Size = UDim2.fromScale(1 - 2 * settings.confirmPadding, settings.confirmTextHeight)

	local function answer(name: string, text: string, rgb: { number }, x: number): Button.Button
		local made = Button.new({ name = name, parent = confirmBar, text = text, color = rgb })
		made.frame.AnchorPoint = Vector2.new(0.5, 1)
		made.frame.Position = UDim2.fromScale(x, 1 - settings.confirmPadding)
		made.frame.Size = UDim2.fromScale(settings.confirmButtonWidth, settings.confirmButtonHeight)
		return made
	end
	local offset = (settings.confirmButtonWidth + settings.confirmButtonGap) / 2
	local yes = answer("Yes", settings.confirmYesText, Ui.colors.danger, 0.5 - offset)
	local no = answer("No", settings.confirmNoText, Ui.colors.confirm, 0.5 + offset)
	yes.onActivated(function()
		local uid = pendingDelete
		setDeleting(false)
		-- Only the wish. The server checks that the player owns this pet.
		if uid and pressAllowed() then
			Remotes.PetDeleteRequested:FireServer(uid)
		end
	end)
	no.onActivated(function()
		setDeleting(false)
	end)
end

-- Builds the page into this page of the window.
function PetsPage.build(itemsWindow: Window.Window, page: Frame)
	local settings = Ui.petsPage
	window = itemsWindow
	buildHeader(page)

	scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Cards"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.fromScale(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.ScrollBarThickness = settings.scrollBarWidth
	scroll.Parent = page

	-- Room around the cards, so the check mark on a tile's corner is not cut off.
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, settings.cardGap)
	padding.PaddingBottom = UDim.new(0, settings.cardGap)
	padding.PaddingLeft = UDim.new(0, settings.cardGap)
	padding.PaddingRight = UDim.new(0, settings.cardGap)
	padding.Parent = scroll

	grid = Instance.new("UIGridLayout")
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.Parent = scroll

	emptyText = OutlinedText.new({ name = "Empty", parent = page, text = settings.emptyText })
	emptyText.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	emptyText.frame.Position = UDim2.fromScale(0.5, settings.emptyCenterY)
	emptyText.frame.Size = UDim2.fromScale(settings.emptyWidth, settings.emptyHeight)

	buildConfirm(page)

	window.onResize(layout)
	refresh()
	for _, attribute in { Remotes.Attributes.Pets, Remotes.Attributes.EquippedPets } do
		player:GetAttributeChangedSignal(attribute):Connect(refresh)
	end
end

-- Called when the window closes or another tab is shown: an open question is dropped.
function PetsPage.reset()
	if deleting then
		setDeleting(false)
	end
end

return PetsPage
