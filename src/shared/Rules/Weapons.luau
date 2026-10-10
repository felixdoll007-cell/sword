--!strict
-- Pure functions for weapons: which ones exist, what a player owns, what happens when a player
-- uses a shop pedestal, and where the pedestals stand.

export type Weapon = {
	id: string,
	name: string,
	price: number,
	trainingBonus: number,
	template: string?,
}

export type WeaponConfig = {
	list: { Weapon },
	startWeapon: string,
	shop: {
		firstPedestal: { x: number, z: number },
		spacing: number,
	},
}

-- What a player has: the ids of the owned weapons, and the id of the one in use.
export type Holdings = {
	owned: { string },
	equipped: string,
}

-- What using a pedestal led to.
export type Outcome = "bought" | "equipped" | "alreadyEquipped" | "notEnoughCoins" | "unknownWeapon"

export type UseResult = {
	outcome: Outcome,
	holdings: Holdings,
	currency: number,
}

local SEPARATOR = ","

local Weapons = {}

function Weapons.count(config: WeaponConfig): number
	return #config.list
end

function Weapons.indexOf(config: WeaponConfig, id: unknown): number?
	for index, weapon in config.list do
		if weapon.id == id then
			return index
		end
	end
	return nil
end

function Weapons.get(config: WeaponConfig, id: unknown): Weapon?
	local index = Weapons.indexOf(config, id)
	return if index then config.list[index] else nil
end

function Weapons.isOwned(holdings: Holdings, id: string): boolean
	return table.find(holdings.owned, id) ~= nil
end

-- Multiplier on strength per training throw for the equipped weapon. Unknown weapons give no bonus.
function Weapons.trainingBonus(config: WeaponConfig, equippedId: unknown): number
	local weapon = Weapons.get(config, equippedId)
	return if weapon then weapon.trainingBonus else 1
end

-- The bonus as whole percent for the sign: 1.25 -> 25.
function Weapons.bonusPercent(weapon: Weapon): number
	return math.round((weapon.trainingBonus - 1) * 100)
end

-- Cleans what was loaded from a save: only known weapons, each once, in shop order; the start
-- weapon is always owned; the equipped weapon must be owned, otherwise it is the start weapon.
function Weapons.sanitize(config: WeaponConfig, owned: unknown, equipped: unknown): Holdings
	local has: { [string]: boolean } = { [config.startWeapon] = true }
	if typeof(owned) == "table" then
		for _, id in owned :: { unknown } do
			if typeof(id) == "string" and Weapons.get(config, id) then
				has[id] = true
			end
		end
	end
	local list = {}
	for _, weapon in config.list do
		if has[weapon.id] then
			table.insert(list, weapon.id)
		end
	end
	local equippedId = if typeof(equipped) == "string" and has[equipped] then equipped else config.startWeapon
	return { owned = list, equipped = equippedId }
end

-- A player uses the pedestal of a weapon: owned -> equip it, not owned -> buy it (and equip it).
-- Returns what happened and the new holdings and coins. The inputs are not changed.
function Weapons.use(config: WeaponConfig, holdings: Holdings, currency: number, id: unknown): UseResult
	local weapon = Weapons.get(config, id)
	if not weapon then
		return { outcome = "unknownWeapon", holdings = holdings, currency = currency }
	end

	if Weapons.isOwned(holdings, weapon.id) then
		if holdings.equipped == weapon.id then
			return { outcome = "alreadyEquipped", holdings = holdings, currency = currency }
		end
		return {
			outcome = "equipped",
			holdings = { owned = table.clone(holdings.owned), equipped = weapon.id },
			currency = currency,
		}
	end

	-- NaN coins are never enough.
	if not (currency >= weapon.price) then
		return { outcome = "notEnoughCoins", holdings = holdings, currency = currency }
	end
	local owned = table.clone(holdings.owned)
	table.insert(owned, weapon.id)
	local cleaned = Weapons.sanitize(config, owned, weapon.id)
	return { outcome = "bought", holdings = cleaned, currency = currency - weapon.price }
end

-- Where the pedestal of the weapon at this place in the list stands on the ground.
function Weapons.pedestalPosition(config: WeaponConfig, index: number): { x: number, z: number }
	local first = config.shop.firstPedestal
	return { x = first.x + (index - 1) * config.shop.spacing, z = first.z }
end

-- The owned weapons as one text, to show them to the client in an attribute.
function Weapons.encodeOwned(owned: { string }): string
	return table.concat(owned, SEPARATOR)
end

function Weapons.decodeOwned(text: unknown): { string }
	if typeof(text) ~= "string" or text == "" then
		return {}
	end
	return string.split(text, SEPARATOR)
end

return Weapons
