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
local SaveConfig = require(Shared.Config.Save)
local StrengthConfig = require(Shared.Config.Strength)
local TestSettings = require(Shared.Config.TestSettings)
local Rebirth = require(Shared.Rules.Rebirth)
local Rewards = require(Shared.Rules.Rewards)
local SaveData = require(Shared.Rules.SaveData)
local StartValues = require(Shared.Rules.StartValues)

local ProfileStore = require(script.Parent.Packages.ProfileStore) :: any

local PlayerStats = {}

local isStudio = RunService:IsStudio()
local template = SaveData.template(SaveConfig, StartValues.startStrength(StrengthConfig, TestSettings, isStudio))

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
	end
end

function PlayerStats.getStrength(player: Player): number?
	local values = data(player)
	return if values then values.strength else nil
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
	local repaired = SaveData.repair(SaveConfig, profile.Data, template)
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
