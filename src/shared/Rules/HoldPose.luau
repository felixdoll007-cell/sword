--!strict
-- Pure functions for how a character holds the weapon while not throwing: how the pose lets go
-- of the arm for a throw and glides back in afterwards.

export type Angles = { x: number, y: number, z: number }

export type ArmPose = {
	shoulder: Angles,
	elbow: Angles,
	wrist: Angles,
}

export type HoldConfig = {
	arm: ArmPose,
	letGoSeconds: number,
	returnSeconds: number,
}

local HoldPose = {}

-- How much of the arm the pose has after this frame. 0 = Roblox's animations alone, 1 = fully the pose.
-- wanted: should the pose hold the arm right now (a weapon is in the hand and no throw is playing)?
-- Letting go and coming back each take their own time from the config.
function HoldPose.nextShare(config: HoldConfig, share: number, wanted: boolean, deltaTime: number): number
	local goal = if wanted then 1 else 0
	local seconds = if wanted then config.returnSeconds else config.letGoSeconds
	if seconds <= 0 or share ~= share then
		return goal
	end
	local current = math.clamp(share, 0, 1)
	if deltaTime ~= deltaTime or deltaTime <= 0 then
		return current
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

return HoldPose
