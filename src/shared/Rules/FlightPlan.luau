--!strict
-- Pure functions for the timing of a throw: when the sword reaches which point of the lane.
-- Server and client use the same plan: the server to know how long to lock the next throw,
-- the client to animate the sword.

local LaneLayout = require("./LaneLayout")
local ThrowCalculation = require("./ThrowCalculation")
local Walls = require("./Walls")

export type LaneConfig = LaneLayout.LaneConfig & {
	wallThickness: number,
}

export type ThrowConfig = {
	slowestSpeed: number,
	fastestSpeed: number,
	minFlightSeconds: number,
	maxFlightSeconds: number,
	bounceSeconds: number,
	stuckSeconds: number,
	stuckDistanceFromLaneEnd: number,
}

export type Point = {
	time: number,
	distance: number,
}

export type Break = {
	time: number,
	wallIndex: number,
}

export type Plan = {
	-- Start, every broken wall and the stop, in order. Between two points the sword moves evenly.
	points: { Point },
	breaks: { Break },
	-- "bounce": stopped by a wall that is too hard. "stuck": every wall broke, sword sticks in the ground.
	ending: "bounce" | "stuck",
	bounceWallIndex: number?,
	flightSeconds: number,
	endingSeconds: number,
	totalSeconds: number,
}

local FlightPlan = {}

local function speedFor(throwConfig: ThrowConfig, powerLeft: number, hardness: number): number
	local ratio = powerLeft / hardness
	if ratio ~= ratio then
		ratio = 0
	end
	return math.clamp(throwConfig.slowestSpeed * ratio, throwConfig.slowestSpeed, throwConfig.fastestSpeed)
end

function FlightPlan.create(
	wallConfig: Walls.WallConfig,
	laneConfig: LaneConfig,
	throwConfig: ThrowConfig,
	throwPower: number,
	result: ThrowCalculation.ThrowResult
): Plan
	local points: { Point } = { { time = 0, distance = 0 } }
	local breaks: { Break } = {}

	local time = 0
	local distance = 0
	local usedPower = 0
	local speed = throwConfig.slowestSpeed

	for _, wall in result.brokenWalls do
		local wallDistance = LaneLayout.wallDistance(laneConfig, wallConfig, wall.index)
		speed = speedFor(throwConfig, throwPower - usedPower, wall.hardness)
		time += (wallDistance - distance) / speed
		distance = wallDistance
		usedPower += wall.hardness
		table.insert(points, { time = time, distance = distance })
		table.insert(breaks, { time = time, wallIndex = wall.index })
	end

	local bounceWall = result.bounceWall
	local stopDistance
	if bounceWall then
		-- The tip stops at the front of the wall. The approach is slow: there is not enough power left.
		stopDistance = LaneLayout.wallDistance(laneConfig, wallConfig, bounceWall.index) - laneConfig.wallThickness / 2
		speed = throwConfig.slowestSpeed
	else
		-- Every wall broke: keep the last speed until the end of the lane.
		stopDistance = LaneLayout.laneLength(laneConfig, wallConfig) - throwConfig.stuckDistanceFromLaneEnd
	end
	time += math.max(stopDistance - distance, 0) / speed
	table.insert(points, { time = time, distance = stopDistance })

	-- Fit the flight between the minimum and maximum duration.
	local flightSeconds = math.clamp(time, throwConfig.minFlightSeconds, throwConfig.maxFlightSeconds)
	local scale = if time > 0 then flightSeconds / time else 1
	for _, point in points do
		point.time *= scale
	end
	for _, wallBreak in breaks do
		wallBreak.time *= scale
	end

	local endingSeconds = if bounceWall then throwConfig.bounceSeconds else throwConfig.stuckSeconds
	return {
		points = points,
		breaks = breaks,
		ending = if bounceWall then "bounce" else "stuck",
		bounceWallIndex = if bounceWall then bounceWall.index else nil,
		flightSeconds = flightSeconds,
		endingSeconds = endingSeconds,
		totalSeconds = flightSeconds + endingSeconds,
	}
end

-- Where the tip of the sword is at a given time of the flight, in studs from the throw line.
function FlightPlan.distanceAt(plan: Plan, time: number): number
	local points = plan.points
	if time <= 0 then
		return points[1].distance
	end
	for i = 2, #points do
		local from = points[i - 1]
		local to = points[i]
		if time <= to.time then
			local span = to.time - from.time
			local alpha = if span > 0 then (time - from.time) / span else 1
			return from.distance + (to.distance - from.distance) * alpha
		end
	end
	return points[#points].distance
end

return FlightPlan
