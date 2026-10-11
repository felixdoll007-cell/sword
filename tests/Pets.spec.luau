local Pets = require("../src/shared/Rules/Pets")
local PetConfig = require("../src/shared/Config/Pets")
local Ui = require("../src/shared/Config/Ui")

local EMPTY: Pets.Holdings = { pets = {}, equipped = {}, eggsHatched = 0 }
local FIRST_PRICE = PetConfig.egg.startPrice

-- Holdings with these pets (ids), uids counted from 1.
local function holdingsWith(ids: { string }, equipped: { number }?): Pets.Holdings
	local pets = {}
	for index, id in ids do
		table.insert(pets, { uid = index, id = id })
	end
	return { pets = pets, equipped = equipped or {}, eggsHatched = #ids }
end

return {
	["there are five pets, one of each rarity, from common to legendary"] = function(expect)
		expect(#PetConfig.list).toBe(5)
		local seenIds, seenRarities = {}, {}
		for index, pet in PetConfig.list do
			expect(seenIds[pet.id]).toBe(nil)
			seenIds[pet.id] = true
			expect(seenRarities[pet.rarity]).toBe(nil)
			seenRarities[pet.rarity] = true
			local rarity = PetConfig.rarities[pet.rarity]
			expect(typeof(rarity)).toBe("table")
			expect(rarity.order).toBe(index)
			-- Every rarity has a color for tiles and names.
			expect(typeof(Ui.rarity[pet.rarity])).toBe("table")
			expect(#pet.name > 0 and #pet.template > 0).toBe(true)
		end
	end,

	["bonuses are 5, 10, 15, 30 and 60 percent, unknown pets give nothing"] = function(expect)
		expect(Pets.bonusPercent(PetConfig, "bunny")).toBe(5)
		expect(Pets.bonusPercent(PetConfig, "fox")).toBe(10)
		expect(Pets.bonusPercent(PetConfig, "panda")).toBe(15)
		expect(Pets.bonusPercent(PetConfig, "dragon")).toBe(30)
		expect(Pets.bonusPercent(PetConfig, "phoenix")).toBe(60)
		expect(Pets.bonus(PetConfig, "unicorn")).toBe(0)
		expect(Pets.bonus(PetConfig, nil)).toBe(0)
		expect(Pets.bonus(PetConfig, 3)).toBe(0)
	end,

	["the chances add up to 100 and name pets that exist"] = function(expect)
		local total = 0
		local seen = {}
		for _, chance in PetConfig.egg.chances do
			expect(Pets.get(PetConfig, chance.pet) ~= nil).toBe(true)
			expect(seen[chance.pet]).toBe(nil)
			seen[chance.pet] = true
			expect(chance.percent > 0).toBe(true)
			total += chance.percent
		end
		expect(total).toBe(100)
	end,

	["rolling follows the chances: 50, 30, 14, 5 and 1 percent"] = function(expect)
		-- The stretch from 0 to 1 is split in the order of the config.
		expect(Pets.roll(PetConfig, 0)).toBe("bunny")
		expect(Pets.roll(PetConfig, 0.4999)).toBe("bunny")
		expect(Pets.roll(PetConfig, 0.5)).toBe("fox")
		expect(Pets.roll(PetConfig, 0.7999)).toBe("fox")
		expect(Pets.roll(PetConfig, 0.8)).toBe("panda")
		expect(Pets.roll(PetConfig, 0.9399)).toBe("panda")
		expect(Pets.roll(PetConfig, 0.94)).toBe("dragon")
		expect(Pets.roll(PetConfig, 0.9899)).toBe("dragon")
		expect(Pets.roll(PetConfig, 0.99)).toBe("phoenix")
		expect(Pets.roll(PetConfig, 0.99999)).toBe("phoenix")
		-- Counted over the whole stretch in small steps, every pet gets exactly its share.
		local counts = {}
		for step = 0, 9999 do
			local pet = Pets.roll(PetConfig, step / 10000)
			counts[pet] = (counts[pet] or 0) + 1
		end
		for _, chance in PetConfig.egg.chances do
			expect(counts[chance.pet]).toBe(chance.percent * 100)
		end
	end,

	["a broken random number still gives a pet"] = function(expect)
		expect(Pets.roll(PetConfig, 1)).toBe("phoenix")
		expect(Pets.roll(PetConfig, 7)).toBe("phoenix")
		expect(Pets.roll(PetConfig, -3)).toBe("bunny")
		expect(Pets.roll(PetConfig, 0 / 0)).toBe("bunny")
		expect(Pets.roll(PetConfig, math.huge)).toBe("bunny")
	end,

	["a legendary stays rare"] = function(expect)
		for _, chance in PetConfig.egg.chances do
			local pet = Pets.get(PetConfig, chance.pet) :: Pets.Pet
			if pet.rarity == "legendary" then
				expect(chance.percent <= 2).toBe(true)
			end
		end
	end,

	["the first egg costs the start price, every further one 20 percent more"] = function(expect)
		expect(Pets.eggPrice(PetConfig, 0)).toBe(150)
		expect(Pets.eggPrice(PetConfig, 1)).toBe(180)
		expect(Pets.eggPrice(PetConfig, 2)).toBe(216)
		expect(Pets.eggPrice(PetConfig, 5)).toBe(373)
		expect(Pets.eggPrice(PetConfig, 19)).toBe(4792)
		-- Always whole coins, never cheaper than the one before.
		local last = 0
		for count = 0, 60 do
			local price = Pets.eggPrice(PetConfig, count)
			expect(price % 1).toBe(0)
			expect(price >= last).toBe(true)
			last = price
		end
		-- Broken counts cost like the first egg; a huge count does not break anything.
		expect(Pets.eggPrice(PetConfig, -4)).toBe(150)
		expect(Pets.eggPrice(PetConfig, 0 / 0)).toBe(150)
		expect(Pets.eggPrice(PetConfig, 2.9)).toBe(216)
		expect(Pets.eggPrice(PetConfig, 1e6) > 1e300).toBe(true)
	end,

	["with a growth of 1 every egg costs the same"] = function(expect)
		local fixed = table.clone(PetConfig)
		fixed.egg = table.clone(PetConfig.egg)
		fixed.egg.priceGrowth = 1
		expect(Pets.eggPrice(fixed, 0)).toBe(150)
		expect(Pets.eggPrice(fixed, 40)).toBe(150)
	end,

	["hatching takes the price, adds the pet and counts the egg"] = function(expect)
		local result = Pets.hatch(PetConfig, EMPTY, 200, 0.6)
		expect(result.outcome).toBe("hatched")
		expect(result.currency).toBe(200 - FIRST_PRICE)
		expect(#result.holdings.pets).toBe(1)
		expect(result.holdings.eggsHatched).toBe(1)
		local pet = result.pet :: Pets.OwnedPet
		expect(pet.id).toBe("fox")
		expect(pet.uid).toBe(1)
		expect(result.holdings.pets[1].uid).toBe(1)
		-- A new pet is not equipped by itself.
		expect(#result.holdings.equipped).toBe(0)
		-- The inputs are not changed.
		expect(#EMPTY.pets).toBe(0)
		expect(EMPTY.eggsHatched).toBe(0)
	end,

	["exactly the price is enough, one coin less is not"] = function(expect)
		expect(Pets.hatch(PetConfig, EMPTY, FIRST_PRICE, 0).outcome).toBe("hatched")
		expect(Pets.hatch(PetConfig, EMPTY, FIRST_PRICE, 0).currency).toBe(0)
		local poor = Pets.hatch(PetConfig, EMPTY, FIRST_PRICE - 1, 0)
		expect(poor.outcome).toBe("notEnoughCoins")
		expect(poor.currency).toBe(FIRST_PRICE - 1)
		expect(#poor.holdings.pets).toBe(0)
		expect(poor.pet).toBe(nil)
		expect(Pets.hatch(PetConfig, EMPTY, 0 / 0, 0).outcome).toBe("notEnoughCoins")
		expect(Pets.hatch(PetConfig, EMPTY, -50, 0).outcome).toBe("notEnoughCoins")
	end,

	["the second egg costs the higher price and gets its own uid"] = function(expect)
		local first = Pets.hatch(PetConfig, EMPTY, 1000, 0)
		local second = Pets.hatch(PetConfig, first.holdings, first.currency, 0)
		expect(second.outcome).toBe("hatched")
		expect(second.currency).toBe(1000 - 150 - 180)
		expect(#second.holdings.pets).toBe(2)
		-- Two pets of the same kind are two entries.
		expect(second.holdings.pets[1].id).toBe("bunny")
		expect(second.holdings.pets[2].id).toBe("bunny")
		expect(second.holdings.pets[1].uid ~= second.holdings.pets[2].uid).toBe(true)
	end,

	["a full inventory buys nothing and keeps the coins"] = function(expect)
		local ids = {}
		for _ = 1, PetConfig.maxOwned do
			table.insert(ids, "bunny")
		end
		local full = holdingsWith(ids)
		local result = Pets.hatch(PetConfig, full, 1e30, 0.5)
		expect(result.outcome).toBe("inventoryFull")
		expect(result.currency).toBe(1e30)
		expect(#result.holdings.pets).toBe(PetConfig.maxOwned)
		expect(result.holdings.eggsHatched).toBe(PetConfig.maxOwned)
		-- One below the limit still works.
		table.remove(ids)
		expect(Pets.hatch(PetConfig, holdingsWith(ids), 1e30, 0.5).outcome).toBe("hatched")
	end,

	["a uid is never used twice, also after deleting"] = function(expect)
		local holdings = EMPTY
		local coins = 1e12
		for _ = 1, 5 do
			local result = Pets.hatch(PetConfig, holdings, coins, 0)
			holdings, coins = result.holdings, result.currency
		end
		holdings = Pets.delete(holdings, 5).holdings
		holdings = Pets.delete(holdings, 2).holdings
		local again = Pets.hatch(PetConfig, holdings, coins, 0)
		expect((again.pet :: Pets.OwnedPet).uid).toBe(6)
		local seen = {}
		for _, pet in again.holdings.pets do
			expect(seen[pet.uid]).toBe(nil)
			seen[pet.uid] = true
		end
	end,

	["equipping works for owned pets, up to three"] = function(expect)
		local holdings = holdingsWith({ "bunny", "fox", "panda", "dragon" })
		for uid = 1, 3 do
			local result = Pets.toggleEquip(PetConfig, holdings, uid)
			expect(result.outcome).toBe("equipped")
			holdings = result.holdings
		end
		expect(#holdings.equipped).toBe(PetConfig.maxEquipped)
		-- A fourth does not fit, and nothing changes.
		local fourth = Pets.toggleEquip(PetConfig, holdings, 4)
		expect(fourth.outcome).toBe("equipLimit")
		expect(#fourth.holdings.equipped).toBe(3)
		-- Taking one off makes room again.
		local off = Pets.toggleEquip(PetConfig, holdings, 2)
		expect(off.outcome).toBe("unequipped")
		expect(#off.holdings.equipped).toBe(2)
		expect(Pets.isEquipped(off.holdings, 2)).toBe(false)
		expect(Pets.toggleEquip(PetConfig, off.holdings, 4).outcome).toBe("equipped")
	end,

	["pets a player does not own cannot be equipped or deleted"] = function(expect)
		local holdings = holdingsWith({ "bunny" })
		for _, uid in { 2, 0, -1, 1.5, 0 / 0, math.huge, "1", {}, true } do
			expect(Pets.toggleEquip(PetConfig, holdings, uid).outcome).toBe("notOwned")
			expect(Pets.delete(holdings, uid).outcome).toBe("notOwned")
		end
		expect(Pets.toggleEquip(PetConfig, holdings, nil).outcome).toBe("notOwned")
		expect(#holdings.pets).toBe(1)
	end,

	["only whole positive numbers are uids"] = function(expect)
		expect(Pets.isUid(1)).toBe(true)
		expect(Pets.isUid(4000)).toBe(true)
		for _, value in { 0, -1, 1.5, 0 / 0, math.huge, 2 ^ 60, "1", {}, false } do
			expect(Pets.isUid(value)).toBe(false)
		end
		expect(Pets.isUid(nil)).toBe(false)
	end,

	["changing what is equipped does not change the input"] = function(expect)
		local holdings = holdingsWith({ "bunny", "fox" }, { 1 })
		Pets.toggleEquip(PetConfig, holdings, 2)
		Pets.toggleEquip(PetConfig, holdings, 1)
		Pets.delete(holdings, 1)
		Pets.equipBest(PetConfig, holdings)
		expect(#holdings.pets).toBe(2)
		expect(#holdings.equipped).toBe(1)
		expect(holdings.equipped[1]).toBe(1)
	end,

	["equip best picks the three highest bonuses"] = function(expect)
		local holdings = holdingsWith({ "bunny", "phoenix", "fox", "dragon", "bunny", "panda" }, { 1, 5 })
		local result = Pets.equipBest(PetConfig, holdings)
		expect(result.outcome).toBe("equipped")
		expect(#result.holdings.equipped).toBe(3)
		for _, uid in { 2, 4, 6 } do
			expect(Pets.isEquipped(result.holdings, uid)).toBe(true)
		end
		-- Doing it again changes nothing.
		expect(Pets.equipBest(PetConfig, result.holdings).outcome).toBe("unchanged")
		-- With fewer pets than places, all are equipped; with none, nothing happens.
		expect(#Pets.equipBest(PetConfig, holdingsWith({ "fox", "bunny" })).holdings.equipped).toBe(2)
		expect(Pets.equipBest(PetConfig, EMPTY).outcome).toBe("unchanged")
		-- Among equal pets the older one is taken.
		local equal = Pets.equipBest(PetConfig, holdingsWith({ "bunny", "bunny", "bunny", "bunny" }))
		expect(Pets.isEquipped(equal.holdings, 4)).toBe(false)
	end,

	["deleting removes exactly that pet and takes it off first"] = function(expect)
		local holdings = holdingsWith({ "bunny", "fox", "bunny" }, { 2, 3 })
		local result = Pets.delete(holdings, 2)
		expect(result.outcome).toBe("deleted")
		expect(#result.holdings.pets).toBe(2)
		expect(Pets.find(result.holdings, 2)).toBe(nil)
		expect(#result.holdings.equipped).toBe(1)
		expect(result.holdings.equipped[1]).toBe(3)
		-- Deleting does not make the next egg cheaper.
		expect(result.holdings.eggsHatched).toBe(3)
		-- The same pet cannot be deleted twice.
		expect(Pets.delete(result.holdings, 2).outcome).toBe("notOwned")
	end,

	["equipped pets add their bonuses to the base of a training throw"] = function(expect)
		expect(Pets.trainingMultiplier(PetConfig, EMPTY)).toBe(1)
		expect(Pets.trainingMultiplier(PetConfig, holdingsWith({ "bunny", "fox" }))).toBe(1)
		local three = holdingsWith({ "bunny", "bunny", "bunny" }, { 1, 2, 3 })
		expect(Pets.trainingMultiplier(PetConfig, three)).toBeNear(1.15)
		local best = holdingsWith({ "phoenix", "phoenix", "phoenix" }, { 1, 2, 3 })
		expect(Pets.trainingMultiplier(PetConfig, best)).toBeNear(2.8)
		local mixed = holdingsWith({ "bunny", "dragon", "fox" }, { 2, 3 })
		expect(Pets.equippedBonus(PetConfig, mixed)).toBeNear(0.4)
		-- A uid that is equipped but not owned counts nothing.
		local broken = { pets = { { uid = 1, id = "fox" } }, equipped = { 1, 9 }, eggsHatched = 9 }
		expect(Pets.equippedBonus(PetConfig, broken)).toBeNear(0.1)
	end,

	["loaded pets are cleaned: known kinds, unique uids, limits kept"] = function(expect)
		local clean = Pets.sanitize(PetConfig, {
			{ uid = 3, id = "fox" },
			{ uid = 3, id = "bunny" },
			{ uid = 4, id = "unicorn" },
			{ uid = 0, id = "fox" },
			{ uid = 2.5, id = "fox" },
			{ id = "fox" },
			"fox",
			{ uid = 9, id = "panda" },
		}, { 9, 9, 3, 4, 77 }, 2)
		expect(#clean.pets).toBe(2)
		expect(clean.pets[1].id).toBe("fox")
		expect(clean.pets[2].uid).toBe(9)
		expect(#clean.equipped).toBe(2)
		-- The counter is raised to the biggest uid, so the next pet gets a fresh one.
		expect(clean.eggsHatched).toBe(9)
		local nothing = Pets.sanitize(PetConfig, nil, nil, nil)
		expect(#nothing.pets).toBe(0)
		expect(nothing.eggsHatched).toBe(0)
		expect(Pets.sanitize(PetConfig, {}, {}, 12.9).eggsHatched).toBe(12)
		expect(Pets.sanitize(PetConfig, {}, {}, -5).eggsHatched).toBe(0)
		expect(Pets.sanitize(PetConfig, {}, {}, 0 / 0).eggsHatched).toBe(0)
	end,

	["loading never keeps more pets or more equipped pets than allowed"] = function(expect)
		local pets, equipped = {}, {}
		for uid = 1, PetConfig.maxOwned + 20 do
			table.insert(pets, { uid = uid, id = "bunny" })
			table.insert(equipped, uid)
		end
		local clean = Pets.sanitize(PetConfig, pets, equipped, 0)
		expect(#clean.pets).toBe(PetConfig.maxOwned)
		expect(#clean.equipped).toBe(PetConfig.maxEquipped)
	end,

	["pets survive being shown to the client and read back"] = function(expect)
		local holdings = holdingsWith({ "bunny", "phoenix", "bunny" }, { 3, 1 })
		local pets = Pets.decodeOwned(Pets.encodeOwned(holdings.pets))
		expect(#pets).toBe(3)
		expect(pets[2].id).toBe("phoenix")
		expect(pets[3].uid).toBe(3)
		local equipped = Pets.decodeEquipped(Pets.encodeEquipped(holdings.equipped))
		expect(#equipped).toBe(2)
		expect(equipped[1]).toBe(3)
		expect(Pets.encodeOwned({})).toBe("")
		expect(#Pets.decodeOwned("")).toBe(0)
		expect(#Pets.decodeOwned(nil)).toBe(0)
		expect(#Pets.decodeEquipped(nil)).toBe(0)
		-- Unreadable entries are left out.
		expect(#Pets.decodeOwned("1:fox,x:y,2,:fox,3:,4:panda")).toBe(2)
		expect(#Pets.decodeEquipped("1,a,,2.5,3")).toBe(2)
	end,

	["on screen, equipped pets come first, then the best, then the newest"] = function(expect)
		local holdings = holdingsWith({ "bunny", "phoenix", "fox", "bunny" }, { 1 })
		local sorted = Pets.sortedForDisplay(PetConfig, holdings)
		expect(sorted[1].uid).toBe(1)
		expect(sorted[2].id).toBe("phoenix")
		expect(sorted[3].id).toBe("fox")
		expect(sorted[4].uid).toBe(4)
		expect(#holdings.pets).toBe(4)
	end,

	["limits and server numbers are sensible"] = function(expect)
		expect(PetConfig.maxEquipped).toBe(3)
		expect(PetConfig.maxOwned).toBe(30)
		expect(PetConfig.egg.startPrice > 0).toBe(true)
		expect(PetConfig.egg.priceGrowth >= 1).toBe(true)
		expect(PetConfig.useDistance > 0).toBe(true)
		expect(PetConfig.maxRequests >= 1 and PetConfig.requestWindowSeconds > 0).toBe(true)
		expect(PetConfig.hatchCooldownSeconds >= 0).toBe(true)
	end,
}
