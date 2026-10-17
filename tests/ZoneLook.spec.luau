local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneLayout = require("../src/shared/Rules/LaneLayout")
local ThrowZoneLayout = require("../src/shared/Rules/ThrowZoneLayout")
local Walls = require("../src/shared/Rules/Walls")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")
local Ui = require("../src/shared/Config/Ui")

local look = Ui.world.lane
local PAPER = 1
local BAMBOO = 2
-- The first zone without a look.
local WOOD = 3
local STONE = 4
local IRON = 5
-- The first zone without a look.
local JADE = 6

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

	["every zone of world 1 has its own floor, to the end of the lane"] = function(expect)
		local segments = ZoneLook.floorSegments(LaneConfig, WallConfig, look)
		expect(#segments).toBe(6)
		expect(segments[1].material).toBe("Paper")
		expect(segments[1].to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 5))
		expect(segments[2].material).toBe("Bamboo")
		expect(segments[2].from).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 5))
		expect(segments[2].to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 10))
		expect(segments[3].material).toBe("Wood")
		expect(segments[3].from).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 10))
		expect(segments[3].to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 15))
		expect(segments[4].material).toBe("Stone")
		expect(segments[4].from).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 15))
		expect(segments[4].to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 20))
		expect(segments[5].material).toBe("Iron")
		expect(segments[5].from).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 20))
		expect(segments[5].to).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 25))
		expect(segments[6].material).toBe("Jade")
		expect(segments[6].from).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 25))
		-- The last zone reaches to the end of the lane.
		expect(segments[6].to).toBe(LaneLayout.laneLength(LaneConfig, WallConfig))
		expect(ZoneLook.hasFloor(look, "Paper")).toBe(true)
		expect(ZoneLook.hasFloor(look, "Bamboo")).toBe(true)
		expect(ZoneLook.hasFloor(look, "Wood")).toBe(true)
		expect(ZoneLook.hasFloor(look, "Stone")).toBe(true)
		expect(ZoneLook.hasFloor(look, "Iron")).toBe(true)
		expect(ZoneLook.hasFloor(look, "Jade")).toBe(true)
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
		local plain = { walk = look.walk, sign = look.sign, zones = {} }
		expect(#ZoneLook.walks(LaneConfig, WallConfig, plain, JADE)).toBe(0)
		expect(#ZoneLook.fences(LaneConfig, WallConfig, plain, JADE)).toBe(0)
	end,

	["the jade zone joins the iron zone with a clean edge and runs to the end of the lane"] = function(expect)
		local _, ironEnd = ZoneLook.range(LaneConfig, WallConfig, IRON)
		local jadeStart, jadeEnd = ZoneLook.range(LaneConfig, WallConfig, JADE)
		expect(jadeStart).toBe(ironEnd)
		expect(jadeEnd).toBe(LaneLayout.laneLength(LaneConfig, WallConfig))
		local iron = ZoneLook.walks(LaneConfig, WallConfig, look, IRON)
		local jade = ZoneLook.walks(LaneConfig, WallConfig, look, JADE)
		expect(#jade).toBe(#iron)
		for index, part in jade do
			expect(part.kind).toBe(iron[index].kind)
			expect(part.side).toBe(iron[index].side)
			expect(part.topY).toBe(iron[index].topY)
			expect(part.area.x).toBe(iron[index].area.x)
			expect(part.area.width).toBe(iron[index].area.width)
			expect(back(part.area)).toBeNear(front(iron[index].area))
			expect(front(part.area)).toBeNear(LaneConfig.throwLine.z - jadeEnd)
			for _, zone in { PAPER, BAMBOO, WOOD, STONE, IRON } do
				for _, other in ZoneLook.walks(LaneConfig, WallConfig, look, zone) do
					expect(overlap(part.area, other.area)).toBe(false)
				end
			end
		end
		local fences = ZoneLook.fences(LaneConfig, WallConfig, look, JADE)
		expect(#fences).toBe(6)
		for _, fence in fences do
			for _, other in ZoneLook.fences(LaneConfig, WallConfig, look, IRON) do
				expect(overlap(fence, other)).toBe(false)
			end
		end
	end,

	["the jade zone: jade green floor, white marble walkways with a gold edge"] = function(expect)
		local jade = look.zones.Jade
		for _, tone in { jade.floor.darkColor, jade.floor.lightColor } do
			-- Strong jade green.
			expect(tone[2] > tone[1] + 100 and tone[2] > tone[3]).toBe(true)
		end
		for _, tone in { jade.walk.darkColor, jade.walk.lightColor } do
			-- White.
			expect(tone[1] >= 220 and tone[2] >= 220 and tone[3] >= 220).toBe(true)
		end
		local curb = jade.walk.curbColor
		expect(curb[1] > curb[2] and curb[2] > curb[3] and curb[2] >= 140).toBe(true)
	end,

	["jade walls are a model about as big as the wall, the scratch on its relief, gold pieces"] = function(expect)
		local wall = look.zones.Jade.wall
		expect(ZoneLook.wallModel(look, "Jade")).toBe(wall.model)
		expect(wall.model.template).toBe("jade_wall")
		expect(ZoneLook.wallScratch(look, "Jade")).toBe(true)
		-- Jade green pieces, every fourth gold like the edge of the walkways.
		local function same(x: { number }, y: { number }): boolean
			return x[1] == y[1] and x[2] == y[2] and x[3] == y[3]
		end
		expect(same(ZoneLook.wallColor(LaneConfig, look, "Jade"), look.zones.Jade.nameColor)).toBe(true)
		local accent = ZoneLook.pieceAccent(look, "Jade") :: { color: { number }, every: number }
		expect(accent.every).toBe(4)
		expect(same(accent.color, look.zones.Jade.walk.curbColor)).toBe(true)
		local place =
			ZoneLook.wallModelPlace(wall.model, LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness)
		expect(place ~= nil).toBe(true)
		if place then
			expect(place.scale >= 1 and place.scale <= 1.05).toBe(true)
			expect(place.towardsThrower + wall.model.coverDepth * place.scale / 2).toBeNear(
				LaneConfig.wallThickness / 2
			)
		end
	end,

	["the iron zone joins the stone zone with a clean edge: nothing on top of anything"] = function(expect)
		local _, stoneEnd = ZoneLook.range(LaneConfig, WallConfig, STONE)
		local ironStart, ironEnd = ZoneLook.range(LaneConfig, WallConfig, IRON)
		expect(ironStart).toBe(stoneEnd)
		expect(ironEnd).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 25))
		local stone = ZoneLook.walks(LaneConfig, WallConfig, look, STONE)
		local iron = ZoneLook.walks(LaneConfig, WallConfig, look, IRON)
		expect(#iron).toBe(#stone)
		for index, part in iron do
			expect(part.kind).toBe(stone[index].kind)
			expect(part.side).toBe(stone[index].side)
			expect(part.topY).toBe(stone[index].topY)
			expect(part.area.x).toBe(stone[index].area.x)
			expect(part.area.width).toBe(stone[index].area.width)
			expect(back(part.area)).toBeNear(front(stone[index].area))
			expect(front(part.area)).toBeNear(LaneConfig.throwLine.z - ironEnd)
			for _, zone in { PAPER, BAMBOO, WOOD, STONE } do
				for _, other in ZoneLook.walks(LaneConfig, WallConfig, look, zone) do
					expect(overlap(part.area, other.area)).toBe(false)
				end
			end
		end
		local fences = ZoneLook.fences(LaneConfig, WallConfig, look, IRON)
		expect(#fences).toBe(6)
		for _, fence in fences do
			for _, other in ZoneLook.fences(LaneConfig, WallConfig, look, STONE) do
				expect(overlap(fence, other)).toBe(false)
			end
		end
	end,

	["the iron zone: dark iron floor, brick red walkways with a glowing orange edge"] = function(expect)
		local iron = look.zones.Iron
		for _, tone in { iron.floor.darkColor, iron.floor.lightColor } do
			-- Dark grey.
			expect(math.abs(tone[1] - tone[2]) <= 8 and math.abs(tone[2] - tone[3]) <= 8 and tone[1] <= 100).toBe(true)
		end
		for _, tone in { iron.walk.darkColor, iron.walk.lightColor } do
			-- Rust red: red clearly ahead.
			expect(tone[1] > tone[2] + 50 and tone[2] >= tone[3]).toBe(true)
		end
		local curb = iron.walk.curbColor
		expect(curb[1] > curb[2] and curb[2] > curb[3] and curb[1] >= 180).toBe(true)
		expect(iron.walk.curbGlow).toBe(true)
		-- No other edge glows.
		for name, zone in look.zones :: { [string]: any } do
			if name ~= "Iron" and zone.walk then
				expect(zone.walk.curbGlow).toBe(nil)
			end
		end
	end,

	["iron walls are a model as big as the wall, with the scratch on its bronze band"] = function(expect)
		local wall = look.zones.Iron.wall
		expect(ZoneLook.wallModel(look, "Iron")).toBe(wall.model)
		expect(wall.model.template).toBe("iron_wall")
		expect(ZoneLook.wallScratch(look, "Iron")).toBe(true)
		-- Dark grey pieces, a few in bronze.
		local grey = ZoneLook.wallColor(LaneConfig, look, "Iron")
		expect(math.abs(grey[1] - grey[2]) <= 8 and grey[1] <= 100).toBe(true)
		expect(ZoneLook.pieceAccent(look, "Iron")).toBe(wall.pieceAccent)
		expect(ZoneLook.pieceAccent(look, "Stone")).toBe(nil)
		local place =
			ZoneLook.wallModelPlace(wall.model, LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness)
		expect(place ~= nil).toBe(true)
		if place then
			-- Barely bigger than modelled.
			expect(place.scale >= 1 and place.scale <= 1.05).toBe(true)
			-- The front of the whole model lies level with the wall's front.
			expect(place.towardsThrower + wall.model.coverDepth * place.scale / 2).toBeNear(
				LaneConfig.wallThickness / 2
			)
		end
	end,

	["the stone zone joins the wood zone with a clean edge: nothing on top of anything"] = function(expect)
		local _, woodEnd = ZoneLook.range(LaneConfig, WallConfig, WOOD)
		local stoneStart, stoneEnd = ZoneLook.range(LaneConfig, WallConfig, STONE)
		expect(stoneStart).toBe(woodEnd)
		expect(stoneEnd).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 20))
		local wood = ZoneLook.walks(LaneConfig, WallConfig, look, WOOD)
		local stone = ZoneLook.walks(LaneConfig, WallConfig, look, STONE)
		expect(#stone).toBe(#wood)
		for index, part in stone do
			expect(part.kind).toBe(wood[index].kind)
			expect(part.side).toBe(wood[index].side)
			expect(part.topY).toBe(wood[index].topY)
			expect(part.area.x).toBe(wood[index].area.x)
			expect(part.area.width).toBe(wood[index].area.width)
			expect(back(part.area)).toBeNear(front(wood[index].area))
			expect(front(part.area)).toBeNear(LaneConfig.throwLine.z - stoneEnd)
			for _, zone in { PAPER, BAMBOO, WOOD } do
				for _, other in ZoneLook.walks(LaneConfig, WallConfig, look, zone) do
					expect(overlap(part.area, other.area)).toBe(false)
				end
			end
		end
		local fences = ZoneLook.fences(LaneConfig, WallConfig, look, STONE)
		expect(#fences).toBe(6)
		for _, fence in fences do
			for _, other in ZoneLook.fences(LaneConfig, WallConfig, look, WOOD) do
				expect(overlap(fence, other)).toBe(false)
			end
		end
	end,

	["the stone zone: stone grey floor, sand white walkways with a moss green edge"] = function(expect)
		local stone = look.zones.Stone
		for _, tone in { stone.floor.darkColor, stone.floor.lightColor } do
			-- Grey: the three parts nearly equal.
			expect(math.abs(tone[1] - tone[2]) <= 8 and math.abs(tone[2] - tone[3]) <= 8).toBe(true)
		end
		for _, tone in { stone.walk.darkColor, stone.walk.lightColor } do
			-- Warm sand beige: clearly more red than blue, and brighter than the grey floor.
			expect(tone[1] > tone[2] and tone[2] > tone[3] and tone[1] - tone[3] >= 40).toBe(true)
			expect(tone[1] > stone.floor.lightColor[1] + 30).toBe(true)
		end
		local curb = stone.walk.curbColor
		expect(curb[2] > curb[1] and curb[2] > curb[3]).toBe(true)
	end,

	["stone walls are a model as big as the wall, with the scratch on its stones"] = function(expect)
		local wall = look.zones.Stone.wall
		expect(ZoneLook.wallModel(look, "Stone")).toBe(wall.model)
		expect(wall.model.template).toBe("stone_wall")
		expect(ZoneLook.wallScratch(look, "Stone")).toBe(true)
		-- Its pieces are grey.
		local grey = ZoneLook.wallColor(LaneConfig, look, "Stone")
		expect(math.abs(grey[1] - grey[2]) <= 8 and math.abs(grey[2] - grey[3]) <= 8).toBe(true)
		local place =
			ZoneLook.wallModelPlace(wall.model, LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness)
		expect(place ~= nil).toBe(true)
		if place then
			-- Barely bigger than modelled.
			expect(place.scale >= 1 and place.scale <= 1.05).toBe(true)
			expect(place.towardsThrower + wall.model.coverDepth * place.scale / 2).toBeNear(
				LaneConfig.wallThickness / 2
			)
		end
	end,

	["the wood zone joins the bamboo zone with a clean edge: nothing on top of anything"] = function(expect)
		local _, bambooEnd = ZoneLook.range(LaneConfig, WallConfig, BAMBOO)
		local woodStart, woodEnd = ZoneLook.range(LaneConfig, WallConfig, WOOD)
		expect(woodStart).toBe(bambooEnd)
		expect(woodEnd).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 15))
		local bamboo = ZoneLook.walks(LaneConfig, WallConfig, look, BAMBOO)
		local wood = ZoneLook.walks(LaneConfig, WallConfig, look, WOOD)
		expect(#wood).toBe(#bamboo)
		for index, part in wood do
			-- The same steps as in the bamboo zone, right behind them.
			expect(part.kind).toBe(bamboo[index].kind)
			expect(part.side).toBe(bamboo[index].side)
			expect(part.topY).toBe(bamboo[index].topY)
			expect(part.area.x).toBe(bamboo[index].area.x)
			expect(part.area.width).toBe(bamboo[index].area.width)
			expect(back(part.area)).toBeNear(front(bamboo[index].area))
			expect(front(part.area)).toBeNear(LaneConfig.throwLine.z - woodEnd)
			for _, zone in { PAPER, BAMBOO } do
				for _, other in ZoneLook.walks(LaneConfig, WallConfig, look, zone) do
					expect(overlap(part.area, other.area)).toBe(false)
				end
			end
		end
		local fences = ZoneLook.fences(LaneConfig, WallConfig, look, WOOD)
		expect(#fences).toBe(6)
		for _, fence in fences do
			for _, other in ZoneLook.fences(LaneConfig, WallConfig, look, BAMBOO) do
				expect(overlap(fence, other)).toBe(false)
			end
		end
	end,

	["the wood zone: honey brown floor, greenish beige walkways with a dark brown edge"] = function(expect)
		local wood = look.zones.Wood
		for _, tone in { wood.floor.darkColor, wood.floor.lightColor } do
			-- Warm and light: red over green over blue.
			expect(tone[1] > tone[2] and tone[2] > tone[3]).toBe(true)
			expect(tone[1] >= 200).toBe(true)
		end
		for _, tone in { wood.walk.darkColor, wood.walk.lightColor } do
			-- Greenish beige: green not below red, clearly less blue.
			expect(tone[2] >= tone[1] and tone[3] < tone[1] - 30).toBe(true)
		end
		local curb = wood.walk.curbColor
		expect(curb[1] > curb[2] and curb[2] > curb[3] and curb[1] < 110).toBe(true)
	end,

	["wood walls are a model as big as the wall, with the scratch on its flat planks"] = function(expect)
		local wall = look.zones.Wood.wall
		expect(ZoneLook.wallModel(look, "Wood")).toBe(wall.model)
		expect(wall.model.template).toBe("wooden_wall")
		expect(ZoneLook.wallScratch(look, "Wood")).toBe(true)
		-- Its pieces are wood brown.
		expect(ZoneLook.wallColor(LaneConfig, look, "Wood")).toBe(wall.color)
		expect(wall.color[1] > wall.color[2] and wall.color[2] > wall.color[3]).toBe(true)
		local place =
			ZoneLook.wallModelPlace(wall.model, LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness)
		expect(place ~= nil).toBe(true)
		if place then
			expect(place.scale).toBeNear(1)
			expect(place.sinkStuds).toBe(0)
			-- The front of the planks lies level with the wall's front.
			expect(place.towardsThrower + wall.model.coverDepth * place.scale / 2).toBeNear(
				LaneConfig.wallThickness / 2
			)
		end
	end,

	["the bamboo zone joins the paper zone with a clean edge: nothing on top of anything"] = function(expect)
		local _, paperEnd = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local bambooStart, bambooEnd = ZoneLook.range(LaneConfig, WallConfig, BAMBOO)
		expect(bambooStart).toBe(paperEnd)
		expect(bambooEnd).toBe(LaneLayout.wallDistance(LaneConfig, WallConfig, 10))
		local paper = ZoneLook.walks(LaneConfig, WallConfig, look, PAPER)
		local bamboo = ZoneLook.walks(LaneConfig, WallConfig, look, BAMBOO)
		expect(#bamboo).toBe(#paper)
		for index, part in bamboo do
			-- The same steps as in the paper zone, right behind them.
			expect(part.kind).toBe(paper[index].kind)
			expect(part.side).toBe(paper[index].side)
			expect(part.topY).toBe(paper[index].topY)
			expect(part.area.x).toBe(paper[index].area.x)
			expect(part.area.width).toBe(paper[index].area.width)
			expect(back(part.area)).toBeNear(front(paper[index].area))
			expect(front(part.area)).toBeNear(LaneConfig.throwLine.z - bambooEnd)
			for _, other in paper do
				expect(overlap(part.area, other.area)).toBe(false)
			end
		end
		-- Its fence keeps players off, and lies on no fence of the paper zone.
		local fences = ZoneLook.fences(LaneConfig, WallConfig, look, BAMBOO)
		expect(#fences).toBe(6)
		for _, fence in fences do
			for _, other in ZoneLook.fences(LaneConfig, WallConfig, look, PAPER) do
				expect(overlap(fence, other)).toBe(false)
			end
		end
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
		expect(sign.text).toBe("BAMBOO")
		expect(sign.color).toBe(look.zones.Bamboo.nameColor)
		expect(sign.x).toBe(LaneConfig.throwLine.x)
		local _, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		expect(sign.z).toBe(LaneConfig.throwLine.z - to - look.sign.behindZoneEnd)
		-- Its lower end is above the top of the walls.
		expect(sign.y - look.sign.heightStuds / 2 > LaneConfig.floorTopY + LaneConfig.wallHeight).toBe(true)
		-- It can be seen from the throw zone.
		expect(look.sign.maxDistance > to + LaneConfig.throwZoneLength).toBe(true)
		-- Behind the bamboo zone floats the name of the wood zone.
		local wood = ZoneLook.sign(LaneConfig, WallConfig, look, BAMBOO) :: ZoneLook.Sign
		expect(wood.text).toBe("WOOD")
		expect(wood.color).toBe(look.zones.Wood.nameColor)
		local _, bambooEnd = ZoneLook.range(LaneConfig, WallConfig, BAMBOO)
		expect(wood.z).toBe(LaneConfig.throwLine.z - bambooEnd - look.sign.behindZoneEnd)
		-- Behind the wood zone floats the name of the stone zone, in stone grey.
		local stone = ZoneLook.sign(LaneConfig, WallConfig, look, WOOD) :: ZoneLook.Sign
		expect(stone.text).toBe("STONE")
		expect(stone.color).toBe(look.zones.Stone.nameColor)
		local grey = stone.color
		expect(math.abs(grey[1] - grey[2]) <= 12 and math.abs(grey[2] - grey[3]) <= 12).toBe(true)
		local _, woodEnd = ZoneLook.range(LaneConfig, WallConfig, WOOD)
		expect(stone.z).toBe(LaneConfig.throwLine.z - woodEnd - look.sign.behindZoneEnd)
		-- Higher than the other names, clear above the torii behind it.
		local wood2 = ZoneLook.sign(LaneConfig, WallConfig, look, BAMBOO) :: ZoneLook.Sign
		expect(stone.y).toBe(wood2.y + look.zones.Stone.nameRaise)
		-- Behind the stone zone floats the name of the iron zone, dark grey with a little orange.
		local iron = ZoneLook.sign(LaneConfig, WallConfig, look, STONE) :: ZoneLook.Sign
		expect(iron.text).toBe("IRON")
		expect(iron.color).toBe(look.zones.Iron.nameColor)
		expect(iron.color[1] > iron.color[2] and iron.color[2] > iron.color[3]).toBe(true)
		expect(iron.color[1] - iron.color[3] <= 40 and iron.color[1] <= 140).toBe(true)
		local _, stoneEnd = ZoneLook.range(LaneConfig, WallConfig, STONE)
		expect(iron.z).toBe(LaneConfig.throwLine.z - stoneEnd - look.sign.behindZoneEnd)
		-- Behind the iron zone floats the name of the jade zone, in strong jade green.
		local jade = ZoneLook.sign(LaneConfig, WallConfig, look, IRON) :: ZoneLook.Sign
		expect(jade.text).toBe("JADE")
		expect(jade.color).toBe(look.zones.Jade.nameColor)
		expect(jade.color[2] > jade.color[1] + 80 and jade.color[2] > jade.color[3]).toBe(true)
		local _, ironEnd = ZoneLook.range(LaneConfig, WallConfig, IRON)
		expect(jade.z).toBe(LaneConfig.throwLine.z - ironEnd - look.sign.behindZoneEnd)
		-- The jade zone is the last one, so nothing floats behind it.
		expect(ZoneLook.sign(LaneConfig, WallConfig, look, JADE)).toBe(nil)
		expect(ZoneLook.sign(LaneConfig, WallConfig, look, #WallConfig.materials)).toBe(nil)
	end,

	["paper walls are cream white with a frame, the other walls keep their plain color"] = function(expect)
		expect(ZoneLook.wallColor(LaneConfig, look, "Paper")).toBe(look.zones.Paper.wall.color)
		expect(ZoneLook.wallFrameColor(look, "Paper")).toBe(look.zones.Paper.wall.frameColor)
		for _, material in WallConfig.materials do
			expect(isColor(ZoneLook.wallColor(LaneConfig, look, material))).toBe(true)
			if material ~= "Paper" then
				expect(ZoneLook.wallFrameColor(look, material)).toBe(nil)
			end
			-- Every zone of world 1 has its own wall color now.
			expect(look.zones[material].wall ~= nil).toBe(true)
		end
		-- The frame is thin compared to the wall.
		expect(look.wallFrame.widthStuds * 10 <= LaneConfig.wallHeight).toBe(true)
	end,

	["a wall can carry upright stripes and a level band on top of them"] = function(expect)
		local wall = {
			color = { 116, 180, 76 },
			stripes = { count = 5, color = { 86, 150, 58 }, widthShare = 0.09 },
			band = { color = { 132, 88, 48 }, centerY = 0.3, heightShare = 0.06 },
		}
		local own = { walk = look.walk, sign = look.sign, zones = { Paper = { wall = wall } } }
		local pattern = ZoneLook.wallPattern(own, "Paper")
		local count = wall.stripes.count
		expect(#pattern).toBe(count + 1)
		for index = 1, count do
			local stripe = pattern[index]
			-- Upright over the whole height, on the wall, apart from each other.
			expect(stripe.y).toBe(0)
			expect(stripe.height).toBe(1)
			expect(stripe.x >= 0 and stripe.x + stripe.width <= 1).toBe(true)
			expect(stripe.color).toBe(wall.stripes.color)
			if index > 1 then
				local before = pattern[index - 1]
				expect(stripe.x > before.x + before.width).toBe(true)
			end
			-- Evenly spread: the same on the left as on the right.
			local mirror = pattern[count + 1 - index]
			expect(stripe.x).toBeNear(1 - mirror.x - mirror.width)
		end
		-- The band: level, across the whole wall, in the upper half, in front of the stripes.
		local band = pattern[count + 1]
		expect(band.color).toBe(wall.band.color)
		expect(band.x).toBe(0)
		expect(band.width).toBe(1)
		expect(band.y > 0 and band.y + band.height < 0.5).toBe(true)
	end,

	["bamboo walls are a model without scratch, the other walls are plain and get a scratch"] = function(expect)
		local wall = look.zones.Bamboo.wall
		-- Its pieces are bamboo green.
		expect(ZoneLook.wallColor(LaneConfig, look, "Bamboo")).toBe(wall.color)
		expect(wall.color[2] > wall.color[1] and wall.color[2] > wall.color[3]).toBe(true)
		expect(ZoneLook.wallModel(look, "Bamboo")).toBe(wall.model)
		expect(wall.model.template).toBe("bamboo_wall")
		expect(ZoneLook.wallScratch(look, "Bamboo")).toBe(false)
		-- Nothing is drawn on it any more.
		expect(#ZoneLook.wallPattern(look, "Bamboo")).toBe(0)
		expect(ZoneLook.wallFrameColor(look, "Bamboo")).toBe(nil)
		for _, material in WallConfig.materials do
			if material ~= "Bamboo" then
				expect(ZoneLook.wallScratch(look, material)).toBe(true)
			end
			if material == "Paper" then
				expect(ZoneLook.wallModel(look, material)).toBe(nil)
			end
		end
		expect(ZoneLook.wallModel(look, "Cheese")).toBe(nil)
		expect(ZoneLook.wallScratch(look, "Cheese")).toBe(true)
	end,

	["a wall model is made evenly bigger until it hides the whole wall, front on front"] = function(expect)
		local model = look.zones.Bamboo.wall.model
		local width, height, thickness = LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness
		local place = ZoneLook.wallModelPlace(model, width, height, thickness)
		expect(place ~= nil).toBe(true)
		if place then
			expect(model.coverWidth * place.scale >= width - 1e-9).toBe(true)
			-- Also when it stands a little in the floor.
			expect(model.coverHeight * place.scale - place.sinkStuds >= height - 1e-9).toBe(true)
			-- Not bigger than needed.
			local needed = math.max(width / model.coverWidth, (height + place.sinkStuds) / model.coverHeight)
			expect(place.scale).toBeNear(needed)
			-- Its front lies level with the wall's front.
			expect(place.towardsThrower + model.coverDepth * place.scale / 2).toBeNear(thickness / 2)
			expect(place.sinkStuds >= 0 and place.sinkStuds <= 0.5).toBe(true)
		end
		-- A tall, narrow wall: the height decides.
		local tall =
			ZoneLook.wallModelPlace({ template = "x", coverWidth = 10, coverHeight = 10, coverDepth = 2 }, 10, 30, 2)
		expect(tall ~= nil and tall.scale == 3 and tall.sinkStuds == 0).toBe(true)
		expect(tall ~= nil and tall.towardsThrower == -2).toBe(true)
		-- Broken sizes: no model.
		for _, broken in { 0, -4, 0 / 0, math.huge } do
			expect(
				ZoneLook.wallModelPlace(
					{ template = "x", coverWidth = broken, coverHeight = 10, coverDepth = 2 },
					10,
					30,
					2
				)
			).toBe(nil)
			expect(
				ZoneLook.wallModelPlace(
					{ template = "x", coverWidth = 10, coverHeight = broken, coverDepth = 2 },
					10,
					30,
					2
				)
			).toBe(nil)
			expect(
				ZoneLook.wallModelPlace(
					{ template = "x", coverWidth = 10, coverHeight = 10, coverDepth = broken },
					10,
					30,
					2
				)
			).toBe(nil)
		end
		local negativeSink = ZoneLook.wallModelPlace(
			{ template = "x", coverWidth = 10, coverHeight = 10, coverDepth = 2, sinkStuds = -3 },
			10,
			10,
			2
		)
		expect(negativeSink ~= nil and negativeSink.sinkStuds == 0).toBe(true)
	end,

	["a hit wall model rocks briefly, calms down and turns a little darker"] = function(expect)
		local hit = look.zones.Bamboo.wall.model.hit
		-- Short and slight.
		expect(hit.wobbleSeconds > 0 and hit.wobbleSeconds <= 1).toBe(true)
		expect(hit.wobbleDegrees > 0 and hit.wobbleDegrees <= 8).toBe(true)
		expect(hit.wobbleSwings >= 1).toBe(true)
		expect(ZoneLook.hitDarken(hit) > 0 and ZoneLook.hitDarken(hit) <= 0.5).toBe(true)
		expect(ZoneLook.wobbleDegrees(hit, 0)).toBe(0)
		expect(ZoneLook.wobbleDegrees(hit, -1)).toBe(0)
		expect(ZoneLook.wobbleDegrees(hit, hit.wobbleSeconds)).toBe(0)
		expect(ZoneLook.wobbleDegrees(hit, 100)).toBe(0)
		local biggest, late = 0, 0
		for step = 1, 99 do
			local time = hit.wobbleSeconds * step / 100
			local lean = math.abs(ZoneLook.wobbleDegrees(hit, time))
			expect(lean <= hit.wobbleDegrees).toBe(true)
			biggest = math.max(biggest, lean)
			if step > 80 then
				late = math.max(late, lean)
			end
		end
		expect(biggest > hit.wobbleDegrees * 0.5).toBe(true)
		expect(late < biggest / 2).toBe(true)
		-- Broken values: it stands still and keeps its color.
		expect(ZoneLook.wobbleDegrees(hit, 0 / 0)).toBe(0)
		local broken = { wobbleDegrees = 0 / 0, wobbleSeconds = 0.5, wobbleSwings = 3, darken = 0 / 0 }
		expect(ZoneLook.wobbleDegrees(broken, 0.1)).toBe(0)
		expect(ZoneLook.hitDarken(broken)).toBe(0)
		expect(ZoneLook.hitDarken({ wobbleDegrees = 1, wobbleSeconds = 1, wobbleSwings = 1, darken = 7 })).toBe(1)
		expect(ZoneLook.hitDarken({ wobbleDegrees = 1, wobbleSeconds = 1, wobbleSwings = 1, darken = -7 })).toBe(0)
	end,

	["a wall pattern stays on the wall whatever the config says"] = function(expect)
		local function patternOf(wall: any): { ZoneLook.FaceRect }
			local odd = { walk = look.walk, sign = look.sign, zones = { Paper = { wall = wall } } }
			return ZoneLook.wallPattern(odd, "Paper")
		end
		local green = { 1, 2, 3 }
		expect(#patternOf({ color = green })).toBe(0)
		expect(#patternOf({ color = green, stripes = { count = 0, color = green, widthShare = 0.1 } })).toBe(0)
		expect(#patternOf({ color = green, stripes = { count = -3, color = green, widthShare = 0.1 } })).toBe(0)
		expect(#patternOf({ color = green, stripes = { count = 4, color = green, widthShare = 0 } })).toBe(0)
		-- Too wide stripes are narrowed until they just touch.
		local wide = patternOf({ color = green, stripes = { count = 4, color = green, widthShare = 3 } })
		expect(#wide).toBe(4)
		expect(wide[1].x).toBeNear(0)
		expect(wide[4].x + wide[4].width).toBeNear(1)
		-- A band outside the wall is pushed back onto it.
		local low = patternOf({ color = green, band = { color = green, centerY = 5, heightShare = 0.2 } })
		expect(low[1].y + low[1].height).toBeNear(1)
		local high = patternOf({ color = green, band = { color = green, centerY = -5, heightShare = 0.2 } })
		expect(high[1].y).toBe(0)
		expect(#patternOf({ color = green, band = { color = green, centerY = 0.3, heightShare = 0 } })).toBe(0)
		expect(#ZoneLook.wallPattern(look, "Cheese")).toBe(0)
	end,

	["every zone look names a material that exists and uses real colors"] = function(expect)
		for material, zoneStyle in look.zones :: { [string]: any } do
			expect(table.find(WallConfig.materials, material) ~= nil).toBe(true)
			if zoneStyle.nameColor then
				expect(isColor(zoneStyle.nameColor)).toBe(true)
			end
			for _, group in { zoneStyle.floor, zoneStyle.walk } do
				for _, value in group or {} do
					-- Switches like curbGlow are not colors.
					if typeof(value) ~= "boolean" then
						expect(isColor(value)).toBe(true)
					end
				end
			end
			local wall = zoneStyle.wall
			if wall then
				expect(isColor(wall.color)).toBe(true)
				expect(wall.frameColor == nil or isColor(wall.frameColor)).toBe(true)
				expect(wall.stripes == nil or isColor(wall.stripes.color)).toBe(true)
				expect(wall.band == nil or isColor(wall.band.color)).toBe(true)
			end
		end
	end,
}
