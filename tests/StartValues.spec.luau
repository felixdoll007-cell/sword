local StartValues = require("../src/shared/Rules/StartValues")
local StrengthConfig = require("../src/shared/Config/Strength")
local TestSettings = require("../src/shared/Config/TestSettings")

local testOn = { enabled = true, startStrength = 100000 }
local testOff = { enabled = false, startStrength = 100000 }

return {
	["test settings are switched off before committing"] = function(expect)
		-- If this fails: set enabled = false in Config/TestSettings before committing.
		expect(TestSettings.enabled).toBe(false)
	end,

	["without test settings the real start strength is used"] = function(expect)
		expect(StartValues.startStrength(StrengthConfig, testOff, true)).toBe(StrengthConfig.startStrength)
		expect(StartValues.startStrength(StrengthConfig, testOff, false)).toBe(StrengthConfig.startStrength)
	end,

	["test settings apply in Studio"] = function(expect)
		expect(StartValues.startStrength(StrengthConfig, testOn, true)).toBe(100000)
	end,

	["test settings never apply in the published game"] = function(expect)
		expect(StartValues.startStrength(StrengthConfig, testOn, false)).toBe(StrengthConfig.startStrength)
	end,
}
