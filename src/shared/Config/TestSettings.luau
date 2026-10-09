--!strict
-- Raised values for testing in Studio. Never change the real values for a test, use this file.
--
-- Two locks keep this off in the published game:
-- 1. These values only apply when the game runs in Studio (see Rules/StartValues).
-- 2. A test fails while enabled is true, so .\check.ps1 is red and nothing gets committed.

return {
	enabled = false,

	-- Replaces Config/Strength.startStrength while enabled.
	startStrength = 100000,
}
