local ThrowZoneLayout = require("../src/shared/Rules/ThrowZoneLayout")
local LaneLayout = require("../src/shared/Rules/LaneLayout")
local LaneConfig = require("../src/shared/Config/Lane")
local Ui = require("../src/shared/Config/Ui")

local world = Ui.world

local function left(area: ThrowZoneLayout.Area): number
	return area.x - area.width / 2
end
local function right(area: ThrowZoneLayout.Area): number
	return area.x + area.width / 2
end
local function front(area: ThrowZoneLayout.Area): number
	return area.z - area.length / 2
end
local function back(area: ThrowZoneLayout.Area): number
	return area.z + area.length / 2
end

local function overlap(a: ThrowZoneLayout.Area, b: ThrowZoneLayout.Area): boolean
	local tolerance = 0.001
	return left(a) < right(b) - tolerance
		and left(b) < right(a) - tolerance
		and front(a) < back(b) - tolerance
		and front(b) < back(a) - tolerance
end

return {
	["the painted zone is exactly the zone the game checks"] = function(expect)
		local zone = ThrowZoneLayout.zone(LaneConfig)
		-- Just inside every edge counts as in the zone, just outside does not.
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, left(zone) + 0.01, zone.z)).toBe(true)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, left(zone) - 0.01, zone.z)).toBe(false)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, right(zone) - 0.01, zone.z)).toBe(true)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, right(zone) + 0.01, zone.z)).toBe(false)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, zone.x, front(zone) + 0.01)).toBe(true)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, zone.x, front(zone) - 0.01)).toBe(false)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, zone.x, back(zone) - 0.01)).toBe(true)
		expect(LaneLayout.isInThrowZone(LaneConfig, 0, zone.x, back(zone) + 0.01)).toBe(false)
		expect(front(zone)).toBe(LaneConfig.throwLine.z)
	end,

	["the edge lies right outside the zone and closes all around it"] = function(expect)
		local zone = ThrowZoneLayout.zone(LaneConfig)
		local rim = ThrowZoneLayout.rim(LaneConfig, world.throwZone.rim)
		local width = world.throwZone.rim.width
		expect(#rim).toBe(4)
		for index, strip in rim do
			expect(overlap(strip, zone)).toBe(false)
			for other = index + 1, #rim do
				expect(overlap(strip, rim[other])).toBe(false)
			end
		end
		-- Together the strips reach exactly one edge width beyond the zone on every side.
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		local area = 0
		for _, strip in rim do
			minX, maxX = math.min(minX, left(strip)), math.max(maxX, right(strip))
			minZ, maxZ = math.min(minZ, front(strip)), math.max(maxZ, back(strip))
			area += strip.width * strip.length
		end
		expect(minX).toBeNear(left(zone) - width)
		expect(maxX).toBeNear(right(zone) + width)
		expect(minZ).toBeNear(front(zone) - width)
		expect(maxZ).toBeNear(back(zone) + width)
		-- No gaps: the strips fill the whole ring between the two rectangles.
		expect(area).toBeNear((zone.width + 2 * width) * (zone.length + 2 * width) - zone.width * zone.length)
	end,

	["the edge is low enough to walk over"] = function(expect)
		expect(world.throwZone.rim.height > 0).toBe(true)
		expect(world.throwZone.rim.height <= 0.5).toBe(true)
	end,

	["the writing lies inside the zone"] = function(expect)
		local zone = ThrowZoneLayout.zone(LaneConfig)
		local label = ThrowZoneLayout.label(LaneConfig, world.throwZone.label)
		expect(left(label) >= left(zone)).toBe(true)
		expect(right(label) <= right(zone)).toBe(true)
		expect(front(label) >= front(zone)).toBe(true)
		expect(back(label) <= back(zone)).toBe(true)
		expect(label.x).toBe(zone.x)
		-- A writing that is too big or misplaced is pulled into the zone.
		local huge = ThrowZoneLayout.label(LaneConfig, { widthStuds = 500, heightStuds = 500, positionShare = 7 })
		expect(huge.width).toBe(zone.width)
		expect(huge.length).toBe(zone.length)
		expect(huge.z).toBeNear(zone.z)
		local broken = ThrowZoneLayout.label(LaneConfig, { widthStuds = 10, heightStuds = 4, positionShare = 0 / 0 })
		expect(broken.z).toBeNear(zone.z)
		local atLine = ThrowZoneLayout.label(LaneConfig, { widthStuds = 10, heightStuds = 4, positionShare = 0 })
		expect(front(atLine)).toBeNear(front(zone))
	end,

	["the green floor reaches around the zone and its edge by the configured room"] = function(expect)
		local zone = ThrowZoneLayout.zone(LaneConfig)
		local settings = world.surroundings
		local green = ThrowZoneLayout.surroundings(LaneConfig, settings)
		expect(left(green)).toBeNear(left(zone) - settings.left)
		expect(right(green)).toBeNear(right(zone) + settings.right)
		expect(front(green)).toBeNear(front(zone) - settings.front)
		expect(back(green)).toBeNear(back(zone) + settings.back)
		for _, room in { settings.left, settings.right, settings.front, settings.back } do
			expect(room > world.throwZone.rim.width).toBe(true)
		end
		-- It stays on the ground of the map.
		expect(math.max(math.abs(left(green)), math.abs(right(green))) <= LaneConfig.groundHalfSize).toBe(true)
		expect(math.max(math.abs(front(green)), math.abs(back(green))) <= LaneConfig.groundHalfSize).toBe(true)
		-- Negative room counts as none.
		local none = ThrowZoneLayout.surroundings(LaneConfig, { left = -5, right = -5, front = -5, back = -5 })
		expect(none.width).toBe(zone.width)
		expect(none.length).toBe(zone.length)
	end,

	["floors of the world are whole checkerboard fields wide, so the pattern is not cut off"] = function(expect)
		local field = world.floorTile.fieldStuds
		local zone = ThrowZoneLayout.zone(LaneConfig)
		local green = ThrowZoneLayout.surroundings(LaneConfig, world.surroundings)
		for _, size in { zone.width, zone.length, green.width, green.length } do
			expect(size % field).toBe(0)
		end
		expect(world.floorTile.image == "" or world.floorTile.image:match("^rbxassetid://%d+$") ~= nil).toBe(true)
	end,

	["the green floor lies between the ground and the lane floors"] = function(expect)
		local top = LaneConfig.floorTopY - world.surroundings.belowFloor
		expect(top > 0).toBe(true)
		expect(top < LaneConfig.floorTopY).toBe(true)
	end,
}
