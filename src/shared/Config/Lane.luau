--!strict
-- Size and layout of the throw zone and the main lane. All lengths in studs.
-- The lane starts at the throw line and runs in the direction of negative Z.
-- Colors are { red, green, blue } from 0 to 255. Version 1 is all grey.

return {
	-- Middle of the throw line, on the ground.
	throwLine = { x = 0, z = 0 },

	floorTopY = 0.1,
	floorThickness = 1,
	laneWidth = 30,

	-- The throw zone lies behind the throw line, the player stands here.
	throwZoneLength = 20,

	-- Distance from the throw line to wall 1.
	firstWallDistance = 30,
	-- Distance between two walls of the same zone.
	wallSpacing = 16,
	-- Extra distance before the first wall of a new zone, so zones are easy to tell apart.
	zoneGap = 24,
	-- Floor behind the last wall.
	endPadding = 30,

	wallHeight = 16,
	wallThickness = 2,

	floorColor = { 120, 120, 120 },
	throwZoneColor = { 90, 90, 90 },
	-- One grey per material, from light (Paper) to dark (Bedrock).
	materialColors = {
		Paper = { 235, 235, 235 },
		Wood = { 200, 200, 200 },
		Stone = { 165, 165, 165 },
		Iron = { 130, 130, 130 },
		Obsidian = { 85, 85, 85 },
		Bedrock = { 45, 45, 45 },
	},
}
