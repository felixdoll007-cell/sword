local ThrowZoneLayout = require("../src/shared/Rules/ThrowZoneLayout")
local LaneLayout = require("../src/shared/Rules/LaneLayout")
local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")
local Ui = require("../src/shared/Config/Ui")

local world = Ui.world
-- Room the walkways of the first zone take next to the lane.
local WALK_WIDTH = ZoneLook.walkWidthAtThrowZone(LaneConfig, WallConfig, world.lane)

local function greenPieces(): { ThrowZoneLayout.Area }
	return ThrowZoneLayout.surroundings(LaneConfig, world.surroundings, WALK_WIDTH)
end

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

	["the green floor lies around the zone and never under or over another floor"] = function(expect)
		local zone = ThrowZoneLayout.zone(LaneConfig)
		local settings = world.surroundings
		local pieces = greenPieces()
		-- Left, right, behind, and in front on each side where the green reaches beyond the walkways.
		local expected = 3
		for _, room in { settings.left, settings.right } do
			if room > WALK_WIDTH then
				expected += 1
			end
		end
		expect(#pieces).toBe(expected)

		-- The lane in front of the zone with its walkways, as far as the green reaches along it.
		local lane: ThrowZoneLayout.Area = {
			x = zone.x,
			z = front(zone) - settings.front / 2,
			width = LaneConfig.laneWidth + 2 * WALK_WIDTH,
			length = settings.front,
		}
		local minX, maxX, minZ, maxZ = math.huge, -math.huge, math.huge, -math.huge
		local area = 0
		for index, piece in pieces do
			expect(overlap(piece, zone)).toBe(false)
			expect(overlap(piece, lane)).toBe(false)
			for other = index + 1, #pieces do
				expect(overlap(piece, pieces[other])).toBe(false)
			end
			minX, maxX = math.min(minX, left(piece)), math.max(maxX, right(piece))
			minZ, maxZ = math.min(minZ, front(piece)), math.max(maxZ, back(piece))
			area += piece.width * piece.length
		end
		expect(minX).toBeNear(left(zone) - settings.left)
		expect(maxX).toBeNear(right(zone) + settings.right)
		expect(minZ).toBeNear(front(zone) - settings.front)
		expect(maxZ).toBeNear(back(zone) + settings.back)
		-- No gaps: everything inside that outline is green, except the zone, the lane and its walkways.
		expect(area).toBeNear((maxX - minX) * (maxZ - minZ) - zone.width * zone.length - lane.width * lane.length)
		-- It stays on the ground of the map.
		expect(math.max(math.abs(minX), math.abs(maxX)) <= LaneConfig.groundHalfSize).toBe(true)
		expect(math.max(math.abs(minZ), math.abs(maxZ)) <= LaneConfig.groundHalfSize).toBe(true)
	end,

	["the green floor keeps away from the training lanes and their pads"] = function(expect)
		local TrainingConfig = require("../src/shared/Config/Training")
		local Training = require("../src/shared/Rules/Training")
		local pieces = greenPieces()
		for laneIndex = 1, Training.laneCount(TrainingConfig) do
			local pad = Training.lanePad(TrainingConfig, laneIndex) :: any
			-- Pad and lane in one rectangle, with the invisible barriers along the sides.
			local padBack = pad.z + pad.length / 2
			local laneFront = pad.z - pad.length / 2 - TrainingConfig.laneLength
			local training: ThrowZoneLayout.Area = {
				x = pad.x,
				z = (padBack + laneFront) / 2,
				width = pad.width + 2 * LaneConfig.barrierThickness,
				length = padBack - laneFront,
			}
			for _, piece in pieces do
				expect(overlap(piece, training)).toBe(false)
			end
		end
	end,

	["negative room around the zone counts as none"] = function(expect)
		expect(#ThrowZoneLayout.surroundings(LaneConfig, { left = -5, right = -5, front = -5, back = -5 })).toBe(0)
		local onlyBack = ThrowZoneLayout.surroundings(LaneConfig, { left = 0, right = 0, front = 30, back = 10 })
		expect(#onlyBack).toBe(1)
		expect(onlyBack[1].length).toBe(10)
		-- Without walkways the front pieces touch the lane; with wide ones they vanish.
		local room = { left = 20, right = 20, front = 30, back = 10 }
		expect(#ThrowZoneLayout.surroundings(LaneConfig, room)).toBe(5)
		expect(#ThrowZoneLayout.surroundings(LaneConfig, room, 20)).toBe(3)
		local touching = ThrowZoneLayout.surroundings(LaneConfig, room, 0)
		expect(right(touching[4])).toBeNear(LaneConfig.throwLine.x - LaneConfig.laneWidth / 2)
	end,

	["the checkerboard continues across the green pieces and is not cut off on the zone"] = function(expect)
		local picture = world.floorTile.fieldStuds * world.floorTile.fieldsPerPicture
		local zone = ThrowZoneLayout.zone(LaneConfig)
		expect(zone.width % picture).toBe(0)
		expect(zone.length % picture).toBe(0)
		-- Every piece is a whole number of pictures wide and long, and all pieces start on the
		-- same grid. Then the pattern lines up whichever corner Roblox starts the picture at.
		local pieces = greenPieces()
		local gridX, gridZ = left(pieces[1]) % picture, front(pieces[1]) % picture
		for _, piece in pieces do
			expect(piece.width % picture).toBe(0)
			expect(piece.length % picture).toBe(0)
			expect(left(piece) % picture).toBe(gridX)
			expect(front(piece) % picture).toBe(gridZ)
		end
		expect(world.floorTile.image == "" or world.floorTile.image:match("^rbxassetid://%d+$") ~= nil).toBe(true)
	end,
}
