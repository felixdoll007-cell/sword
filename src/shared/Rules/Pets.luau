--!strict
-- Pure functions for pets: what hatches from an egg, what an egg costs, what a player owns
-- and has equipped, and what the equipped pets add to training.
-- Chance never happens in here: the caller passes the random number in.

export type Pet = {
	id: string,
	name: string,
	rarity: string,
	template: string,
}

export type Rarity = { order: number, name: string, bonus: number }

export type PetConfig = {
	list: { Pet },
	rarities: { [string]: Rarity },
	maxEquipped: number,
	maxOwned: number,
	egg: {
		startPrice: number,
		priceGrowth: number,
		chances: { { pet: string, percent: number } },
	},
}

-- One pet a player owns. Every pet is its own entry, also two of the same kind.
-- uid tells them apart; it is unique for this player and never used again.
export type OwnedPet = { uid: number, id: string }

-- What a player has: the pets, which of them are equipped (their uids), and how many eggs were
-- hatched so far (decides the price of the next egg and the uid of the next pet).
export type Holdings = {
	pets: { OwnedPet },
	equipped: { number },
	eggsHatched: number,
}

export type HatchOutcome = "hatched" | "notEnoughCoins" | "inventoryFull"
export type HatchResult = {
	outcome: HatchOutcome,
	holdings: Holdings,
	currency: number,
	-- The pet that hatched. nil unless outcome is "hatched".
	pet: OwnedPet?,
}

export type ChangeOutcome = "equipped" | "unequipped" | "deleted" | "equipLimit" | "notOwned" | "unchanged"
export type ChangeResult = { outcome: ChangeOutcome, holdings: Holdings }

local PAIR_SEPARATOR = ","
local FIELD_SEPARATOR = ":"
-- Uids are whole numbers in this range. Bigger numbers cannot be told apart exactly.
local MAX_UID = 2 ^ 53

local Pets = {}

local function isUsableNumber(value: unknown): boolean
	return typeof(value) == "number" and value == value and math.abs(value) ~= math.huge
end

function Pets.get(config: PetConfig, id: unknown): Pet?
	for _, pet in config.list do
		if pet.id == id then
			return pet
		end
	end
	return nil
end

-- What one pet of this kind adds while equipped (0.05 = +5 %). Unknown pets add nothing.
function Pets.bonus(config: PetConfig, id: unknown): number
	local pet = Pets.get(config, id)
	local rarity = if pet then config.rarities[pet.rarity] else nil
	return if rarity then rarity.bonus else 0
end

-- The bonus as whole percent for the screen: 0.05 -> 5.
function Pets.bonusPercent(config: PetConfig, id: unknown): number
	return math.round(Pets.bonus(config, id) * 100)
end

-- Is this a value a pet uid can have? For checking what a client sends.
function Pets.isUid(value: unknown): boolean
	return isUsableNumber(value)
		and (value :: number) >= 1
		and (value :: number) <= MAX_UID
		and (value :: number) % 1 == 0
end

function Pets.find(holdings: Holdings, uid: unknown): OwnedPet?
	for _, pet in holdings.pets do
		if pet.uid == uid then
			return pet
		end
	end
	return nil
end

function Pets.isEquipped(holdings: Holdings, uid: number): boolean
	return table.find(holdings.equipped, uid) ~= nil
end

-- Price of the next egg for a player who hatched this many eggs so far, in whole Coins.
function Pets.eggPrice(config: PetConfig, eggsHatched: number): number
	local count = if isUsableNumber(eggsHatched) then math.max(math.floor(eggsHatched), 0) else 0
	return math.round(config.egg.startPrice * config.egg.priceGrowth ^ count)
end

-- Which pet hatches. random: a number from 0 (included) to 1 (not included).
-- The chances are laid out one after the other on that stretch, in the order of the config.
function Pets.roll(config: PetConfig, random: number): string
	local chances = config.egg.chances
	local total = 0
	for _, chance in chances do
		total += math.max(chance.percent, 0)
	end
	local point = if isUsableNumber(random) then math.clamp(random, 0, 1) * total else 0
	local passed = 0
	for _, chance in chances do
		passed += math.max(chance.percent, 0)
		if point < passed then
			return chance.pet
		end
	end
	-- random was exactly 1 (or all chances are 0): the last pet with a chance, else the first.
	for index = #chances, 1, -1 do
		if chances[index].percent > 0 then
			return chances[index].pet
		end
	end
	return chances[1].pet
