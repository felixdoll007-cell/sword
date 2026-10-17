-- Checks that weapon prices and bonuses fit the rest of the game.
-- It plays through the first rebirths with a simple model of a player and looks at when each
-- weapon becomes affordable and how long the runs take.
--
-- The model: the player trains for TRAIN_SECONDS, then does one main throw (THROW_SECONDS),
-- hits the meter with METER_FACTOR on average, and buys each weapon as soon as the coins suffice.
-- Real players throw more or less often, so the windows below are wide on purpose.
local Rebirth = require("../src/shared/Rules/Rebirth")
local ThrowCalculation = require("../src/shared/Rules/ThrowCalculation")
local Training = require("../src/shared/Rules/Training")
local Weapons = require("../src/shared/Rules/Weapons")
local LaneConfig = require("../src/shared/Config/Lane")
local RebirthConfig = require("../src/shared/Config/Rebirth")
local StrengthConfig = require("../src/shared/Config/Strength")
local TrainingConfig = require("../src/shared/Config/Training")
local WallConfig = require("../src/shared/Config/Walls")
local WeaponConfig = require("../src/shared/Config/Weapons")

local TRAIN_SECONDS = 25
local THROW_SECONDS = 5
local METER_FACTOR = 1.2
local RUNS_TO_PLAY = 14

-- With all weapons bought as early as possible, no run may be shorter than this.
local SHORTEST_RUN_MINUTES = 3

-- The run (number of the rebirth it leads to) in which each weapon should become affordable.
local AFFORDABLE_IN_RUN = {
	iron_dagger = { from = 2, to = 3 },
	battle_axe = { from = 3, to = 5 },
	ember_greatsword = { from = 6, to = 9 },
	void_blade = { from = 10, to = 13 },
}

local function bestLaneMultiplier(rebirths: number): number
	local best = 0
	for index, lane in TrainingConfig.lanes do
		if Training.isUnlocked(TrainingConfig, index, { rebirths = rebirths }) then
			best = math.max(best, lane.multiplier)
		end
	end
	return best
end

type Played = {
	runMinutes: { number },
	boughtInRun: { [string]: number },
}

-- Plays RUNS_TO_PLAY rebirth runs. withWeapons = false never buys anything.
local function play(withWeapons: boolean): Played
	local holdings = Weapons.sanitize(WeaponConfig, nil, nil)
	local coins = 0
	local played: Played = { runMinutes = {}, boughtInRun = {} }

	local function buyWhatIsAffordable(run: number)
		if not withWeapons then
			return
		end
		for _, weapon in WeaponConfig.list do
			if not Weapons.isOwned(holdings, weapon.id) then
				local result = Weapons.use(WeaponConfig, holdings, coins, weapon.id)
				if result.outcome ~= "bought" then
					return -- weapons are bought in shop order
				end
				holdings = result.holdings
				coins = result.currency
				played.boughtInRun[weapon.id] = run
			end
		end
	end

	for run = 1, RUNS_TO_PLAY do
		local rebirths = run - 1
		local threshold = Rebirth.threshold(RebirthConfig, rebirths)
		local rebirthMultiplier = Rebirth.multiplier(RebirthConfig, rebirths)
		local strength = StrengthConfig.startStrength
		local seconds = 0

		while true do
			local perSecond = StrengthConfig.trainingStrengthPerThrow
				/ StrengthConfig.trainingSecondsPerThrow
				* bestLaneMultiplier(rebirths)
				* rebirthMultiplier
				* Weapons.trainingBonus(WeaponConfig, holdings.equipped)
			local trained = math.min(TRAIN_SECONDS, (threshold - strength) / perSecond)
			strength += perSecond * trained
			seconds += trained

			local throw = ThrowCalculation.calculate(WallConfig, StrengthConfig, strength * METER_FACTOR)
			coins += throw.currency
			seconds += THROW_SECONDS
			buyWhatIsAffordable(run)

			if strength >= threshold then
				break
			end
			strength += throw.strength * rebirthMultiplier
		end
		played.runMinutes[run] = seconds / 60
	end
	return played
end

