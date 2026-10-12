--!strict
-- What this player sees of the egg stand: the egg floating above the pedestal (it bobs and
-- turns slowly), the sign floating above it (name and this player's price), and, while the
-- player stands at the stand, a card above the middle of the screen with the pets that can
-- hatch, their chances and a row of buttons: HATCH with the price below it (on a keyboard also
-- E), and the planned ones, which only answer "Coming soon".
-- The pedestal is made by the server (server/PetService). Pressing HATCH only tells the server
-- "I want to hatch an egg"; coins, room and the pet are decided there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local PetConfig = require(Shared.Config.Pets)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)
local Pets = require(Shared.Rules.Pets)
local UiLayout = require(Shared.Rules.UiLayout)
local Visibility = require(Shared.Rules.Visibility)

local HatchView = require(script.Parent.HatchView)
local ThrowSession = require(script.Parent.ThrowSession)
local Button = require(script.Parent.Ui.Button)
local Draw = require(script.Parent.Ui.Draw)
local Hud = require(script.Parent.Ui.Hud)
local OutlinedText = require(script.Parent.Ui.OutlinedText)
local PetPreview = require(script.Parent.Ui.PetPreview)
local Tile = require(script.Parent.Ui.Tile)
local Toast = require(script.Parent.Ui.Toast)
local Window = require(script.Parent.Ui.Window)
local WorldSign = require(script.Parent.Ui.WorldSign)

local FOLDER_NAME = "MyEggStand"
-- The rows of the sign, from top to bottom.
local PRICE_ROW = 2

local EggStandView = {}

local player = Players.LocalPlayer

local sign: WorldSign.WorldSign
local card: Frame
local title: OutlinedText.OutlinedText
local hatchButton: Button.Button
-- HATCH first, then the planned ones, from left to right.
local buttons: { Button.Button } = {}
local oddsTiles: { Tile.Tile } = {}
-- os.clock() until which presses are ignored after a press.
local pressBlockedUntil = 0

local function numberAttribute(name: string): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

-- The price of this player's next egg.
local function price(): number
	return Pets.eggPrice(PetConfig, numberAttribute(Remotes.Attributes.EggsHatched))
end

local function isNearStand(): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	local stand = PetConfig.egg.position
	return Visibility.isNear(Ui.world.eggStand.promptDistance, root.Position.X, root.Position.Z, stand.x, stand.z)
end

local function onHatchPressed()
	local settings = Ui.eggCard
	if os.clock() < pressBlockedUntil or HatchView.isPlaying() then
		return
	end
	-- Say right away what is missing. The server checks again with its own values.
	local owned = Pets.decodeOwned(player:GetAttribute(Remotes.Attributes.Pets))
	if #owned >= PetConfig.maxOwned then
		Toast.show(settings.fullText)
		return
	end
	if numberAttribute(Remotes.Attributes.Currency) < price() then
		Toast.show(settings.notEnoughText)
		return
	end
	pressBlockedUntil = os.clock() + settings.pressWaitSeconds
	Remotes.EggHatchRequested:FireServer()
end

-- The egg floats above the pedestal, rises and sinks a little and turns slowly around itself.
local function buildEgg(folder: Folder)
	local settings = Ui.world.eggStand
	local stand = PetConfig.egg.position
	local egg = PetPreview.eggModel()
	egg.Name = "Egg"
	egg:ScaleTo(settings.eggScale)
	egg:PivotTo(CFrame.new())
	-- How far the point the egg is moved by lies above its lowest point.
	local boxFrame, boxSize = egg:GetBoundingBox()
	local pivotAboveBottom = boxSize.Y / 2 - boxFrame.Position.Y
	local lowest = CFrame.new(
		stand.x,
		LaneConfig.floorTopY + settings.pedestalHeight + settings.hoverHeight + pivotAboveBottom,
		stand.z
	)
	egg:PivotTo(lowest)
	egg.Parent = folder

	local fullTurn = 2 * math.pi
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		-- From the lowest point up by bobHeight and back.
		local rise = (1 - math.cos(now / settings.bobSeconds * fullTurn)) / 2 * settings.bobHeight
		local turn = now / settings.turnSeconds * fullTurn % fullTurn
		egg:PivotTo(lowest * CFrame.new(0, rise, 0) * CFrame.Angles(0, turn, 0))
	end)
end

