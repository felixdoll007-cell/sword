--!strict
-- Pure functions for the decoration on the walkways of a zone: which model stands where and
-- which way it is turned. Only looks.
--
-- Decoration stands in a row on both walkways of a zone, with the same distance between two
-- pieces, in a repeating order of models. Every piece is turned so that its front looks at
-- the lane.

local ThrowZoneLayout = require("./ThrowZoneLayout")
local Walls = require("./Walls")
local ZoneLook = require("./ZoneLook")

-- How decoration is spread in one zone.
export type ZoneDecor = {
	-- Model names, repeated along the walkway.
	order: { string },
	-- Distance from the start of the zone to the first piece, and from the last piece to its end.
	firstDistance: number,
	-- Distance between two pieces.
	spacing: number,
	-- How far from the lane's edge the pieces stand.
	distanceFromLane: number,
	-- The right walkway starts this many places further in the order than the left one.
	sideShift: number,
}

-- What the game needs to know about one decoration model to turn it.
export type ModelFacing = {
	-- The direction, in the model's own space, of its front. Only x and z count.
	front: { x: number, z: number },
	-- 0 = the front looks straight at the lane. More turns it towards the throw zone.
	turnTowardsThrowZoneDegrees: number?,
}

export type Placement = {
	model: string,
	-- -1 = left walkway (smaller X), 1 = right walkway.
	side: number,
	x: number,
	-- Height of the ground the piece stands on.
	y: number,
	z: number,
	-- Turn around the upright axis, in degrees (as used by CFrame.Angles).
	yawDegrees: number,
}

local Decor = {}

-- Direction of a flat vector as an angle that grows when turned with CFrame.Angles(0, angle, 0).
local function heading(x: number, z: number): number
	return math.atan2(-z, x)
end

-- How far a model must be turned so that its front looks at the lane from this side of it.
function Decor.yawDegrees(facing: ModelFacing, side: number): number
	local turn = math.rad(facing.turnTowardsThrowZoneDegrees or 0)
	-- Left of the lane the lane lies towards positive X, right of it towards negative X.
	-- The throw zone lies towards positive Z from both.
	local wanted = if side < 0 then -turn else math.pi + turn
	local degrees = math.deg(wanted - heading(facing.front.x, facing.front.z))
	-- Keep the result between -180 and 180.
	return (degrees + 180) % 360 - 180
end

-- Distances from the start of a zone at which pieces stand.
function Decor.distances(decor: ZoneDecor, zoneLength: number): { number }
	local list = {}
	if decor.spacing <= 0 or decor.spacing ~= decor.spacing then
		return list
	end
	local distance = decor.firstDistance
	-- A tiny tolerance, so a piece exactly at the end is not lost to rounding.
	while distance <= zoneLength - decor.firstDistance + 1e-6 do
		table.insert(list, distance)
		distance += decor.spacing
	end
	return list
end

-- All pieces of decoration of a zone. Empty if the zone has no walkways or no decoration.
-- facings: how each model is turned; a model that is not listed is left out.
function Decor.placements(
	laneConfig: ZoneLook.LaneConfig,
	wallConfig: Walls.WallConfig,
	look: ZoneLook.LookConfig,
	decor: ZoneDecor?,
	facings: { [string]: ModelFacing },
	zone: number
): { Placement }
	local placements: { Placement } = {}
	if not decor or #decor.order == 0 or #ZoneLook.walks(laneConfig, wallConfig, look, zone) == 0 then
		return placements
	end
	local from, to = ZoneLook.range(laneConfig, wallConfig, zone)
	local lane: ThrowZoneLayout.Area = ZoneLook.laneArea(laneConfig, from, to)
	local walkTop = laneConfig.floorTopY + look.walk.height

	for _, side in { -1, 1 } do
		local shift = if side > 0 then decor.sideShift else 0
		for index, distance in Decor.distances(decor, to - from) do
			local model = decor.order[(index - 1 + shift) % #decor.order + 1]
			local facing = facings[model]
			if facing then
				table.insert(placements, {
					model = model,
					side = side,
					x = lane.x + side * (lane.width / 2 + decor.distanceFromLane),
					y = walkTop,
					z = laneConfig.throwLine.z - (from + distance),
					yawDegrees = Decor.yawDegrees(facing, side),
				})
			end
		end
	end
	return placements
end

return Decor
