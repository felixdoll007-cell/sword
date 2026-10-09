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

local LaneLayout = {}

function LaneLayout.wallDistance(laneConfig: LaneConfig, wallConfig: Walls.WallConfig, index: number): number
	local zone = (index - 1) // wallConfig.wallsPerZone + 1
	return laneConfig.firstWallDistance + (index - 1) * laneConfig.wallSpacing + (zone - 1) * laneConfig.zoneGap
end

-- Length of the lane floor, from the throw line to behind the last wall.
function LaneLayout.laneLength(laneConfig: LaneConfig, wallConfig: Walls.WallConfig): number
	return LaneLayout.wallDistance(laneConfig, wallConfig, Walls.count(wallConfig)) + laneConfig.endPadding
end

return LaneLayout
