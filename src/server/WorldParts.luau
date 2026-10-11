--!strict
-- Small helpers for building the floors of the world (throw zone, lane, walkways).
-- A floor is one big part in its darker tone with the floor picture (checkerboard with studs)
-- on top, tinted in its lighter tone. See Config/Ui (world.floorTile).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local ThrowZoneLayout = require(Shared.Rules.ThrowZoneLayout)

-- Things like this in ReplicatedStorage are templates for props (see assets/decor-templates.NOTES.md).
local warnedAbout: { [string]: boolean } = {}

local WorldParts = {}

function WorldParts.color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Lays the floor picture on a part, tinted with the lighter tone.
-- Does nothing while Config/Ui names no picture: the surface is plain then.
-- fieldStuds: edge length of one checkerboard field (default: the one of the world's floors).
-- face: which side of the part (default: its top).
function WorldParts.addFloorTile(part: BasePart, lightColor: { number }, fieldStuds: number?, face: Enum.NormalId?)
	local tile = Ui.world.floorTile
	if tile.image == "" then
		return
	end
	local studsPerPicture = (fieldStuds or tile.fieldStuds) * tile.fieldsPerPicture
	local texture = Instance.new("Texture")
	texture.Name = "FloorTile"
	texture.Face = face or Enum.NormalId.Top
	texture.Texture = tile.image
	texture.Color3 = WorldParts.color(lightColor)
	texture.StudsPerTileU = studsPerPicture
	texture.StudsPerTileV = studsPerPicture
	texture.Parent = part
end

-- A block on the ground that covers this area, with its top at this height.
-- It reaches down as deep as the lane floors, so nothing shows below it.
function WorldParts.addBlock(
	folder: Instance,
	name: string,
	area: ThrowZoneLayout.Area,
	topY: number,
	rgb: { number }
): Part
	local bottomY = LaneConfig.floorTopY - LaneConfig.floorThickness
	local height = math.max(topY - bottomY, LaneConfig.floorThickness)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(area.width, height, area.length)
	part.Position = Vector3.new(area.x, topY - height / 2, area.z)
	part.Color = WorldParts.color(rgb)
	part.Parent = folder
	return part
end

-- An invisible wall standing on this area, from the lane floor up to this height. It stops
-- players and nothing else: it is not drawn, casts no shadow, and Roblox's camera does not
-- zoom in for invisible parts.
function WorldParts.addInvisibleWall(folder: Instance, name: string, area: ThrowZoneLayout.Area, height: number): Part
	local wall = Instance.new("Part")
	wall.Name = name
	wall.Anchored = true
	wall.Transparency = 1
	wall.CastShadow = false
	wall.CanTouch = false
	wall.Size = Vector3.new(area.width, height, area.length)
	wall.Position = Vector3.new(area.x, LaneConfig.floorTopY + height / 2, area.z)
	wall.Parent = folder
	return wall
end

-- An invisible plate lying just above a floor, to draw on (writing, marks). Returns the
-- drawing surface. On it, "up" points along the lanes (towards negative Z) and "right"
-- towards positive X, so things read the right way up for a player looking along a lane.
-- topY: height of the drawing surface.
function WorldParts.addFloorCanvas(
	folder: Instance,
	name: string,
	area: ThrowZoneLayout.Area,
	topY: number,
	pixelsPerStud: number
): SurfaceGui
	local thickness = Ui.world.throwZone.label.plateThickness
	local plate = Instance.new("Part")
	plate.Name = name
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanTouch = false
	plate.CanQuery = false
	plate.CastShadow = false
	plate.Transparency = 1
	plate.Size = Vector3.new(area.width, area.length, thickness)
	-- The plate's front face points up; the top of the drawing points along the lane.
	plate.CFrame = CFrame.fromMatrix(
		Vector3.new(area.x, topY - thickness / 2, area.z),
		Vector3.new(-1, 0, 0),
		Vector3.new(0, 0, -1),
		Vector3.new(0, -1, 0)
	)
	plate.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Name = "Drawing"
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = pixelsPerStud
	gui.LightInfluence = 0
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = plate
	return gui
end

-- A prop built from a template: decoration that stands still and has no collision.
-- Returns nil (and warns once) if the template is missing in the place.
function WorldParts.addProp(
	folder: Instance,
	name: string,
	templateName: string,
	placement: { x: number, y: number, z: number, yawDegrees: number }
): Model?
	local templates = ReplicatedStorage:FindFirstChild(Ui.world.decor.templateFolder)
	local template = templates and templates:FindFirstChild(templateName)
	if not template or not template:IsA("Model") then
		if not warnedAbout[templateName] then
			warnedAbout[templateName] = true
			warn(`[WorldParts] template {templateName} not found in ReplicatedStorage, left out`)
		end
		return nil
	end
	local model = template:Clone()
	model.Name = name
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	model:PivotTo(
		CFrame.new(placement.x, placement.y, placement.z) * CFrame.Angles(0, math.rad(placement.yawDegrees), 0)
	)
	model.Parent = folder
	return model
end

return WorldParts
