--!strict
-- Pure functions for the decoration of a zone: which model stands where, which way it is
-- turned and how big it is. Only looks.
--
-- Decoration is scenery on the outer, higher step of a zone's walkways. Every piece is listed
-- by hand in Config/Ui (so it does not look lined up); this file turns that list into places in
-- the world and keeps it within limits: pieces stay on the outer step, sizes stay close to the
-- modelled size, and a zone never has more pieces than allowed.

local LaneLayout = require("./LaneLayout")
local Walls = require("./Walls")
local ZoneLook = require("./ZoneLook")

-- One piece as written in the config.
export type Piece = {
	model: string,
	-- "left" or "right" of the lane, seen from the throw zone.
	side: string,
	-- Distance from the start of the zone, in studs.
	along: number,
	-- Where on the outer step: 0 = its inner edge, 1 = its outer edge.
	across: number,
	-- Turned this much away from looking straight at the lane.
	turnDegrees: number?,
	-- 1 = as modelled.
	scale: number?,
	-- false: no light, even if the model has one.
	light: boolean?,
}

export type ZoneDecor = { pieces: { Piece } }

-- A gate across the lane, as written in the config: which model, and its distance from the
-- start of the zone in studs.
export type Gate = { model: string, along: number }

-- A gate at the end of the lane: which model, and how far behind the end of the lane floor its
-- front stands, in studs.
export type EndGate = { model: string, behindLaneEnd: number }

export type Limits = {
	maxScaleChange: number,
	maxPiecesPerZone: number,
}

-- What the game needs to know about one decoration model to turn it.
export type ModelFacing = {
	-- The direction, in the model's own space, of its front. Only x and z count.
	front: { x: number, z: number },
	-- 0 = the front looks straight at the lane. More turns it towards the throw zone.
	turnTowardsThrowZoneDegrees: number?,
	-- For a model that may differ more (or less) in size than Limits allows.
	maxScaleChange: number?,
	-- The model is shown this many times as big as it was modelled. Left out = 1.
	size: number?,
	-- How far its front lies in front of its pivot, in its own studs (for a gate at the end).
	frontDepth: number?,
}

-- A part that tips forward every now and then: within downSeconds down, holdSeconds down, then
-- within backSeconds back, once every everySeconds.
export type Tip = {
	-- How far it sinks, and how far its front end is lifted above the modelled position at rest.
	degrees: number,
	restDegrees: number?,
	everySeconds: number,
	downSeconds: number,
	holdSeconds: number,
	backSeconds: number,
}

export type Placement = {
	model: string,
	-- -1 = left walkway (smaller X), 1 = right walkway, 0 = across the lane (a gate).
	side: number,
	x: number,
	-- Height of the ground the piece stands on.
	y: number,
	z: number,
	-- Turn around the upright axis, in degrees (as used by CFrame.Angles).
	yawDegrees: number,
	scale: number,
	-- false: built without its model's light.
	light: boolean?,
}

local SIDES: { [string]: number } = { left = -1, right = 1 }

local Decor = {}

local function isNumber(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) ~= math.huge
end

-- Direction of a flat vector as an angle that grows when turned with CFrame.Angles(0, angle, 0).
local function heading(x: number, z: number): number
	return math.atan2(-z, x)
end

-- Keeps an angle between -180 and 180 degrees.
local function wrap(degrees: number): number
	return (degrees + 180) % 360 - 180
end

-- How far a model must be turned so that its front looks at the lane from this side of it.
function Decor.yawDegrees(facing: ModelFacing, side: number): number
	local turn = math.rad(facing.turnTowardsThrowZoneDegrees or 0)
	-- Left of the lane the lane lies towards positive X, right of it towards negative X.
	-- The throw zone lies towards positive Z from both.
	local wanted = if side < 0 then -turn else math.pi + turn
	return wrap(math.deg(wanted - heading(facing.front.x, facing.front.z)))
end

