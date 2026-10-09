--!strict
-- Pure functions that turn the wall config into concrete walls.
-- Wall numbers start at 1. Wall 1 is the first wall of zone 1.

export type WallConfig = {
	materials: { string },
	wallsPerZone: number,
	firstHardness: number,
	growthInZone: number,
	jumpToNextZone: number,
	rewardPerHardness: number,
	zoneBonusFactor: number,
}

export type Wall = {
	index: number,
	zone: number,
	positionInZone: number,
	material: string,
	hardness: number,
	reward: number,
}

local Walls = {}

function Walls.count(config: WallConfig): number
	return #config.materials * config.wallsPerZone
end

-- Returns nil if the wall number does not exist.
function Walls.get(config: WallConfig, index: number): Wall?
	if index ~= index or index < 1 or index > Walls.count(config) or index % 1 ~= 0 then
		return nil
	end

	local zone = (index - 1) // config.wallsPerZone + 1
	local positionInZone = (index - 1) % config.wallsPerZone + 1

	-- Going from the first wall of one zone to the first wall of the next:
	-- (wallsPerZone - 1) growth steps plus one jump.
	local zoneStep = config.growthInZone ^ (config.wallsPerZone - 1) * config.jumpToNextZone
	local hardness = config.firstHardness * zoneStep ^ (zone - 1) * config.growthInZone ^ (positionInZone - 1)

	return {
		index = index,
		zone = zone,
		positionInZone = positionInZone,
		material = config.materials[zone],
		hardness = hardness,
		reward = hardness * config.rewardPerHardness,
	}
end

return Walls
