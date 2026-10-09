local FlightPlan = require("../src/shared/Rules/FlightPlan")
local ThrowCalculation = require("../src/shared/Rules/ThrowCalculation")
local LaneLayout = require("../src/shared/Rules/LaneLayout")
local Walls = require("../src/shared/Rules/Walls")
local WallConfig = require("../src/shared/Config/Walls")
local LaneConfig = require("../src/shared/Config/Lane")
local ThrowConfig = require("../src/shared/Config/Throw")
local StrengthConfig = require("../src/shared/Config/Strength")

local function plan(power: number)
	local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, power)
	return FlightPlan.create(WallConfig, LaneConfig, ThrowConfig, power, result)
end

return {
	["a weak throw lasts at least the minimum flight time"] = function(expect)
		local p = plan(10)
		expect(p.flightSeconds).toBeNear(ThrowConfig.minFlightSeconds)
		expect(p.ending).toBe("bounce")
		expect(p.bounceWallIndex).toBe(2)
	end,

	["zero power still gives a short flight to wall 1"] = function(expect)
		local p = plan(0)
		expect(#p.breaks).toBe(0)
		expect(p.bounceWallIndex).toBe(1)
		expect(p.flightSeconds).toBeNear(ThrowConfig.minFlightSeconds)
	end,

	["a huge throw never lasts longer than the maximum"] = function(expect)
		for _, power in { 1e6, 1e30, 1e300, math.huge } do
			local p = plan(power)
			expect(p.flightSeconds <= ThrowConfig.maxFlightSeconds + 1e-9).toBe(true)
			expect(p.ending).toBe("stuck")
			expect(#p.breaks).toBe(30)
		end
	end,

	["every wall breaks later than the one before"] = function(expect)
		local p = plan(1e6)
		for i = 2, #p.breaks do
			expect(p.breaks[i].time > p.breaks[i - 1].time).toBe(true)
		end
	end,

	["the sword is at the wall when it breaks"] = function(expect)
		local p = plan(500)
		for _, wallBreak in p.breaks do
			local wallDistance = LaneLayout.wallDistance(LaneConfig, WallConfig, wallBreak.wallIndex)
			expect(FlightPlan.distanceAt(p, wallBreak.time)).toBeNear(wallDistance)
		end
	end,

	["the sword stops at the front of the bounce wall"] = function(expect)
		local p = plan(500)
		local bounceDistance = LaneLayout.wallDistance(LaneConfig, WallConfig, p.bounceWallIndex :: number)
		local stop = FlightPlan.distanceAt(p, p.flightSeconds + 10)
		expect(stop).toBeNear(bounceDistance - LaneConfig.wallThickness / 2)
	end,

	["when every wall breaks the sword stops near the lane end"] = function(expect)
		local p = plan(math.huge)
		local laneLength = LaneLayout.laneLength(LaneConfig, WallConfig)
		expect(FlightPlan.distanceAt(p, p.flightSeconds)).toBeNear(laneLength - ThrowConfig.stuckDistanceFromLaneEnd)
	end,

	["a wall barely broken takes longer than a wall broken easily"] = function(expect)
		-- With exactly enough power for 10 walls, wall 10 is broken with almost nothing left.
		local power = 0
		for index = 1, 10 do
			power += (Walls.get(WallConfig, index) :: Walls.Wall).hardness
		end
		local p = plan(power)
		local function segmentSeconds(i)
			return p.points[i + 1].time - p.points[i].time
		end
		local function segmentLength(i)
			return p.points[i + 1].distance - p.points[i].distance
		end
		-- Point 2 is wall 1 (lots of power left), point 11 is wall 10 (barely enough).
		local speedAtWall1 = segmentLength(1) / segmentSeconds(1)
		local speedAtWall10 = segmentLength(10) / segmentSeconds(10)
		expect(speedAtWall1 > speedAtWall10).toBe(true)
	end,

	["total time adds the ending"] = function(expect)
		local bounce = plan(10)
		expect(bounce.totalSeconds).toBeNear(bounce.flightSeconds + ThrowConfig.bounceSeconds)
		local stuck = plan(math.huge)
		expect(stuck.totalSeconds).toBeNear(stuck.flightSeconds + ThrowConfig.stuckSeconds)
	end,

	["distance before the start and after the stop"] = function(expect)
		local p = plan(100)
		expect(FlightPlan.distanceAt(p, -1)).toBe(0)
		expect(FlightPlan.distanceAt(p, 1e9)).toBe(p.points[#p.points].distance)
	end,

	["NaN power gives a normal plan without NaN"] = function(expect)
		local p = plan(0 / 0)
		expect(p.flightSeconds == p.flightSeconds).toBe(true)
		local distance = FlightPlan.distanceAt(p, 1)
		expect(distance == distance).toBe(true)
	end,
}
