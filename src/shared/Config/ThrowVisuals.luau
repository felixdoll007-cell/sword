--!strict
-- How the throw looks on the client: sword, camera, wall pieces, bounce.
-- Lengths in studs, colors as { red, green, blue } from 0 to 255.

return {
	-- Sword made of three simple parts. The tip points along the lane.
	bladeLength = 5,
	bladeWidth = 0.8,
	bladeThickness = 0.2,
	guardWidth = 2.2,
	guardThickness = 0.4,
	handleLength = 1.6,
	handleThickness = 0.4,
	bladeColor = { 210, 210, 215 },
	handleColor = { 70, 70, 70 },
	-- Height of the flying sword above the floor.
	swordHeight = 5,

	-- Camera behind and above the sword, looking a bit ahead of it.
	cameraBehind = 16,
	cameraAbove = 7,
	cameraLookAhead = 12,
	-- Time for the camera to glide from the player to behind the sword.
	cameraBlendInSeconds = 0.4,

	-- Pieces of a broken wall. Kept low so weak phones run smoothly.
	piecesPerWall = 4,
	maxActivePieces = 40,
	pieceSize = 2.5,
	pieceLifetimeSeconds = 1.5,
	pieceForwardSpeed = 30,
	pieceSideSpeed = 12,
	pieceUpSpeed = 18,

	-- Bounce off the wall that is too hard.
	bounceBackDistance = 6,
	bounceSpinDegrees = 270,
	-- While bouncing, the camera pulls back by this much so sword, wall and scratch are in view.
	bounceCameraExtraBehind = 14,
	bounceCameraExtraAbove = 4,
	-- Scratch left on the wall the sword bounced off.
	scratchLength = 3,
	scratchWidth = 0.4,
	scratchTiltDegrees = 25,
	scratchColor = { 30, 30, 30 },

	-- Every wall broke: the sword tilts down and sticks in the ground.
	stuckTiltDegrees = 60,
	stuckDepth = 1.5,

	-- Safety: if a throw has not ended this many seconds after its planned end, it is ended anyway.
	safetyExtraSeconds = 2,
}
