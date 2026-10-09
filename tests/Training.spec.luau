local Training = require("../src/shared/Rules/Training")
local TrainingConfig = require("../src/shared/Config/Training")

local pad = TrainingConfig.pad

return {
	["standing in the middle of the pad counts"] = function(expect)
		expect(Training.isOnPad(TrainingConfig, pad.x, pad.z)).toBe(true)
	end,

	["edge with tolerance counts, just outside does not"] = function(expect)
		local edge = pad.width / 2 + TrainingConfig.padTolerance
		expect(Training.isOnPad(TrainingConfig, pad.x + edge, pad.z)).toBe(true)
		expect(Training.isOnPad(TrainingConfig, pad.x + edge + 0.1, pad.z)).toBe(false)
		expect(Training.isOnPad(TrainingConfig, pad.x, pad.z - pad.length)).toBe(false)
	end,

	["the throw zone is not the training pad"] = function(expect)
		expect(Training.isOnPad(TrainingConfig, 0, 10)).toBe(false)
	end,

	["NaN position is not on the pad"] = function(expect)
		expect(Training.isOnPad(TrainingConfig, 0 / 0, pad.z)).toBe(false)
	end,

	["stepping on starts the clock, first throw one interval later"] = function(expect)
		local throws, nextAt = Training.tick(nil, true, 10, 1)
		expect(throws).toBe(false)
		expect(nextAt).toBe(11)
		throws, nextAt = Training.tick(nextAt, true, 10.5, 1)
		expect(throws).toBe(false)
		expect(nextAt).toBe(11)
		throws, nextAt = Training.tick(nextAt, true, 11.05, 1)
		expect(throws).toBe(true)
		expect(nextAt).toBe(12)
	end,

	["the rhythm stays steady"] = function(expect)
		local count = 0
		local nextAt: number? = nil
		local throws
		-- 10 seconds, checked every 0.1 s, interval 1 s: 9 throws (the first comes after 1 s).
		for i = 0, 99 do
			throws, nextAt = Training.tick(nextAt, true, i * 0.1 + 0.0001, 1)
			if throws then
				count += 1
			end
		end
		expect(count).toBe(9)
	end,

	["stepping off stops training and resets the clock"] = function(expect)
		local throws, nextAt = Training.tick(11, false, 11.5, 1)
		expect(throws).toBe(false)
		expect(nextAt).toBe(nil)
	end,

	["a blocked player does not train while on the pad"] = function(expect)
		expect(Training.isTraining(true, true)).toBe(false)
		expect(Training.isTraining(true, false)).toBe(true)
		expect(Training.isTraining(false, false)).toBe(false)
	end,

	["the block stays while on the pad and clears only after leaving it"] = function(expect)
		local blocked = true
		blocked = Training.updateBlock(blocked, true)
		expect(blocked).toBe(true)
		blocked = Training.updateBlock(blocked, false)
		expect(blocked).toBe(false)
		-- Stepping back on after leaving: not blocked, training can start again.
		blocked = Training.updateBlock(blocked, true)
		expect(blocked).toBe(false)
	end,

	["after a long lag there is one throw, not a burst"] = function(expect)
		local throws, nextAt = Training.tick(11, true, 20, 1)
		expect(throws).toBe(true)
		expect(nextAt).toBe(21)
		throws = Training.tick(nextAt, true, 20.1, 1)
		expect(throws).toBe(false)
	end,
}