-- The size a piece is shown at: what the config asks for, but never further from the modelled
-- size than allowed. modelLimit: the model's own limit, if it has one.
function Decor.scale(limits: Limits, wanted: number?, modelLimit: number?): number
	if not isNumber(wanted) then
		return 1
	end
	local change = math.max(if isNumber(modelLimit) then modelLimit :: number else limits.maxScaleChange, 0)
	return math.clamp(wanted :: number, 1 - change, 1 + change)
end

-- How many times as big as modelled a model is shown before a piece's own scale: what the
-- config says, 1 if that is missing or broken.
function Decor.modelSize(size: number?): number
	if not isNumber(size) or (size :: number) <= 0 then
		return 1
	end
	return size :: number
end

-- All pieces of decoration of a zone, in the order of the list. Empty if the zone has no
-- walkways or no decoration.
-- facings: how each model is turned. Left out are: pieces of a model that is not listed there,
-- pieces with a broken entry, pieces beyond the end of the zone, and pieces beyond the limit.
function Decor.placements(
	laneConfig: ZoneLook.LaneConfig,
	wallConfig: Walls.WallConfig,
	look: ZoneLook.LookConfig,
	decor: ZoneDecor?,
	facings: { [string]: ModelFacing },
	limits: Limits,
	zone: number
): { Placement }
	local placements: { Placement } = {}
	if not decor then
		return placements
	end
	-- The outer step on each side.
	local outer: { [number]: ZoneLook.WalkPart } = {}
	for _, part in ZoneLook.walks(laneConfig, wallConfig, look, zone) do
		if part.kind == "outer" then
			outer[part.side] = part
		end
	end
	local from, to = ZoneLook.range(laneConfig, wallConfig, zone)

	for _, piece in decor.pieces do
		if #placements >= limits.maxPiecesPerZone then
			break
		end
		local side = SIDES[piece.side]
		local step = if side then outer[side] else nil
		local facing = facings[piece.model]
		local valid = step ~= nil
			and facing ~= nil
			and isNumber(piece.along)
			and isNumber(piece.across)
			and piece.along >= 0
			and piece.along <= to - from
		if valid and step and facing then
			local area = step.area
			-- The inner edge of the step is the one nearer to the lane.
			local innerEdge = area.x - side * area.width / 2
			table.insert(placements, {
				model = piece.model,
				side = side,
				x = innerEdge + side * area.width * math.clamp(piece.across, 0, 1),
				y = step.topY,
				z = laneConfig.throwLine.z - (from + piece.along),
				yawDegrees = wrap(
					Decor.yawDegrees(facing, side)
						+ (if isNumber(piece.turnDegrees) then piece.turnDegrees :: number else 0)
				),
				scale = Decor.modelSize(facing.size) * Decor.scale(limits, piece.scale, facing.maxScaleChange),
				light = piece.light ~= false,
			})
		end
	end
	return placements
end

-- How far a tipping part is down at this time: 0 = at rest, 1 = all the way down. It starts
-- and stops softly.
function Decor.tipProgress(tip: Tip, time: number): number
	if not isNumber(time) or not isNumber(tip.everySeconds) or tip.everySeconds <= 0 then
		return 0
	end
	local down = math.max(tip.downSeconds, 0)
	local hold = math.max(tip.holdSeconds, 0)
	local back = math.max(tip.backSeconds, 0)
	local at = time % tip.everySeconds
	local progress: number
	if at < down then
		progress = at / down
	elseif at < down + hold then
		progress = 1
	elseif at < down + hold + back then
		progress = 1 - (at - down - hold) / back
	else
		progress = 0
	end
	-- Soft at both ends.
	return progress * progress * (3 - 2 * progress)
end

