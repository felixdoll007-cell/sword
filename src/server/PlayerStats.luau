--!strict
-- The one place on the server that holds each player's values. Loaded and saved with
-- ProfileStore (session locking, autosave, saving on leave and on server shutdown).
--
-- The values are copied into attributes on the Player so the client can show them.
-- The client can read them, but changes it makes stay on its own screen; the server never reads them back.
--
-- Test data stays separate (see docs/ROADMAP.md, Etappe 6):
--   * In Studio the store name gets a suffix, so Studio never touches real players' data.
--   * With raised test values on, nothing is saved at all (ProfileStore.Mock).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local RebirthConfig = require(Shared.Config.Rebirth)
local PetConfig = require(Shared.Config.Pets)
local SaveConfig = require(Shared.Config.Save)
local StrengthConfig = require(Shared.Config.Strength)
local TestSettings = require(Shared.Config.TestSettings)
local WeaponConfig = require(Shared.Config.Weapons)
local Pets = require(Shared.Rules.Pets)
local Rebirth = require(Shared.Rules.Rebirth)
local Rewards = require(Shared.Rules.Rewards)
local SaveData = require(Shared.Rules.SaveData)
local StartValues = require(Shared.Rules.StartValues)
local Weapons = require(Shared.Rules.Weapons)

local ProfileStore = require(script.Parent.Packages.ProfileStore) :: any

local PlayerStats = {}

local isStudio = RunService:IsStudio()
local template =
	SaveData.template(SaveConfig, StartValues.startStrength(StrengthConfig, TestSettings, isStudio), WeaponConfig)

local store: any = nil
-- Loaded profile per player. Missing = not loaded (yet), the player cannot train or throw.
local profiles: { [Player]: any } = {}

local function data(player: Player): SaveData.Data?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

local function publish(player: Player)
	local values = data(player)
	if values then
		player:SetAttribute(Remotes.Attributes.Strength, values.strength)
		player:SetAttribute(Remotes.Attributes.Currency, values.currency)
		player:SetAttribute(Remotes.Attributes.Rebirths, values.rebirths)
		player:SetAttribute(Remotes.Attributes.EquippedWeapon, values.equippedWeapon)
		player:SetAttribute(Remotes.Attributes.OwnedWeapons, Weapons.encodeOwned(values.ownedWeapons))
		player:SetAttribute(Remotes.Attributes.Pets, Pets.encodeOwned(values.pets))
		player:SetAttribute(Remotes.Attributes.EquippedPets, Pets.encodeEquipped(values.equippedPets))
		player:SetAttribute(Remotes.Attributes.EggsHatched, values.eggsHatched)
	end
end

function PlayerStats.getStrength(player: Player): number?
	local values = data(player)
	return if values then values.strength else nil
end

function PlayerStats.getRebirths(player: Player): number?
	local values = data(player)
	return if values then values.rebirths else nil
end

-- The player's lasting multiplier on all strength gains (from rebirths). nil if not loaded.
function PlayerStats.strengthMultiplier(player: Player): number?
	local values = data(player)
	return if values then Rebirth.multiplier(RebirthConfig, values.rebirths) else nil
end

