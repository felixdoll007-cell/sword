--!strict
-- Pure functions for where things stand on the lane.
-- "Distance" always means studs from the throw line along the lane.

local Walls = require("./Walls")

export type LaneConfig = {
	firstWallDistance: number,
	wallSpacing: number,
	zoneGap: number,
	endPadding: number,
}

export type ThrowZoneConfig = {
	throwLine: { x: number, z: number },
	laneWidth: number,
	throwZoneLength: number,
}

local LaneLayout = {}

function LaneLayout.wallDistance(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, index: number): number
	local zone = (index - 1) // wallConfig.wallsPerZone + 1
	return laneConfig.firstWallDistance + (index - 1) * laneConfig.wallSpacing + (zone - 1) * laneConfig.zoneGap
end

-- Length of the lane floor, from the throw line to behind the last wall.
function LaneLayout.laneLength(laneConfig: LaneConfig, wallConfig: Walls.WallConfig): number
	return LaneLayout.wallDistance(laneConfig, wallConfig, Walls.count(wallConfig)) + laneConfig.endPadding
end

-- Is a position inside the throw zone? tolerance adds extra room on every side.
function LaneLayout.isInThrowZone(laneConfig: ThrowZoneConfig, tolerance: number, x: number, z: number): boolean
	local halfWidth = laneConfig.laneWidth / 2 + tolerance
	local front = laneConfig.throwLine.z - tolerance
	local back = laneConfig.throwLine.z + laneConfig.throwZoneLength + tolerance
	return math.abs(x - laneConfig.throwLine.x) <= halfWidth and z >= front and z <= back
end

return LaneLayout
