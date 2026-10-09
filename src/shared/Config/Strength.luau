--!strict
-- Start values and how players gain strength.
-- Raised values for testing do NOT go here, they go into Config/TestSettings.

return {
	-- Strength of a brand new player.
	startStrength = 10,

	-- Training lane 1 (used from Etappe 5 on).
	trainingStrengthPerThrow = 1,
	trainingSecondsPerThrow = 1,

	-- Main throw: strength for each broken wall. Much less than training on purpose.
	strengthPerBrokenWall = 0.1,
}
