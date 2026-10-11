local TrainingLook = require("../src/shared/Rules/TrainingLook")
local Training = require("../src/shared/Rules/Training")
local ThrowZoneLayout = require("../src/shared/Rules/ThrowZoneLayout")
local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneConfig = require("../src/shared/Config/Lane")
local TrainingConfig = require("../src/shared/Config/Training")
local WallConfig = require("../src/shared/Config/Walls")
local Ui = require("../src/shared/Config/Ui")

local world = Ui.world
local training = world.training
local field = training.field
local STRAW_LANE = 1
local straw = training.themes.straw
local floorTopY = LaneConfig.floorTopY

type Area = TrainingLook.Area

local function left(area: Area): number
	return area.x - area.width / 2
end
local function right(area: Area): number
	return area.x + area.width / 2
end
local function front(area: Area): number
	return area.z - area.length / 2
end
local function back(area: Area): number
	return area.z + area.length / 2
end

local function overlap(a: Area, b: Area): boolean
	local tolerance = 0.001
	return left(a) < right(b) - tolerance
		and left(b) < right(a) - tolerance
		and front(a) < back(b) - tolerance
		and front(b) < back(a) - tolerance
end

local function inside(inner: Area, outer: Area): boolean
	local tolerance = 0.001
	return left(inner) >= left(outer) - tolerance
		and right(inner) <= right(outer) + tolerance
		and front(inner) >= front(outer) - tolerance
		and back(inner) <= back(outer) + tolerance
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

local outline = TrainingLook.outline(TrainingConfig, field, STRAW_LANE)
local inner = TrainingLook.inner(TrainingConfig, field, STRAW_LANE)
local pad = TrainingLook.pad(TrainingConfig, STRAW_LANE)
local strip = TrainingLook.strip(TrainingConfig, field, STRAW_LANE)
local floors = TrainingLook.floors(TrainingConfig, field, STRAW_LANE)
local frame = TrainingLook.frame(TrainingConfig, field, STRAW_LANE)
local stones = TrainingLook.stones(TrainingConfig, field, STRAW_LANE, floorTopY, straw.strip.stones)

