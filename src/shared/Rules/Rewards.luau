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
-- Added up, the entries give the same totals as ThrowCalculation.
function Rewards.perWall(
	wallConfig: WallConfig,
	strengthConfig: StrengthConfig,
	brokenWalls: { BrokenWall }
): { WallReward }
	local list = {}
	for _, wall in brokenWalls do
		local completesZone = wall.positionInZone == wallConfig.wallsPerZone
		table.insert(list, {
			currency = wall.reward,
			strength = strengthConfig.strengthPerBrokenWall,
			zoneBonus = if completesZone then wall.reward * wallConfig.zoneBonusFactor else 0,
		})
	end
	return list
end

function Rewards.applyThrow(values: Values, outcome: ThrowOutcome): Values
	return {
		strength = values.strength + outcome.strength,
		currency = values.currency + outcome.currency,
		bestWall = math.max(values.bestWall, outcome.wallsBroken),
	}
end

return Rewards