-- The gate across the lane of a zone: in the middle of the lane, standing on the inner step of
-- the walkways, its front towards the throw zone, at the model's size. nil if the zone has no
-- gate, no walkways, or the entry is broken.
function Decor.gate(
	laneConfig: ZoneLook.LaneConfig,
	wallConfig: Walls.WallConfig,
	look: ZoneLook.LookConfig,
	gate: Gate?,
	facings: { [string]: ModelFacing },
	zone: number
): Placement?
	if not gate then
		return nil
	end
	local facing = facings[gate.model]
	local inner: ZoneLook.WalkPart? = nil
	for _, part in ZoneLook.walks(laneConfig, wallConfig, look, zone) do
		if part.kind == "inner" then
			inner = part
		end
	end
	local from, to = ZoneLook.range(laneConfig, wallConfig, zone)
	if not facing or not inner or not isNumber(gate.along) or gate.along < 0 or gate.along > to - from then
		return nil
	end
	return {
		model = gate.model,
		side = 0,
		x = laneConfig.throwLine.x,
		y = inner.topY,
		z = laneConfig.throwLine.z - (from + gate.along),
		-- The throw zone lies towards positive Z.
		yawDegrees = wrap(math.deg(heading(0, 1) - heading(facing.front.x, facing.front.z))),
		scale = Decor.modelSize(facing.size),
	}
end

-- The gate at the end of the lane: in the middle, its front just behind the end of the lane floor
-- and towards the throw zone, standing on the ground (groundY). nil if there is none or the
-- entry is broken.
function Decor.endGate(
	laneConfig: ZoneLook.LaneConfig,
	wallConfig: Walls.WallConfig,
	gate: EndGate?,
	facings: { [string]: ModelFacing },
	groundY: number
): Placement?
	local facing = if gate then facings[gate.model] else nil
	if not gate or not facing or not isNumber(gate.behindLaneEnd) or not isNumber(groundY) then
		return nil
	end
	local scale = Decor.modelSize(facing.size)
	local frontDepth = if isNumber(facing.frontDepth) then math.max(facing.frontDepth :: number, 0) else 0
	local laneEnd = LaneLayout.laneLength(laneConfig, wallConfig)
	return {
		model = gate.model,
		side = 0,
		x = laneConfig.throwLine.x,
		y = groundY,
		z = laneConfig.throwLine.z - (laneEnd + math.max(gate.behindLaneEnd, 0) + frontDepth * scale),
		yawDegrees = wrap(math.deg(heading(0, 1) - heading(facing.front.x, facing.front.z))),
		scale = scale,
	}
end

-- How far the front end of a tipping part is turned up from its modelled position at this time,
-- in degrees. Negative = below the modelled position.
function Decor.tipDegrees(tip: Tip, time: number): number
	local rest = if isNumber(tip.restDegrees) then tip.restDegrees :: number else 0
	local degrees = if isNumber(tip.degrees) then tip.degrees else 0
	return rest - degrees * Decor.tipProgress(tip, time)
end

-- A slow swelling and fading: 0 at the start, 1 halfway through, 0 again after seconds. Soft
-- all the way. 0 for broken values.
function Decor.pulse(seconds: number, time: number): number
	if not isNumber(seconds) or seconds <= 0 or not isNumber(time) then
		return 0
	end
	return 0.5 - 0.5 * math.cos(time / seconds * 2 * math.pi)
end

-- Something rising and fading, again and again (steam): how far up it is (0 = bottom, 1 = top)
-- and how much of it can be seen (0 = nothing, 1 = fully). It shows up quickly at the bottom and
-- fades out on the way up, so starting again from below cannot be seen.
local RISE_SHOW_SHARE = 0.15
function Decor.rise(seconds: number, time: number): (number, number)
	if not isNumber(seconds) or seconds <= 0 or not isNumber(time) then
		return 0, 0
	end
	local progress = (time % seconds) / seconds
	return progress, math.min(progress / RISE_SHOW_SHARE, 1) * (1 - progress)
end

-- The color of every piece of a broken wall: the wall's color, and every so many pieces the
-- accent color if the wall has one.
function Decor.pieceColors(
	color: { number },
	accent: { color: { number }, every: number }?,
	count: number
): { { number } }
	local colors = {}
	local every = if accent and isNumber(accent.every) then math.floor(accent.every) else 0
	for index = 1, math.max(math.floor(if isNumber(count) then count else 0), 0) do
		table.insert(colors, if accent and every >= 1 and index % every == 0 then accent.color else color)
	end
	return colors
end

return Decor
