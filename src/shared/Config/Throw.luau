--!strict
-- Settings for the main throw: server checks and the timing of the flight.
-- Looks (sword, camera, pieces) are in Config/ThrowVisuals.

local Animations = require("./Animations")

return {
	-- Server: at most this many throw requests per player within the time window. More are ignored.
	maxThrowRequests = 3,
	requestWindowSeconds = 2,
	-- Server: extra room around the throw zone for the position check (lag, standing on the edge).
	throwZoneTolerance = 4,

	-- Flight speed in studs per second. Speed = slowestSpeed * (power left / hardness of the next wall),
	-- but never slower than slowestSpeed and never faster than fastestSpeed.
	slowestSpeed = 40,
	fastestSpeed = 450,

	-- Before the flight: the character winds up and throws. The weapon leaves the hand after this
	-- time. It is the release moment of the throw animation, kept in one place (Config/Animations).
	windUpSeconds = Animations.mainThrow.releaseSeconds,

	-- The flight is stretched or squeezed to fit between these two durations.
	minFlightSeconds = 1.2,
	maxFlightSeconds = 4,

	-- After the flight: bouncing off the wall that is too hard ...
	bounceSeconds = 1.2,
	-- ... or, if every wall broke, the sword stuck in the ground at the end of the lane.
	stuckSeconds = 1.5,
	stuckDistanceFromLaneEnd = 10,
}
