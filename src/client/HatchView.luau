--!strict
-- What a player sees when their egg hatches. The world behind is blurred and darkened. Rays
-- turn slowly behind the egg, which sits big in the middle and wobbles more and more. A press
-- opens it at once, otherwise it opens by itself after a few seconds: a white flash, then the
-- pet with its name, its rarity in its color and its bonus, and the rays take the color of the
-- rarity. A press closes.
-- Only showing: when this runs, the server has already taken the coins, rolled the pet and
-- added it (see server/PetService). The pet named in the server's message is what is shown.

local Lighting = game:GetService("Lighting")
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
-- The layers that cover the screen are this many times the screen, so they also cover the
-- strip of Roblox's own buttons at the top.
local BACKDROP_SCREENS = 2
-- Layers from back to front.
local Z_RAYS = 2
local Z_PICTURE = 3
local Z_TEXT = 4
local Z_FLASH = 5
local Z_PRESS = 6
local FULL_TURN = 360

type Step = "idle" | "egg" | "pet"
type Range = { from: number, to: number }
type Strip = {
	frame: Frame,
	-- Direction of the ray this strip belongs to, in degrees.
	rayDegrees: number,
	-- Where the strip sits in the fan of its ray: 0 = in the middle, -1 and 1 = one strip to
	-- each side.
	fan: number,
	-- Its direction before any turning. Worked out in resize().
	degrees: number,
}

local HatchView = {}

local gui: ScreenGui
local blur: BlurEffect
local picture: Frame
local eggHolder: Frame
local eggScale: UIScale
local petHolder: Frame
local petScale: UIScale
local flash: Frame
local nameText: OutlinedText.OutlinedText
local rarityText: OutlinedText.OutlinedText
local bonusText: OutlinedText.OutlinedText
local hintText: OutlinedText.OutlinedText
-- The strips the rays are made of.
local strips: { Strip } = {}

local step: Step = "idle"
local stepStartedAt = 0
-- Counts hatches, so the end of an old one cannot close a newer one.
local token = 0
-- The color the rays take once the egg is open: the color of the pet's rarity.
local openColor: { number } = Ui.rarity[Ui.defaultRarity]
-- How far the rays have turned, and where the egg is in its tilting.
local raysTurned = 0
local wobblePhase = 0

local function between(range: Range, progress: number): number
	return range.from + (range.to - range.from) * progress
end

local function setBlur(shown: boolean)
	if shown then
		blur.Enabled = true
	end
	local info = TweenInfo.new(Ui.hatch.blurSeconds)
	local tween = TweenService:Create(blur, info, { Size = if shown then Ui.window.blurSize else 0 })
	tween.Completed:Connect(function(state: Enum.PlaybackState)
		-- Switched off completely while nothing hatches, so it costs nothing then.
		if state == Enum.PlaybackState.Completed and step == "idle" then
			blur.Enabled = false
		end
	end)
	tween:Play()
end

local function setRayColor(rgb: { number })
	local color = Draw.color(rgb)
	for _, strip in strips do
		strip.frame.BackgroundColor3 = color
	end
end

-- The line at the bottom. An empty text hides it.
local function setHint(text: string)
	hintText.setText(text)
	hintText.frame.Visible = text ~= ""
end

-- Every ray is a fan of narrow strips through the middle of the picture. Each strip fades
-- towards both of its ends and makes two rays, one to each side.
local function buildRays()
	local settings = Ui.hatch.rays
	local lines = math.max(math.floor(settings.count / 2), 1)
	local perRay = math.max(math.floor(settings.stripsPerRay), 1)
	for line = 1, lines do
		for index = 1, perRay do
			local frame = Draw.panel("Ray", settings.color, gui)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)
			frame.Position = UDim2.fromScale(0.5, Ui.hatch.pictureCenterY)
			frame.ZIndex = Z_RAYS
			local fade = Instance.new("UIGradient")
			fade.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, settings.transparency),
				NumberSequenceKeypoint.new(1, 1),
			})
			fade.Parent = frame
			table.insert(strips, {
				frame = frame,
				-- The lines share half a turn: each one points to both sides.
				rayDegrees = (line - 1) * FULL_TURN / 2 / lines,
				fan = index - (perRay + 1) / 2,
				degrees = 0,
			})
		end
	end
end

local function resize()
	local settings = Ui.hatch
	local size = gui.AbsoluteSize
	local short = math.min(size.X, size.Y)
	local edge = math.round(short * settings.pictureShare)
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
	hintText.frame.Size =
		UDim2.fromOffset(math.round(short * settings.hintWidth), math.round(short * settings.hintHeight))

	-- The strips of one ray are fanned out just so far that they still touch at their ends.
	local rays = settings.rays
	local thickness = math.max(short * rays.thickness, 1)
	local reach = math.max(math.max(size.X, size.Y) * rays.reach, 1)
	local fanDegrees = math.deg(math.atan(thickness / reach))
	for _, strip in strips do
		strip.frame.Size = UDim2.fromOffset(math.round(2 * reach), math.round(thickness))
		strip.degrees = strip.rayDegrees + strip.fan * fanDegrees
	end
end

local function close()
	if step == "idle" then
		return
	end
	step = "idle"
	token += 1
	gui.Enabled = false
	setBlur(false)
end

