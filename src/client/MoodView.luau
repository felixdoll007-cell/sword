--!strict
-- Sky and light. A "mood" is one complete set of values: time of day, sunlight, light in the
-- shadows, haze at the horizon, glow of bright parts and color tuning. All moods are in
-- Config/Ui (world.moods); this script sets one of them, with built-in Roblox means only.
-- It runs on each client, so later a zone can switch to its own mood for the player who is
-- there. Only looks.
--
-- Not set from here: which lighting technology Roblox uses (cheap soft "Voxel" lighting, set in
-- default.project.json). Scripts are not allowed to change it.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)

-- Names of the things this script keeps in Lighting. Found again when a mood is set anew.
local ATMOSPHERE_NAME = "MoodAtmosphere"
local SKY_NAME = "MoodSky"
local GLOW_NAME = "MoodGlow"
local COLOR_NAME = "MoodColor"

local MoodView = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- The thing of this class and name in Lighting; made if it is not there yet.
local function ensure(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local made = Instance.new(className)
	made.Name = name
	made.Parent = Lighting
	return made
end

-- Sets the mood with this name. Unknown names are ignored with a warning.
function MoodView.apply(name: string)
	local mood = (Ui.world.moods :: { [string]: any })[name]
	if not mood then
		warn(`[MoodView] no mood named {name} in the config`)
		return
	end

	-- Sun: where it stands and how strong it is.
	Lighting.ClockTime = mood.clockTime
	Lighting.GeographicLatitude = mood.latitude
	Lighting.Brightness = mood.brightness
	Lighting.ExposureCompensation = mood.exposure
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = mood.shadowSoftness
	-- Light in the shadows, so nothing turns black.
	Lighting.Ambient = color(mood.shadowLight)
	Lighting.OutdoorAmbient = color(mood.skyLight)
	Lighting.ColorShift_Top = color(mood.sunTint)
	Lighting.ColorShift_Bottom = color(mood.shadeTint)
	Lighting.EnvironmentDiffuseScale = mood.environmentLight
	Lighting.EnvironmentSpecularScale = mood.environmentShine

	-- Haze: the distance fades softly into the sky.
	local atmosphere = ensure("Atmosphere", ATMOSPHERE_NAME) :: Atmosphere
	atmosphere.Density = mood.haze.density
	atmosphere.Offset = mood.haze.offset
	atmosphere.Haze = mood.haze.horizon
	atmosphere.Glare = mood.haze.glare
	atmosphere.Color = color(mood.haze.color)
	atmosphere.Decay = color(mood.haze.sunsetColor)

	-- Roblox's own sky picture, with the sun.
	local sky = ensure("Sky", SKY_NAME) :: Sky
	sky.CelestialBodiesShown = true
	sky.SunAngularSize = mood.sky.sunSize
	sky.MoonAngularSize = mood.sky.moonSize
	sky.StarCount = mood.sky.stars

	-- A slight glow around bright parts (lanterns, neon).
	local glow = ensure("BloomEffect", GLOW_NAME) :: BloomEffect
	glow.Intensity = mood.glow.intensity
	glow.Size = mood.glow.size
	glow.Threshold = mood.glow.threshold

	-- Strong but not garish colors.
	local tuning = ensure("ColorCorrectionEffect", COLOR_NAME) :: ColorCorrectionEffect
	tuning.Saturation = mood.color.saturation
	tuning.Contrast = mood.color.contrast
	tuning.Brightness = mood.color.brightness
	tuning.TintColor = color(mood.color.tint)
end

-- Sets the mood the game starts with.
function MoodView.start()
	MoodView.apply(Ui.world.startMood)
end

return MoodView
