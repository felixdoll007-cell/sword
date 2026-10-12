--!strict
-- What this player sees of the egg stand: the egg floating above the pedestal (it bobs and
-- turns slowly), the sign floating above it (name and this player's price), and, while the
-- player stands at the stand, a window with the pets that can hatch, their chances and the
-- HATCH button with the price in it.
-- The pedestal is made by the server (server/PetService). Pressing HATCH only tells the server
-- "I want to hatch an egg"; coins, room and the pet are decided there.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
local window: Window.Window
local hatchButton: Button.Button
local oddsTiles: { Tile.Tile } = {}
-- Where everything in the window sits on the current screen.
local layout: UiLayout.EggWindow
-- os.clock() until which presses are ignored after a press.
local pressBlockedUntil = 0
-- The player closed the window with its X: it stays away until they walk off and come back.
local dismissed = false
-- true while this view closes the window itself (and not the player).
local closingMyself = false

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
	local settings = Ui.eggWindow
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

-- The window: one tile per pet that can hatch, in the color of its rarity, with its chance.
-- Below them the HATCH button; the room right of it stays free for later buttons.
local function buildWindow()
	local settings = Ui.eggWindow
	local petCount = #PetConfig.egg.chances
	window = Window.new({
		name = "EggWindow",
		title = PetConfig.egg.name,
		place = function(screenWidth: number, screenHeight: number): UiLayout.Rect
			layout = UiLayout.eggWindow(
				Ui.layout,
				screenWidth,
				screenHeight,
				#Ui.menu.entries,
				Hud.STAT_COUNT,
				petCount,
				Ui.window.paddingFactor
			)
			return layout.window
		end,
	})

	for _, chance in PetConfig.egg.chances do
		local pet = Pets.get(PetConfig, chance.pet)
		local rarity = if pet then pet.rarity else Ui.defaultRarity
		local color = (Ui.rarity :: { [string]: { number } })[rarity] or Ui.rarity[Ui.defaultRarity]
		local tile = Tile.new(chance.pet, color, window.content, "filled")
		PetPreview.pet(chance.pet, tile.content)
		tile.setValue(string.format(settings.chanceText, tostring(chance.percent)))
		table.insert(oddsTiles, tile)
	end

	hatchButton = Button.new({
		name = "HatchButton",
		parent = window.content,
		text = settings.hatchText,
		color = Ui.colors.confirm,
		pill = { icon = "coins", color = Ui.colors.coins },
	})
	hatchButton.onActivated(onHatchPressed)

	window.onResize(function()
		for index, tile in oddsTiles do
			Draw.place(tile.frame, layout.tiles[index])
		end
		Draw.place(hatchButton.frame, layout.button)
	end)
	window.onLeave(function()
		if not closingMyself then
			dismissed = true
		end
	end)
end

function EggStandView.start()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	buildEgg(folder)
	buildSign(folder)
	folder.Parent = Workspace

	buildWindow()
	refreshPrice()
	player:GetAttributeChangedSignal(Remotes.Attributes.EggsHatched):Connect(refreshPrice)

	RunService.Heartbeat:Connect(function()
		local near = isNearStand()
		if not near then
			dismissed = false
		end
		-- Only at the stand, and not while a throw, another window or a hatching is on screen.
		local shown = near
			and not dismissed
			and not ThrowSession.isActive()
			and not HatchView.isPlaying()
			and not Window.anyOpen()
		if shown and not window.isOpen() then
			window.open()
		elseif not shown and window.isOpen() then
			closingMyself = true
			window.close()
			closingMyself = false
		end
	end)
end

return EggStandView
