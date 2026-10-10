local SaveData = require("../src/shared/Rules/SaveData")
local SaveConfig = require("../src/shared/Config/Save")
local WeaponConfig = require("../src/shared/Config/Weapons")

local template = SaveData.template(SaveConfig, 10, WeaponConfig)

return {
	["a new save starts with the start strength and nothing else"] = function(expect)
		expect(template.version).toBe(SaveConfig.dataVersion)
		expect(template.strength).toBe(10)
		expect(template.currency).toBe(0)
		expect(template.bestWall).toBe(0)
		expect(template.lastLeftAt).toBe(0)
		expect(template.rebirths).toBe(0)
	end,

	["a save from Version 1 (without rebirths) loads with 0 rebirths and keeps everything else"] = function(expect)
		local data = SaveData.repair(
			SaveConfig,
			{ version = 1, strength = 500, currency = 42.5, bestWall = 7, lastLeftAt = 99 },
			template,
			WeaponConfig
		)
		expect(data.rebirths).toBe(0)
		expect(data.strength).toBe(500)
		expect(data.currency).toBe(42.5)
		expect(data.bestWall).toBe(7)
	end,

	["rebirths are kept, broken or fractional values are cleaned"] = function(expect)
		expect(SaveData.repair(SaveConfig, { rebirths = 4 }, template, WeaponConfig).rebirths).toBe(4)
		expect(SaveData.repair(SaveConfig, { rebirths = 2.7 }, template, WeaponConfig).rebirths).toBe(2)
		expect(SaveData.repair(SaveConfig, { rebirths = -1 }, template, WeaponConfig).rebirths).toBe(0)
		expect(SaveData.repair(SaveConfig, { rebirths = "many" }, template, WeaponConfig).rebirths).toBe(0)
	end,

	["a new save owns and uses only the start weapon"] = function(expect)
		expect(#template.ownedWeapons).toBe(1)
		expect(template.ownedWeapons[1]).toBe(WeaponConfig.startWeapon)
		expect(template.equippedWeapon).toBe(WeaponConfig.startWeapon)
	end,

	["a save from before the weapon shop loads with the start weapon and keeps everything else"] = function(expect)
		local data = SaveData.repair(
			SaveConfig,
			{ version = 1, strength = 500, currency = 42.5, bestWall = 7, lastLeftAt = 99, rebirths = 3 },
			template,
			WeaponConfig
		)
		expect(#data.ownedWeapons).toBe(1)
		expect(data.ownedWeapons[1]).toBe(WeaponConfig.startWeapon)
		expect(data.equippedWeapon).toBe(WeaponConfig.startWeapon)
		expect(data.strength).toBe(500)
		expect(data.currency).toBe(42.5)
		expect(data.rebirths).toBe(3)
	end,

	["owned and equipped weapons are kept, broken entries are cleaned"] = function(expect)
		local data = SaveData.repair(
			SaveConfig,
			{ ownedWeapons = { "wooden_sword", "battle_axe", "laser_gun" }, equippedWeapon = "battle_axe" },
			template,
			WeaponConfig
		)
		expect(#data.ownedWeapons).toBe(2)
		expect(data.equippedWeapon).toBe("battle_axe")

		local broken =
			SaveData.repair(SaveConfig, { ownedWeapons = "all", equippedWeapon = "void_blade" }, template, WeaponConfig)
		expect(#broken.ownedWeapons).toBe(1)
		expect(broken.equippedWeapon).toBe(WeaponConfig.startWeapon)
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
			template,
			WeaponConfig
		)
		expect(data.strength).toBe(500)
		expect(data.currency).toBe(42.5)
		expect(data.bestWall).toBe(7)
		expect(data.lastLeftAt).toBe(99)
	end,

	["missing fields are filled from the template"] = function(expect)
		local data = SaveData.repair(SaveConfig, { strength = 500 }, template, WeaponConfig)
		expect(data.strength).toBe(500)
		expect(data.currency).toBe(0)
		expect(data.bestWall).toBe(0)
		expect(data.version).toBe(SaveConfig.dataVersion)
	end,

	["broken values are replaced, not kept"] = function(expect)
		local data = SaveData.repair(
			SaveConfig,
			{ strength = "lots", currency = 0 / 0, bestWall = -3, lastLeftAt = math.huge },
			template,
			WeaponConfig
		)
		expect(data.strength).toBe(10)
		expect(data.currency).toBe(0)
		expect(data.bestWall).toBe(0)
		expect(data.lastLeftAt).toBe(0)
	end,

	["very large numbers are kept"] = function(expect)
		local data = SaveData.repair(SaveConfig, { strength = 1e300, currency = 1e30 }, template, WeaponConfig)
		expect(data.strength).toBe(1e300)
		expect(data.currency).toBe(1e30)
	end,

	["repair does not change the loaded table"] = function(expect)
		local loaded = { strength = "broken" }
		SaveData.repair(SaveConfig, loaded, template, WeaponConfig)
		expect(loaded.strength).toBe("broken")
	end,
}
