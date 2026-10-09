--!strict
-- Pure function that decides which start values a new player gets.
-- Test values only win when they are enabled AND the game runs in Studio.

export type StrengthConfig = {
	startStrength: number,
}

export type TestSettings = {
	enabled: boolean,
	startStrength: number,
}

local StartValues = {}

function StartValues.startStrength(
	strengthConfig: StrengthConfig,
	testSettings: TestSettings,
	isStudio: boolean
): number
	if testSettings.enabled and isStudio then
		return testSettings.startStrength
	end
	return strengthConfig.startStrength
end

return StartValues
