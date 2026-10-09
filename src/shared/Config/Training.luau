--!strict
-- Training lane 1: a pad next to the throw zone and a short lane with one wall.
-- How much strength a training throw gives and how often is in Config/Strength.
-- Lengths in studs, colors as { red, green, blue } from 0 to 255.

return {
	-- The pad the player stands on. Center and size on the ground, left of the throw zone.
	-- Small, because the player snaps to its center and does not walk around on it.
	pad = { x = -45, z = 7, width = 8, length = 8 },
	-- Extra room around the pad for the position check (standing on the edge, lag).
	padTolerance = 0.5,
	padColor = { 85, 85, 85 },

	-- Short lane in front of the pad, running towards negative Z like the main lane.
	laneLength = 40,
	laneColor = { 120, 120, 120 },
	-- Distance from the front edge of the pad to the wall.
	wallDistance = 24,
	wallHeight = 10,
	wallThickness = 1.5,
	wallColor = { 235, 235, 235 },

	-- Server: how often it looks who is standing on the pad.
	checkSeconds = 0.1,

	-- Client comfort: stepping on the pad snaps the character to the pad center, facing the wall.
	-- To leave, hold a direction this long (a short tap does not count) or jump.
	leaveHoldSeconds = 0.3,
	-- How far the stick or keys must be pushed (0 to 1) to count as "holding a direction".
	leaveInputThreshold = 0.3,
	-- Server: at most this many "training left" messages per player within the time window.
	maxLeaveMessages = 3,
	leaveMessageWindowSeconds = 2,

	-- Client animation of a training throw. Must be shorter than the time between two throws.
	swordScale = 0.6,
	swordHeight = 3,
	flightSeconds = 0.35,
	-- The broken wall stands again after this time.
	wallBackSeconds = 0.3,
	piecesPerThrow = 2,
	pieceSize = 1.5,
}
