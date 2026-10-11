--!strict
-- Pure functions for the ground of the whole map: big plain tiles lying next to each other,
-- far beyond everything a player can reach, so no end of the world is seen. Only looks.
-- A part in Roblox can be at most 2048 studs wide, so a big ground is laid from several tiles.

export type GroundConfig = {
	-- Edge length of one tile.
	tileStuds: number,
	-- The ground is this many tiles wide and long.
	tilesPerSide: number,
	-- Middle of the ground.
	centerX: number,
	centerZ: number,
	-- Height of its surface, and how thick it is.
	topY: number,
	thickness: number,
}

-- One tile: its middle and its size. size is along X and along Z.
export type Tile = { x: number, y: number, z: number, size: number, thickness: number }

local Ground = {}

-- The tiles of the ground, in rows. They touch but never overlap.
function Ground.tiles(config: GroundConfig): { Tile }
	local count = math.max(math.floor(config.tilesPerSide), 0)
	local size = math.max(config.tileStuds, 0)
	local tiles: { Tile } = {}
	if count == 0 or size == 0 then
		return tiles
	end
	local first = -(count - 1) / 2
	for row = 0, count - 1 do
		for column = 0, count - 1 do
			table.insert(tiles, {
				x = config.centerX + (first + column) * size,
				y = config.topY - config.thickness / 2,
				z = config.centerZ + (first + row) * size,
				size = size,
				thickness = config.thickness,
			})
		end
	end
	return tiles
end

-- How far the ground reaches: smallest and biggest X and Z.
function Ground.bounds(config: GroundConfig): (number, number, number, number)
	local half = math.max(math.floor(config.tilesPerSide), 0) * math.max(config.tileStuds, 0) / 2
	return config.centerX - half, config.centerX + half, config.centerZ - half, config.centerZ + half
end

return Ground
