local TestMode = require("../src/shared/Rules/TestMode")
local TestSettings = require("../src/shared/Config/TestSettings")

return {
	["all test switches are off before committing"] = function(expect)
		-- If this fails: set the switch back to false in Config/TestSettings before committing.
		expect(TestSettings.enabled).toBe(false)
		expect(TestSettings.debugTools).toBe(false)
	end,

	["a switch counts only when on and in Studio"] = function(expect)
		expect(TestMode.isOn(true, true)).toBe(true)
		expect(TestMode.isOn(true, false)).toBe(false)
		expect(TestMode.isOn(false, true)).toBe(false)
		expect(TestMode.isOn(false, false)).toBe(false)
	end,
}
