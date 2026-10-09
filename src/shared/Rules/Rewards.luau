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

local Rewards = {}

function Rewards.applyThrow(values: Values, outcome: ThrowOutcome): Values
	return {
		strength = values.strength + outcome.strength,
		currency = values.currency + outcome.currency,
		bestWall = math.max(values.bestWall, outcome.wallsBroken),
	}
end

return Rewards