end

local function copy(holdings: Holdings): Holdings
	return {
		pets = table.clone(holdings.pets),
		equipped = table.clone(holdings.equipped),
		eggsHatched = holdings.eggsHatched,
	}
end

-- A player buys an egg. Returns what happened and the new holdings and coins.
-- The inputs are not changed. random: see Pets.roll.
function Pets.hatch(config: PetConfig, holdings: Holdings, currency: number, random: number): HatchResult
	if #holdings.pets >= config.maxOwned then
		return { outcome = "inventoryFull", holdings = holdings, currency = currency, pet = nil }
	end
	local price = Pets.eggPrice(config, holdings.eggsHatched)
	-- NaN coins are never enough.
	if not (currency >= price) then
		return { outcome = "notEnoughCoins", holdings = holdings, currency = currency, pet = nil }
	end

	local after = copy(holdings)
	after.eggsHatched += 1
	-- The number of the egg is the pet's uid: counted up for every egg, so never used twice.
	local pet: OwnedPet = { uid = after.eggsHatched, id = Pets.roll(config, random) }
	table.insert(after.pets, pet)
	return { outcome = "hatched", holdings = after, currency = currency - price, pet = pet }
end

-- Equips a pet that is not equipped, takes off one that is. Only works for owned pets, and
-- never more than maxEquipped at the same time.
function Pets.toggleEquip(config: PetConfig, holdings: Holdings, uid: unknown): ChangeResult
	local pet = Pets.find(holdings, uid)
	if not pet then
		return { outcome = "notOwned", holdings = holdings }
	end
	local after = copy(holdings)
	local place = table.find(after.equipped, pet.uid)
	if place then
		table.remove(after.equipped, place)
		return { outcome = "unequipped", holdings = after }
	end
	if #after.equipped >= config.maxEquipped then
		return { outcome = "equipLimit", holdings = holdings }
	end
	table.insert(after.equipped, pet.uid)
	return { outcome = "equipped", holdings = after }
end

