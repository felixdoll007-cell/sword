--!strict
-- The weapons a player can throw, and the shop where they are bought.
-- Lengths in studs, colors as { red, green, blue } from 0 to 255.

return {
	-- The weapons in shop order (left to right). A new weapon is added by adding an entry here.
	--   id: how the weapon is saved. Never change the id of a weapon players may already own.
	--   name: shown on the sign.
	--   price: in Coins. The start weapon costs nothing.
	--   trainingBonus: strength per training throw is multiplied by this, on top of lane and rebirths.
	--     The main throw is not affected. 1.25 is shown as "+25% Strength".
	--   template: name of the model in ReplicatedStorage.Assets (see assets/weapon-templates.NOTES.md).
	--     Without a template, or if the model is missing, a plain grey sword is shown instead.
	--   rarity: color of the tile and the name in the shop window: common, uncommon, rare, epic or
	--     legendary (colors in Config/Ui).
	--   gripDegrees: how the weapon sits in the hand, in degrees around the X, Y and Z axis of the
	--     hand's grip. With 0, 0, 0 the tip points down along the arm. x = 90 turns the tip forward,
	--     z = 90 stands the blade on its edge. The arm poses (Config/HoldPose) and the throw
	--     animations expect the tip to point forward, so change this in small steps only.
	list = {
		{
			id = "wooden_sword",
			rarity = "common",
			name = "Wooden Sword",
			price = 0,
			trainingBonus = 1,
			template = "wooden_sword",
			gripDegrees = { x = 90, y = 0, z = 90 },
		},
		{
			id = "iron_dagger",
			rarity = "uncommon",
			name = "Iron Dagger",
			price = 500,
			trainingBonus = 1.25,
			template = "iron_dagger",
			gripDegrees = { x = 90, y = 0, z = 90 },
		},
		{
			id = "battle_axe",
			rarity = "rare",
			name = "Battle Axe",
			price = 8000,
			trainingBonus = 1.5,
			template = "battle_axe",
			gripDegrees = { x = 90, y = 0, z = 90 },
		},
		{
			id = "ember_greatsword",
			rarity = "epic",
			name = "Ember Greatsword",
			price = 120000,
			trainingBonus = 2,
			template = "ember_greatsword",
			gripDegrees = { x = 90, y = 0, z = 90 },
		},
		-- Placeholder: has no model yet.
		{
			id = "void_blade",
			rarity = "legendary",
			name = "Void Blade",
			price = 800000,
			trainingBonus = 3,
			gripDegrees = { x = 90, y = 0, z = 90 },
		},
	},

	-- For a weapon without gripDegrees, and for a weapon id the game does not know.
	defaultGripDegrees = { x = 90, y = 0, z = 90 },

	-- Every player owns this weapon from the start and has it equipped.
	startWeapon = "wooden_sword",

	-- Folder in ReplicatedStorage with the weapon models.
	templateFolder = "Assets",

	-- Server: at most this many uses of a pedestal or of the items window per player within the time window.
	maxRequests = 3,
	requestWindowSeconds = 2,
	-- Server: a weapon id sent by a client that is longer than this is thrown away unread.
	maxIdLength = 40,
	-- Server: a player must stand this close to a pedestal to buy or equip there.
	useDistance = 12,

	-- The shop: one pedestal per weapon in a row, to the right of the throw zone.
	shop = {
		-- Center of the first pedestal on the ground. Each further one lies `spacing` to the right.
		-- The row stands beside the throw zone (z above 0), clear of the walkways along the lane.
		firstPedestal = { x = 36, z = 6 },
		spacing = 11,
		pedestalWidth = 4,
		pedestalHeight = 3,
		-- The weapon stands upright above the pedestal, this far above its top.
		weaponGap = 0.6,

		-- How long the button at the pedestal must be held (touch, key or gamepad).
		holdSeconds = 0.4,
		-- The button shows when the player is this close. Must not be more than useDistance.
		promptDistance = 10,

		-- The sign above each pedestal and the pedestals' colors are in Config/Ui
		-- (world.signs.shop and world.shop).

		-- Texts on the button at the pedestal.
		buyActionText = "Buy",
		equipActionText = "Equip",
		tooExpensiveActionText = "Not enough Coins",
	},
}