local function buildSign(folder: Folder)
	local settings = Ui.world.eggStand.sign
	local stand = PetConfig.egg.position
	sign = WorldSign.new({
		name = "EggSign",
		parent = folder,
		position = Vector3.new(stand.x, LaneConfig.floorTopY + settings.heightAboveFloor, stand.z),
		widthStuds = settings.widthStuds,
		heightStuds = settings.heightStuds,
		rows = {
			{ kind = "text", height = settings.nameHeight, text = PetConfig.egg.name },
			{ kind = "pill", height = settings.pillHeight, icon = "coins", text = "", color = Ui.colors.coins },
		},
	})
end

-- The price on the sign and in the HATCH button is this player's own next price.
local function refreshPrice()
	local text = NumberFormat.abbreviate(NumberFormatConfig, price())
	sign.setText(PRICE_ROW, text)
	hatchButton.setPillText(text)
end

-- The card: the egg's name, one glossy tile per pet that can hatch in the colors of its rarity
-- with its chance, and below them the buttons.
local function buildCard()
	local settings = Ui.eggCard
	card = Draw.panel("EggCard", settings.backColor, Hud.gui())
	card.BackgroundTransparency = settings.backTransparency
	card.Visible = false
	-- Takes presses, so a press between the tiles does not turn the camera.
	card.Active = true
	Draw.corner(card, settings.cornerShare)
	Draw.border(card, settings.borderColor, settings.borderThickness).Transparency = settings.borderTransparency

	title = OutlinedText.new({ name = "Title", parent = card, text = PetConfig.egg.name, color = settings.titleColor })

	for _, chance in PetConfig.egg.chances do
		local pet = Pets.get(PetConfig, chance.pet)
		local rarity = if pet then pet.rarity else Ui.defaultRarity
		local color = (Ui.rarity :: { [string]: { number } })[rarity] or Ui.rarity[Ui.defaultRarity]
		local tile = Tile.new(chance.pet, color, card, "glossy", rarity)
		tile.content.Size = UDim2.fromScale(1, 1 - settings.petBottomShare)
		PetPreview.pet(chance.pet, tile.content, settings.petFill)
		tile.setValue(string.format(settings.chanceText, tostring(chance.percent)))
		table.insert(oddsTiles, tile)
	end

	hatchButton = Button.new({
		name = "HatchButton",
		parent = card,
		text = settings.hatchText,
		color = Ui.colors.confirm,
		gloss = settings.hatchColors,
		pill = { icon = "coins", color = Ui.colors.coins, below = true },
		key = settings.key,
	})
	hatchButton.onActivated(onHatchPressed)
	-- Above its neighbors, so the key and the pill that stick out of it are not covered.
	hatchButton.frame.ZIndex = 2
	table.insert(buttons, hatchButton)

	-- Planned, without a function yet.
	for _, planned in settings.lockedButtons do
		local button = Button.new({
			name = planned.id,
			parent = card,
			text = planned.text,
			color = planned.colors.bottom,
			gloss = planned.colors,
			icon = "lock",
		})
		button.onActivated(function()
			Toast.show(settings.lockedText)
		end)
		table.insert(buttons, button)
	end

	Hud.onLayout(function()
		local size = Hud.screenSize()
		local layout =
			UiLayout.eggCard(Ui.layout, size.X, size.Y, #Ui.menu.entries, Hud.STAT_COUNT, #oddsTiles, #buttons)
		Draw.place(card, layout.card)
		Draw.place(title.frame, layout.title)
		for index, tile in oddsTiles do
			Draw.place(tile.frame, layout.tiles[index])
		end
		for index, button in buttons do
			Draw.place(button.frame, layout.buttons[index])
		end
	end)
end

-- The key is shown on the button unless the player uses touch.
local function refreshKeyHint()
	local touching = UserInputService:GetLastInputType() == Enum.UserInputType.Touch
	hatchButton.setKeyShown(UserInputService.KeyboardEnabled and not touching)
end

function EggStandView.start()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	buildEgg(folder)
	buildSign(folder)
	folder.Parent = Workspace

	buildCard()
	refreshPrice()
	player:GetAttributeChangedSignal(Remotes.Attributes.EggsHatched):Connect(refreshPrice)

	refreshKeyHint()
	UserInputService.LastInputTypeChanged:Connect(refreshKeyHint)
	local key = (Enum.KeyCode :: any)[Ui.eggCard.key]
	UserInputService.InputBegan:Connect(function(input: InputObject, typingInTextBox: boolean)
		if not typingInTextBox and input.KeyCode == key and card.Visible then
			onHatchPressed()
		end
	end)

	RunService.Heartbeat:Connect(function()
		-- Only at the stand, and not while a throw, a window or a hatching is on screen.
		card.Visible = isNearStand()
			and not ThrowSession.isActive()
			and not HatchView.isPlaying()
			and not Window.anyOpen()
	end)
end

return EggStandView
