local Rewards = require("../src/shared/Rules/Rewards")
local ThrowCalculation = require("../src/shared/Rules/ThrowCalculation")
local WallConfig = require("../src/shared/Config/Walls")
local StrengthConfig = require("../src/shared/Config/Strength")

local start = { strength = 100, currency = 5, bestWall = 3 }

local function outcomeFor(power: number)
	local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, power)
	return { currency = result.currency, strength = result.strength, wallsBroken = #result.brokenWalls }
end

return {
	["a throw adds its currency and strength"] = function(expect)
		local outcome = outcomeFor(100)
		local after = Rewards.applyThrow(start, outcome)
		expect(after.currency).toBeNear(start.currency + outcome.currency)
		expect(after.strength).toBeNear(start.strength + outcome.strength)
	end,

	["a further throw raises the best wall"] = function(expect)
		local after = Rewards.applyThrow(start, outcomeFor(100))
		expect(after.bestWall).toBe(6)
	end,

	["a shorter throw keeps the best wall"] = function(expect)
		local after = Rewards.applyThrow({ strength = 1, currency = 0, bestWall = 20 }, outcomeFor(100))
		expect(after.bestWall).toBe(20)
	end,

	["a throw that breaks nothing changes nothing"] = function(expect)
		local after = Rewards.applyThrow(start, outcomeFor(0))
		expect(after.strength).toBe(start.strength)
		expect(after.currency).toBe(start.currency)
		expect(after.bestWall).toBe(start.bestWall)
	end,

	["per wall: one entry per broken wall, adding up to the totals"] = function(expect)
		for _, power in { 0, 10, 100, 1000, 1e6, math.huge } do
			local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, power)
			local list = Rewards.perWall(WallConfig, StrengthConfig, result.brokenWalls, 1)
			expect(#list).toBe(#result.brokenWalls)
			local currency, strength = 0, 0
			for _, entry in list do
				currency += entry.currency + entry.zoneBonus
				strength += entry.strength
			end
			if #list > 0 then
				expect(currency).toBeNear(result.currency)
				expect(strength).toBeNear(result.strength)
			else
				expect(currency).toBe(0)
			end
		end
	end,

	["per wall: only the last wall of a zone carries the zone bonus"] = function(expect)
		local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, 1e6)
		local list = Rewards.perWall(WallConfig, StrengthConfig, result.brokenWalls, 1)
		for index, entry in list do
			if index % WallConfig.wallsPerZone == 0 then
				expect(entry.zoneBonus).toBeNear(entry.currency * WallConfig.zoneBonusFactor)
			else
				expect(entry.zoneBonus).toBe(0)
			end
		end
	end,

	["per wall: the strength multiplier multiplies strength, not currency"] = function(expect)
		local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, 1000)
		local plain = Rewards.total(Rewards.perWall(WallConfig, StrengthConfig, result.brokenWalls, 1))
		local tripled = Rewards.total(Rewards.perWall(WallConfig, StrengthConfig, result.brokenWalls, 3))
		expect(tripled.strength).toBeNear(plain.strength * 3)
		expect(tripled.currency).toBeNear(plain.currency)
		expect(tripled.wallsBroken).toBe(#result.brokenWalls)
	end,

	["total of no walls is nothing"] = function(expect)
		local total = Rewards.total({})
		expect(total.currency).toBe(0)
		expect(total.strength).toBe(0)
		expect(total.wallsBroken).toBe(0)
	end,

	["the input values are not changed"] = function(expect)
		local values = { strength = 1, currency = 2, bestWall = 0 }
		Rewards.applyThrow(values, outcomeFor(100))
		expect(values.strength).toBe(1)
		expect(values.currency).toBe(2)
	end,
}
