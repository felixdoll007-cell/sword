local Ground = require("../src/shared/Rules/Ground")
local LaneLayout = require("../src/shared/Rules/LaneLayout")
local ThrowZoneLayout = require("../src/shared/Rules/ThrowZoneLayout")
local ZoneLook = require("../src/shared/Rules/ZoneLook")
local LaneConfig = require("../src/shared/Config/Lane")
local WallConfig = require("../src/shared/Config/Walls")
local WeaponConfig = require("../src/shared/Config/Weapons")
local Weapons = require("../src/shared/Rules/Weapons")
local Ui = require("../src/shared/Config/Ui")

local world = Ui.world
local ground = world.ground
-- The biggest part Roblox allows.
local MAX_PART_STUDS = 2048
-- From this far away the haze must have room to hide the end of the ground.
local FADE_ROOM_STUDS = 1000

local function isColor(value: any): boolean
	if typeof(value) ~= "table" or #value ~= 3 then
		return false
	end
	for _, part in value do
		if typeof(part) ~= "number" or part < 0 or part > 255 then
			return false
		end
	end
	return true
end

return {
	["the ground is laid from big tiles that touch and never overlap"] = function(expect)
		local tiles = Ground.tiles(ground)
		expect(#tiles).toBe(ground.tilesPerSide * ground.tilesPerSide)
		for index, tile in tiles do
			expect(tile.size <= MAX_PART_STUDS).toBe(true)
			expect(tile.y + tile.thickness / 2).toBeNear(ground.topY)
			for other = index + 1, #tiles do
				local b = tiles[other]
				local overlapX = math.min(tile.x + tile.size / 2, b.x + b.size / 2)
					- math.max(tile.x - tile.size / 2, b.x - b.size / 2)
				local overlapZ = math.min(tile.z + tile.size / 2, b.z + b.size / 2)
					- math.max(tile.z - tile.size / 2, b.z - b.size / 2)
				expect(overlapX > 0.001 and overlapZ > 0.001).toBe(false)
			end
		end
		-- Together they fill the whole outline: no gaps.
		local minX, maxX, minZ, maxZ = Ground.bounds(ground)
		local area = 0
		for _, tile in tiles do
			area += tile.size * tile.size
			expect(tile.x - tile.size / 2 >= minX - 0.001 and tile.x + tile.size / 2 <= maxX + 0.001).toBe(true)
			expect(tile.z - tile.size / 2 >= minZ - 0.001 and tile.z + tile.size / 2 <= maxZ + 0.001).toBe(true)
		end
		expect(area).toBeNear((maxX - minX) * (maxZ - minZ))
	end,

	["the ground reaches far beyond everything a player can see up close"] = function(expect)
		local minX, maxX, minZ, maxZ = Ground.bounds(ground)
		-- The whole lane, the throw zone and the area players walk in, with room for the haze.
		local laneEnd = LaneConfig.throwLine.z - LaneLayout.laneLength(LaneConfig, WallConfig)
		expect(minZ <= laneEnd - FADE_ROOM_STUDS).toBe(true)
		expect(maxZ >= LaneConfig.groundHalfSize + FADE_ROOM_STUDS).toBe(true)
		expect(minX <= -LaneConfig.groundHalfSize - FADE_ROOM_STUDS).toBe(true)
		expect(maxX >= LaneConfig.groundHalfSize + FADE_ROOM_STUDS).toBe(true)
	end,

	["no floor lies on the ground at almost the same height"] = function(expect)
		-- Floors lie at floorTopY. Two surfaces on top of each other need at least 0.2 studs.
		expect(LaneConfig.floorTopY - ground.topY >= 0.2).toBe(true)
		-- The floors are thick enough to reach down into the ground: no gap shows below them.
		expect(LaneConfig.floorTopY - LaneConfig.floorThickness < ground.topY).toBe(true)
	end,

	["broken ground values give no tiles instead of an error"] = function(expect)
		local none = table.clone(ground)
		none.tilesPerSide = 0
		expect(#Ground.tiles(none)).toBe(0)
		none.tilesPerSide = -3
		expect(#Ground.tiles(none)).toBe(0)
		none.tilesPerSide = 2
		none.tileStuds = 0
		expect(#Ground.tiles(none)).toBe(0)
		local one = table.clone(ground)
		one.tilesPerSide = 1
		local tiles = Ground.tiles(one)
		expect(#tiles).toBe(1)
		expect(tiles[1].x).toBe(ground.centerX)
		expect(tiles[1].z).toBe(ground.centerZ)
	end,

	["the ground is a calm green close to the green at the throw zone"] = function(expect)
		expect(isColor(ground.color)).toBe(true)
		local green = world.surroundings
		for channel = 1, 3 do
			local low = math.min(green.darkColor[channel], green.lightColor[channel]) - 10
			local high = math.max(green.darkColor[channel], green.lightColor[channel]) + 10
			expect(ground.color[channel] >= low and ground.color[channel] <= high).toBe(true)
		end
	end,

	["all shop pedestals stand on the green floor at the throw zone, clear of the walkways"] = function(_expect)
		local walkWidth = ZoneLook.walkWidthAtThrowZone(LaneConfig, WallConfig, world.lane)
		local pieces = ThrowZoneLayout.surroundings(LaneConfig, world.surroundings, walkWidth)
		local half = WeaponConfig.shop.pedestalWidth / 2
		for index = 1, Weapons.count(WeaponConfig) do
			local position = Weapons.pedestalPosition(WeaponConfig, index)
			local standsOnGreen = false
			for _, piece in pieces do
				local inside = position.x - half >= piece.x - piece.width / 2
					and position.x + half <= piece.x + piece.width / 2
					and position.z - half >= piece.z - piece.length / 2
					and position.z + half <= piece.z + piece.length / 2
				standsOnGreen = standsOnGreen or inside
			end
			if not standsOnGreen then
				error(`pedestal {index} does not stand on the green floor`)
			end
			for zone in WallConfig.materials do
				for _, part in ZoneLook.walks(LaneConfig, WallConfig, world.lane, zone) do
					local area = part.area
					local overlaps = position.x - half < area.x + area.width / 2
						and position.x + half > area.x - area.width / 2
						and position.z - half < area.z + area.length / 2
						and position.z + half > area.z - area.length / 2
					if overlaps then
						error(`pedestal {index} stands in a walkway`)
					end
				end
			end
		end
	end,

	["the start mood exists and every mood is complete"] = function(expect)
		expect(typeof(world.moods[world.startMood])).toBe("table")
		for name, mood in world.moods :: { [string]: any } do
			for _, key in
				{
					"clockTime",
					"latitude",
					"brightness",
					"exposure",
					"shadowSoftness",
					"environmentLight",
					"environmentShine",
				}
			do
				if typeof(mood[key]) ~= "number" then
					error(`mood {name}: {key} is missing`)
				end
			end
			for _, key in { "shadowLight", "skyLight", "sunTint", "shadeTint" } do
				if not isColor(mood[key]) then
					error(`mood {name}: {key} is not a color`)
				end
			end
			expect(mood.clockTime >= 0 and mood.clockTime <= 24).toBe(true)
			expect(mood.brightness > 0).toBe(true)
			expect(mood.shadowSoftness >= 0 and mood.shadowSoftness <= 1).toBe(true)
			-- Haze: within what Roblox accepts.
			expect(mood.haze.density >= 0 and mood.haze.density <= 1).toBe(true)
			expect(mood.haze.offset >= 0 and mood.haze.offset <= 1).toBe(true)
			expect(mood.haze.horizon >= 0 and mood.haze.horizon <= 10).toBe(true)
			expect(mood.haze.glare >= 0 and mood.haze.glare <= 10).toBe(true)
			expect(isColor(mood.haze.color) and isColor(mood.haze.sunsetColor)).toBe(true)
			expect(mood.sky.sunSize >= 0 and mood.sky.moonSize >= 0 and mood.sky.stars >= 0).toBe(true)
			expect(mood.glow.intensity >= 0 and mood.glow.size >= 0 and mood.glow.threshold >= 0).toBe(true)
			expect(math.abs(mood.color.saturation) <= 1 and math.abs(mood.color.contrast) <= 1).toBe(true)
			expect(isColor(mood.color.tint)).toBe(true)
		end
	end,

	["the afternoon is bright: the sun is up and the shadows are lit"] = function(expect)
		local mood = world.moods.afternoon
		expect(mood.clockTime > 12 and mood.clockTime < 17).toBe(true)
		-- Nothing sinks into black: the light in the shadows is at least mid grey.
		for _, value in mood.shadowLight do
			expect(value >= 110).toBe(true)
		end
		-- There is haze, so the distance fades.
		expect(mood.haze.density > 0.1).toBe(true)
	end,
}