return {
	["weapon ids are unique and the start weapon exists"] = function(expect)
		local seen = {}
		for _, weapon in WeaponConfig.list do
			if seen[weapon.id] then
				error(`weapon id "{weapon.id}" is used twice`)
			end
			seen[weapon.id] = true
		end
		expect(seen[WeaponConfig.startWeapon]).toBe(true)
	end,

	["the start weapon is first, free and without bonus"] = function(expect)
		local first = WeaponConfig.list[1]
		expect(first.id).toBe(WeaponConfig.startWeapon)
		expect(first.price).toBe(0)
		expect(first.trainingBonus).toBe(1)
	end,

	["every weapon costs more and gives more than the one before"] = function(expect)
		for index = 2, #WeaponConfig.list do
			local weapon, previous = WeaponConfig.list[index], WeaponConfig.list[index - 1]
			if not (weapon.price > previous.price) then
				error(`{weapon.id} must cost more than {previous.id}`)
			end
			if not (weapon.trainingBonus > previous.trainingBonus) then
				error(`{weapon.id} must give a higher bonus than {previous.id}`)
			end
		end
		expect(true).toBe(true)
	end,

	["every weapon becomes affordable in its planned run"] = function(expect)
		local played = play(true)
		for _, weapon in WeaponConfig.list do
			if weapon.id ~= WeaponConfig.startWeapon then
				local window = AFFORDABLE_IN_RUN[weapon.id]
				if not window then
					error(`{weapon.id}: no planned run in this test, add one to AFFORDABLE_IN_RUN`)
				end
				local run = played.boughtInRun[weapon.id]
				if not run then
					error(`{weapon.id} is not affordable within {RUNS_TO_PLAY} runs`)
				end
				if run < window.from or run > window.to then
					error(`{weapon.id} becomes affordable in run {run}, planned is run {window.from} to {window.to}`)
				end
			end
		end
		expect(true).toBe(true)
	end,

	["with all weapons no run is shorter than three minutes"] = function(expect)
		local played = play(true)
		for run, minutes in played.runMinutes do
			if minutes < SHORTEST_RUN_MINUTES then
				error(`run {run} takes only {minutes} minutes with weapons`)
			end
		end
		expect(#played.runMinutes).toBe(RUNS_TO_PLAY)
	end,

	["weapons make the game faster, never slower"] = function(expect)
		local without = play(false)
		local with = play(true)
		for run = 1, RUNS_TO_PLAY do
			expect(with.runMinutes[run] <= without.runMinutes[run] + 1e-9).toBe(true)
		end
	end,

	["the shop pedestals stand on the ground, clear of the main lane and the training lanes"] = function(expect)
		local shop = WeaponConfig.shop
		local half = shop.pedestalWidth / 2
		local ground = LaneConfig.groundHalfSize
		for index = 1, Weapons.count(WeaponConfig) do
			local position = Weapons.pedestalPosition(WeaponConfig, index)
			local minX, maxX = position.x - half, position.x + half
			local minZ, maxZ = position.z - half, position.z + half
			if minX < -ground or maxX > ground or minZ < -ground or maxZ > ground then
				error(`pedestal {index} lies outside the ground: too many weapons for this spacing`)
			end
			-- Throw zone and main lane: everything from the back of the throw zone towards negative Z.
			local laneHalfWidth = LaneConfig.laneWidth / 2
			local overlapsMainLane = minX < LaneConfig.throwLine.x + laneHalfWidth
				and maxX > LaneConfig.throwLine.x - laneHalfWidth
				and minZ < LaneConfig.throwLine.z + LaneConfig.throwZoneLength
			if overlapsMainLane then
				error(`pedestal {index} overlaps the throw zone or the main lane`)
			end
			for lane = 1, Training.laneCount(TrainingConfig) do
				local area = Training.laneArea(TrainingConfig, lane) :: Training.Area
				if minX < area.maxX and maxX > area.minX and minZ < area.maxZ and maxZ > area.minZ then
					error(`pedestal {index} overlaps training lane {lane}`)
				end
			end
		end
		expect(shop.spacing > shop.pedestalWidth).toBe(true)
	end,

	["the button at a pedestal shows only where the server also accepts its use"] = function(expect)
		expect(WeaponConfig.shop.promptDistance <= WeaponConfig.useDistance).toBe(true)
	end,
}
