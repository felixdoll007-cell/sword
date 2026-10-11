--!strict
-- Small helpers for building the floors of the world (throw zone, lane, walkways).
-- A floor is one big part in its darker tone with the floor picture (checkerboard with studs)
-- on top, tinted in its lighter tone. See Config/Ui (world.floorTile).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local ThrowZoneLayout = require(Shared.Rules.ThrowZoneLayout)

local WorldParts = {}

function WorldParts.color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- Lays the floor picture on the top of a part, tinted with the lighter tone.
-- Does nothing while Config/Ui names no picture: the floor is plain then.
function WorldParts.addFloorTile(part: BasePart, lightColor: { number })
	local tile = Ui.world.floorTile
	if tile.image == "" then
		return
	end
	local texture = Instance.new("Texture")
	texture.Name = "FloorTile"
	texture.Face = Enum.NormalId.Top
	texture.Texture = tile.image
	texture.Color3 = WorldParts.color(lightColor)
	texture.StudsPerTileU = tile.fieldStuds * tile.fieldsPerPicture
	texture.StudsPerTileV = tile.fieldStuds * tile.fieldsPerPicture
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

return WorldParts
