--!strict
-- How a character holds the weapon in the right hand while it is not throwing.
-- Made from code on every client (client/HoldPoseView), so no uploaded animation is needed.
-- The throw animations always win over these poses.
--
-- Angles in degrees around the X, Y and Z axis of each joint of the right arm. 0, 0, 0 is the
-- arm hanging straight down with the weapon's tip pointing forward.
--   shoulder: x+ swings the arm forward and up, y- turns it outward, z+ lifts it away from the body
--   elbow: x+ bends the arm, y turns the forearm around itself (180 or -180 = the tip points
--     backward; with -180 the blade swings around on the outside, with 180 through the body)
--   wrist: x tilts the hand up and down (after the forearm is turned around: x- tilts the tip down),
--     y- turns the tip outward
-- How the weapon itself sits in the hand is set per weapon (Config/Weapons, gripDegrees).

return {
	-- Standing: arm a little bent, blade pointing up at an angle and away from the body.
	standing = {
		shoulder = { x = 10, y = -15, z = 12 },
		elbow = { x = 40, y = 0, z = 0 },
		wrist = { x = 0, y = -10, z = 0 },
	},

	-- Walking: arm out to the side, blade pointing backward and down. The body leans forward
	-- while walking, which lifts the blade; the tip must still stay above the floor with the
	-- longest weapon.
	walking = {
		shoulder = { x = -10, y = 0, z = 15 },
		elbow = { x = 20, y = -180, z = 0 },
		wrist = { x = -19, y = 0, z = 0 },
	},

	-- From this speed over the ground on (studs per second) the walking pose is used.
	walkingMinSpeed = 2,
	-- Time to change between the standing and the walking pose.
	blendSeconds = 0.2,
	-- Halfway through that change the arm is lifted this many degrees further out to the side.
	-- The blade turns around on the outside, so the handle end turns on the inside; with a long
	-- handle (the axe) it would pass through the hip otherwise.
	blendSideDegrees = 30,
	-- Time for the pose to let go of the arm when a throw starts, and to take it back afterwards.
	throwBlendSeconds = 0.1,
	-- Characters further away from the camera than this are left alone, to save work on weak phones.
	maxDistance = 120,
}
