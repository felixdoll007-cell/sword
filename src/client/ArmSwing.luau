--!strict
-- A simple throwing movement of the right arm, made from code. No uploaded animation needed.
-- It only changes what THIS client draws (changes on the client are not sent on). To let others
-- see a throw, the server tells their clients, and each of them plays the swing on its own screen.
--
-- How: every frame, after Roblox's own animations have posed the character, the shoulder joint's
-- "Transform" is overwritten with our arm angle. When the swing is over, Roblox's animations take
-- over again by themselves.
-- Works with the new joints ("AnimationConstraint", Avatar Joint Upgrade) and the old ones
-- ("Motor6D"): both have Transform. R15 joint is "RightShoulder", R6 joint is "Right Shoulder".

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)

local ArmSwing = {}

type Joint = AnimationConstraint | Motor6D

local playing: { [Instance]: boolean } = {}

-- Returns the shoulder joint and how to turn the arm forward/up by an angle.
local function findShoulder(character: Model): (Joint?, ((number) -> CFrame)?)
	local r15 = character:FindFirstChild("RightShoulder", true)
	if r15 and (r15:IsA("AnimationConstraint") or r15:IsA("Motor6D")) then
		return r15, function(angle: number)
			return CFrame.Angles(angle, 0, 0)
		end
	end
	local torso = character:FindFirstChild("Torso")
	local r6 = torso and torso:FindFirstChild("Right Shoulder")
	if r6 and r6:IsA("Motor6D") then
		return r6, function(angle: number)
			return CFrame.Angles(0, 0, angle)
		end
	end
	return nil, nil
end

-- Arm angle (radians) at a time of the swing, or nil when the swing is over.
-- 0 = arm hanging down, 90 degrees = pointing forward, 180 = straight up, more = behind the head.
local function angleAt(time: number): number?
	local v = ThrowVisuals
	local windUp = math.rad(v.armWindUpDegrees)
	local release = math.rad(v.armReleaseDegrees)
	if time < v.armWindUpSeconds then
		return windUp * (time / v.armWindUpSeconds)
	end
	time -= v.armWindUpSeconds
	if time < v.armThrowSeconds then
		return windUp + (release - windUp) * (time / v.armThrowSeconds)
	end
	time -= v.armThrowSeconds
	if time < v.armReturnSeconds then
		return release * (1 - time / v.armReturnSeconds)
	end
	return nil
end

-- Seconds from the start of the swing until the arm has come forward: the moment to let go.
function ArmSwing.releaseDelay(): number
	return ThrowVisuals.armWindUpSeconds + ThrowVisuals.armThrowSeconds
end

-- Seconds the whole swing takes, from its start until the arm hangs down again.
function ArmSwing.duration(): number
	return ThrowVisuals.armWindUpSeconds + ThrowVisuals.armThrowSeconds + ThrowVisuals.armReturnSeconds
end

-- Plays the swing on a character. Without one, on this player's own character.
function ArmSwing.play(ofCharacter: Model?)
	local character = ofCharacter or Players.LocalPlayer.Character
	if not character then
		return
	end
	local found, turn = findShoulder(character)
	if not found or not turn or playing[found] then
		return
	end
	local joint: Joint = found
	local rotate: (number) -> CFrame = turn

	playing[joint] = true
	local elapsed = 0
	local connection: RBXScriptConnection
	-- PreSimulation runs after Roblox's animations have set the pose for this frame.
	connection = RunService.PreSimulation:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local angle = angleAt(elapsed)
		if angle == nil or not joint.Parent then
			connection:Disconnect()
			playing[joint] = nil
			-- Back to the neutral pose; Roblox's animations continue from there.
			joint.Transform = CFrame.identity
			return
		end
		joint.Transform = rotate(angle)
	end)
end

return ArmSwing
