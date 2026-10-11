--!strict
-- What this player sees of the egg stand: the egg on the pedestal (it wobbles a little), the
-- sign floating above it (name and this player's price), and, while the player stands at the
-- stand, the big HATCH button with a row of the pets that can hatch and their chances.
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
local hatchButton: Button.Button
local oddsRow: Frame
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
	local settings = Ui.eggPrompt
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

-- The egg stands on the pedestal. Its shell tilts a little to both sides; the nest stands still.
local function buildEgg(folder: Folder)
	local settings = Ui.world.eggStand
	local stand = PetConfig.egg.position
	local egg = PetPreview.eggModel()
	egg.Name = "Egg"
	local base = CFrame.new(stand.x, LaneConfig.floorTopY + settings.pedestalHeight, stand.z)
	egg:PivotTo(base)
	egg.Parent = folder

	local moving: { BasePart } = {}
	local built: { CFrame } = {}
	for _, part in egg:GetDescendants() do
		if part:IsA("BasePart") and not table.find(settings.stillParts, part.Name) then
			table.insert(moving, part)
			table.insert(built, part.CFrame)
		end
	end
	if #moving == 0 then
		return
	end
	local frames = table.clone(built)
	RunService.Heartbeat:Connect(function()
		local swing = math.sin(os.clock() / settings.wobbleSeconds * 2 * math.pi)
		-- Tilted around the point the egg stands on.
		local tilt = base * CFrame.Angles(0, 0, math.rad(swing * settings.wobbleDegrees)) * base:Inverse()
		for index, frame in built do
			frames[index] = tilt * frame
		end
		Workspace:BulkMoveTo(moving, frames, Enum.BulkMoveMode.FireCFrameChanged)
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

-- The price on the sign is this player's own next price.
local function refreshPrice()
	sign.setText(PRICE_ROW, NumberFormat.abbreviate(NumberFormatConfig, price()))
end

-- The row above the button: one small tile per pet that can hatch, with its chance.
local function buildOdds()
	oddsRow = Draw.box("HatchOdds", Hud.gui())
	oddsRow.Visible = false
	for _, chance in PetConfig.egg.chances do
		local pet = Pets.get(PetConfig, chance.pet)
		if pet then
			local color = (Ui.rarity :: { [string]: { number } })[pet.rarity] or Ui.rarity[Ui.defaultRarity]
			local tile = Tile.new(pet.id, color, oddsRow)
			PetPreview.pet(pet.id, tile.content)
			tile.setValue(string.format(Ui.eggPrompt.chanceText, tostring(chance.percent)))
			table.insert(oddsTiles, tile)
		end
	end
end

function EggStandView.start()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	buildEgg(folder)
	buildSign(folder)
	folder.Parent = Workspace

	refreshPrice()
	player:GetAttributeChangedSignal(Remotes.Attributes.EggsHatched):Connect(refreshPrice)

	hatchButton = Button.new({
		name = "HatchButton",
		parent = Hud.gui(),
		text = Ui.eggPrompt.hatchText,
		color = Ui.colors.confirm,
	})
	hatchButton.frame.Visible = false
	hatchButton.onActivated(onHatchPressed)
	buildOdds()

	Hud.onLayout(function(layout: UiLayout.Hud)
		-- The HATCH button takes the place of the THROW button; the two are never there together.
		Draw.place(hatchButton.frame, layout.throwButton)
		Draw.place(oddsRow, layout.hatchInfo)
		local step = layout.hatchTile + layout.gap
		for index, tile in oddsTiles do
			tile.frame.Position = UDim2.fromOffset(math.round((index - 1) * step), 0)
			tile.frame.Size = UDim2.fromOffset(math.round(layout.hatchTile), math.round(layout.hatchTile))
		end
	end)

	RunService.Heartbeat:Connect(function()
		-- Only at the stand, and not while a throw, a window or a hatching is on screen.
		local shown = isNearStand()
			and not ThrowSession.isActive()
			and not HatchView.isPlaying()
			and not Window.anyOpen()
		hatchButton.frame.Visible = shown
		oddsRow.Visible = shown
	end)
end

return EggStandView
