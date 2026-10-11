--!strict
-- The finished look of the throw zone, the first part of the world in the new style:
--   * floor: checkerboard in two tones of ember orange with studs
--   * a slightly raised, darker edge all around, low enough to walk over
--   * "THROW ZONE" written big on the floor, in the font of the interface
--   * the floor around the zone: checkerboard in two tones of calm green. It lies next to the
--     zone and the lane at the same height, in pieces, and never under or over another floor
--     (two floors on top of each other flicker).
-- Only looks. Where the zone is and whether a player stands in it is not touched
-- (Config/Lane, Rules/LaneLayout). All colors and sizes are in Config/Ui (world).
--
-- The checkerboard with its studs is one picture laid as a tiled texture on one big part: the
-- part has the darker tone, the picture is tinted with the lighter one. So a whole floor is
-- two things, not hundreds of small parts. Until the picture is uploaded and named in the
-- config, the floors are plain.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local WallConfig = require(Shared.Config.Walls)
local ThrowZoneLayout = require(Shared.Rules.ThrowZoneLayout)
local ZoneLook = require(Shared.Rules.ZoneLook)

local WorldParts = require(script.Parent.WorldParts)

-- Text size at which the writing is measured. Also the biggest text size Roblox can draw.
local MEASURE_SIZE = 100

local ThrowZoneLook = {}

local color = WorldParts.color

local function makeLine(name: string, text: string, textSize: number, rgb: { number }, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = (Enum.Font :: any)[Ui.font]
	label.Text = text
	label.TextSize = textSize
	label.TextColor3 = color(rgb)
	label.Parent = parent
	return label
end

-- The writing on the floor. It lies on its own invisible plate just above the floor, turned so
-- that it reads the right way up for a player who looks along the lane.
local function addLabel(folder: Instance)
	local settings = Ui.world.throwZone.label
	local area = ThrowZoneLayout.label(LaneConfig, settings)

	local plate = Instance.new("Part")
	plate.Name = "ThrowZoneLabel"
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanTouch = false
	plate.CanQuery = false
	plate.CastShadow = false
	plate.Transparency = 1
	plate.Size = Vector3.new(area.width, area.length, settings.plateThickness)
	-- The plate's front face points up; the top of the writing points along the lane.
	plate.CFrame = CFrame.fromMatrix(
		Vector3.new(area.x, LaneConfig.floorTopY + settings.aboveFloor - settings.plateThickness / 2, area.z),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, -1),
		Vector3.new(0, -1, 0)
	)
	plate.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Writing"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = settings.pixelsPerStud
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = plate

	-- The biggest text size at which the whole writing fits into its room.
	local font = (Enum.Font :: any)[Ui.font]
	local measured = TextService:GetTextSize(settings.text, MEASURE_SIZE, font, Vector2.new(math.huge, math.huge))
	local roomX = area.width * settings.pixelsPerStud * settings.fill
	local roomY = area.length * settings.pixelsPerStud * settings.fill
	local fit = math.min(roomX / math.max(measured.X, 1), roomY / math.max(measured.Y, 1))
	local textSize = math.clamp(math.floor(MEASURE_SIZE * fit), 1, MEASURE_SIZE)
	local strokeThickness = math.max(textSize * settings.strokeShare, 1)

	-- Same style as the text of the interface: black border around every letter, hard shadow below.
	local function outline(label: TextLabel)
		local stroke = Instance.new("UIStroke")
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Color = color(Ui.text.strokeColor)
		stroke.Thickness = strokeThickness
		stroke.Parent = label
	end
	local shadow = makeLine("Shadow", settings.text, textSize, Ui.text.shadowColor, gui)
	shadow.Position = UDim2.fromOffset(0, math.max(math.round(textSize * Ui.text.shadowShare), 1))
	outline(shadow)
	local writing = makeLine("Text", settings.text, textSize, settings.color, gui)
	writing.ZIndex = 2
	outline(writing)
end

-- zoneFloor: the floor part of the throw zone, built by LaneBuilder. folder: where the new parts go.
function ThrowZoneLook.build(zoneFloor: BasePart, folder: Instance)
	local world = Ui.world
	local zone = world.throwZone

	zoneFloor.Color = color(zone.darkColor)
	WorldParts.addFloorTile(zoneFloor, zone.lightColor)

	for index, strip in ThrowZoneLayout.rim(LaneConfig, zone.rim) do
		WorldParts.addBlock(
			folder,
			`ThrowZoneRim{index}`,
			strip,
			LaneConfig.floorTopY + zone.rim.height,
			zone.rim.color
		)
	end

	addLabel(folder)

	-- The green leaves out the walkways that run along the first zone of the lane.
	local green = world.surroundings
	local walkWidth = ZoneLook.walkWidthAtThrowZone(LaneConfig, WallConfig, world.lane)
	for index, piece in ThrowZoneLayout.surroundings(LaneConfig, green, walkWidth) do
		local ground =
			WorldParts.addBlock(folder, `ThrowZoneSurroundings{index}`, piece, LaneConfig.floorTopY, green.darkColor)
		WorldParts.addFloorTile(ground, green.lightColor)
	end
end

return ThrowZoneLook