-- Adds strength from training. baseAmount is the gain before the player's multiplier.
-- Returns what was really added (0 if the player's data is not loaded).
function PlayerStats.gainStrength(player: Player, baseAmount: number): number
	local values = data(player)
	if not values then
		return 0
	end
	local gained = baseAmount * Rebirth.multiplier(RebirthConfig, values.rebirths)
	values.strength += gained
	publish(player)
	return gained
end

-- Multiplier on training strength from the weapon the player has equipped. nil if not loaded.
function PlayerStats.trainingBonus(player: Player): number?
	local values = data(player)
	return if values then Weapons.trainingBonus(WeaponConfig, values.equippedWeapon) else nil
end

local function petHoldings(values: SaveData.Data): Pets.Holdings
	return { pets = values.pets, equipped = values.equippedPets, eggsHatched = values.eggsHatched }
end

local function storePets(values: SaveData.Data, holdings: Pets.Holdings)
	values.pets = holdings.pets
	values.equippedPets = holdings.equipped
	values.eggsHatched = holdings.eggsHatched
end

-- What a training throw is multiplied by because of the equipped pets. nil if not loaded.
function PlayerStats.petMultiplier(player: Player): number?
	local values = data(player)
	return if values then Pets.trainingMultiplier(PetConfig, petHoldings(values)) else nil
end

-- The player buys an egg: coins and room are checked here with the server's own values, the
-- price is taken, the pet is added. random: a number from 0 to 1 that decides the pet.
-- Returns what happened and the pet (if one hatched), or nil if the player's data is not loaded.
function PlayerStats.hatchEgg(player: Player, random: number): Pets.HatchResult?
	local values = data(player)
	if not values then
		return nil
	end
	local result = Pets.hatch(PetConfig, petHoldings(values), values.currency, random)
	if result.outcome == "hatched" then
		storePets(values, result.holdings)
		values.currency = result.currency
		publish(player)
	end
	return result
end

-- Equips a pet of the player, or takes it off if it is equipped. Ownership and the number of
-- equipped pets are checked here. Returns what happened, or nil if not loaded.
function PlayerStats.togglePet(player: Player, uid: number): Pets.ChangeOutcome?
	local values = data(player)
	if not values then
		return nil
	end
	local result = Pets.toggleEquip(PetConfig, petHoldings(values), uid)
	if result.outcome == "equipped" or result.outcome == "unequipped" then
		storePets(values, result.holdings)
		publish(player)
	end
	return result.outcome
end

-- Equips the player's best pets. Returns what happened, or nil if not loaded.
function PlayerStats.equipBestPets(player: Player): Pets.ChangeOutcome?
	local values = data(player)
	if not values then
		return nil
	end
	local result = Pets.equipBest(PetConfig, petHoldings(values))
	if result.outcome == "equipped" then
		storePets(values, result.holdings)
		publish(player)
	end
	return result.outcome
end

-- Deletes a pet of the player for good. Returns what happened, or nil if not loaded.
function PlayerStats.deletePet(player: Player, uid: number): Pets.ChangeOutcome?
	local values = data(player)
	if not values then
		return nil
	end
	local result = Pets.delete(petHoldings(values), uid)
	if result.outcome == "deleted" then
		storePets(values, result.holdings)
		publish(player)
	end
	return result.outcome
end

-- The player uses the shop pedestal of a weapon: buys it if not owned and affordable, equips it
-- if owned. Price, ownership and coins are checked here with the server's own values.
-- Returns what happened, or nil if the player's data is not loaded.
function PlayerStats.useWeaponPedestal(player: Player, weaponId: string): Weapons.Outcome?
	local values = data(player)
	if not values then
		return nil
	end
	local result = Weapons.use(
		WeaponConfig,
		{ owned = values.ownedWeapons, equipped = values.equippedWeapon },
		values.currency,
		weaponId
	)
	if result.outcome == "bought" or result.outcome == "equipped" then
		values.ownedWeapons = result.holdings.owned
		values.equippedWeapon = result.holdings.equipped
		values.currency = result.currency
		publish(player)
	end
	return result.outcome
end

-- The player wants to equip a weapon from the items window. Only works for a weapon the player
-- owns, checked here with the server's own values. Nothing is bought.
-- Returns what happened, or nil if the player's data is not loaded.
function PlayerStats.equipWeapon(player: Player, weaponId: string): Weapons.EquipOutcome?
	local values = data(player)
	if not values then
		return nil
	end
	local result =
		Weapons.equip(WeaponConfig, { owned = values.ownedWeapons, equipped = values.equippedWeapon }, weaponId)
	if result.outcome == "equipped" then
		values.equippedWeapon = result.holdings.equipped
		publish(player)
	end
	return result.outcome
end

-- Does a rebirth if the player has enough strength. Returns whether it happened.
function PlayerStats.rebirth(player: Player): boolean
	local values = data(player)
	if not values then
		return false
	end
	local after = Rebirth.apply(RebirthConfig, values, template.strength)
	if not after then
		return false
	end
	-- Only strength and the rebirth count change. Currency and best wall stay.
	values.strength = after.strength
	values.rebirths = after.rebirths
	publish(player)
	return true
end

-- Credits a main throw: currency, strength and the best wall.
-- The strength in outcome already contains the player's multiplier (see Rewards.perWall).
function PlayerStats.applyThrow(player: Player, outcome: Rewards.ThrowOutcome)
	local values = data(player)
	if not values then
		return
	end
	local after = Rewards.applyThrow(values, outcome)
	values.strength = after.strength
	values.currency = after.currency
	values.bestWall = after.bestWall
	publish(player)
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(SaveData.key(SaveConfig, player.UserId), {
		-- Stop trying if the player left while loading.
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		-- Never let the player play with empty data: that would overwrite the real data later.
		if player.Parent == Players then
			player:Kick(SaveConfig.loadFailedMessage)
		end
		return
	end

	profile:AddUserId(player.UserId) -- lets Roblox find the data if the player asks for deletion
	profile:Reconcile()
	-- Repair broken or missing values and convert old versions. Copy into the same table,
	-- because ProfileStore saves exactly this table.
	local repaired = SaveData.repair(SaveConfig, profile.Data, template, WeaponConfig, PetConfig)
	for field, value in repaired :: any do
		profile.Data[field] = value
	end

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		-- Also fires when another server took over this player's data.
		player:Kick(SaveConfig.sessionEndedMessage)
	end)

	if player.Parent ~= Players then
		-- Left while loading.
		profile:EndSession()
		return
	end

	profiles[player] = profile
	publish(player)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile then
		profile.Data.lastLeftAt = os.time()
		-- Saves one last time and releases the session lock.
		profile:EndSession()
	end
	profiles[player] = nil
end

function PlayerStats.start()
	ProfileStore.SetConstant("AUTO_SAVE_PERIOD", SaveConfig.autoSaveSeconds)
	local realStore = ProfileStore.New(SaveData.storeName(SaveConfig, isStudio), template)
	store = if SaveData.useMock(TestSettings.enabled, isStudio) then realStore.Mock else realStore

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	-- Players who joined before this script ran (happens in Studio).
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlayerStats
