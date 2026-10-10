-- Checks that the numbers in the config files still fit together.
-- If one of these fails after changing a config value (for example after adding a training
-- lane), the message says which value needs to follow.
local Rebirth = require("../src/shared/Rules/Rebirth")
local Training = require("../src/shared/Rules/Training")
local LaneConfig = require("../src/shared/Config/Lane")
local OtherPlayersConfig = require("../src/shared/Config/OtherPlayers")
local RebirthConfig = require("../src/shared/Config/Rebirth")
local StrengthConfig = require("../src/shared/Config/Strength")
local TrainingConfig = require("../src/shared/Config/Training")

-- Planned pure training time per run in minutes, for rebirth 1 to 10 (docs/GAME_DESIGN.md).
local TARGET_MINUTES = { 3, 3, 3.5, 4, 4.5, 5, 6, 7, 8.5, 10 }
local ALLOWED_DIFFERENCE_MINUTES = 0.25

-- Unlock kinds the game knows, and what each needs in the config.
local KNOWN_UNLOCK_KINDS = {
	Rebirths = function(unlock: Training.Unlock): boolean
		local rebirths = unlock.rebirths
		return typeof(rebirths) == "number" and rebirths >= 0 and rebirths % 1 == 0
	end,
}

-- Strength per second on the best lane a player with this many rebirths can use.
local function bestStrengthPerSecond(rebirths: number): number
	local bestLaneMultiplier = 0
	for index, lane in TrainingConfig.lanes do
		if Training.isUnlocked(TrainingConfig, index, { rebirths = rebirths }) then
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

local function overlaps(a: Training.Area, b: Training.Area): boolean
	return a.minX < b.maxX and b.minX < a.maxX and a.minZ < b.maxZ and b.minZ < a.maxZ
end

-- Throw zone and main lane together, as far as the training lanes can reach.
local function mainLaneArea(): Training.Area
	local halfWidth = LaneConfig.laneWidth / 2
	return {
		minX = LaneConfig.throwLine.x - halfWidth,
		maxX = LaneConfig.throwLine.x + halfWidth,
		minZ = -math.huge,
		maxZ = LaneConfig.throwLine.z + LaneConfig.throwZoneLength,
	}
end

-- Fails with a clear message if the lanes of this config do not fit on the map.
local function checkLanesFitOnMap(config: Training.TrainingConfig)
	local ground = LaneConfig.groundHalfSize
	for index = 1, Training.laneCount(config) do
		local area = Training.laneArea(config, index) :: Training.Area
		if area.minX < -ground or area.maxX > ground or area.minZ < -ground or area.maxZ > ground then
			error(`training lane {index} lies outside the ground (x {area.minX} to {area.maxX}): too many lanes`)
		end
		if overlaps(area, mainLaneArea()) then
			error(`training lane {index} overlaps the throw zone or the main lane`)
		end
		for other = 1, index - 1 do
			if overlaps(area, Training.laneArea(config, other) :: Training.Area) then
				error(`training lanes {other} and {index} overlap: laneSpacing is too small`)
			end
		end
	end
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

	["every training lane has a known unlock kind with valid values"] = function(expect)
		for index, lane in TrainingConfig.lanes do
			local check = KNOWN_UNLOCK_KINDS[lane.unlock.kind]
			if not check then
				error(`training lane {index}: unknown unlock kind "{lane.unlock.kind}"`)
			end
			if not check(lane.unlock) then
				error(`training lane {index}: values for unlock kind "{lane.unlock.kind}" are missing or wrong`)
			end
		end
		expect(#TrainingConfig.lanes >= 1).toBe(true)
	end,

	["every training lane has a useful multiplier and walls that fit on its floor"] = function(expect)
		for index, lane in TrainingConfig.lanes do
			if not (lane.multiplier > 0) then
				error(`training lane {index}: multiplier must be above 0`)
			end
			if lane.walls < 1 or lane.walls % 1 ~= 0 then
				error(`training lane {index}: needs a whole number of walls, at least 1`)
			end
			if Training.wallOffset(TrainingConfig, lane.walls) >= TrainingConfig.laneLength then
				error(
					`training lane {index}: {lane.walls} walls do not fit on a lane of length {TrainingConfig.laneLength}`
				)
			end
		end
		expect(true).toBe(true)
	end,

	["all training lanes fit on the map without overlapping"] = function(expect)
		checkLanesFitOnMap(TrainingConfig)
		expect(true).toBe(true)
	end,

	["there is room on the map for more lanes, and too many are noticed"] = function(expect)
		local function withLanes(count: number): Training.TrainingConfig
			local config = table.clone(TrainingConfig)
			config.lanes = {}
			for index = 1, count do
				config.lanes[index] =
					{ unlock = { kind = "Rebirths", rebirths = index }, multiplier = index, walls = 1 }
			end
			return config
		end
		-- Twice as many lanes as now still fit.
		checkLanesFitOnMap(withLanes(#TrainingConfig.lanes * 2))
		-- A hundred lanes do not, and the check says so instead of building lanes in the void.
		local ok = pcall(checkLanesFitOnMap, withLanes(100))
		expect(ok).toBe(false)
	end,

	["a sword thrown by another player fades before it reaches the first wall"] = function(expect)
		-- It starts at the thrower, who stands at or behind the throw line.
		expect(OtherPlayersConfig.mainThrowFadeDistance < LaneConfig.firstWallDistance).toBe(true)
	end,
}
