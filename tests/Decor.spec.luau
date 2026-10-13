local Decor = require("../src/shared/Rules/Decor")
local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")
local Ui = require("../src/shared/Config/Ui")

local world = Ui.world
local look = world.lane
local models = world.decor.models
local limits = world.decor
local PAPER = 1
local BAMBOO = 2
-- The first zone without a look.
local WOOD = 3
local bambooDecor = look.zones.Bamboo.decor
local BAMBOO_GROUP = "bamboo_cluster"
local STONE_LANTERN = "stone_lantern"
local paperDecor = look.zones.Paper.decor
local TREE = "cherry_tree"
local LANTERN = "paper_lantern"

local function place(decor: any, zone: number?): { Decor.Placement }
	return Decor.placements(LaneConfig, WallConfig, look, decor, models, limits, zone or PAPER)
end

local function placements(): { Decor.Placement }
	return place(paperDecor)
end

local function bambooPlacements(): { Decor.Placement }
	return place(bambooDecor, BAMBOO)
end

local function outerStep(side: number): ZoneLook.WalkPart
	for _, part in ZoneLook.walks(LaneConfig, WallConfig, look, PAPER) do
		if part.kind == "outer" and part.side == side then
			return part
		end
	end
	error("no outer step")
end

-- Turns a flat direction the way CFrame.Angles(0, yaw, 0) does.
local function turn(x: number, z: number, yawDegrees: number): (number, number)
	local yaw = math.rad(yawDegrees)
	return x * math.cos(yaw) + z * math.sin(yaw), -x * math.sin(yaw) + z * math.cos(yaw)
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- Distance of a piece from the lane's edge.
local function fromLane(placement: Decor.Placement): number
	return math.abs(placement.x - LaneConfig.throwLine.x) - LaneConfig.laneWidth / 2
end

