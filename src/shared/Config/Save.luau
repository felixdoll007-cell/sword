--!strict
-- Saving player data. Nothing secret here: the client may read this file.

return {
	-- Name of the data store. In Studio the suffix is added, so tests in Studio never touch
	-- the data of real players, even if Studio access is switched on by mistake.
	storeName = "PlayerData",
	studioSuffix = "_Studio",

	-- Key of one player's data inside the store.
	keyPrefix = "Player_",

	-- Version of the saved data. Raise it when the meaning of a field changes,
	-- and add a conversion in Rules/SaveData.
	dataVersion = 1,

	-- Save every player's data in the background at least this often (seconds).
	autoSaveSeconds = 60,

	-- Shown when a player's data cannot be loaded. The player is sent out instead of
	-- playing with empty data, which would later overwrite the real data.
	loadFailedMessage = "Your progress could not be loaded. Please rejoin in a moment.",
	-- Shown when the same account joined another server, which now owns the data.
	sessionEndedMessage = "Your progress is now used on another server. Please rejoin.",
}
