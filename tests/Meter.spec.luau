local Meter = require("../src/shared/Rules/Meter")
local MeterConfig = require("../src/shared/Config/Meter")

local swing = MeterConfig.swingSeconds

local function position(time: number, phase: number?): number
	return Meter.position(MeterConfig, 100, phase or 0, 100 + time)
end

local function timeToUse(pressTime: any, receiveTime: number): number?
	return Meter.timeToUse(MeterConfig, 100, pressTime, receiveTime)
end

return {
	["pointer starts at the bottom, reaches the top after half a swing"] = function(expect)
		expect(position(0)).toBeNear(-1)
		expect(math.abs(position(swing / 4)) < 1e-9).toBe(true)
		expect(position(swing / 2)).toBeNear(1)
		expect(position(swing)).toBeNear(-1)
	end,

	["pointer moves at even speed"] = function(expect)
		expect(position(swing / 8)).toBeNear(-0.5)
		expect(position(swing * 3 / 8)).toBeNear(0.5)
	end,

	["pointer always stays between the ends"] = function(expect)
		for i = 0, 200 do
			local p = position(i * 0.037, 0.3)
			expect(p >= -1 and p <= 1).toBe(true)
		end
	end,

	["start phase shifts the pointer"] = function(expect)
		expect(position(0, 0.5)).toBeNear(1)
		expect(math.abs(position(0, 0.25)) < 1e-9).toBe(true)
	end,

	["factor is highest in the middle and lowest at the ends"] = function(expect)
		expect(Meter.factor(MeterConfig, 0)).toBe(MeterConfig.maxFactor)
		expect(Meter.factor(MeterConfig, 1)).toBe(MeterConfig.minFactor)
		expect(Meter.factor(MeterConfig, -1)).toBe(MeterConfig.minFactor)
		expect(Meter.factor(MeterConfig, 0.5)).toBeNear(1)
	end,

	["factor never leaves the allowed range"] = function(expect)
		expect(Meter.factor(MeterConfig, 5)).toBe(MeterConfig.minFactor)
		expect(Meter.factor(MeterConfig, 0 / 0)).toBe(MeterConfig.minFactor)
	end,

	["a normal press counts as sent"] = function(expect)
		expect(timeToUse(101.2, 101.3)).toBe(101.2)
	end,

	["a press older than the allowed delay counts as the earliest allowed moment"] = function(expect)
		expect(timeToUse(101, 102)).toBeNear(102 - MeterConfig.maxDelaySeconds)
	end,

	["a press slightly in the future is allowed, but counts at arrival"] = function(expect)
		expect(timeToUse(101.05, 101)).toBe(101)
	end,

	["a press far in the future is impossible"] = function(expect)
		expect(timeToUse(105, 101)).toBe(nil)
	end,

	["a press before the start is impossible"] = function(expect)
		expect(timeToUse(99, 101)).toBe(nil)
	end,

	["a press just before the start (clock difference) counts at the start"] = function(expect)
		expect(timeToUse(99.95, 100.05)).toBe(100)
	end,

	["a press after the meter ran out is impossible"] = function(expect)
		local late = 100 + MeterConfig.timeoutSeconds + 1
		expect(timeToUse(late, late)).toBe(nil)
	end,

	["values that are not a real number are impossible"] = function(expect)
		expect(timeToUse("101", 101)).toBe(nil)
		expect(timeToUse(nil, 101)).toBe(nil)
		expect(timeToUse(0 / 0, 101)).toBe(nil)
		expect(timeToUse(math.huge, 101)).toBe(nil)
		expect(timeToUse({}, 101)).toBe(nil)
	end,
}