return {
	["every listed piece is placed, and there are at most twelve"] = function(expect)
		expect(#placements()).toBe(#paperDecor.pieces)
		expect(#placements() <= 12).toBe(true)
		expect(limits.maxPiecesPerZone <= 12).toBe(true)
	end,

	["every piece stands on the outer, higher step and inside the zone"] = function(expect)
		local _, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		for _, placement in placements() do
			local step = outerStep(placement.side)
			local area = step.area
			expect(placement.x >= area.x - area.width / 2 and placement.x <= area.x + area.width / 2).toBe(true)
			expect(placement.z <= LaneConfig.throwLine.z and placement.z >= LaneConfig.throwLine.z - to).toBe(true)
			expect(placement.y).toBeNear(step.topY)
			-- Well away from the lane: beyond the edge and the whole inner step.
			expect(fromLane(placement) >= look.walk.curbWidth + look.walk.innerWidth).toBe(true)
		end
	end,

	["a lantern stands on each side at the start of the zone, like a gate"] = function(expect)
		local all = placements()
		local first: { [number]: Decor.Placement } = {}
		for _, placement in all do
			local current = first[placement.side]
			if not current or placement.z > current.z then
				first[placement.side] = placement
			end
		end
		expect(first[-1].model).toBe(LANTERN)
		expect(first[1].model).toBe(LANTERN)
		-- Opposite each other, the same distance from the lane.
		expect(first[-1].z).toBe(first[1].z)
		expect(fromLane(first[-1])).toBeNear(fromLane(first[1]))
		-- Near the throw line.
		expect(LaneConfig.throwLine.z - first[-1].z <= 10).toBe(true)
	end,

	["after the gate each side has at most three more pieces, mixed, not counting trees"] = function(expect)
		for _, side in { -1, 1 } do
			local others = {}
			local kinds = {}
			for _, placement in placements() do
				if placement.side == side and placement.model ~= TREE then
					table.insert(others, placement)
					kinds[placement.model] = true
				end
			end
			-- The gate lantern plus at most three.
			expect(#others <= 4).toBe(true)
			local kindCount = 0
			for _ in kinds do
				kindCount += 1
			end
			expect(kindCount >= 3).toBe(true)
		end
	end,

	["the pieces are not lined up: uneven distances along the zone and from the lane"] = function(expect)
		for _, side in { -1, 1 } do
			local along = {}
			local across = {}
			for _, placement in placements() do
				if placement.side == side and placement.model ~= TREE then
					table.insert(along, LaneConfig.throwLine.z - placement.z)
					across[fromLane(placement)] = true
				end
			end
			table.sort(along)
			local gaps = {}
			for index = 2, #along do
				gaps[math.round(along[index] - along[index - 1])] = true
			end
			local differentGaps, differentAcross = 0, 0
			for _ in gaps do
				differentGaps += 1
			end
			for _ in across do
				differentAcross += 1
			end
			-- No two gaps along the zone are the same, and not all pieces keep the same distance to the lane.
			expect(differentGaps).toBe(#along - 1)
			expect(differentAcross >= 2).toBe(true)
		end
	end,

	["the two sides are not mirror images"] = function(expect)
		local bySide: { [number]: { [string]: boolean } } = { [-1] = {}, [1] = {} }
		for _, placement in placements() do
			-- The gate is the one pair that is meant to match.
			if LaneConfig.throwLine.z - placement.z > 10 then
				bySide[placement.side][`{placement.model}@{math.round(placement.z)}`] = true
			end
		end
		for key in bySide[-1] do
			expect(bySide[1][key]).toBe(nil)
		end
	end,

	["two or three trees stand at the very outside, behind the other pieces"] = function(expect)
		local trees = 0
		for _, tree in placements() do
			if tree.model == TREE then
				trees += 1
				for _, other in placements() do
					if other.model ~= TREE and other.side == tree.side then
						expect(fromLane(tree) > fromLane(other)).toBe(true)
					end
				end
				-- In the outer half of the outer step.
				local step = outerStep(tree.side)
				expect(fromLane(tree) >= ZoneLook.walkWidth(look) - step.area.width / 2).toBe(true)
			end
		end
		expect(trees >= 2 and trees <= 3).toBe(true)
	end,

	["every piece is turned a little differently"] = function(expect)
		local seen = {}
		for _, piece in paperDecor.pieces do
			expect(piece.turnDegrees ~= 0).toBe(true)
			expect(seen[piece.turnDegrees]).toBe(nil)
			seen[piece.turnDegrees] = true
		end
		-- The turn is added to looking straight at the lane.
		for index, placement in placements() do
			local piece = paperDecor.pieces[index]
			local straight = Decor.yawDegrees(models[piece.model], placement.side)
			local difference = (placement.yawDegrees - straight - piece.turnDegrees + 180) % 360 - 180
			expect(near(difference, 0)).toBe(true)
			expect(placement.yawDegrees >= -180 and placement.yawDegrees <= 180).toBe(true)
		end
	end,

	["without a turn of its own a piece looks straight at the lane"] = function(expect)
		for _, model in { LANTERN, "origami_crane", "paper_pinwheel", TREE } do
			for _, sideName in { "left", "right" } do
				local list = place({ pieces = { { model = model, side = sideName, along = 20, across = 0.5 } } })
				expect(#list).toBe(1)
				local front = models[model].front
				local x, z = turn(front.x, front.z, list[1].yawDegrees)
				-- Left of the lane the lane lies towards positive X, right of it towards negative X.
				expect(near(x, -list[1].side)).toBe(true)
				expect(near(z, 0)).toBe(true)
				expect(list[1].scale).toBe(1)
			end
		end
	end,

	["a model can be turned towards the throw zone, mirrored on both sides"] = function(expect)
		for _, front in { { x = -1, z = 0 }, { x = 0, z = -1 }, { x = 1, z = 0 }, { x = 0, z = 1 } } do
			for _, side in { -1, 1 } do
				local facing = { front = front, turnTowardsThrowZoneDegrees = 90 }
				local x, z = turn(front.x, front.z, Decor.yawDegrees(facing, side))
				-- The throw zone lies towards positive Z.
				expect(near(x, 0)).toBe(true)
				expect(near(z, 1)).toBe(true)
			end
		end
	end,

	["sizes stay within 15 percent of the modelled size"] = function(expect)
		expect(limits.maxScaleChange <= 0.15).toBe(true)
		for _, placement in placements() do
			expect(placement.scale >= 0.85 - 1e-9 and placement.scale <= 1.15 + 1e-9).toBe(true)
		end
		expect(Decor.scale(limits, 3)).toBeNear(1 + limits.maxScaleChange)
		expect(Decor.scale(limits, 0.1)).toBeNear(1 - limits.maxScaleChange)
		expect(Decor.scale(limits, -2)).toBeNear(1 - limits.maxScaleChange)
		expect(Decor.scale(limits, 1.05)).toBeNear(1.05)
		expect(Decor.scale(limits, nil)).toBe(1)
		expect(Decor.scale(limits, 0 / 0)).toBe(1)
		expect(Decor.scale(limits, math.huge)).toBe(1)
	end,

	["where across the outer step a piece stands follows its entry, and stays on the step"] = function(expect)
		local function at(across: number): number
			return fromLane(place({ pieces = { { model = LANTERN, side = "left", along = 20, across = across } } })[1])
		end
		local inner = look.walk.curbWidth + look.walk.innerWidth
		expect(at(0)).toBeNear(inner)
		expect(at(1)).toBeNear(inner + look.walk.outerWidth)
		expect(at(0.5)).toBeNear(inner + look.walk.outerWidth / 2)
		expect(at(-4)).toBeNear(inner)
		expect(at(9)).toBeNear(inner + look.walk.outerWidth)
	end,

	["broken entries are left out, the others still stand"] = function(expect)
		local list = place({
			pieces = {
				{ model = "garden_gnome", side = "left", along = 20, across = 0.5 },
				{ model = LANTERN, side = "middle", along = 20, across = 0.5 },
				{ model = LANTERN, side = "left", along = -3, across = 0.5 },
				{ model = LANTERN, side = "left", along = 5000, across = 0.5 },
				{ model = LANTERN, side = "left", along = 0 / 0, across = 0.5 },
				{ model = LANTERN, side = "left", along = 20, across = 0 / 0 },
				{ model = LANTERN, side = "right", along = 20, across = 0.5 },
			},
		})
		expect(#list).toBe(1)
		expect(list[1].side).toBe(1)
	end,

	["a zone never shows more pieces than the limit"] = function(expect)
		local many = { pieces = {} }
		for index = 1, 40 do
			table.insert(many.pieces, { model = LANTERN, side = "left", along = index * 2, across = 0.5 })
		end
		expect(#place(many)).toBe(limits.maxPiecesPerZone)
	end,

	["zones without walkways or without decoration have none"] = function(expect)
		expect(#place(paperDecor, WOOD)).toBe(0)
		expect(#place(nil)).toBe(0)
		expect(#place({ pieces = {} })).toBe(0)
	end,

	["the bamboo zone: at most twelve pieces, all on the outer step inside the zone"] = function(expect)
		local all = bambooPlacements()
		expect(#all).toBe(#bambooDecor.pieces)
		expect(#all <= 12).toBe(true)
		local from, to = ZoneLook.range(LaneConfig, WallConfig, BAMBOO)
		for _, placement in all do
			expect(placement.z <= LaneConfig.throwLine.z - from and placement.z >= LaneConfig.throwLine.z - to).toBe(
				true
			)
			expect(fromLane(placement) >= look.walk.curbWidth + look.walk.innerWidth).toBe(true)
			expect(fromLane(placement) <= ZoneLook.walkWidth(look)).toBe(true)
			expect(placement.y).toBeNear(LaneConfig.floorTopY + look.walk.outerHeight)
		end
	end,

	["the bamboo zone: a stone lantern on each side at its start, like a gate"] = function(expect)
		local from = ZoneLook.range(LaneConfig, WallConfig, BAMBOO)
		local first: { [number]: Decor.Placement } = {}
		for _, placement in bambooPlacements() do
			local current = first[placement.side]
			if not current or placement.z > current.z then
				first[placement.side] = placement
			end
		end
		expect(first[-1].model).toBe(STONE_LANTERN)
		expect(first[1].model).toBe(STONE_LANTERN)
		expect(first[-1].z).toBe(first[1].z)
		expect(fromLane(first[-1])).toBeNear(fromLane(first[1]))
		expect(LaneConfig.throwLine.z - from - first[-1].z <= 10).toBe(true)
	end,

	["the bamboo zone: three or four bamboo groups at the very outside, turned differently"] = function(expect)
		local groups = 0
		local turns = {}
		for index, placement in bambooPlacements() do
			if placement.model == BAMBOO_GROUP then
				groups += 1
				local turned = bambooDecor.pieces[index].turnDegrees
				expect(turns[turned]).toBe(nil)
				turns[turned] = true
				for _, other in bambooPlacements() do
					if other.model ~= BAMBOO_GROUP and other.side == placement.side then
						expect(fromLane(placement) > fromLane(other)).toBe(true)
					end
				end
				-- At most 20 percent bigger than modelled.
				expect(placement.scale <= 1.2 + 1e-9 and placement.scale >= 0.8 - 1e-9).toBe(true)
			else
				expect(placement.scale >= 0.85 - 1e-9 and placement.scale <= 1.15 + 1e-9).toBe(true)
			end
		end
		expect(groups >= 3 and groups <= 4).toBe(true)
	end,

	["the bamboo zone: a drum, one or two water features and one more lantern, sides not mirrored"] = function(expect)
		local counts: { [string]: number } = {}
		local bySide: { [number]: { [string]: boolean } } = { [-1] = {}, [1] = {} }
		local from = ZoneLook.range(LaneConfig, WallConfig, BAMBOO)
		for _, placement in bambooPlacements() do
			counts[placement.model] = (counts[placement.model] or 0) + 1
			-- The gate is the one pair that is meant to match.
			if LaneConfig.throwLine.z - from - placement.z > 10 then
				bySide[placement.side][`{placement.model}@{math.round(placement.z)}`] = true
			end
		end
		expect(counts.taiko_drum).toBe(1)
		expect(counts.shishi_odoshi >= 1 and counts.shishi_odoshi <= 2).toBe(true)
		expect(counts[STONE_LANTERN]).toBe(3)
		for key in bySide[-1] do
			expect(bySide[1][key]).toBe(nil)
		end
		-- Uneven distances along the zone on each side.
		for _, side in { -1, 1 } do
			local along = {}
			for _, placement in bambooPlacements() do
				if placement.side == side then
					table.insert(along, -placement.z)
				end
			end
			table.sort(along)
			local gaps = {}
			for index = 2, #along do
				local gap = math.round(along[index] - along[index - 1])
				expect(gaps[gap]).toBe(nil)
				gaps[gap] = true
			end
		end
	end,

	["a model with its own size limit may differ more than the others"] = function(expect)
		expect(models[BAMBOO_GROUP].maxScaleChange).toBe(0.2)
		expect(Decor.scale(limits, 1.2, 0.2)).toBeNear(1.2)
		expect(Decor.scale(limits, 3, 0.2)).toBeNear(1.2)
		expect(Decor.scale(limits, 0.1, 0.2)).toBeNear(0.8)
		expect(Decor.scale(limits, 1.2, nil)).toBeNear(1 + limits.maxScaleChange)
		expect(Decor.scale(limits, 1.2, 0 / 0)).toBeNear(1 + limits.maxScaleChange)
		expect(Decor.scale(limits, 1.2, -1)).toBe(1)
	end,

	["a tipping part goes down slowly, stays down briefly, comes back and then rests"] = function(expect)
		local tip = { everySeconds = 10, downSeconds = 2, holdSeconds = 1, backSeconds = 1 }
		expect(Decor.tipProgress(tip, 0)).toBe(0)
		expect(Decor.tipProgress(tip, 1)).toBeNear(0.5)
		expect(Decor.tipProgress(tip, 2)).toBe(1)
		expect(Decor.tipProgress(tip, 2.5)).toBe(1)
		expect(Decor.tipProgress(tip, 3.5)).toBeNear(0.5)
		expect(Decor.tipProgress(tip, 4)).toBe(0)
		expect(Decor.tipProgress(tip, 7)).toBe(0)
		-- Again every ten seconds.
		expect(Decor.tipProgress(tip, 11)).toBeNear(0.5)
		expect(Decor.tipProgress(tip, 1e9 + 2)).toBe(1)
		-- Never outside 0 to 1, soft at the start.
		local before = 0
		for step = 0, 200 do
			local value = Decor.tipProgress(tip, step / 100)
			expect(value >= before and value <= 1).toBe(true)
			before = value
		end
		expect(Decor.tipProgress(tip, 0.1) < 0.05).toBe(true)
		-- Broken values: it rests.
		expect(Decor.tipProgress(tip, 0 / 0)).toBe(0)
		expect(Decor.tipProgress(tip, math.huge)).toBe(0)
		expect(Decor.tipProgress({ everySeconds = 0, downSeconds = 1, holdSeconds = 1, backSeconds = 1 }, 3)).toBe(0)
		local instant = { everySeconds = 5, downSeconds = 0, holdSeconds = 1, backSeconds = 0 }
		expect(Decor.tipProgress(instant, 0.5)).toBe(1)
		expect(Decor.tipProgress(instant, 2)).toBe(0)
	end,

	["every model in the list is known, and movements have sensible values"] = function(expect)
		for _, decor in { paperDecor, bambooDecor } do
			for _, piece in decor.pieces do
				expect(typeof(models[piece.model])).toBe("table")
				expect(piece.side == "left" or piece.side == "right").toBe(true)
			end
		end
		for _, model in models :: { [string]: any } do
			if model.sway then
				-- Very slight and slow.
				expect(#model.sway.part > 0).toBe(true)
				expect(model.sway.degrees > 0 and model.sway.degrees <= 3).toBe(true)
				expect(model.sway.seconds >= 2).toBe(true)
			end
			if model.tip then
				local tip = model.tip
				expect(#tip.part > 0).toBe(true)
				expect(tip.degrees > 0 and tip.degrees <= 30).toBe(true)
				-- Every few seconds, slowly down, briefly down, and a rest in between.
				expect(tip.everySeconds >= 3 and tip.everySeconds <= 15).toBe(true)
				expect(tip.downSeconds >= 1).toBe(true)
				expect(tip.holdSeconds > 0 and tip.holdSeconds <= 1).toBe(true)
				expect(tip.downSeconds + tip.holdSeconds + tip.backSeconds < tip.everySeconds).toBe(true)
			end
		end
		for name, model in models :: { [string]: any } do
			expect(#model.template > 0).toBe(true)
			expect(math.abs(model.front.x) + math.abs(model.front.z) > 0).toBe(true)
			if model.light then
				expect(model.light.brightness > 0 and model.light.brightness <= 2).toBe(true)
				expect(model.light.range > 0 and model.light.range <= 20).toBe(true)
				expect(model.light.flickerStrength >= 0 and model.light.flickerStrength < 0.5).toBe(true)
			end
			if model.float then
				expect(model.float.seconds > 0).toBe(true)
				expect(model.float.heightStuds > 0 and model.float.heightStuds <= 1).toBe(true)
			end
			if model.spin then
				expect(model.spin.secondsPerTurn > 0).toBe(true)
				expect(#model.spin.parts > 0).toBe(true)
			end
			-- The tree stands still.
			if name == TREE then
				expect(model.light == nil and model.float == nil and model.spin == nil).toBe(true)
			end
		end
	end,
}
