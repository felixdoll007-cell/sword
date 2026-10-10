--!strict
-- Rebirth: give up the strength, get a lasting multiplier on all strength gains.
-- Strength after a rebirth is the normal start strength (Config/Strength).

return {
	-- Strength needed for rebirth 1, 2, 3, ... Derived from target training times per run
	-- (3, 3, 3.5, 4, 4.5, 5, 6, 7, 8.5, 10 minutes) with the training lanes of Version 2:
	-- threshold = start strength + seconds * rebirth multiplier * lane multiplier.
	thresholds = { 200, 400, 2500, 3800, 13500, 18000, 50000, 67000, 92000, 120000 },

	-- After the list: every run takes this many times as long as the one before.
	-- The formula continues from the last list value (see Rules/Rebirth).
	runTimeGrowthAfterList = 1.2,

	-- Multiplier on all strength gains = 1 + rebirths * this. So 2x after the first, then 3x, 4x, ...
	multiplierPerRebirth = 1,

	-- Server: at most this many rebirth requests per player within the time window.
	maxRequests = 3,
	requestWindowSeconds = 2,
}
