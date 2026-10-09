local LaneLayout = require("../src/shared/Rules/LaneLayout")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")

local function distance(index: number): number
	return LaneLayout.wallDistance(LaneConfig, WallConfig, index)
end

return {
	["wall 1 stands at the first wall distance"] = function(expect)
		expect(distance(1)).toBe(LaneConfig.firstWallDistance)
	end,

	["walls inside a zone are one spacing apart"] = function(expect)
		for index = 1, 4 do
			expect(distance(index + 1) - distance(index)).toBe(LaneConfig.wallSpacing)
		end
	end,

	["a new zone adds the zone gap"] = function(expect)
		for zone = 1, 5 do
			local lastOfZone = zone * WallConfig.wallsPerZone
			expect(distance(lastOfZone + 1) - distance(lastOfZone)).toBe(LaneConfig.wallSpacing + LaneConfig.zoneGap)
		end
	end,

	["every wall is further away than the one before"] = function(expect)
		for index = 1, 29 do
			expect(distance(index + 1) > distance(index)).toBe(true)
		end
	end,

	["the lane ends behind the last wall"] = function(expect)
		expect(LaneLayout.laneLength(LaneConfig, WallConfig)).toBe(distance(30) + LaneConfig.endPadding)
	end,

	["throw zone check: inside, on the edge with tolerance, outside"] = function(expect)
		local tolerance = 4
		local function inZone(x: number, z: number): boolean
			return LaneLayout.isInThrowZone(LaneConfig, tolerance, x, z)
		end
		-- The throw zone runs from the throw line (z = 0) back to z = throwZoneLength.
		expect(inZone(0, LaneConfig.throwZoneLength / 2)).toBe(true)
		expect(inZone(LaneConfig.laneWidth / 2 + tolerance, 1)).toBe(true)
		expect(inZone(LaneConfig.laneWidth / 2 + tolerance + 0.1, 1)).toBe(false)
		expect(inZone(0, -tolerance - 0.1)).toBe(false)
		expect(inZone(0, -100)).toBe(false)
		expect(inZone(0, LaneConfig.throwZoneLength + tolerance + 0.1)).toBe(false)
		expect(inZone(0 / 0, 1)).toBe(false)
	end,

	["every material has a color"] = function(expect)
		for _, material in WallConfig.materials do
			expect(LaneConfig.materialColors[material] ~= nil).toBe(true)
		end
	end,
}
