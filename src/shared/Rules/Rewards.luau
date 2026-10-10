--!strict
-- Pure function: what a main throw adds to the player's values.

export type Values = {
	strength: number,
	currency: number,
	bestWall: number,
}

export type ThrowOutcome = {
	-- From ThrowCalculation: currency includes the zone bonus, strength is per broken wall.
	currency: number,
	strength: number,
	wallsBroken: number,
}

-- What one broken wall gives. zoneBonus is extra currency if this wall completes its zone, else 0.
export type WallReward = {
	currency: number,
	strength: number,
	zoneBonus: number,
}

export type WallConfig = {
	wallsPerZone: number,
	zoneBonusFactor: number,
}

export type StrengthConfig = {
	strengthPerBrokenWall: number,
}

-- The broken walls of a throw, as ThrowCalculation returns them (only the fields needed here).
export type BrokenWall = {
	positionInZone: number,
	reward: number,
}

local Rewards = {}

-- Splits the reward of a throw into one entry per broken wall, in the order the sword breaks them.
-- strengthMultiplier is the player's multiplier on strength gains (rebirths); currency is not multiplied.
-- With multiplier 1 the entries add up to the same totals as ThrowCalculation.
function Rewards.perWall(
	wallConfig: WallConfig,
	strengthConfig: StrengthConfig,
	brokenWalls: { BrokenWall },
	strengthMultiplier: number
): { WallReward }
	local list = {}
	for _, wall in brokenWalls do
		local completesZone = wall.positionInZone == wallConfig.wallsPerZone
		table.insert(list, {
			currency = wall.reward,
			strength = strengthConfig.strengthPerBrokenWall * strengthMultiplier,
			zoneBonus = if completesZone then wall.reward * wallConfig.zoneBonusFactor else 0,
		})
	end
	return list
end

-- Adds the per-wall entries up to what the whole throw gives.
function Rewards.total(perWall: { WallReward }): ThrowOutcome
	local currency, strength = 0, 0
	for _, entry in perWall do
		currency += entry.currency + entry.zoneBonus
		strength += entry.strength
	end
	return { currency = currency, strength = strength, wallsBroken = #perWall }
end

function Rewards.applyThrow(values: Values, outcome: ThrowOutcome): Values
	return {
		strength = values.strength + outcome.strength,
		currency = values.currency + outcome.currency,
		bestWall = math.max(values.bestWall, outcome.wallsBroken),
	}
end

return Rewards
