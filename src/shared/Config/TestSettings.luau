--!strict
-- Test helpers for Studio. Never change the real values for a test, use this file.
--
-- Two locks keep everything here off in the published game:
-- 1. A switch only works when the game runs in Studio (see Rules/TestMode).
-- 2. A test fails while a switch is true, so .\check.ps1 is red and nothing gets committed.

return {
	-- Switch 1: raised test values.
	enabled = false,
	-- Replaces Config/Strength.startStrength while enabled.
	startStrength = 100000,

	-- Switch 2: debug keys and the label that shows which window you are looking at.
	debugTools = false,
	breakNextWallKey = "B",
	resetWallsKey = "R",
	labelTextSize = 18,
}
