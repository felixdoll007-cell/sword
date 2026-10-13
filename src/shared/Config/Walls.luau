--!strict
-- Settings for the walls on the main lane. Walls are not listed one by one:
-- every wall is calculated from these values (see Rules/Walls).

return {
	-- One zone per material, in this order. World 1 is a dojo in Japan. The names only tell the
	-- zones apart and choose their look; how hard a wall is depends on its number alone.
	materials = { "Paper", "Bamboo", "Wood", "Stone", "Iron", "Jade" },
	wallsPerZone = 5,

	-- Hardness of the very first wall.
	firstHardness = 5,
	-- Each wall inside a zone is this many times harder than the one before.
	growthInZone = 1.3,
	-- The first wall of a new zone is this many times harder than the last wall of the previous zone.
	jumpToNextZone = 2.5,

	-- Currency for breaking a wall = hardness * rewardPerHardness.
	rewardPerHardness = 0.2,
	-- Breaking a whole zone gives a bonus = reward of the zone's last wall * zoneBonusFactor.
	zoneBonusFactor = 2,
}