-- The egg opens: a white flash, then the pet pops in.
local function showPet()
	local settings = Ui.hatch
	step = "pet"
	stepStartedAt = os.clock()
	eggHolder.Rotation = 0

	TweenService:Create(eggScale, TweenInfo.new(settings.burstSeconds), { Scale = settings.burstScale }):Play()
	flash.BackgroundTransparency = 0
	flash.Visible = true
	TweenService:Create(flash, TweenInfo.new(settings.flashSeconds), { BackgroundTransparency = 1 }):Play()

	local current = token
	task.delay(settings.burstSeconds, function()
		if current == token then
			eggHolder.Visible = false
		end
	end)
	task.delay(settings.flashSeconds, function()
		if current == token then
			flash.Visible = false
		end
	end)

	-- Behind the flash: the rays change color, the pet and its texts appear.
	setRayColor(openColor)
	petScale.Scale = 0
	petHolder.Visible = true
	local pop = TweenInfo.new(settings.popSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(petScale, pop, { Scale = 1 }):Play()
	for _, text in { nameText, rarityText, bonusText } do
		text.frame.Visible = true
	end
	setHint(settings.closeHintText)
end

local function onPressed()
	-- First press: open the egg. Next press: done.
	if step == "egg" then
		showPet()
	elseif step == "pet" and os.clock() - stepStartedAt >= Ui.hatch.petMinSeconds then
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
	local wasIdle = step == "idle"
	token += 1
	step = "egg"
	stepStartedAt = os.clock()
	wobblePhase = 0

	petHolder:ClearAllChildren()
	petScale = Instance.new("UIScale")
	petScale.Parent = petHolder
	PetPreview.pet(pet.id, petHolder)
	petHolder.Visible = false

	local rarity = PetConfig.rarities[pet.rarity]
	openColor = (Ui.rarity :: { [string]: { number } })[pet.rarity] or Ui.rarity[Ui.defaultRarity]
	nameText.setText(pet.name)
	rarityText.setText(if rarity then string.upper(rarity.name) else "")
	rarityText.setColor(openColor)
	bonusText.setText(string.format(settings.bonusText, tostring(Pets.bonusPercent(PetConfig, pet.id))))
	for _, text in { nameText, rarityText, bonusText } do
		text.frame.Visible = false
	end
	setHint(settings.hatchHintText)
	setRayColor(settings.rays.color)

	eggScale.Scale = 1
	eggHolder.Rotation = 0
	eggHolder.Visible = true
	flash.Visible = false
	resize()
	gui.Enabled = true
	if wasIdle then
		setBlur(true)
	end
end

function HatchView.isPlaying(): boolean
	return step ~= "idle"
end

-- A layer that covers the whole screen.
local function cover(layer: GuiObject)
	layer.AnchorPoint = Vector2.new(0.5, 0.5)
	layer.Position = UDim2.fromScale(0.5, 0.5)
	layer.Size = UDim2.fromScale(BACKDROP_SCREENS, BACKDROP_SCREENS)
end

function HatchView.start()
	local settings = Ui.hatch
	gui = Draw.screen("HatchGui", DISPLAY_ORDER)
	gui.Enabled = false

	blur = Instance.new("BlurEffect")
	blur.Name = "HatchBlur"
	blur.Size = 0
	blur.Enabled = false
	blur.Parent = Lighting

	local dim = Draw.panel("Dim", settings.dimColor, gui)
	dim.BackgroundTransparency = settings.dimTransparency
	cover(dim)

	buildRays()

	-- The square in the middle for egg and pet, a little above the middle to leave room for the texts.
	picture = Draw.box("Picture", gui)
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromScale(0.5, settings.pictureCenterY)
	picture.ZIndex = Z_PICTURE

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

	nameText = OutlinedText.new({ name = "PetName", parent = picture })
	rarityText = OutlinedText.new({ name = "Rarity", parent = picture })
	bonusText = OutlinedText.new({ name = "Bonus", parent = picture, color = Ui.colors.positive })
	for _, text in { nameText, rarityText, bonusText } do
		text.frame.AnchorPoint = Vector2.new(0.5, 0)
		text.frame.ZIndex = Z_TEXT
	end

	hintText = OutlinedText.new({ name = "Hint", parent = gui })
	hintText.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	hintText.frame.Position = UDim2.fromScale(0.5, settings.hintCenterY)
	hintText.frame.ZIndex = Z_TEXT

	-- The white flash when the egg opens.
	flash = Draw.panel("Flash", settings.flashColor, gui)
	flash.ZIndex = Z_FLASH
	flash.Visible = false
	cover(flash)

	-- On top of everything: takes the press that opens the egg or closes the display.
	local press = Instance.new("TextButton")
	press.Name = "Press"
	press.Text = ""
	press.AutoButtonColor = false
	press.BackgroundTransparency = 1
	press.BorderSizePixel = 0
	press.ZIndex = Z_PRESS
	cover(press)
	press.Parent = gui
	press.Activated:Connect(onPressed)

	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)

	RunService.Heartbeat:Connect(function(deltaTime: number)
		if step == "idle" then
			return
		end
		raysTurned = (raysTurned + deltaTime * FULL_TURN / settings.rays.turnSeconds) % FULL_TURN
		for _, strip in strips do
			strip.frame.Rotation = strip.degrees + raysTurned
		end

		local elapsed = os.clock() - stepStartedAt
		if step == "egg" then
			-- The egg tilts to both sides, further and faster the longer it takes.
			local progress = if settings.eggSeconds > 0 then math.clamp(elapsed / settings.eggSeconds, 0, 1) else 1
			wobblePhase += deltaTime * between(settings.wobblesPerSecond, progress) * 2 * math.pi
			eggHolder.Rotation = math.sin(wobblePhase) * between(settings.wobbleDegrees, progress)
			if elapsed >= settings.eggSeconds then
				showPet()
			end
		elseif settings.petSeconds > 0 and elapsed >= settings.petSeconds then
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
