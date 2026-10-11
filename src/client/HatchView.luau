--!strict
-- What a player sees when their egg hatches: the egg in the middle of the screen wobbles,
-- bursts, and the pet appears with its name, its rarity in its color and its bonus. About two
-- seconds; a press anywhere skips ahead (first to the pet, then away).
-- Only showing: when this runs, the server has already taken the coins, rolled the pet and
-- added it (see server/PetService). The pet named in the server's message is what is shown.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local PetConfig = require(Shared.Config.Pets)
local Ui = require(Shared.Config.Ui)
local Pets = require(Shared.Rules.Pets)

local Draw = require(script.Parent.Ui.Draw)
local OutlinedText = require(script.Parent.Ui.OutlinedText)
local PetPreview = require(script.Parent.Ui.PetPreview)

-- Above the windows and the short messages.
local DISPLAY_ORDER = 30
-- The dark layer is this many times the screen, so it also covers the strip of Roblox's own
-- buttons at the top.
local BACKDROP_SCREENS = 2

type Step = "idle" | "egg" | "pet"

local HatchView = {}

local gui: ScreenGui
local backdrop: TextButton
local picture: Frame
local eggHolder: Frame
local eggScale: UIScale
local petHolder: Frame
local petScale: UIScale
local flash: Frame
local nameText: OutlinedText.OutlinedText
local rarityText: OutlinedText.OutlinedText
local bonusText: OutlinedText.OutlinedText

local step: Step = "idle"
local stepEndsAt = 0
-- Counts hatches, so the end of an old one cannot close a newer one.
local token = 0

local function resize()
	local settings = Ui.hatch
	local size = gui.AbsoluteSize
	local edge = math.round(math.min(size.X, size.Y) * settings.pictureShare)
	picture.Size = UDim2.fromOffset(edge, edge)
	local y = edge
	for _, entry in
		{
			{ text = nameText, height = settings.nameHeight },
			{ text = rarityText, height = settings.rarityHeight },
			{ text = bonusText, height = settings.bonusHeight },
		}
	do
		local height = math.round(edge * entry.height)
		entry.text.frame.Position = UDim2.new(0.5, 0, 0, y)
		-- Wider than the picture, so long names fit.
		entry.text.frame.Size = UDim2.fromOffset(edge * 2, height)
		y += height
	end
end

local function close()
	if step == "idle" then
		return
	end
	step = "idle"
	token += 1
	gui.Enabled = false
end

-- The egg bursts and the pet pops in.
local function showPet()
	local settings = Ui.hatch
	step = "pet"
	stepEndsAt = os.clock() + settings.petSeconds
	eggHolder.Rotation = 0

	local burst = TweenInfo.new(settings.burstSeconds)
	TweenService:Create(eggScale, burst, { Scale = settings.burstScale }):Play()
	flash.BackgroundTransparency = 0
	flash.Visible = true
	TweenService:Create(flash, burst, { BackgroundTransparency = 1 }):Play()

	local current = token
	task.delay(settings.burstSeconds, function()
		if current ~= token then
			return
		end
		eggHolder.Visible = false
		flash.Visible = false
	end)

	petScale.Scale = 0
	petHolder.Visible = true
	local pop = TweenInfo.new(settings.popSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(petScale, pop, { Scale = 1 }):Play()
	for _, text in { nameText, rarityText, bonusText } do
		text.frame.Visible = true
	end
end

local function onPressed()
	-- First press: skip the egg. Second press: done.
	if step == "egg" then
		showPet()
	elseif step == "pet" then
		close()
	end
end

-- Plays the hatching of this pet. A hatch that is still playing is replaced.
function HatchView.play(petId: string)
	local settings = Ui.hatch
	local pet = Pets.get(PetConfig, petId)
	if not pet then
		return
	end
	token += 1
	step = "egg"
	stepEndsAt = os.clock() + settings.eggSeconds

	petHolder:ClearAllChildren()
	petScale = Instance.new("UIScale")
	petScale.Parent = petHolder
	PetPreview.pet(pet.id, petHolder)
	petHolder.Visible = false

	local rarity = PetConfig.rarities[pet.rarity]
	local rarityColor = (Ui.rarity :: { [string]: { number } })[pet.rarity] or Ui.rarity[Ui.defaultRarity]
	nameText.setText(pet.name)
	rarityText.setText(if rarity then string.upper(rarity.name) else "")
	rarityText.setColor(rarityColor)
	bonusText.setText(string.format(settings.bonusText, tostring(Pets.bonusPercent(PetConfig, pet.id))))
	for _, text in { nameText, rarityText, bonusText } do
		text.frame.Visible = false
	end

	eggScale.Scale = 1
	eggHolder.Rotation = 0
	eggHolder.Visible = true
	flash.Visible = false
	resize()
	gui.Enabled = true
end

function HatchView.isPlaying(): boolean
	return step ~= "idle"
end

function HatchView.start()
	local settings = Ui.hatch
	gui = Draw.screen("HatchGui", DISPLAY_ORDER)
	gui.Enabled = false

	-- Darkens the whole screen and takes the press that skips ahead.
	backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.BorderSizePixel = 0
	backdrop.BackgroundColor3 = Draw.color(Ui.window.dimColor)
	backdrop.BackgroundTransparency = settings.dimTransparency
	backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
	backdrop.Position = UDim2.fromScale(0.5, 0.5)
	backdrop.Size = UDim2.fromScale(BACKDROP_SCREENS, BACKDROP_SCREENS)
	backdrop.Parent = gui
	backdrop.Activated:Connect(onPressed)

	-- The square in the middle for egg and pet, a little above the middle to leave room for the texts.
	picture = Draw.box("Picture", gui)
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, settings.pictureCenterY)

	eggHolder = Draw.box("Egg", picture)
	eggHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	eggHolder.Position = UDim2.fromScale(0.5, 0.5)
	eggScale = Instance.new("UIScale")
	eggScale.Parent = eggHolder
	PetPreview.egg(eggHolder)

	petHolder = Draw.box("Pet", picture)
	petHolder.AnchorPoint = Vector2.new(0.5, 0.5)
	petHolder.Position = UDim2.fromScale(0.5, 0.5)
	petHolder.ZIndex = 2
	petScale = Instance.new("UIScale")
	petScale.Parent = petHolder

	-- A short white flash when the egg bursts.
	flash = Draw.panel("Flash", settings.flashColor, picture)
	flash.ZIndex = 3
	flash.Visible = false
	Draw.corner(flash, Ui.corners.round)

	nameText = OutlinedText.new({ name = "PetName", parent = picture })
	rarityText = OutlinedText.new({ name = "Rarity", parent = picture })
	bonusText = OutlinedText.new({ name = "Bonus", parent = picture, color = Ui.colors.positive })
	for _, text in { nameText, rarityText, bonusText } do
		text.frame.AnchorPoint = Vector2.new(0.5, 0)
		text.frame.ZIndex = 4
	end

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)

	RunService.Heartbeat:Connect(function()
		if step == "idle" then
			return
		end
		local now = os.clock()
		if step == "egg" then
			-- The egg tilts to both sides.
			local swing = math.sin(now * settings.wobblesPerSecond * 2 * math.pi)
			eggHolder.Rotation = swing * settings.wobbleDegrees
			if now >= stepEndsAt then
				showPet()
			end
		elseif now >= stepEndsAt then
			close()
		end
	end)

	Remotes.EggHatched.OnClientEvent:Connect(function(petId: unknown)
		-- The server is trusted, but a broken value must not break the client.
		if typeof(petId) == "string" then
			HatchView.play(petId)
		end
	end)
end

return HatchView
