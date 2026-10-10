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
	list = {
		{ id = "wooden_sword", name = "Wooden Sword", price = 0, trainingBonus = 1, template = "wooden_sword" },
		{ id = "iron_dagger", name = "Iron Dagger", price = 500, trainingBonus = 1.25, template = "iron_dagger" },
		{ id = "battle_axe", name = "Battle Axe", price = 8000, trainingBonus = 1.5, template = "battle_axe" },
		{
			id = "ember_greatsword",
			name = "Ember Greatsword",
			price = 120000,
			trainingBonus = 2,
			template = "ember_greatsword",
		},
		-- Placeholder: has no model yet.
		{ id = "void_blade", name = "Void Blade", price = 800000, trainingBonus = 3 },
	},

	-- Every player owns this weapon from the start and has it equipped.
	startWeapon = "wooden_sword",

	-- Folder in ReplicatedStorage with the weapon models.
	templateFolder = "Assets",

	-- Server: at most this many uses of a shop pedestal per player within the time window.
	maxRequests = 3,
	requestWindowSeconds = 2,
	-- Server: a player must stand this close to a pedestal to buy or equip there.
	useDistance = 12,

	-- The shop: one pedestal per weapon in a row, to the right of the throw zone.
	shop = {
		-- Center of the first pedestal on the ground. Each further one lies `spacing` to the right.
		firstPedestal = { x = 36, z = -6 },
		spacing = 11,
		pedestalWidth = 4,
		pedestalHeight = 3,
		pedestalColor = { 95, 95, 95 },
		-- The weapon stands upright above the pedestal, this far above its top.
		weaponGap = 0.6,

		-- How long the button at the pedestal must be held (touch, key or gamepad).
		holdSeconds = 0.4,
		-- The button shows when the player is this close. Must not be more than useDistance.
		promptDistance = 10,

		-- Sign above each pedestal. Built on the client, because OWNED / EQUIPPED / LOCKED depends
		-- on the player looking at it.
		signHeightAboveFloor = 11.5,
		signWidth = 9,
		signBoardHeight = 6.5,
		signBoardThickness = 0.4,
		signBoardColor = { 40, 40, 40 },
		signTextColor = { 255, 255, 255 },
		-- Four lines from top to bottom: name, bonus, price, state. Share of the board height for each.
		signLineHeights = { 0.26, 0.24, 0.22, 0.28 },

		-- %s is replaced by the bonus in percent: 1.25 becomes "+25% Strength".
		bonusText = "+%s%% Strength",
		-- %s is replaced by the price.
		priceText = "%s Coins",
		freeText = "FREE",
		ownedText = "OWNED",
		equippedText = "EQUIPPED",
		lockedText = "LOCKED",
		ownedColor = { 255, 255, 255 },
		equippedColor = { 110, 220, 120 },
		lockedColor = { 230, 90, 90 },

		-- Texts on the button at the pedestal.
		buyActionText = "Buy",
		equipActionText = "Equip",
		tooExpensiveActionText = "Not enough Coins",
	},
}
