local Decor = require("../src/shared/Rules/Decor")
local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")
local Ui = require("../src/shared/Config/Ui")

local world = Ui.world
local look = world.lane
local models = world.decor.models
local PAPER = 1
local paperDecor = look.zones.Paper.decor

local function placements(): { Decor.Placement }
	return Decor.placements(LaneConfig, WallConfig, look, paperDecor, models, PAPER)
end

-- Turns a flat direction the way CFrame.Angles(0, yaw, 0) does.
local function turn(x: number, z: number, yawDegrees: number): (number, number)
	local yaw = math.rad(yawDegrees)
	return x * math.cos(yaw) + z * math.sin(yaw), -x * math.sin(yaw) + z * math.cos(yaw)
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	["decoration stands on both walkways, the same number on each"] = function(expect)
		local leftCount, rightCount = 0, 0
		for _, placement in placements() do
			if placement.side < 0 then
				leftCount += 1
			else
				rightCount += 1
			end
		end
		expect(leftCount > 0).toBe(true)
		expect(leftCount).toBe(rightCount)
	end,

	["every piece stands on a walkway of the paper zone, not on its edge and not on the lane"] = function(expect)
		local walks = {}
		for _, part in ZoneLook.walks(LaneConfig, WallConfig, look, PAPER) do
			if part.kind == "walk" then
				table.insert(walks, part)
			end
		end
		for _, placement in placements() do
			local onWalk = false
			for _, walk in walks do
				local area = walk.area
				local inside = placement.x > area.x - area.width / 2
					and placement.x < area.x + area.width / 2
					and placement.z > area.z - area.length / 2
					and placement.z < area.z + area.length / 2
				if inside then
					onWalk = true
					expect(placement.y).toBeNear(walk.topY)
				end
			end
			expect(onWalk).toBe(true)
			expect(math.abs(placement.x - LaneConfig.throwLine.x) > LaneConfig.laneWidth / 2).toBe(true)
		end
	end,

	["pieces stand in a row with the same distance between them"] = function(expect)
		local _, to = ZoneLook.range(LaneConfig, WallConfig, PAPER)
		local distances = Decor.distances(paperDecor, to)
		expect(distances[1]).toBe(paperDecor.firstDistance)
		for index = 2, #distances do
			expect(distances[index] - distances[index - 1]).toBeNear(paperDecor.spacing)
		end
		-- The same room is left at the end of the zone as at its start.
		expect(distances[#distances] <= to - paperDecor.firstDistance + 1e-6).toBe(true)
		expect(distances[#distances] + paperDecor.spacing > to - paperDecor.firstDistance).toBe(true)
		-- Both sides use the same distances.
		local byZ = {}
		for _, placement in placements() do
			byZ[placement.z] = (byZ[placement.z] or 0) + 1
		end
		for _, count in byZ do
			expect(count).toBe(2)
		end
	end,

	["the models alternate in the configured order, shifted on the right side"] = function(expect)
		local order = paperDecor.order
		local bySide: { [number]: { Decor.Placement } } = { [-1] = {}, [1] = {} }
		for _, placement in placements() do
			table.insert(bySide[placement.side], placement)
		end
		for index, placement in bySide[-1] do
			expect(placement.model).toBe(order[(index - 1) % #order + 1])
		end
		for index, placement in bySide[1] do
			expect(placement.model).toBe(order[(index - 1 + paperDecor.sideShift) % #order + 1])
		end
		-- Across the lane two different pieces face each other.
		for index, placement in bySide[-1] do
			expect(placement.model ~= bySide[1][index].model).toBe(true)
		end
		-- Every model of the order is used.
		local used = {}
		for _, placement in placements() do
			used[placement.model] = true
		end
		for _, model in order do
			expect(used[model]).toBe(true)
		end
	end,

	["every piece is turned so that its front looks at the lane"] = function(expect)
		for _, placement in placements() do
			local front = models[placement.model].front
			local x, z = turn(front.x, front.z, placement.yawDegrees)
			-- Left of the lane the lane lies towards positive X, right of it towards negative X.
			expect(near(x, -placement.side)).toBe(true)
			expect(near(z, 0)).toBe(true)
			expect(placement.yawDegrees >= -180 and placement.yawDegrees <= 180).toBe(true)
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
				local half = { front = front, turnTowardsThrowZoneDegrees = 45 }
				local halfX, halfZ = turn(front.x, front.z, Decor.yawDegrees(half, side))
				expect(near(halfX, -side * math.sqrt(0.5))).toBe(true)
				expect(near(halfZ, math.sqrt(0.5))).toBe(true)
			end
		end
	end,

	["zones without walkways or without decoration have none"] = function(expect)
		expect(#Decor.placements(LaneConfig, WallConfig, look, paperDecor, models, 2)).toBe(0)
		expect(#Decor.placements(LaneConfig, WallConfig, look, nil, models, PAPER)).toBe(0)
		local empty = table.clone(paperDecor)
		empty.order = {}
		expect(#Decor.placements(LaneConfig, WallConfig, look, empty, models, PAPER)).toBe(0)
		-- A model the game does not know is left out, the others still stand.
		local odd = table.clone(paperDecor)
		odd.order = { "paper_lantern", "garden_gnome" }
		for _, placement in Decor.placements(LaneConfig, WallConfig, look, odd, models, PAPER) do
			expect(placement.model).toBe("paper_lantern")
		end
	end,

	["broken spacing does not hang the game"] = function(expect)
		local broken = table.clone(paperDecor)
		broken.spacing = 0
		expect(#Decor.distances(broken, 110)).toBe(0)
		broken.spacing = -5
		expect(#Decor.distances(broken, 110)).toBe(0)
		broken.spacing = 0 / 0
		expect(#Decor.distances(broken, 110)).toBe(0)
		-- A zone too short for even one piece has none.
		expect(#Decor.distances(paperDecor, paperDecor.firstDistance)).toBe(0)
	end,

	["the amount of decoration stays small"] = function(expect)
		-- Each piece is four or five meshes. Keep it light for phones.
		expect(#placements() <= 24).toBe(true)
	end,

	["every model in the order is known, and movements have sensible values"] = function(expect)
		for _, name in paperDecor.order do
			expect(typeof(models[name])).toBe("table")
		end
		for _, model in models :: { [string]: any } do
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
		end
	end,
}
