--!strict
-- Pure functions for rebirth: how much strength it needs, what multiplier it gives,
-- and what a rebirth changes.
-- "rebirths" always means how many rebirths the player has done so far.

export type RebirthConfig = {
	thresholds: { number },
	runTimeGrowthAfterList: number,
	multiplierPerRebirth: number,
}

export type Values = {
	strength: number,
	rebirths: number,
}

local Rebirth = {}

-- Multiplier on all strength gains with this many rebirths.
function Rebirth.multiplier(config: RebirthConfig, rebirths: number): number
	return 1 + math.max(rebirths, 0) * config.multiplierPerRebirth
end

-- Strength needed for the NEXT rebirth.
function Rebirth.threshold(config: RebirthConfig, rebirths: number): number
	local listLength = #config.thresholds
	local number = math.max(math.floor(rebirths), 0) + 1 -- the rebirth this threshold is for
	if number <= listLength then
		return config.thresholds[number]
	end
	-- After the list: each run takes runTimeGrowthAfterList times as long as the one before.
	-- Training gets faster with the multiplier, so the threshold grows by the time factor
	-- and by how much the multiplier has grown since the last list entry.
	local stepsAfterList = number - listLength
	local multiplierGrowth = Rebirth.multiplier(config, number - 1) / Rebirth.multiplier(config, listLength - 1)
	return config.thresholds[listLength] * config.runTimeGrowthAfterList ^ stepsAfterList * multiplierGrowth
end

function Rebirth.canRebirth(config: RebirthConfig, strength: number, rebirths: number): boolean
	-- NaN is never enough.
	return strength == strength and strength >= Rebirth.threshold(config, rebirths)
end

-- Progress towards the next rebirth, from 0 to 1.
function Rebirth.progress(config: RebirthConfig, strength: number, rebirths: number): number
	local progress = strength / Rebirth.threshold(config, rebirths)
	if progress ~= progress then
		return 0
	end
	return math.clamp(progress, 0, 1)
end

-- What a rebirth changes: strength back to the start, one more rebirth.
-- Everything else (currency, best wall) is not touched. Returns nil if not allowed.
function Rebirth.apply(config: RebirthConfig, values: Values, startStrength: number): Values?
	if not Rebirth.canRebirth(config, values.strength, values.rebirths) then
		return nil
	end
	return {
		strength = startStrength,
		rebirths = values.rebirths + 1,
	}
end

return Rebirth
