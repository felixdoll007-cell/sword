local Training = require("../src/shared/Rules/Training")
local TrainingConfig = require("../src/shared/Config/Training")

local pad = TrainingConfig.pad

return {
	["there are four lanes with the planned requirements and multipliers"] = function(expect)
		expect(Training.laneCount(TrainingConfig)).toBe(4)
		local required = { 0, 2, 4, 6 }
		local multipliers = { 1, 4, 10, 20 }
		for index, lane in TrainingConfig.lanes do
			expect(lane.unlock.kind).toBe("Rebirths")
			expect(lane.unlock.rebirths).toBe(required[index])
			expect(lane.multiplier).toBe(multipliers[index])
		end
	end,

	["higher lanes have more walls"] = function(expect)
		for index = 2, #TrainingConfig.lanes do
			expect(TrainingConfig.lanes[index].walls > TrainingConfig.lanes[index - 1].walls).toBe(true)
		end
	end,

	["lane 1 uses the configured pad, further lanes lie to the left without overlapping"] = function(expect)
		local first = Training.lanePad(TrainingConfig, 1) :: Training.Pad
		expect(first.x).toBe(pad.x)
		expect(first.z).toBe(pad.z)
		for index = 2, 4 do
			local previous = Training.lanePad(TrainingConfig, index - 1) :: Training.Pad
			local current = Training.lanePad(TrainingConfig, index) :: Training.Pad
			local gap = (previous.x - previous.width / 2) - (current.x + current.width / 2)
			-- Room between two pads, also with the position tolerance on both sides.
			expect(gap > 2 * TrainingConfig.padTolerance).toBe(true)
		end
		expect(Training.lanePad(TrainingConfig, 5)).toBe(nil)
		expect(Training.lanePad(TrainingConfig, 0)).toBe(nil)
	end,

	["standing in the middle of each pad gives that lane"] = function(expect)
		for index = 1, 4 do
			local lanePad = Training.lanePad(TrainingConfig, index) :: Training.Pad
			expect(Training.laneAt(TrainingConfig, lanePad.x, lanePad.z)).toBe(index)
		end
	end,

	["edge with tolerance counts, just outside does not"] = function(expect)
		local edge = pad.width / 2 + TrainingConfig.padTolerance
		expect(Training.laneAt(TrainingConfig, pad.x + edge, pad.z)).toBe(1)
		expect(Training.laneAt(TrainingConfig, pad.x + edge + 0.1, pad.z)).toBe(nil)
		expect(Training.laneAt(TrainingConfig, pad.x, pad.z - pad.length)).toBe(nil)
	end,

	["between two pads, in the throw zone and at NaN there is no lane"] = function(expect)
		expect(Training.laneAt(TrainingConfig, pad.x - TrainingConfig.laneSpacing / 2, pad.z)).toBe(nil)
		expect(Training.laneAt(TrainingConfig, 0, 10)).toBe(nil)
		expect(Training.laneAt(TrainingConfig, 0 / 0, pad.z)).toBe(nil)
	end,

	["lanes unlock exactly at their required rebirths"] = function(expect)
		expect(Training.isUnlocked(TrainingConfig, 1, { rebirths = 0 })).toBe(true)
		expect(Training.isUnlocked(TrainingConfig, 2, { rebirths = 1 })).toBe(false)
		expect(Training.isUnlocked(TrainingConfig, 2, { rebirths = 2 })).toBe(true)
		expect(Training.isUnlocked(TrainingConfig, 3, { rebirths = 3 })).toBe(false)
		expect(Training.isUnlocked(TrainingConfig, 3, { rebirths = 4 })).toBe(true)
		expect(Training.isUnlocked(TrainingConfig, 4, { rebirths = 5 })).toBe(false)
		expect(Training.isUnlocked(TrainingConfig, 4, { rebirths = 6 })).toBe(true)
		expect(Training.isUnlocked(TrainingConfig, 4, { rebirths = 100 })).toBe(true)
		expect(Training.isUnlocked(TrainingConfig, 5, { rebirths = 100 })).toBe(false)
		expect(Training.isUnlocked(TrainingConfig, 2, { rebirths = 0 / 0 })).toBe(false)
	end,

	["a lane with an unlock kind the game does not know stays locked for everyone"] = function(expect)
		local config = table.clone(TrainingConfig)
		config.lanes = table.clone(TrainingConfig.lanes)
		table.insert(config.lanes, { unlock = { kind = "Purchase" }, multiplier = 50, walls = 5 })
		local newLane = #config.lanes
		expect(Training.isUnlocked(config, newLane, { rebirths = 0 })).toBe(false)
		expect(Training.isUnlocked(config, newLane, { rebirths = 1000 })).toBe(false)
		-- The lanes before it are not affected.
		expect(Training.isUnlocked(config, 1, { rebirths = 0 })).toBe(true)
	end,

	["a lane added in the config gets its own place to the left of the others"] = function(expect)
		local config = table.clone(TrainingConfig)
		config.lanes = table.clone(TrainingConfig.lanes)
		table.insert(config.lanes, { unlock = { kind = "Rebirths", rebirths = 8 }, multiplier = 40, walls = 5 })
		local newLane = #config.lanes
		local newPad = Training.lanePad(config, newLane) :: Training.Pad
		local previousPad = Training.lanePad(config, newLane - 1) :: Training.Pad
		expect(previousPad.x - newPad.x).toBe(config.laneSpacing)
		expect(Training.laneAt(config, newPad.x, newPad.z)).toBe(newLane)
		expect(Training.isUnlocked(config, newLane, { rebirths = 8 })).toBe(true)
		expect(Training.isUnlocked(config, newLane, { rebirths = 7 })).toBe(false)
	end,

	["standing on a locked pad is not training"] = function(expect)
		local second = Training.lanePad(TrainingConfig, 2) :: Training.Pad
		expect(Training.trainingLane(TrainingConfig, second.x, second.z, { rebirths = 1 })).toBe(nil)
		expect(Training.trainingLane(TrainingConfig, second.x, second.z, { rebirths = 2 })).toBe(2)
		expect(Training.trainingLane(TrainingConfig, pad.x, pad.z, { rebirths = 0 })).toBe(1)
		expect(Training.trainingLane(TrainingConfig, 0, 10, { rebirths = 50 })).toBe(nil)
	end,

	["walls of a lane stand one spacing apart and fit on the lane floor"] = function(expect)
		expect(Training.wallOffset(TrainingConfig, 1)).toBe(TrainingConfig.wallDistance)
		expect(Training.wallOffset(TrainingConfig, 2) - Training.wallOffset(TrainingConfig, 1)).toBe(
			TrainingConfig.wallSpacing
		)
		for _, lane in TrainingConfig.lanes do
			expect(Training.wallOffset(TrainingConfig, lane.walls) < TrainingConfig.laneLength).toBe(true)
		end
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
