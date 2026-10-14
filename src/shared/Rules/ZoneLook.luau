--!strict
-- Pure functions for the look of the zones on the main lane: which stretch of the lane belongs
-- to which zone, where its raised walkways and the invisible fence around them lie, where the name of the next zone floats and
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

-- Upright stripes on a wall: how many, and the width of one as a share of the wall's width.
export type Stripes = { count: number, color: { number }, widthShare: number }
-- A level band on a wall: where its middle sits (0 = top of the wall, 1 = bottom) and its height
-- as a share of the wall's height.
export type Band = { color: { number }, centerY: number, heightShare: number }

-- What a wall model does when the weapon bounces off it.
export type WallHit = { wobbleDegrees: number, wobbleSeconds: number, wobbleSwings: number, darken: number }
-- A model shown instead of the plain wall. cover...: the modelled size of the part of it that
-- has to hide the wall.
export type WallModel = {
	template: string,
	coverWidth: number,
	coverHeight: number,
	coverDepth: number,
	sinkStuds: number?,
	hit: WallHit?,
}
-- How a wall model is set onto its wall: how many times as big as modelled, how far its foot
-- stands below the floor, and how far its middle lies from the wall's middle towards the thrower.
export type ModelPlace = { scale: number, sinkStuds: number, towardsThrower: number }

export type WallStyle = {
	color: { number },
	frameColor: { number }?,
	stripes: Stripes?,
	band: Band?,
	scratch: boolean?,
	model: WallModel?,
}

-- A rectangle on the face of a wall, in shares of the face: x and y of its top left corner
-- (0, 0 = top left of the wall), width and height.
export type FaceRect = { x: number, y: number, width: number, height: number, color: { number } }

-- The look of one zone. Everything is optional: a zone with only a name is still plain, but the
-- zone before it can announce it.
export type ZoneStyle = {
	name: string?,
	nameColor: { number }?,
	-- The name floats this many studs higher than the other names (for a tall gate below it).
	nameRaise: number?,
	floor: Tones?,
	walk: { darkColor: { number }, lightColor: { number }, curbColor: { number } }?,
	wall: WallStyle?,
	-- Decoration on the walkways, see Rules/Decor.
	decor: any?,
}

export type WalkConfig = {
	curbWidth: number,
	curbAbove: number,
	innerWidth: number,
	innerHeight: number,
	outerWidth: number,
	outerHeight: number,
	fenceThickness: number,
}

