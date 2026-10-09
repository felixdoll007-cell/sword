local ThrowCalculation = require("../src/shared/Rules/ThrowCalculation")
local Walls = require("../src/shared/Rules/Walls")
local WallConfig = require("../src/shared/Config/Walls")
local StrengthConfig = require("../src/shared/Config/Strength")

local function calculate(power: number)
	return ThrowCalculation.calculate(WallConfig, StrengthConfig, power)
end

-- Sum of the hardness of walls 1 to n, added in the same order as the calculation does.
local function powerNeededFor(n: number): number
	local sum = 0
	for index = 1, n do
		sum += (Walls.get(WallConfig, index) :: Walls.Wall).hardness
	end
	return sum
end

return {
	["zero power breaks nothing and bounces off wall 1"] = function(expect)
		local result = calculate(0)
		expect(#result.brokenWalls).toBe(0)
		expect((result.bounceWall :: Walls.Wall).index).toBe(1)
		expect(result.currency).toBe(0)
		expect(result.strength).toBe(0)
	end,

	["negative and NaN power break nothing"] = function(expect)
		expect(#calculate(-100).brokenWalls).toBe(0)
		expect(#calculate(0 / 0).brokenWalls).toBe(0)
		expect((calculate(0 / 0).bounceWall :: Walls.Wall).index).toBe(1)
	end,

	["just below the hardness of wall 1 breaks nothing"] = function(expect)
		expect(#calculate(4.99).brokenWalls).toBe(0)
	end,

	["exactly enough power breaks the wall"] = function(expect)
		for n = 1, 30 do
			expect(#calculate(powerNeededFor(n)).brokenWalls).toBe(n)
		end
	end,

	["power is used up wall by wall"] = function(expect)
		-- Wall 1 costs 5, wall 2 costs 6.5: 10 power is enough for wall 1 only.
		local result = calculate(10)
		expect(#result.brokenWalls).toBe(1)
		expect((result.bounceWall :: Walls.Wall).index).toBe(2)
	end,

	["start strength 10 breaks the first wall"] = function(expect)
		expect(#calculate(StrengthConfig.startStrength).brokenWalls >= 1).toBe(true)
	end,

	["reward is the sum of the broken walls"] = function(expect)
		local result = calculate(powerNeededFor(3))
		local expected = 0
		for index = 1, 3 do
			expected += (Walls.get(WallConfig, index) :: Walls.Wall).reward
		end
		expect(result.currency).toBeNear(expected)
		expect(#result.completedZones).toBe(0)
	end,

	["a full zone adds the zone bonus"] = function(expect)
		local result = calculate(powerNeededFor(5))
		local wallRewards = 0
		for index = 1, 5 do
			wallRewards += (Walls.get(WallConfig, index) :: Walls.Wall).reward
		end
		local lastWall = Walls.get(WallConfig, 5) :: Walls.Wall
		expect(#result.completedZones).toBe(1)
		expect(result.completedZones[1]).toBe(1)
		expect(result.currency).toBeNear(wallRewards + lastWall.reward * 2)
	end,

	["strength is 0.1 per broken wall"] = function(expect)
		expect(calculate(powerNeededFor(10)).strength).toBeNear(1)
	end,

	["huge power breaks all 30 walls and does not bounce"] = function(expect)
		for _, power in { 1e15, 1e30, 1e300, math.huge } do
			local result = calculate(power)
			expect(#result.brokenWalls).toBe(30)
			expect(result.bounceWall).toBe(nil)
			expect(#result.completedZones).toBe(6)
			expect(result.currency < math.huge).toBe(true)
		end
	end,
}
