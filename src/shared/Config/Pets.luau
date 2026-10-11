--!strict
-- Pets: bought as eggs, hatched by chance, up to three equipped. Equipped pets raise the
-- strength of every training throw. Nothing secret here: the client may read this file, the
-- server does all the rolling and checking.
-- Looks (follow distance, hatch animation, sizes on screen) are in Config/Ui.

return {
	-- The pets. A new pet is added by adding an entry here and its template to the place.
	--   id: how the pet is saved. Never change the id of a pet players may already own.
	--   name: shown on screen.
	--   rarity: decides its bonus (rarities below) and its color (Config/Ui, rarity).
	--   template: name of the model in ReplicatedStorage.Assets.
	list = {
		{ id = "bunny", name = "Bunny", rarity = "common", template = "pet_bunny" },
		{ id = "fox", name = "Fox", rarity = "uncommon", template = "pet_fox" },
		{ id = "panda", name = "Panda", rarity = "rare", template = "pet_panda" },
		{ id = "dragon", name = "Dragon", rarity = "epic", template = "pet_dragon" },
		{ id = "phoenix", name = "Phoenix", rarity = "legendary", template = "pet_phoenix" },
	},

	-- What a pet of each rarity gives while equipped: this share of the base strength per
	-- training throw is added (0.05 = "+5%"). The bonuses of all equipped pets are added to the
	-- base value; lane, weapon and rebirths multiply the result as before.
	-- order: from the most common to the rarest, for sorting.
	rarities = {
		common = { order = 1, name = "Common", bonus = 0.05 },
		uncommon = { order = 2, name = "Uncommon", bonus = 0.10 },
		rare = { order = 3, name = "Rare", bonus = 0.15 },
		epic = { order = 4, name = "Epic", bonus = 0.30 },
		legendary = { order = 5, name = "Legendary", bonus = 0.60 },
	},

	-- How many pets work at the same time, and how many a player can keep.
	maxEquipped = 3,
	maxOwned = 30,

	-- The egg at the stand in the world.
	egg = {
		name = "STARTER EGG",
		-- Price of a player's first egg, in Coins.
		startPrice = 150,
		-- Each further egg costs this many times the one before (1.2 = 20 % more).
		-- 1 = every egg costs the same.
		priceGrowth = 1.2,
		-- What can hatch, with its chance in percent. Must add up to 100.
		chances = {
			{ pet = "bunny", percent = 50 },
			{ pet = "fox", percent = 30 },
			{ pet = "panda", percent = 14 },
			{ pet = "dragon", percent = 5 },
			{ pet = "phoenix", percent = 1 },
		},
		template = "pet_egg",
		-- Where the stand is: center on the ground. Next to the shop pedestals.
		position = { x = 36, z = 22 },
	},

	-- Server: a player must stand this close to the egg stand to hatch.
	useDistance = 12,
	-- Server: at most this many pet requests (hatch, equip, delete) per player within the time window.
	maxRequests = 6,
	requestWindowSeconds = 2,
	-- Server: after a hatch the next one is possible only after this many seconds.
	hatchCooldownSeconds = 1,
}
