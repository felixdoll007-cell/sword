--!strict
-- Training lanes: pads next to the throw zone, each with a short lane and one or more walls.
-- How much strength a training throw gives before multipliers, and how often, is in Config/Strength.
-- Lengths in studs, colors as { red, green, blue } from 0 to 255.

return {
	-- The lanes from right (next to the throw zone) to left.
	-- requiredRebirths: rebirths needed to train here. Whether a lane is unlocked is always
	--   calculated from the player's rebirths, never saved.
	-- multiplier: strength per training throw is multiplied by this (on top of the rebirth multiplier).
	-- walls: how many walls a training throw breaks. Only looks, more walls for better lanes.
	lanes = {
		{ requiredRebirths = 0, multiplier = 1, walls = 1 },
		{ requiredRebirths = 2, multiplier = 4, walls = 2 },
		{ requiredRebirths = 4, multiplier = 10, walls = 3 },
		{ requiredRebirths = 6, multiplier = 20, walls = 4 },
	},

	-- The pad of lane 1: center and size on the ground, left of the throw zone.
	-- Small, because the player snaps to its center and does not walk around on it.
	pad = { x = -45, z = 7, width = 8, length = 8 },
	-- Each further lane lies this far to the left of the one before (center to center).
	laneSpacing = 16,
	-- Extra room around a pad for the position check (standing on the edge, lag).
	padTolerance = 0.5,
	padColor = { 85, 85, 85 },

	-- Short lane in front of each pad, running towards negative Z like the main lane.
	laneLength = 60,
	laneColor = { 120, 120, 120 },
	-- Distance from the front edge of the pad to the first wall, and between two walls.
	wallDistance = 24,
	wallSpacing = 8,
	wallHeight = 10,
	wallThickness = 1.5,
	wallColor = { 235, 235, 235 },

	-- Sign above each lane with its multiplier and what it needs. Built on the client,
	-- because "LOCKED" depends on the rebirths of the player looking at it.
	sign = {
		-- Bottom edge above the floor, size of the board.
		heightAboveFloor = 12,
		boardHeight = 7,
		boardThickness = 0.4,
		boardColor = { 40, 40, 40 },
		textColor = { 255, 255, 255 },
		lockedTextColor = { 230, 90, 90 },
		-- %s is replaced by the lane's multiplier.
		multiplierText = "x%s",
		-- %s is replaced by the rebirths needed. For a lane that needs none: freeText.
		requirementText = "%s Rebirths",
		freeText = "FREE",
		lockedText = "LOCKED",
		-- Three lines from top to bottom: multiplier, requirement, LOCKED (empty when unlocked).
		-- Share of the board height for each line.
		lineHeights = { 0.44, 0.28, 0.28 },
	},

	-- Server: how often it looks who is standing on a pad.
	checkSeconds = 0.1,

	-- Client comfort: stepping on an unlocked pad snaps the character to the pad center, facing the wall.
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
	-- Time for the sword to reach the last wall of the lane.
	flightSeconds = 0.35,
	-- A broken wall stands again after this time.
	wallBackSeconds = 0.3,
	-- Pieces per broken wall. All pieces in the game share one cap (Config/ThrowVisuals).
	piecesPerWall = 2,
	pieceSize = 1.5,
}