return {
	["lane 1 has the straw theme, the other lanes stay plain"] = function(expect)
		expect(training.laneThemes[1]).toBe("straw")
		for laneIndex = 2, Training.laneCount(TrainingConfig) do
			expect(training.laneThemes[laneIndex]).toBe(nil)
		end
		for _, name in training.laneThemes :: { [number]: string } do
			expect(typeof(training.themes[name])).toBe("table")
		end
	end,

	["the start pad is exactly the pad the game checks"] = function(expect)
		local logicPad = Training.lanePad(TrainingConfig, STRAW_LANE) :: Training.Pad
		expect(pad.x).toBe(logicPad.x)
		expect(pad.z).toBe(logicPad.z)
		expect(pad.width).toBe(logicPad.width)
		expect(pad.length).toBe(logicPad.length)
		-- Standing anywhere on the drawn pad counts as on the pad, right up to its edges.
		expect(Training.laneAt(TrainingConfig, left(pad) + 0.01, pad.z)).toBe(STRAW_LANE)
		expect(Training.laneAt(TrainingConfig, right(pad) - 0.01, front(pad) + 0.01)).toBe(STRAW_LANE)
	end,

	["the target line is where the lane's wall stands"] = function(expect)
		local walls = TrainingConfig.lanes[STRAW_LANE].walls
		local expected = front(pad) - Training.wallOffset(TrainingConfig, walls)
		expect(TrainingLook.targetLineZ(TrainingConfig, STRAW_LANE)).toBe(expected)
	end,

	["frame, floor, strip and pad fill the field without gaps and without lying on each other"] = function(expect)
		local pieces: { Area } = { pad, strip }
		for _, piece in floors do
			table.insert(pieces, piece)
		end
		for _, piece in frame do
			table.insert(pieces, piece)
		end
		local area = 0
		for index, piece in pieces do
			expect(inside(piece, outline)).toBe(true)
			expect(piece.width > 0 and piece.length > 0).toBe(true)
			area += piece.width * piece.length
			for other = index + 1, #pieces do
				if overlap(piece, pieces[other]) then
					error(`pieces {index} and {other} lie on each other`)
				end
			end
		end
		expect(area).toBeNear(outline.width * outline.length)
	end,

	["the frame runs all around and is about two studs wide"] = function(expect)
		expect(#frame).toBe(4)
		expect(field.frameWidth >= 1.5 and field.frameWidth <= 2.5).toBe(true)
		for _, piece in frame do
			expect(overlap(piece, inner)).toBe(false)
			expect(math.min(piece.width, piece.length)).toBeNear(field.frameWidth)
		end
		expect(inner.width).toBeNear(outline.width - 2 * field.frameWidth)
		expect(inner.length).toBeNear(outline.length - 2 * field.frameWidth)
	end,

	["the layers step down towards the middle: frame, floor, strip; the pad is raised"] = function(expect)
		expect(field.frameHeight > field.floorHeight).toBe(true)
		-- The strip lies at the lane floor level, clearly below the themed floor.
		expect(field.floorHeight >= 0.2).toBe(true)
		expect(field.frameHeight - field.floorHeight >= 0.2).toBe(true)
		expect(field.padHeight >= 0.2).toBe(true)
		-- Everything a player steps over stays low.
		expect(field.frameHeight <= 0.6).toBe(true)
	end,

	["the strip runs down the middle from the pad to behind the target"] = function(expect)
		expect(strip.x).toBe(pad.x)
		expect(strip.width).toBe(pad.width)
		expect(back(strip)).toBeNear(front(pad))
		expect(front(strip)).toBeNear(front(inner))
		expect(front(strip) < TrainingLook.targetLineZ(TrainingConfig, STRAW_LANE)).toBe(true)
		-- The themed floor lies left and right of it, over the whole inner length.
		expect(#floors).toBe(2)
		for _, band in floors do
			expect(band.length).toBeNear(inner.length)
			expect(band.width >= 3).toBe(true)
		end
	end,

	["the stone edge makes the strip's outline step in and out, with at most ten stones"] = function(expect)
		expect(#stones <= 10).toBe(true)
		expect(#stones >= 6).toBe(true)
		for _, side in { straw.strip.stones.left, straw.strip.stones.right } do
			-- Neighbouring stones differ in width, so the edge really steps.
			for index = 2, #side do
				expect(side[index].width ~= side[index - 1].width).toBe(true)
			end
		end
		-- The two sides are not mirror images.
		local same = #straw.strip.stones.left == #straw.strip.stones.right
		for index, stone in straw.strip.stones.left do
			local other = straw.strip.stones.right[index]
			same = same and other ~= nil and other.width == stone.width and other.share == stone.share
		end
		expect(same).toBe(false)
	end,

	["stones lie on the strip along its sides, from the pad to the far end, and leave the middle free"] = function(
		expect
	)
		local leftLength, rightLength = 0, 0
		for index, stone in stones do
			expect(inside(stone.area, strip)).toBe(true)
			for other = index + 1, #stones do
				expect(overlap(stone.area, stones[other].area)).toBe(false)
			end
			-- Each stone touches one side of the strip.
			local onLeft = math.abs(left(stone.area) - left(strip)) < 0.001
			local onRight = math.abs(right(stone.area) - right(strip)) < 0.001
			expect(onLeft ~= onRight).toBe(true)
			if onLeft then
				leftLength += stone.area.length
			else
				rightLength += stone.area.length
			end
			-- The weapon flies down the middle of the lane.
			local free = field.minFreeWidth / 2
			expect(right(stone.area) <= pad.x - free + 0.001 or left(stone.area) >= pad.x + free - 0.001).toBe(true)
			-- As high as the themed floor, clearly above the strip they lie on.
			expect(stone.topY).toBeNear(floorTopY + field.floorHeight)
			expect(stone.topY - floorTopY >= 0.2).toBe(true)
		end
		expect(leftLength).toBeNear(strip.length)
		expect(rightLength).toBeNear(strip.length)
	end,

	["stones that are too wide are cut back, broken stone lists give no stones"] = function(expect)
		local wide = { left = { { share = 1, width = 50 } }, right = { { share = 1, width = 50 } } }
		for _, stone in TrainingLook.stones(TrainingConfig, field, STRAW_LANE, floorTopY, wide) do
			expect(stone.area.width).toBeNear((strip.width - field.minFreeWidth) / 2)
		end
		local none = { left = {}, right = { { share = 0, width = 1 }, { share = -2, width = 1 } } }
		expect(#TrainingLook.stones(TrainingConfig, field, STRAW_LANE, floorTopY, none)).toBe(0)
	end,

	["the fence closes everything in front of the pad and leaves the pad open"] = function(expect)
		local fences = TrainingLook.fences(TrainingConfig, field, STRAW_LANE)
		expect(#fences).toBe(4)
		for index, fence in fences do
			expect(inside(fence, outline)).toBe(true)
			expect(overlap(fence, pad)).toBe(false)
			for other = index + 1, #fences do
				expect(overlap(fence, fences[other])).toBe(false)
			end
		end
		-- One wall across the whole field right in front of the pad.
		local across = fences[1]
		expect(across.width).toBeNear(outline.width)
		expect(back(across)).toBeNear(front(pad))
		-- The others run along the far end and both sides, all the way round.
		local minX, maxX, minZ = math.huge, -math.huge, math.huge
		for _, fence in fences do
			minX, maxX, minZ = math.min(minX, left(fence)), math.max(maxX, right(fence)), math.min(minZ, front(fence))
		end
		expect(minX).toBeNear(left(outline))
		expect(maxX).toBeNear(right(outline))
		expect(minZ).toBeNear(front(outline))
		-- Behind the pad and beside it nothing is fenced: the player walks in from there.
		for _, fence in fences do
			expect(back(fence) <= front(pad) + 0.001).toBe(true)
		end
	end,

	["the target stands on the strip, its face on the target line, looking at the player"] = function(expect)
		local place = TrainingLook.target(TrainingConfig, STRAW_LANE, floorTopY, straw.target)
		local line = TrainingLook.targetLineZ(TrainingConfig, STRAW_LANE)
		expect(place.x).toBe(pad.x)
		expect(place.y).toBeNear(floorTopY + (straw.target.lift or 0))
		expect(place.z).toBeNear(line - straw.target.faceDistance)
		expect(place.z > front(strip) and place.z < back(strip)).toBe(true)
		-- Its front, turned the way CFrame.Angles(0, yaw, 0) turns, points towards positive Z.
		local yaw = math.rad(place.yawDegrees)
		local frontX, frontZ = straw.target.front.x, straw.target.front.z
		local x = frontX * math.cos(yaw) + frontZ * math.sin(yaw)
		local z = -frontX * math.sin(yaw) + frontZ * math.cos(yaw)
		expect(math.abs(x) < 1e-6).toBe(true)
		expect(math.abs(z - 1) < 1e-6).toBe(true)
		-- The whole target stays inside the frame.
		expect(place.z - 2.5 > front(inner)).toBe(true)
	end,

	["three to four hay bales lie on the themed floor, turned differently, one on another"] = function(expect)
		expect(#straw.props >= 3 and #straw.props <= 4).toBe(true)
		local turns = {}
		local stacked = 0
		for _, prop in straw.props do
			local place = TrainingLook.prop(TrainingConfig, field, STRAW_LANE, floorTopY, prop)
			-- On one of the two bands, not on the strip and not on the pad's row.
			local onBand = false
			for _, band in floors do
				onBand = onBand
					or (
						place.x > left(band)
						and place.x < right(band)
						and place.z > front(band)
						and place.z < back(band)
					)
			end
			expect(onBand).toBe(true)
			expect(place.z < front(pad)).toBe(true)
			expect(turns[prop.turnDegrees]).toBe(nil)
			turns[prop.turnDegrees] = true
			if (prop.lift or 0) > 0 then
				stacked += 1
				expect(place.y).toBeNear(floorTopY + field.floorHeight + prop.lift)
			else
				expect(place.y).toBeNear(floorTopY + field.floorHeight)
			end
		end
		expect(stacked).toBe(1)
	end,

	["tufts are small, flat and lie clearly above the floor they are on"] = function(expect)
		expect(#straw.tufts >= 3 and #straw.tufts <= 8).toBe(true)
		expect(field.tuftHeight >= 0.2 and field.tuftHeight <= 0.4).toBe(true)
		for _, tuft in straw.tufts do
			local block = TrainingLook.tuft(TrainingConfig, field, STRAW_LANE, floorTopY, tuft)
			expect(inside(block.area, inner)).toBe(true)
			expect(block.area.length <= 2 and block.area.width <= 1).toBe(true)
			local onStrip = math.abs(tuft.right) < pad.width / 2
			local ground = if onStrip then floorTopY else floorTopY + field.floorHeight
			expect(block.topY).toBeNear(ground + field.tuftHeight)
			-- A tuft on the strip lies in the free middle, not inside a stone.
			if onStrip then
				expect(math.abs(tuft.right) + tuft.length / 2 <= field.minFreeWidth / 2 + 0.3).toBe(true)
			end
		end
	end,

	["the field keeps clear of the other lanes, the walkways and the green at the throw zone"] = function(expect)
		for laneIndex = 1, Training.laneCount(TrainingConfig) do
			if laneIndex ~= STRAW_LANE then
				local area = Training.laneArea(TrainingConfig, laneIndex) :: Training.Area
				-- The other lane with its invisible barriers along the sides.
				local other: Area = {
					x = (area.minX + area.maxX) / 2,
					z = (area.minZ + area.maxZ) / 2,
					width = area.maxX - area.minX + 2 * LaneConfig.barrierThickness,
					length = area.maxZ - area.minZ,
				}
				expect(overlap(outline, other)).toBe(false)
			end
		end
		for zone in WallConfig.materials do
			for _, part in ZoneLook.walks(LaneConfig, WallConfig, world.lane, zone) do
				expect(overlap(outline, part.area)).toBe(false)
			end
		end
		local walkWidth = ZoneLook.walkWidthAtThrowZone(LaneConfig, WallConfig, world.lane)
		for _, piece in ThrowZoneLayout.surroundings(LaneConfig, world.surroundings, walkWidth) do
			expect(overlap(outline, piece)).toBe(false)
		end
		expect(overlap(outline, ThrowZoneLayout.zone(LaneConfig))).toBe(false)
	end,

	["signs float above every lane, a little in front of the pad"] = function(expect)
		local sign = world.signs.training
		for laneIndex = 1, Training.laneCount(TrainingConfig) do
			local lanePad = TrainingLook.pad(TrainingConfig, laneIndex)
			local place = TrainingLook.sign(TrainingConfig, laneIndex, floorTopY, sign.heightAboveFloor, sign.forward)
			expect(place.x).toBe(lanePad.x)
			expect(place.z).toBeNear(front(lanePad) - sign.forward)
			-- Its lower end is above a player's head.
			expect(place.y - sign.heightStuds / 2 > floorTopY + 6).toBe(true)
		end
		expect(sign.pillHeight + sign.statusHeight + sign.effectHeight <= 1).toBe(true)
		local shop = world.signs.shop
		expect(shop.nameHeight + shop.bonusHeight + shop.pillHeight + shop.statusHeight <= 1).toBe(true)
		expect(string.format(sign.effectText, "4")).toBe("4x STRENGTH")
		expect(string.format(shop.bonusText, "25")).toBe("+25% STRENGTH")
	end,

	["every color of the theme, the signs and the pedestals is a real color"] = function(expect)
		for _, value in
			{
				straw.frame.darkColor,
				straw.frame.lightColor,
				straw.floor.darkColor,
				straw.floor.lightColor,
				straw.strip.color,
				straw.strip.stoneColor,
				straw.pad.darkColor,
				straw.pad.lightColor,
				straw.pieceColor,
				straw.tuftColor,
				training.padMark.color,
				world.signs.pill.color,
				world.shop.pedestal.darkColor,
				world.shop.pedestal.lightColor,
			}
		do
			expect(isColor(value)).toBe(true)
		end
	end,
}
