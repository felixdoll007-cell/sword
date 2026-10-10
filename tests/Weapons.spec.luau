local Weapons = require("../src/shared/Rules/Weapons")
local WeaponConfig = require("../src/shared/Config/Weapons")

local start = { owned = { "wooden_sword" }, equipped = "wooden_sword" }

return {
	["there are five weapons and the start weapon is free"] = function(expect)
		expect(Weapons.count(WeaponConfig)).toBe(5)
		local first = Weapons.get(WeaponConfig, WeaponConfig.startWeapon) :: Weapons.Weapon
		expect(first.price).toBe(0)
		expect(first.trainingBonus).toBe(1)
		expect(Weapons.indexOf(WeaponConfig, WeaponConfig.startWeapon)).toBe(1)
	end,

	["unknown ids are not weapons"] = function(expect)
		expect(Weapons.get(WeaponConfig, "laser_gun")).toBe(nil)
		expect(Weapons.get(WeaponConfig, 3)).toBe(nil)
		expect(Weapons.get(WeaponConfig, nil)).toBe(nil)
	end,

	["training bonus comes from the equipped weapon, unknown weapons give none"] = function(expect)
		expect(Weapons.trainingBonus(WeaponConfig, "wooden_sword")).toBe(1)
		expect(Weapons.trainingBonus(WeaponConfig, "iron_dagger")).toBe(1.25)
		expect(Weapons.trainingBonus(WeaponConfig, "void_blade")).toBe(3)
		expect(Weapons.trainingBonus(WeaponConfig, "laser_gun")).toBe(1)
		expect(Weapons.trainingBonus(WeaponConfig, nil)).toBe(1)
	end,

	["every weapon has its own grip angles"] = function(expect)
		for _, weapon in WeaponConfig.list do
			local grip = Weapons.gripDegrees(WeaponConfig, weapon.id)
			expect(grip).toBe(weapon.gripDegrees)
			expect(typeof(grip.x)).toBe("number")
			expect(typeof(grip.y)).toBe("number")
			expect(typeof(grip.z)).toBe("number")
		end
	end,

	["unknown weapons and weapons without grip angles use the default grip"] = function(expect)
		expect(Weapons.gripDegrees(WeaponConfig, "laser_gun")).toBe(WeaponConfig.defaultGripDegrees)
		expect(Weapons.gripDegrees(WeaponConfig, nil)).toBe(WeaponConfig.defaultGripDegrees)
		local config = table.clone(WeaponConfig)
		config.list = { { id = "stick", name = "Stick", price = 0, trainingBonus = 1 } }
		expect(Weapons.gripDegrees(config, "stick")).toBe(WeaponConfig.defaultGripDegrees)
	end,

	["the bonus is shown as whole percent"] = function(expect)
		local percents = { 0, 25, 50, 100, 200 }
		for index, weapon in WeaponConfig.list do
			expect(Weapons.bonusPercent(weapon)).toBe(percents[index])
		end
	end,

	["buying needs enough coins, takes them and equips the weapon"] = function(expect)
		local result = Weapons.use(WeaponConfig, start, 600, "iron_dagger")
		expect(result.outcome).toBe("bought")
		expect(result.currency).toBe(100)
		expect(result.holdings.equipped).toBe("iron_dagger")
		expect(Weapons.isOwned(result.holdings, "iron_dagger")).toBe(true)
		expect(Weapons.isOwned(result.holdings, "wooden_sword")).toBe(true)
	end,

	["exactly the price is enough, one coin less is not"] = function(expect)
		expect(Weapons.use(WeaponConfig, start, 500, "iron_dagger").outcome).toBe("bought")
		local poor = Weapons.use(WeaponConfig, start, 499.99, "iron_dagger")
		expect(poor.outcome).toBe("notEnoughCoins")
		expect(poor.currency).toBe(499.99)
		expect(Weapons.isOwned(poor.holdings, "iron_dagger")).toBe(false)
	end,

	["broken coin values never buy anything"] = function(expect)
		expect(Weapons.use(WeaponConfig, start, 0 / 0, "iron_dagger").outcome).toBe("notEnoughCoins")
		expect(Weapons.use(WeaponConfig, start, -1000, "iron_dagger").outcome).toBe("notEnoughCoins")
	end,

	["an owned weapon is equipped for free, never bought twice"] = function(expect)
		local owner = { owned = { "wooden_sword", "iron_dagger" }, equipped = "iron_dagger" }
		local result = Weapons.use(WeaponConfig, owner, 10000, "wooden_sword")
		expect(result.outcome).toBe("equipped")
		expect(result.currency).toBe(10000)
		expect(result.holdings.equipped).toBe("wooden_sword")
		expect(#result.holdings.owned).toBe(2)

		local again = Weapons.use(WeaponConfig, owner, 10000, "iron_dagger")
		expect(again.outcome).toBe("alreadyEquipped")
		expect(again.currency).toBe(10000)
		expect(#again.holdings.owned).toBe(2)
	end,

	["a weapon can be bought out of order"] = function(expect)
		local result = Weapons.use(WeaponConfig, start, 1e6, "ember_greatsword")
		expect(result.outcome).toBe("bought")
		expect(result.currency).toBe(1e6 - 120000)
		expect(#result.holdings.owned).toBe(2)
	end,

	["unknown weapons cannot be used"] = function(expect)
		local result = Weapons.use(WeaponConfig, start, 1e30, "laser_gun")
		expect(result.outcome).toBe("unknownWeapon")
		expect(result.currency).toBe(1e30)
		expect(Weapons.use(WeaponConfig, start, 1e30, nil).outcome).toBe("unknownWeapon")
		expect(Weapons.use(WeaponConfig, start, 1e30, 2).outcome).toBe("unknownWeapon")
	end,

	["using a pedestal does not change the input"] = function(expect)
		local holdings = { owned = { "wooden_sword" }, equipped = "wooden_sword" }
		Weapons.use(WeaponConfig, holdings, 600, "iron_dagger")
		expect(#holdings.owned).toBe(1)
		expect(holdings.equipped).toBe("wooden_sword")
	end,

	["loaded data is cleaned: unknown and double weapons go, the start weapon is always there"] = function(expect)
		local cleaned =
			Weapons.sanitize(WeaponConfig, { "battle_axe", "laser_gun", "battle_axe", 7, "iron_dagger" }, "battle_axe")
		expect(Weapons.encodeOwned(cleaned.owned)).toBe("wooden_sword,iron_dagger,battle_axe")
		expect(cleaned.equipped).toBe("battle_axe")
	end,

	["an equipped weapon that is not owned falls back to the start weapon"] = function(expect)
		expect(Weapons.sanitize(WeaponConfig, { "iron_dagger" }, "void_blade").equipped).toBe("wooden_sword")
		expect(Weapons.sanitize(WeaponConfig, nil, nil).equipped).toBe("wooden_sword")
		expect(Weapons.encodeOwned(Weapons.sanitize(WeaponConfig, "broken", 5).owned)).toBe("wooden_sword")
	end,

	["owned weapons survive being written into text and back"] = function(expect)
		local owned = { "wooden_sword", "battle_axe" }
		local back = Weapons.decodeOwned(Weapons.encodeOwned(owned))
		expect(#back).toBe(2)
		expect(back[2]).toBe("battle_axe")
		expect(#Weapons.decodeOwned("")).toBe(0)
		expect(#Weapons.decodeOwned(nil)).toBe(0)
	end,

	["pedestals stand in a row, one spacing apart"] = function(expect)
		local first = Weapons.pedestalPosition(WeaponConfig, 1)
		expect(first.x).toBe(WeaponConfig.shop.firstPedestal.x)
		local fifth = Weapons.pedestalPosition(WeaponConfig, 5)
		expect(fifth.x - first.x).toBe(4 * WeaponConfig.shop.spacing)
		expect(fifth.z).toBe(first.z)
	end,
}
