local SaveData = require("../src/shared/Rules/SaveData")
local SaveConfig = require("../src/shared/Config/Save")

local template = SaveData.template(SaveConfig, 10)

return {
	["a new save starts with the start strength and nothing else"] = function(expect)
		expect(template.version).toBe(SaveConfig.dataVersion)
		expect(template.strength).toBe(10)
		expect(template.currency).toBe(0)
		expect(template.bestWall).toBe(0)
		expect(template.lastLeftAt).toBe(0)
	end,

	["Studio uses its own store, the real game the plain one"] = function(expect)
		expect(SaveData.storeName(SaveConfig, true)).toBe(SaveConfig.storeName .. SaveConfig.studioSuffix)
		expect(SaveData.storeName(SaveConfig, false)).toBe(SaveConfig.storeName)
	end,

	["key contains the user id"] = function(expect)
		expect(SaveData.key(SaveConfig, 12345)).toBe(SaveConfig.keyPrefix .. "12345")
	end,

	["test values are never saved: mock only with test values on in Studio"] = function(expect)
		expect(SaveData.useMock(true, true)).toBe(true)
		expect(SaveData.useMock(true, false)).toBe(false)
		expect(SaveData.useMock(false, true)).toBe(false)
	end,

	["a good save stays as it is"] = function(expect)
		local data = SaveData.repair(
			SaveConfig,
			{ version = 1, strength = 500, currency = 42.5, bestWall = 7, lastLeftAt = 99 },
			template
		)
		expect(data.strength).toBe(500)
		expect(data.currency).toBe(42.5)
		expect(data.bestWall).toBe(7)
		expect(data.lastLeftAt).toBe(99)
	end,

	["missing fields are filled from the template"] = function(expect)
		local data = SaveData.repair(SaveConfig, { strength = 500 }, template)
		expect(data.strength).toBe(500)
		expect(data.currency).toBe(0)
		expect(data.bestWall).toBe(0)
		expect(data.version).toBe(SaveConfig.dataVersion)
	end,

	["broken values are replaced, not kept"] = function(expect)
		local data = SaveData.repair(
			SaveConfig,
			{ strength = "lots", currency = 0 / 0, bestWall = -3, lastLeftAt = math.huge },
			template
		)
		expect(data.strength).toBe(10)
		expect(data.currency).toBe(0)
		expect(data.bestWall).toBe(0)
		expect(data.lastLeftAt).toBe(0)
	end,

	["very large numbers are kept"] = function(expect)
		local data = SaveData.repair(SaveConfig, { strength = 1e300, currency = 1e30 }, template)
		expect(data.strength).toBe(1e300)
		expect(data.currency).toBe(1e30)
	end,

	["repair does not change the loaded table"] = function(expect)
		local loaded = { strength = "broken" }
		SaveData.repair(SaveConfig, loaded, template)
		expect(loaded.strength).toBe("broken")
	end,
}
