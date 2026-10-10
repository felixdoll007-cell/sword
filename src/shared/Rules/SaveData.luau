--!strict
-- Pure functions for saved player data: what a new save looks like, how old or broken
-- saves are repaired, and which store is used where.

local TestMode = require("./TestMode")

export type SaveConfig = {
	storeName: string,
	studioSuffix: string,
	keyPrefix: string,
	dataVersion: number,
}

-- Everything that is saved per player. Fields are only added when the feature exists
-- (pets come in a later version). A new field with a default value needs no new data version:
-- old saves simply get the default when they are loaded.
export type Data = {
	version: number,
	strength: number,
	currency: number,
	-- Number of walls broken in the best main throw so far.
	bestWall: number,
	-- os.time() when the player last left. 0 = never.
	lastLeftAt: number,
	-- Number of rebirths done. Added in Version 2; older saves load with 0.
	rebirths: number,
}

local SaveData = {}

function SaveData.template(config: SaveConfig, startStrength: number): Data
	return {
		version = config.dataVersion,
		strength = startStrength,
		currency = 0,
		bestWall = 0,
		lastLeftAt = 0,
		rebirths = 0,
	}
end

function SaveData.storeName(config: SaveConfig, isStudio: boolean): string
	if isStudio then
		return config.storeName .. config.studioSuffix
	end
	return config.storeName
end

function SaveData.key(config: SaveConfig, userId: number): string
	return config.keyPrefix .. tostring(userId)
end

-- Raised test values must never end up in a real save. With test values on, nothing is saved.
function SaveData.useMock(testValuesEnabled: boolean, isStudio: boolean): boolean
	return TestMode.isOn(testValuesEnabled, isStudio)
end

local function isUsableNumber(value: unknown): boolean
	return typeof(value) == "number" and value == value and value >= 0 and value ~= math.huge
end

-- Repairs loaded data: fills missing fields, replaces broken values with the template value,
-- converts older versions. Returns a clean copy; the input is not changed.
function SaveData.repair(config: SaveConfig, loaded: { [string]: unknown }, template: Data): Data
	local function number(field: string): number
		local value = loaded[field]
		if isUsableNumber(value) then
			return value :: number
		end
		return (template :: any)[field]
	end

	-- Version 1 is the first version, so there is nothing to convert yet. Conversions for
	-- later versions go here, oldest first.

	return {
		version = config.dataVersion,
		strength = number("strength"),
		currency = number("currency"),
		bestWall = number("bestWall"),
		lastLeftAt = number("lastLeftAt"),
		-- Always a whole number.
		rebirths = math.floor(number("rebirths")),
	}
end

return SaveData
