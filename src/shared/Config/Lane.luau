--!strict
-- Size and layout of the throw zone and the main lane. All lengths in studs.
-- The lane starts at the throw line and runs in the direction of negative Z.
-- Colors are { red, green, blue } from 0 to 255. The lanes are still grey; the look of the
-- throw zone and of the floor around it is in Config/Ui (world).

return {
	-- Middle of the throw line, on the ground.
	throwLine = { x = 0, z = 0 },

	-- Everything players walk on (throw zone, training lanes, shop) must lie within this distance
	-- of the middle of the map. The green ground itself reaches much further (Config/Ui, world.ground).
	groundHalfSize = 256,

	floorTopY = 0.1,
	floorThickness = 1,
	laneWidth = 30,

	-- The throw zone lies behind the throw line, the player stands here.
	throwZoneLength = 20,

	-- Distance from the throw line to wall 1.
	firstWallDistance = 30,
	-- Distance between two walls of the same zone.
	wallSpacing = 20,
	-- Extra distance before the first wall of a new zone, so zones are easy to tell apart.
	zoneGap = 40,
	-- Floor behind the last wall.
	endPadding = 30,

	wallHeight = 16,
	wallThickness = 2,

	-- Invisible barriers on the throw line and along both sides, so players cannot walk onto the lane.
	barrierHeight = 20,
	barrierThickness = 1,

	floorColor = { 120, 120, 120 },
	-- One grey per material, from light (Paper) to dark (Jade), for zones without a look yet.
	materialColors = {
		Paper = { 235, 235, 235 },
		Bamboo = { 200, 200, 200 },
		Wood = { 165, 165, 165 },
		Stone = { 130, 130, 130 },
		Iron = { 85, 85, 85 },
		Jade = { 45, 45, 45 },
	},
}
