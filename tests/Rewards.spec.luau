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

	["the input values are not changed"] = function(expect)
		local values = { strength = 1, currency = 2, bestWall = 0 }
		Rewards.applyThrow(values, outcomeFor(100))
		expect(values.strength).toBe(1)
		expect(values.currency).toBe(2)
	end,
}
