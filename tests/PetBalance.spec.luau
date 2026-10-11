-- Checks that eggs and pets fit the rest of the game.
-- It plays through the first rebirths with the same simple model of a player as
-- WeaponBalance.spec: train for TRAIN_SECONDS, do one main throw, hit the meter with
-- METER_FACTOR on average. This player buys an egg whenever the coins suffice (before weapons),
-- always has the best three pets equipped and buys each weapon as soon as possible.
-- Chance is played with a fixed row of numbers per player, so the result is the same every time.
local Pets = require("../src/shared/Rules/Pets")
local Rebirth = require("../src/shared/Rules/Rebirth")
local ThrowCalculation = require("../src/shared/Rules/ThrowCalculation")
local Training = require("../src/shared/Rules/Training")
local Weapons = require("../src/shared/Rules/Weapons")
local PetConfig = require("../src/shared/Config/Pets")
local RebirthConfig = require("../src/shared/Config/Rebirth")
local StrengthConfig = require("../src/shared/Config/Strength")
local TrainingConfig = require("../src/shared/Config/Training")
local WallConfig = require("../src/shared/Config/Walls")
local WeaponConfig = require("../src/shared/Config/Weapons")

local TRAIN_SECONDS = 25
local THROW_SECONDS = 5
local METER_FACTOR = 1.2
local RUNS_TO_PLAY = 13
local PLAYERS = 60

-- With weapons and pets, the average run must not be shorter than this.
local SHORTEST_RUN_MINUTES = 2
-- The first egg should be affordable after a few minutes, not right away and not after ages.
local FIRST_EGG_MINUTES = { from = 1.5, to = 6 }
-- After RUNS_TO_PLAY runs at most this share of the players has a legendary pet.
local MOST_WITH_LEGENDARY = 0.6

local function bestLaneMultiplier(rebirths: number): number
	local best = 0
	for index, lane in TrainingConfig.lanes do
		if Training.isUnlocked(TrainingConfig, index, { rebirths = rebirths }) then
			best = math.max(best, lane.multiplier)
		end
	end
	return best
end

-- A fixed row of numbers from 0 to 1 that looks random (the same for the same seed).
local function numbers(seed: number): () -> number
	local state = seed
	return function(): number
		state = (state * 1103515245 + 12345) % 2147483648
		return state / 2147483648
	end
end

type Played = {
	runMinutes: { number },
	firstEggMinutes: number?,
	eggs: number,
	hasLegendary: boolean,
	bestBonus: number,
}

local function play(seed: number, withPets: boolean): Played
	local nextNumber = numbers(seed)
	local weapons = Weapons.sanitize(WeaponConfig, nil, nil)
	local pets: Pets.Holdings = { pets = {}, equipped = {}, eggsHatched = 0 }
	local coins, clock = 0, 0
	local played: Played = { runMinutes = {}, firstEggMinutes = nil, eggs = 0, hasLegendary = false, bestBonus = 0 }

	local function spend()
		while withPets do
			-- A full inventory: throw away the weakest pet that is not equipped.
			if #pets.pets >= PetConfig.maxOwned then
				local sorted = Pets.sortedForDisplay(PetConfig, pets)
				pets = Pets.delete(pets, sorted[#sorted].uid).holdings
			end
			local result = Pets.hatch(PetConfig, pets, coins, nextNumber())
			if result.outcome ~= "hatched" then
				break
			end
			pets, coins = result.holdings, result.currency
			pets = Pets.equipBest(PetConfig, pets).holdings
			played.eggs += 1
			played.firstEggMinutes = played.firstEggMinutes or clock / 60
			local hatched = Pets.get(PetConfig, (result.pet :: Pets.OwnedPet).id) :: Pets.Pet
			played.hasLegendary = played.hasLegendary or hatched.rarity == "legendary"
		end
		for _, weapon in WeaponConfig.list do
			if not Weapons.isOwned(weapons, weapon.id) then
				local result = Weapons.use(WeaponConfig, weapons, coins, weapon.id)
				if result.outcome ~= "bought" then
					break
				end
				weapons, coins = result.holdings, result.currency
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
				* Pets.trainingMultiplier(PetConfig, pets)
				* bestLaneMultiplier(rebirths)
				* rebirthMultiplier
				* Weapons.trainingBonus(WeaponConfig, weapons.equipped)
			local trained = math.min(TRAIN_SECONDS, (threshold - strength) / perSecond)
			strength += perSecond * trained
			local throw = ThrowCalculation.calculate(WallConfig, StrengthConfig, strength * METER_FACTOR)
			coins += throw.currency
			seconds += trained + THROW_SECONDS
			clock += trained + THROW_SECONDS
			spend()
			if strength >= threshold then
				break
			end
			strength += throw.strength * rebirthMultiplier
		end
		played.runMinutes[run] = seconds / 60
	end
	played.bestBonus = Pets.equippedBonus(PetConfig, pets)
	return played
end

local allPlayed: { Played } = {}
for seed = 1, PLAYERS do
	table.insert(allPlayed, play(seed, true))
end
local withoutPets = play(1, false)

local function averageRun(run: number): number
	local sum = 0
	for _, played in allPlayed do
		sum += played.runMinutes[run]
	end
	return sum / #allPlayed
end

return {
	["with weapons and pets the average run is never shorter than two minutes"] = function(_expect)
		for run = 1, RUNS_TO_PLAY do
			local minutes = averageRun(run)
			if minutes < SHORTEST_RUN_MINUTES then
				error(
					`run {run} takes only {string.format("%.1f", minutes)} minutes on average with weapons and pets: `
						.. "pet bonuses are too high or eggs too cheap"
				)
			end
		end
	end,

	["pets make the runs shorter, but not by more than half"] = function(expect)
		local with, without = 0, 0
		for run = 1, RUNS_TO_PLAY do
			with += averageRun(run)
			without += withoutPets.runMinutes[run]
		end
		expect(with < without).toBe(true)
		expect(with > without / 2).toBe(true)
	end,

	["the first egg is affordable after a few minutes"] = function(_expect)
		for seed, played in allPlayed do
			local minutes = played.firstEggMinutes
			if not minutes or minutes < FIRST_EGG_MINUTES.from or minutes > FIRST_EGG_MINUTES.to then
				error(`player {seed} gets the first egg after {tostring(minutes)} minutes`)
			end
		end
	end,

	["eggs keep coming, but slower and slower"] = function(expect)
		local eggs = 0
		for _, played in allPlayed do
			eggs += played.eggs
		end
		local average = eggs / #allPlayed
		-- More than a handful, far fewer than an inventory's worth per run.
		expect(average >= 15).toBe(true)
		expect(average <= RUNS_TO_PLAY * 6).toBe(true)
	end,

	["a legendary pet stays rare"] = function(_expect)
		local lucky = 0
		for _, played in allPlayed do
			if played.hasLegendary then
				lucky += 1
			end
		end
		if lucky / #allPlayed > MOST_WITH_LEGENDARY then
			error(`{lucky} of {#allPlayed} players have a legendary pet after {RUNS_TO_PLAY} runs: too many`)
		end
	end,

	["three of the best pets together stay below the best weapon"] = function(expect)
		local best = 0
		for _, rarity in PetConfig.rarities do
			best = math.max(best, rarity.bonus)
		end
		local bestWeapon = 0
		for _, weapon in WeaponConfig.list do
			bestWeapon = math.max(bestWeapon, weapon.trainingBonus)
		end
		expect(1 + PetConfig.maxEquipped * best <= bestWeapon).toBe(true)
	end,
}
