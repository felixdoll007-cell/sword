--!strict
-- Pure functions for the look of the zones on the main lane: which stretch of the lane belongs
-- to which zone, where its raised walkways lie, where the name of the next zone floats and
-- which color its walls have. Only looks; where the walls stand and what a throw does is not
-- decided here.
--
-- A zone has a look as soon as Config/Ui (world.lane.zones) gives its material a floor. Zones
-- without one stay plain. "Distance" means studs from the throw line along the lane (the lane
-- runs towards negative Z).

local LaneLayout = require("./LaneLayout")
local ThrowZoneLayout = require("./ThrowZoneLayout")
local Walls = require("./Walls")

export type Area = ThrowZoneLayout.Area

export type Tones = { darkColor: { number }, lightColor: { number } }

-- The look of one zone. Everything is optional: a zone with only a name is still plain, but the
-- zone before it can announce it.
export type ZoneStyle = {
	name: string?,
	nameColor: { number }?,
	floor: Tones?,
	walk: { darkColor: { number }, lightColor: { number }, curbColor: { number } }?,
	wall: { color: { number }, frameColor: { number } }?,
	-- Decoration on the walkways, see Rules/Decor.
	decor: any?,
}

export type LookConfig = {
	walk: { width: number, height: number, curbWidth: number, curbAbove: number },
	sign: { heightAboveFloor: number, behindZoneEnd: number },
	zones: { [string]: ZoneStyle },
}

export type LaneConfig = LaneLayout.LaneConfig & {
	throwLine: { x: number, z: number },
	laneWidth: number,
	floorTopY: number,
	materialColors: { [string]: { number } },
}

-- A stretch of the lane floor. material is nil for a plain stretch.
export type Segment = { from: number, to: number, material: string? }

-- One block of a walkway: the walkway itself or the edge between it and the lane.
export type WalkPart = { kind: "walk" | "curb", area: Area, topY: number, material: string }

export type Sign = { x: number, y: number, z: number, text: string, color: { number } }

local ZoneLook = {}

local function style(look: LookConfig, material: string?): ZoneStyle?
	return if material then look.zones[material] else nil
end

-- Does the zone of this material have its own floor?
function ZoneLook.hasFloor(look: LookConfig, material: string?): boolean
	local zoneStyle = style(look, material)
	return zoneStyle ~= nil and zoneStyle.floor ~= nil
end

-- Where a zone starts and ends on the lane. A zone ends at its last wall; the stretch between
-- that wall and the first wall of the next zone belongs to the next zone. The first zone starts
-- at the throw line, the last one reaches to the end of the lane.
function ZoneLook.range(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, zone: number): (number, number)
	local zones = #wallConfig.materials
	local perZone = wallConfig.wallsPerZone
	local from = if zone <= 1 then 0 else LaneLayout.wallDistance(laneConfig, wallConfig, (zone - 1) * perZone)
	local to = if zone >= zones
		then LaneLayout.laneLength(laneConfig, wallConfig)
		else LaneLayout.wallDistance(laneConfig, wallConfig, zone * perZone)
	return from, to
end

