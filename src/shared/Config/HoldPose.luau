--!strict
-- How a character holds the weapon in the right hand while it is not throwing: always the same
-- pose, whether it stands, walks, jumps, falls or lands.
-- Made from code on every client (client/HoldPoseView), so no uploaded animation is needed.
-- Only the three joints of the right arm are set; the rest of the body keeps Roblox's own
-- animations. The throw animations always win over the pose.
--
-- Angles in degrees around the X, Y and Z axis of each joint of the right arm. 0, 0, 0 is the
-- arm hanging straight down with the weapon's tip pointing forward.
--   shoulder: x+ swings the arm forward and up, y- turns it outward, z+ lifts it away from the body
--   elbow: x+ bends the arm
--   wrist: x tilts the hand up and down, y- turns the tip outward
-- How the weapon itself sits in the hand is set per weapon (Config/Weapons, gripDegrees).

return {
	-- Arm a little bent in front of the body, blade pointing up at an angle and away from the body.
	arm = {
		shoulder = { x = 10, y = -15, z = 12 },
		elbow = { x = 40, y = 0, z = 0 },
		wrist = { x = 0, y = -10, z = 0 },
	},

	-- Time for the pose to let go of the arm when a throw starts. Must be shorter than the time
	-- until the weapon leaves the hand (Config/Animations).
	letGoSeconds = 0.1,
	-- Time for the arm to glide back into the pose after a throw, and when a weapon appears in
	-- the hand.
	returnSeconds = 0.3,
	-- Other players' characters further away from the camera than this are left alone, to save work
	-- on weak phones.
	maxDistance = 120,
}
