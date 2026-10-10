-- Checks that the numbers in the config files still fit together.
-- If one of these fails after changing a config value, the other value needs to follow.
local Rebirth = require("../src/shared/Rules/Rebirth")
local Training = require("../src/shared/Rules/Training")
local RebirthConfig = require("../src/shared/Config/Rebirth")
local StrengthConfig = require("../src/shared/Config/Strength")
local TrainingConfig = require("../src/shared/Config/Training")

-- Planned pure training time per run in minutes, for rebirth 1 to 10 (docs/GAME_DESIGN.md).
local TARGET_MINUTES = { 3, 3, 3.5, 4, 4.5, 5, 6, 7, 8.5, 10 }
local ALLOWED_DIFFERENCE_MINUTES = 0.25

-- Strength per second on the best lane a player with this many rebirths can use.
local function bestStrengthPerSecond(rebirths: number): number
	local bestLaneMultiplier = 0
	for index, lane in TrainingConfig.lanes do
		if Training.isUnlocked(TrainingConfig, index, rebirths) then
			bestLaneMultiplier = math.max(bestLaneMultiplier, lane.multiplier)
		end
	end
	local perThrow = StrengthConfig.trainingStrengthPerThrow
		* bestLaneMultiplier
		* Rebirth.multiplier(RebirthConfig, rebirths)
	return perThrow / StrengthConfig.trainingSecondsPerThrow
end

local function runMinutes(rebirths: number): number
	local needed = Rebirth.threshold(RebirthConfig, rebirths) - StrengthConfig.startStrength
	return needed / bestStrengthPerSecond(rebirths) / 60
end

return {
	["rebirth thresholds match the planned training time per run"] = function(expect)
		for number, target in TARGET_MINUTES do
			local minutes = runMinutes(number - 1)
			if math.abs(minutes - target) > ALLOWED_DIFFERENCE_MINUTES then
				error(`rebirth {number}: run takes {minutes} minutes, planned {target}`)
			end
		end
		expect(#RebirthConfig.thresholds).toBe(#TARGET_MINUTES)
	end,

	["runs never get shorter from one rebirth to the next"] = function(expect)
		for rebirths = 0, 30 do
			expect(runMinutes(rebirths + 1) >= runMinutes(rebirths) - ALLOWED_DIFFERENCE_MINUTES).toBe(true)
		end
	end,

	["a new player can train on lane 1 right away"] = function(expect)
		expect(bestStrengthPerSecond(0) > 0).toBe(true)
	end,
}