-- Equips the pets with the highest bonus, as many as fit. Among equal ones the older pet wins.
function Pets.equipBest(config: PetConfig, holdings: Holdings): ChangeResult
	local sorted = table.clone(holdings.pets)
	table.sort(sorted, function(a: OwnedPet, b: OwnedPet): boolean
		local bonusA, bonusB = Pets.bonus(config, a.id), Pets.bonus(config, b.id)
		if bonusA ~= bonusB then
			return bonusA > bonusB
		end
		return a.uid < b.uid
	end)
	local best = {}
	for index = 1, math.min(config.maxEquipped, #sorted) do
		table.insert(best, sorted[index].uid)
	end

	-- The same pets as before, in any order: nothing to do.
	local same = #best == #holdings.equipped
	for _, uid in best do
		same = same and table.find(holdings.equipped, uid) ~= nil
	end
	if same then
		return { outcome = "unchanged", holdings = holdings }
	end
	local after = copy(holdings)
	after.equipped = best
	return { outcome = "equipped", holdings = after }
end

-- Deletes a pet for good. An equipped pet is taken off first.
function Pets.delete(holdings: Holdings, uid: unknown): ChangeResult
	local pet = Pets.find(holdings, uid)
	if not pet then
		return { outcome = "notOwned", holdings = holdings }
	end
	local after = copy(holdings)
	table.remove(after.pets, table.find(after.pets, pet) :: number)
	local place = table.find(after.equipped, pet.uid)
	if place then
		table.remove(after.equipped, place)
	end
	return { outcome = "deleted", holdings = after }
end

-- The sum of the bonuses of all equipped pets (0.15 = +15 %).
function Pets.equippedBonus(config: PetConfig, holdings: Holdings): number
	local sum = 0
	for _, uid in holdings.equipped do
		local pet = Pets.find(holdings, uid)
		if pet then
			sum += Pets.bonus(config, pet.id)
		end
	end
	return sum
end

-- What a training throw is multiplied by because of the equipped pets: their bonuses are added
-- to the base value of 1. Without pets this is 1.
function Pets.trainingMultiplier(config: PetConfig, holdings: Holdings): number
	return 1 + Pets.equippedBonus(config, holdings)
end

-- Cleans what was loaded from a save: only known pets with a valid uid, each uid once, at most
-- maxOwned; equipped pets must be owned, each once, at most maxEquipped; the egg counter is a
-- whole number and at least as big as the biggest uid, so a new pet never gets a used uid.
function Pets.sanitize(config: PetConfig, pets: unknown, equipped: unknown, eggsHatched: unknown): Holdings
	local clean: Holdings = { pets = {}, equipped = {}, eggsHatched = 0 }
	local seen: { [number]: boolean } = {}
	local biggestUid = 0

	if typeof(pets) == "table" then
		for _, entry in pets :: { unknown } do
			if #clean.pets >= config.maxOwned then
				break
			end
			if typeof(entry) == "table" then
				local uid, id = (entry :: any).uid, (entry :: any).id
				if Pets.isUid(uid) and not seen[uid] and typeof(id) == "string" and Pets.get(config, id) then
					seen[uid] = true
					biggestUid = math.max(biggestUid, uid)
					table.insert(clean.pets, { uid = uid, id = id })
				end
			end
		end
	end

	if typeof(equipped) == "table" then
		for _, uid in equipped :: { unknown } do
			if #clean.equipped >= config.maxEquipped then
				break
			end
			if Pets.isUid(uid) and seen[uid :: number] and not table.find(clean.equipped, uid :: number) then
				table.insert(clean.equipped, uid :: number)
			end
		end
	end

	local counted = if isUsableNumber(eggsHatched) and (eggsHatched :: number) >= 0
		then math.min(math.floor(eggsHatched :: number), MAX_UID)
		else 0
	clean.eggsHatched = math.max(counted, biggestUid)
	return clean
end

-- The owned pets as one text ("3:fox,7:bunny"), to show them to the client in an attribute.
function Pets.encodeOwned(pets: { OwnedPet }): string
	local parts = {}
	for _, pet in pets do
		table.insert(parts, `{pet.uid}{FIELD_SEPARATOR}{pet.id}`)
	end
	return table.concat(parts, PAIR_SEPARATOR)
end

-- Entries that cannot be read are left out.
function Pets.decodeOwned(text: unknown): { OwnedPet }
	local pets: { OwnedPet } = {}
	if typeof(text) ~= "string" or text == "" then
		return pets
	end
	for _, part in string.split(text, PAIR_SEPARATOR) do
		local fields = string.split(part, FIELD_SEPARATOR)
		local uid = tonumber(fields[1])
		if #fields == 2 and Pets.isUid(uid) and fields[2] ~= "" then
			table.insert(pets, { uid = uid :: number, id = fields[2] })
		end
	end
	return pets
end

-- The equipped uids as one text ("3,7").
function Pets.encodeEquipped(equipped: { number }): string
	local parts = {}
	for _, uid in equipped do
		table.insert(parts, tostring(uid))
	end
	return table.concat(parts, PAIR_SEPARATOR)
end

function Pets.decodeEquipped(text: unknown): { number }
	local equipped: { number } = {}
	if typeof(text) ~= "string" or text == "" then
		return equipped
	end
	for _, part in string.split(text, PAIR_SEPARATOR) do
		local uid = tonumber(part)
		if Pets.isUid(uid) then
			table.insert(equipped, uid :: number)
		end
	end
	return equipped
end

-- The pets a player owns, sorted for the screen: equipped first, then the best, then the newest.
function Pets.sortedForDisplay(config: PetConfig, holdings: Holdings): { OwnedPet }
	local sorted = table.clone(holdings.pets)
	table.sort(sorted, function(a: OwnedPet, b: OwnedPet): boolean
		local equippedA, equippedB = Pets.isEquipped(holdings, a.uid), Pets.isEquipped(holdings, b.uid)
		if equippedA ~= equippedB then
			return equippedA
		end
		local bonusA, bonusB = Pets.bonus(config, a.id), Pets.bonus(config, b.id)
		if bonusA ~= bonusB then
			return bonusA > bonusB
		end
		return a.uid > b.uid
	end)
	return sorted
end

return Pets