export type LookConfig = {
	walk: WalkConfig,
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

-- One block of a walkway: the edge towards the lane, the inner (lower) step or the outer
-- (higher) step.
export type WalkPart = { kind: "curb" | "inner" | "outer", side: number, area: Area, topY: number, material: string }

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

-- Width of one walkway from the lane's edge to its outer edge: edge, inner step, outer step.
function ZoneLook.walkWidth(look: LookConfig): number
	local walk = look.walk
	return math.max(walk.curbWidth, 0) + math.max(walk.innerWidth, 0) + math.max(walk.outerWidth, 0)
end

local function hasWalks(look: LookConfig, material: string?): boolean
	local zoneStyle = style(look, material)
	return zoneStyle ~= nil and zoneStyle.floor ~= nil and zoneStyle.walk ~= nil
end

-- The raised walkways left and right of a zone, along its whole length. From the lane outwards:
-- the edge, the inner step, the higher outer step. The blocks lie next to each other, none on
-- top of another. Empty if the zone has no walkways.
-- side: -1 = left of the lane (smaller X), 1 = right of it.
function ZoneLook.walks(
	laneConfig: LaneConfig,
	wallConfig: Walls.WallConfig,
	look: LookConfig,
	zone: number
): { WalkPart }
	local material = wallConfig.materials[zone]
	if not hasWalks(look, material) then
		return {}
	end
	local from, to = ZoneLook.range(laneConfig, wallConfig, zone)
	local lane = ZoneLook.laneArea(laneConfig, from, to)
	local walk = look.walk
	local floor = laneConfig.floorTopY
	local strips: { { kind: "curb" | "inner" | "outer", width: number, topY: number } } = {
		{ kind = "curb", width = math.max(walk.curbWidth, 0), topY = floor + walk.innerHeight + walk.curbAbove },
		{ kind = "inner", width = math.max(walk.innerWidth, 0), topY = floor + walk.innerHeight },
		{ kind = "outer", width = math.max(walk.outerWidth, 0), topY = floor + walk.outerHeight },
	}

	local parts: { WalkPart } = {}
	for _, side in { -1, 1 } do
		-- Distance from the lane's edge at which the next strip starts.
		local offset = 0
		for _, strip in strips do
			if strip.width > 0 then
				table.insert(parts, {
					kind = strip.kind,
					side = side,
					area = {
						x = lane.x + side * (lane.width / 2 + offset + strip.width / 2),
						z = lane.z,
						width = strip.width,
						length = lane.length,
					},
					topY = strip.topY,
					material = material,
				})
			end
			offset += strip.width
		end
	end
	return parts
end

-- Invisible walls that keep players off the walkways: across each walkway's start and end, and
-- along its outer edge. (Towards the lane the lane's own barrier already stands.) They lie
-- inside the walkway's outline, flush with its outer faces.
function ZoneLook.fences(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, look: LookConfig, zone: number): { Area }
	if not hasWalks(look, wallConfig.materials[zone]) then
		return {}
	end
	local from, to = ZoneLook.range(laneConfig, wallConfig, zone)
	local lane = ZoneLook.laneArea(laneConfig, from, to)
	local width = ZoneLook.walkWidth(look)
	local thickness = math.min(math.max(look.walk.fenceThickness, 0), width, lane.length / 2)
	if width <= 0 or thickness <= 0 then
		return {}
	end
	local nearZ = lane.z + lane.length / 2
	local farZ = lane.z - lane.length / 2

	local fences: { Area } = {}
	for _, side in { -1, 1 } do
		local middleX = lane.x + side * (lane.width / 2 + width / 2)
		local outerX = lane.x + side * (lane.width / 2 + width - thickness / 2)
		table.insert(fences, { x = middleX, z = nearZ - thickness / 2, width = width, length = thickness })
		table.insert(fences, { x = middleX, z = farZ + thickness / 2, width = width, length = thickness })
		-- Between the two, so the three do not overlap.
		table.insert(fences, { x = outerX, z = lane.z, width = thickness, length = lane.length - 2 * thickness })
	end
	return fences
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
		y = laneConfig.floorTopY + look.sign.heightAboveFloor + (if typeof(nextStyle.nameRaise) == "number"
				and nextStyle.nameRaise == nextStyle.nameRaise
			then nextStyle.nameRaise
			else 0),
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

-- What is drawn on the walls of this material besides their color: upright stripes, spread
-- evenly over the wall's width, and on top of them a level band. From back to front. Empty for
-- walls without a pattern. Everything stays on the wall.
function ZoneLook.wallPattern(look: LookConfig, material: string): { FaceRect }
	local zoneStyle = style(look, material)
	local wall = zoneStyle and zoneStyle.wall
	local rects: { FaceRect } = {}
	if not wall then
		return rects
	end
	local stripes = wall.stripes
	if stripes then
		local count = math.max(math.floor(stripes.count), 0)
		-- Never so wide that two stripes touch.
		local width = if count > 0 then math.clamp(stripes.widthShare, 0, 1 / count) else 0
		for index = 1, count do
			if width > 0 then
				table.insert(rects, {
					x = (index - 0.5) / count - width / 2,
					y = 0,
					width = width,
					height = 1,
					color = stripes.color,
				})
			end
		end
	end
	local band = wall.band
	if band then
		local height = math.clamp(band.heightShare, 0, 1)
		local top = math.clamp(band.centerY - height / 2, 0, 1 - height)
		if height > 0 then
			table.insert(rects, { x = 0, y = top, width = 1, height = height, color = band.color })
		end
	end
	return rects
end

local function isNumber(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) ~= math.huge
end

-- Whether the wall the weapon bounces off gets a scratch. Yes, unless its zone says no.
function ZoneLook.wallScratch(look: LookConfig, material: string): boolean
	local zoneStyle = style(look, material)
	return not (zoneStyle and zoneStyle.wall and zoneStyle.wall.scratch == false)
end

-- The model shown instead of the plain walls of this material, or nil if they have none.
function ZoneLook.wallModel(look: LookConfig, material: string): WallModel?
	local zoneStyle = style(look, material)
	return if zoneStyle and zoneStyle.wall then zoneStyle.wall.model else nil
end

-- How a wall model is set onto a wall of this size: evenly bigger until its covering part hides
-- the whole wall, its front level with the wall's front. nil if the model's sizes are broken.
function ZoneLook.wallModelPlace(
	model: WallModel,
	wallWidth: number,
	wallHeight: number,
	wallThickness: number
): ModelPlace?
	for _, value in { model.coverWidth, model.coverHeight, model.coverDepth } do
		if not isNumber(value) or value <= 0 then
			return nil
		end
	end
	local scale = math.max(wallWidth / model.coverWidth, wallHeight / model.coverHeight)
	local sink = if isNumber(model.sinkStuds) then math.max(model.sinkStuds :: number, 0) else 0
	-- Sunk into the floor it must still reach the top of the wall.
	scale = math.max(scale, (wallHeight + sink) / model.coverHeight)
	return {
		scale = scale,
		sinkStuds = sink,
		towardsThrower = wallThickness / 2 - model.coverDepth * scale / 2,
	}
end

-- How far a wall model leans at this time after a hit, in degrees: it rocks there and back and
-- calms down. 0 before the hit and once it is over.
function ZoneLook.wobbleDegrees(hit: WallHit, time: number): number
	if not isNumber(time) or not isNumber(hit.wobbleSeconds) or not isNumber(hit.wobbleDegrees) then
		return 0
	end
	if time <= 0 or time >= hit.wobbleSeconds then
		return 0
	end
	local swings = if isNumber(hit.wobbleSwings) then math.max(hit.wobbleSwings, 0) else 0
	local progress = time / hit.wobbleSeconds
	return hit.wobbleDegrees * (1 - progress) * math.sin(progress * swings * 2 * math.pi)
end

-- How much darker a wall model is after a hit: 0 = unchanged, 1 = black.
function ZoneLook.hitDarken(hit: WallHit): number
	return if isNumber(hit.darken) then math.clamp(hit.darken, 0, 1) else 0
end

return ZoneLook
