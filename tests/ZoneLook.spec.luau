local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneLayout = require("../src/shared/Rules/LaneLayout")
local ThrowZoneLayout = require("../src/shared/Rules/ThrowZoneLayout")
local Walls = require("../src/shared/Rules/Walls")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")
local Ui = require("../src/shared/Config/Ui")

local look = Ui.world.lane
local PAPER = 1

local function left(area: ZoneLook.Area): number
	return area.x - area.width / 2
end
local function right(area: ZoneLook.Area): number
	return area.x + area.width / 2
end
local function front(area: ZoneLook.Area): number
	return area.z - area.length / 2
end
local function back(area: ZoneLook.Area): number
	return area.z + area.length / 2
end

local function overlap(a: ZoneLook.Area, b: ZoneLook.Area): boolean
	local tolerance = 0.001
	return left(a) < right(b) - tolerance
		and left(b) < right(a) - tolerance
		and front(a) < back(b) - tolerance
		and front(b) < back(a) - tolerance
end

local function isColor(value: any): boolean
	if typeof(value) ~= "table" or #value ~= 3 then
		return false
	end
	for _, part in value do
		if typeof(part) ~= "number" or part < 0 or part > 255 then
			return false
		end
	end
	return true
end

return {
	["the paper zone reaches from the throw line to wall 5, the next zone starts there"] = function(expect)
		local from, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		expect(from).toBe(0)
		expect(to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 5))
		local nextFrom, nextTo = ZoneLook.range(LaneConfig, WallConfig, 2)
		expect(nextFrom).toBe(to)
		expect(nextTo).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 10))
		-- The last zone reaches to the end of the lane.
		local _, lastTo = ZoneLook.range(LaneConfig, WallConfig, #WallConfig.materials)
		expect(lastTo).toBe(LaneLayout.laneLength(LaneConfig, WallConfig))
	end,

	["every wall stands in the stretch of its own zone"] = function(expect)
		for index = 1, Walls.count(WallConfig) do
			local wall = Walls.get(WallConfig, index) :: Walls.Wall
			local from, to = ZoneLook.range(LaneConfig, WallConfig, wall.zone)
			local distance = LaneLayout.wallDistance(LaneConfig, WallConfig, index)
			expect(distance > from and distance <= to).toBe(true)
		end
	end,

	["the lane floor is laid in stretches without gaps and without overlap"] = function(expect)
		local segments = ZoneLook.floorSegments(LaneConfig, WallConfig, look)
		expect(segments[1].from).toBe(0)
		expect(segments[#segments].to).toBe(LaneLayout.laneLength(LaneConfig, WallConfig))
		for index = 2, #segments do
			expect(segments[index].from).toBe(segments[index - 1].to)
		end
		for _, segment in segments do
			expect(segment.to > segment.from).toBe(true)
		end
	end,

	["only the paper zone has its own floor, everything behind wall 5 is one plain stretch"] = function(expect)
		local segments = ZoneLook.floorSegments(LaneConfig, WallConfig, look)
		expect(#segments).toBe(2)
		expect(segments[1].material).toBe("Paper")
		expect(segments[1].to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 5))
		expect(segments[2].material).toBe(nil)
		expect(ZoneLook.hasFloor(look, "Paper")).toBe(true)
		expect(ZoneLook.hasFloor(look, "Wood")).toBe(false)
		expect(ZoneLook.hasFloor(look, "Cheese")).toBe(false)
		expect(ZoneLook.hasFloor(look, nil)).toBe(false)
	end,

	["without any zone look the lane floor is one plain stretch"] = function(expect)
		local plain = { walk = look.walk, sign = look.sign, zones = {} }
		local segments = ZoneLook.floorSegments(LaneConfig, WallConfig, plain)
		expect(#segments).toBe(1)
		expect(segments[1].material).toBe(nil)
		expect(#ZoneLook.walks(LaneConfig, WallConfig, plain, PAPER)).toBe(0)
		expect(#ZoneLook.fences(LaneConfig, WallConfig, plain, PAPER)).toBe(0)
		expect(ZoneLook.walkWidthAtThrowZone(LaneConfig, WallConfig, plain)).toBe(0)
		expect(ZoneLook.sign(LaneConfig, WallConfig, plain, PAPER)).toBe(nil)
	end,

	["a look for every zone gives every zone its own stretch"] = function(expect)
		local zones = {}
		for _, material in WallConfig.materials do
			zones[material] = { floor = look.zones.Paper.floor }
		end
		local all = { walk = look.walk, sign = look.sign, zones = zones }
		local segments = ZoneLook.floorSegments(LaneConfig, WallConfig, all)
		expect(#segments).toBe(#WallConfig.materials)
		for index, segment in segments do
			expect(segment.material).toBe(WallConfig.materials[index])
		end
	end,

	["walkways run along the whole paper zone on both sides: edge, inner step, outer step"] = function(expect)
		local from, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local lane = ZoneLook.laneArea(LaneConfig, from, to)
		local parts = ZoneLook.walks(LaneConfig, WallConfig, look, PAPER)
		expect(#parts).toBe(6)
		local count = { curb = 0, inner = 0, outer = 0 }
		for index, part in parts do
			count[part.kind] += 1
			expect(overlap(part.area, lane)).toBe(false)
			-- No block lies on top of another one.
			for other = index + 1, #parts do
				expect(overlap(part.area, parts[other].area)).toBe(false)
			end
			-- From the throw line to the end of the zone.
			expect(back(part.area)).toBeNear(LaneConfig.throwLine.z)
			expect(front(part.area)).toBeNear(LaneConfig.throwLine.z - to)
			-- On its own side of the lane.
			expect((part.area.x - lane.x) * part.side > 0).toBe(true)
		end
		expect(count.curb).toBe(2)
		expect(count.inner).toBe(2)
		expect(count.outer).toBe(2)
		-- Zones without a look have no walkways and no fence.
		expect(#ZoneLook.walks(LaneConfig, WallConfig, look, 2)).toBe(0)
		expect(#ZoneLook.fences(LaneConfig, WallConfig, look, 2)).toBe(0)
	end,

	["from the lane outwards: edge, then the lower step, then the higher step, without gaps"] = function(expect)
		local from, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local lane = ZoneLook.laneArea(LaneConfig, from, to)
		for _, side in { -1, 1 } do
			local bySide = {}
			for _, part in ZoneLook.walks(LaneConfig, WallConfig, look, PAPER) do
				if part.side == side then
					bySide[part.kind] = part
				end
			end
			-- Nearest and furthest edge of a block, measured from the lane's middle.
			local function near(part: ZoneLook.WalkPart): number
				return math.abs(part.area.x - lane.x) - part.area.width / 2
			end
			local function far(part: ZoneLook.WalkPart): number
				return math.abs(part.area.x - lane.x) + part.area.width / 2
			end
			expect(near(bySide.curb)).toBeNear(lane.width / 2)
			expect(near(bySide.inner)).toBeNear(far(bySide.curb))
			expect(near(bySide.outer)).toBeNear(far(bySide.inner))
			expect(far(bySide.outer)).toBeNear(lane.width / 2 + ZoneLook.walkWidth(look))
			expect(bySide.inner.topY).toBeNear(LaneConfig.floorTopY + look.walk.innerHeight)
			expect(bySide.outer.topY).toBeNear(LaneConfig.floorTopY + look.walk.outerHeight)
			expect(bySide.curb.topY > bySide.inner.topY).toBe(true)
			expect(bySide.outer.topY > bySide.curb.topY).toBe(true)
		end
	end,

	["the walkways are two steps of about the same width, about 1 and 2.5 studs high"] = function(expect)
		local walk = look.walk
		expect(walk.innerHeight >= 0.8 and walk.innerHeight <= 1.2).toBe(true)
		expect(walk.outerHeight >= 2.2 and walk.outerHeight <= 2.8).toBe(true)
		expect(math.abs(walk.outerWidth - (walk.innerWidth + walk.curbWidth)) <= 1).toBe(true)
		-- Two surfaces of different height next to each other need at least 0.2 studs between them.
		expect(walk.curbAbove >= 0.2).toBe(true)
		expect(walk.outerHeight - walk.innerHeight - walk.curbAbove >= 0.2).toBe(true)
	end,

	["lane and walkways together are wider than the throw zone and meet it"] = function(expect)
		local zone = ThrowZoneLayout.zone(LaneConfig)
		local parts = ZoneLook.walks(LaneConfig, WallConfig, look, PAPER)
		local minX, maxX = math.huge, -math.huge
		for _, part in parts do
			minX, maxX = math.min(minX, left(part.area)), math.max(maxX, right(part.area))
			-- They start exactly where the throw zone ends, and do not reach into it.
			expect(back(part.area)).toBeNear(front(zone))
			expect(overlap(part.area, zone)).toBe(false)
		end
		expect(maxX - minX >= zone.width).toBe(true)
		expect(maxX - minX).toBeNear(LaneConfig.laneWidth + 2 * ZoneLook.walkWidth(look))
	end,

	["an invisible fence closes every open side of the walkways"] = function(expect)
		local from, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local lane = ZoneLook.laneArea(LaneConfig, from, to)
		local width = ZoneLook.walkWidth(look)
		local fences = ZoneLook.fences(LaneConfig, WallConfig, look, PAPER)
		expect(#fences).toBe(6)
		for index, fence in fences do
			expect(overlap(fence, lane)).toBe(false)
			for other = index + 1, #fences do
				expect(overlap(fence, fences[other])).toBe(false)
			end
		end
		for _, side in { -1, 1 } do
			-- The outline of this side's walkway.
			local walkLeft = if side < 0 then left(lane) - width else right(lane)
			local walkRight = walkLeft + width
			local nearEnd, farEnd, outerSide = false, false, false
			for _, fence in fences do
				local onThisSide = (fence.x - lane.x) * side > 0
				if onThisSide then
					-- Inside the walkway's outline, never on the ground around it.
					expect(left(fence) >= walkLeft - 0.001 and right(fence) <= walkRight + 0.001).toBe(true)
					expect(back(fence) <= back(lane) + 0.001 and front(fence) >= front(lane) - 0.001).toBe(true)
					local acrossWhole = math.abs(fence.width - width) < 0.001
					if acrossWhole and math.abs(back(fence) - back(lane)) < 0.001 then
						nearEnd = true
					elseif acrossWhole and math.abs(front(fence) - front(lane)) < 0.001 then
						farEnd = true
					elseif not acrossWhole then
						-- Flush with the outer edge, and reaching from one end fence to the other.
						local outerEdge = if side < 0 then walkLeft else walkRight
						local flush = math.abs((if side < 0 then left(fence) else right(fence)) - outerEdge) < 0.001
						expect(flush).toBe(true)
						expect(fence.length).toBeNear(lane.length - 2 * look.walk.fenceThickness)
						outerSide = true
					end
				end
			end
			expect(nearEnd and farEnd and outerSide).toBe(true)
		end
		-- High enough that nobody jumps over it.
		expect(LaneConfig.barrierHeight >= 15).toBe(true)
	end,

	["the green floor around the throw zone leaves out lane and walkways"] = function(expect)
		local walkWidth = ZoneLook.walkWidthAtThrowZone(LaneConfig, WallConfig, look)
		expect(walkWidth).toBe(ZoneLook.walkWidth(look))
		local green = ThrowZoneLayout.surroundings(LaneConfig, Ui.world.surroundings, walkWidth)
		local from, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local lane = ZoneLook.laneArea(LaneConfig, from, to)
		for _, piece in green do
			expect(overlap(piece, lane)).toBe(false)
			for _, part in ZoneLook.walks(LaneConfig, WallConfig, look, PAPER) do
				expect(overlap(piece, part.area)).toBe(false)
			end
		end
	end,

	["the checkerboard is not cut off on the paper floor"] = function(expect)
		local picture = Ui.world.floorTile.fieldStuds * Ui.world.floorTile.fieldsPerPicture
		local from, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local lane = ZoneLook.laneArea(LaneConfig, from, to)
		expect(lane.width % picture).toBe(0)
		expect(lane.length % picture).toBe(0)
		-- Walkway and edge together are a whole number of pictures wide, so the green beside
		-- them keeps its pattern.
		expect(ZoneLook.walkWidth(look) % picture).toBe(0)
	end,

	["the name of the next zone floats at the end of the paper zone, above the walls"] = function(expect)
		local sign = ZoneLook.sign(LaneConfig, WallConfig, look, PAPER) :: ZoneLook.Sign
		expect(sign.text).toBe("WOOD")
		expect(sign.color).toBe(look.zones.Wood.nameColor)
		expect(sign.x).toBe(LaneConfig.throwLine.x)
		local _, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		expect(sign.z).toBe(LaneConfig.throwLine.z - to - look.sign.behindZoneEnd)
		-- Its lower end is above the top of the walls.
		expect(sign.y - look.sign.heightStuds / 2 > LaneConfig.floorTopY + LaneConfig.wallHeight).toBe(true)
		-- It can be seen from the throw zone.
		expect(look.sign.maxDistance > to + LaneConfig.throwZoneLength).toBe(true)
		-- The wood zone has no look yet, so it announces nothing; neither does the last zone.
		expect(ZoneLook.sign(LaneConfig, WallConfig, look, 2)).toBe(nil)
		expect(ZoneLook.sign(LaneConfig, WallConfig, look, #WallConfig.materials)).toBe(nil)
	end,

	["paper walls are cream white with a frame, the other walls keep their plain color"] = function(expect)
		expect(ZoneLook.wallColor(LaneConfig, look, "Paper")).toBe(look.zones.Paper.wall.color)
		expect(ZoneLook.wallFrameColor(look, "Paper")).toBe(look.zones.Paper.wall.frameColor)
		for _, material in WallConfig.materials do
			expect(isColor(ZoneLook.wallColor(LaneConfig, look, material))).toBe(true)
			if material ~= "Paper" then
				expect(ZoneLook.wallColor(LaneConfig, look, material)).toBe(LaneConfig.materialColors[material])
				expect(ZoneLook.wallFrameColor(look, material)).toBe(nil)
			end
		end
		-- The frame is thin compared to the wall.
		expect(look.wallFrame.widthStuds * 10 <= LaneConfig.wallHeight).toBe(true)
	end,

	["every zone look names a material that exists and uses real colors"] = function(expect)
		for material, zoneStyle in look.zones :: { [string]: any } do
			expect(table.find(WallConfig.materials, material) ~= nil).toBe(true)
			if zoneStyle.nameColor then
				expect(isColor(zoneStyle.nameColor)).toBe(true)
			end
			for _, group in { zoneStyle.floor, zoneStyle.walk, zoneStyle.wall } do
				for _, value in group or {} do
					expect(isColor(value)).toBe(true)
				end
			end
		end
	end,
}