-- The lane floor from the throw line to its end, as stretches lying one behind the other.
-- Every zone with a floor look is its own stretch; plain zones next to each other are one.
function ZoneLook.floorSegments(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, look: LookConfig): { Segment }
	local segments: { Segment } = {}
	for zone, material in wallConfig.materials do
		local from, to = ZoneLook.range(laneConfig, wallConfig, zone)
		local styled = ZoneLook.hasFloor(look, material)
		local last = segments[#segments]
		if not styled and last and last.material == nil then
			last.to = to
		else
			table.insert(segments, { from = from, to = to, material = if styled then material else nil })
		end
	end
	return segments
end

-- The piece of ground a stretch of the lane covers.
function ZoneLook.laneArea(laneConfig: LaneConfig, from: number, to: number): Area
	return {
		x = laneConfig.throwLine.x,
		z = laneConfig.throwLine.z - (from + to) / 2,
		width = laneConfig.laneWidth,
		length = to - from,
	}
end

-- Width of one walkway with its edge.
function ZoneLook.walkWidth(look: LookConfig): number
	return math.max(look.walk.width, 0) + math.max(look.walk.curbWidth, 0)
end

-- The raised walkways left and right of a zone, along its whole length: next to the lane the
-- edge, outside of it the walkway. Empty if the zone has no walkways.
function ZoneLook.walks(
	laneConfig: LaneConfig,
	wallConfig: Walls.WallConfig,
	look: LookConfig,
	zone: number
): { WalkPart }
	local material = wallConfig.materials[zone]
	local zoneStyle = style(look, material)
	if not zoneStyle or not zoneStyle.floor or not zoneStyle.walk then
		return {}
	end
	local from, to = ZoneLook.range(laneConfig, wallConfig, zone)
	local lane = ZoneLook.laneArea(laneConfig, from, to)
	local curbWidth = math.max(look.walk.curbWidth, 0)
	local walkWidth = math.max(look.walk.width, 0)
	local walkTop = laneConfig.floorTopY + look.walk.height
	local curbTop = walkTop + look.walk.curbAbove

	local parts: { WalkPart } = {}
	for _, side in { -1, 1 } do
		local laneEdge = lane.x + side * lane.width / 2
		if curbWidth > 0 then
			table.insert(parts, {
				kind = "curb" :: "curb",
				area = { x = laneEdge + side * curbWidth / 2, z = lane.z, width = curbWidth, length = lane.length },
				topY = curbTop,
				material = material,
			})
		end
		if walkWidth > 0 then
			table.insert(parts, {
				kind = "walk" :: "walk",
				area = {
					x = laneEdge + side * (curbWidth + walkWidth / 2),
					z = lane.z,
					width = walkWidth,
					length = lane.length,
				},
				topY = walkTop,
				material = material,
			})
		end
	end
	return parts
end

-- How much room the walkways of the first zone take next to the lane, right in front of the
-- throw zone. The green floor around the throw zone leaves this out. 0 without walkways.
function ZoneLook.walkWidthAtThrowZone(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, look: LookConfig): number
	return if #ZoneLook.walks(laneConfig, wallConfig, look, 1) > 0 then ZoneLook.walkWidth(look) else 0
end

-- The name of the next zone, floating high above the lane at the end of this zone.
-- nil if this zone has no look, if it is the last one, or if the next zone has no name.
function ZoneLook.sign(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, look: LookConfig, zone: number): Sign?
	if not ZoneLook.hasFloor(look, wallConfig.materials[zone]) then
		return nil
	end
	local nextStyle = style(look, wallConfig.materials[zone + 1])
	if not nextStyle or not nextStyle.name or not nextStyle.nameColor then
		return nil
	end
	local _, to = ZoneLook.range(laneConfig, wallConfig, zone)
	return {
		x = laneConfig.throwLine.x,
		y = laneConfig.floorTopY + look.sign.heightAboveFloor,
		z = laneConfig.throwLine.z - (to + look.sign.behindZoneEnd),
		text = nextStyle.name,
		color = nextStyle.nameColor,
	}
end

-- Color of a wall (and of its pieces). Zones without a look keep the plain color of their material.
function ZoneLook.wallColor(laneConfig: LaneConfig, look: LookConfig, material: string): { number }
	local zoneStyle = style(look, material)
	return if zoneStyle and zoneStyle.wall then zoneStyle.wall.color else laneConfig.materialColors[material]
end

-- Color of the thin frame on a wall, or nil if the walls of this material have none.
function ZoneLook.wallFrameColor(look: LookConfig, material: string): { number }?
	local zoneStyle = style(look, material)
	return if zoneStyle and zoneStyle.wall then zoneStyle.wall.frameColor else nil
end

return ZoneLook
