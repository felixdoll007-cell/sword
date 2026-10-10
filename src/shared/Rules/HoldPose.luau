--!strict
-- Pure functions for how a character holds the weapon while not throwing: which pose applies,
-- and how one pose glides into the other.

export type Angles = { x: number, y: number, z: number }

export type ArmPose = {
	shoulder: Angles,
	elbow: Angles,
	wrist: Angles,
}

export type HoldConfig = {
	standing: ArmPose,
	walking: ArmPose,
	walkingMinSpeed: number,
	blendSeconds: number,
	blendSideDegrees: number,
	throwBlendSeconds: number,
}

local HoldPose = {}

-- Is a character moving over the ground fast enough for the walking pose? Broken speeds are not.
function HoldPose.isWalking(config: HoldConfig, groundSpeed: number): boolean
	return groundSpeed >= config.walkingMinSpeed
end

-- Moves a share (0 to 1) toward its target. Going all the way from 0 to 1 takes `seconds`.
function HoldPose.approach(current: number, target: number, deltaTime: number, seconds: number): number
	local goal = math.clamp(target, 0, 1)
	if goal ~= goal then
		goal = 0
	end
	if seconds <= 0 or current ~= current then
		return goal
	end
	if deltaTime ~= deltaTime or deltaTime <= 0 then
		return math.clamp(current, 0, 1)
	end
	local step = deltaTime / seconds
	if current < goal then
		return math.min(current + step, goal)
	end
	return math.max(current - step, goal)
end

-- Makes a share start and stop gently instead of abruptly. 0 stays 0, 1 stays 1.
function HoldPose.ease(share: number): number
	local s = math.clamp(share, 0, 1)
	if s ~= s then
		return 0
	end
	return s * s * (3 - 2 * s)
end

-- How many degrees the arm is lifted further out to the side while it changes between the two
-- poses: nothing at share 0 and 1, the full amount halfway.
function HoldPose.sideSwing(config: HoldConfig, share: number): number
	local s = math.clamp(share, 0, 1)
	if s ~= s then
		return 0
	end
	return config.blendSideDegrees * 4 * s * (1 - s)
end

-- The angles between two poses of one joint: share 0 is `from`, share 1 is `to`.
-- Every angle is mixed on its own, so a turn of 180 degrees always goes around the same way.
-- Returns x, y, z in degrees (three numbers instead of a table: this runs every frame).
function HoldPose.mix(from: Angles, to: Angles, share: number): (number, number, number)
	local s = math.clamp(share, 0, 1)
	if s ~= s then
		s = 0
	end
	return from.x + (to.x - from.x) * s, from.y + (to.y - from.y) * s, from.z + (to.z - from.z) * s
end

return HoldPose
