-- Builds the first version of the two throw animations and the rig they belong to.
-- This is NOT game code. It is run once in Studio in edit mode (through the Studio MCP),
-- and creates in the place:
--   ReplicatedStorage.Assets.ThrowAnimationRig              a plain R15 figure
--   ReplicatedStorage.Assets.ThrowAnimationRig.AnimSaves    with the animations ThrowMain and ThrowTraining
--
-- After that the animations are reworked in Studio's animation editor and uploaded; from then on
-- the uploaded versions are the real ones and this file is only where they started.
-- The times of the "Release" marker must match Config/Animations.
--
-- How the joints turn (measured on an R15 character):
--   Root, Waist, Neck: Y+ turns to the LEFT, X+ leans BACK
--   Shoulder: X+ swings the arm forward and up (180 = straight up, more = behind the head), Z+ lifts it sideways
--   Elbow: X+ bends the arm
--   Wrist: X+ turns the hand the same way as the shoulder. The weapon's tip points forward when
--     shoulder + elbow + wrist add up to 0 (or 360). At the release the wrist is turned back so far
--     that the tip points forward, like the flying weapon does.
--   Hip: X+ swings the leg forward

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RIG_NAME = "ThrowAnimationRig"
local SAVES_NAME = "AnimSaves"
local RELEASE_MARKER = "Release"

-- Which part hangs on which, as far as the animations use them.
local PARENT_OF = {
	LowerTorso = "HumanoidRootPart",
	UpperTorso = "LowerTorso",
	Head = "UpperTorso",
	RightUpperArm = "UpperTorso",
	RightLowerArm = "RightUpperArm",
	RightHand = "RightLowerArm",
	LeftUpperArm = "UpperTorso",
	LeftLowerArm = "LeftUpperArm",
	RightUpperLeg = "LowerTorso",
	LeftUpperLeg = "LowerTorso",
}
-- Order matters: a part must come after the part it hangs on.
local ORDER = {
	"LowerTorso",
	"UpperTorso",
	"Head",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperArm",
	"LeftLowerArm",
	"RightUpperLeg",
	"LeftUpperLeg",
}

-- The parts each animation moves. Every other part is left to Roblox's own animations (standing,
-- walking). A part that is in an animation without being turned is still held in its plain rest
-- pose by it: that is how the training throw used to pull the legs back a little on every throw.
-- The main throw moves the whole body.
local MAIN_PARTS = ORDER
-- The training throw only moves the upper body and the right arm. Hips, legs and the left arm
-- are not in it.
local TRAINING_PARTS = { "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "RightHand" }

-- Angles in degrees { x, y, z } per part. Parts not listed in a keyframe stay in their rest pose.
type Angles = { number }
type KeyframeSpec = { time: number, marker: string?, poses: { [string]: Angles } }

local MAIN_THROW: { KeyframeSpec } = {
	{ time = 0, poses = {} },
	-- Wind up: body turns to the right, leans back a little, arm goes up behind the head.
	{
		time = 0.3,
		poses = {
			LowerTorso = { 0, -20, 0 },
			UpperTorso = { 8, -35, 0 },
			Head = { 0, 40, 0 },
			RightUpperArm = { 195, 0, 20 },
			RightLowerArm = { 70, 0, 0 },
			LeftUpperArm = { 75, 0, 0 },
			LeftLowerArm = { 20, 0, 0 },
			RightUpperLeg = { -18, 0, 0 },
			LeftUpperLeg = { 18, 0, 0 },
		},
	},
	-- Hold for a moment at the top.
	{
		time = 0.42,
		poses = {
			LowerTorso = { 0, -22, 0 },
			UpperTorso = { 10, -38, 0 },
			Head = { 0, 42, 0 },
			RightUpperArm = { 205, 0, 20 },
			RightLowerArm = { 80, 0, 0 },
			LeftUpperArm = { 80, 0, 0 },
			LeftLowerArm = { 20, 0, 0 },
			RightUpperLeg = { -18, 0, 0 },
			LeftUpperLeg = { 18, 0, 0 },
		},
	},
	-- Release: body comes forward, arm stretched out in front. The body is only turned a little
	-- to the left here, so the weapon points along the lane when it leaves the hand; the big turn
	-- follows in the follow-through. The wrist also makes up for the forward lean.
	{
		time = 0.55,
		marker = RELEASE_MARKER,
		poses = {
			LowerTorso = { 0, 4, 0 },
			UpperTorso = { -15, 8, 0 },
			Head = { 8, -10, 0 },
			RightUpperArm = { 100, 0, 0 },
			RightLowerArm = { 8, 0, 0 },
			RightHand = { -93, 0, 0 },
			LeftUpperArm = { -30, 0, 0 },
			LeftLowerArm = { 30, 0, 0 },
			RightUpperLeg = { 8, 0, 0 },
			LeftUpperLeg = { -5, 0, 0 },
		},
	},
	-- Follow through: arm swings down across the body.
	{
		time = 0.72,
		poses = {
			LowerTorso = { 0, 20, 0 },
			UpperTorso = { -25, 35, 0 },
			Head = { 12, -45, 0 },
			RightUpperArm = { 35, 0, -25 },
			RightLowerArm = { 25, 0, 0 },
			RightHand = { -60, 0, 0 },
			LeftUpperArm = { -40, 0, 0 },
			LeftLowerArm = { 35, 0, 0 },
			RightUpperLeg = { 12, 0, 0 },
			LeftUpperLeg = { -8, 0, 0 },
		},
	},
	{ time = 1.0, poses = {} },
}

local TRAINING_THROW: { KeyframeSpec } = {
	{ time = 0, poses = {} },
	{
		time = 0.14,
		poses = {
			UpperTorso = { 5, -22, 0 },
			Head = { 0, 20, 0 },
			RightUpperArm = { 185, 0, 15 },
			RightLowerArm = { 60, 0, 0 },
		},
	},
	{
		time = 0.25,
		marker = RELEASE_MARKER,
		poses = {
			UpperTorso = { -10, 6, 0 },
			Head = { 5, -5, 0 },
			RightUpperArm = { 95, 0, 0 },
			RightLowerArm = { 8, 0, 0 },
			RightHand = { -93, 0, 0 },
		},
	},
	{
		time = 0.36,
		poses = {
			UpperTorso = { -14, 22, 0 },
			Head = { 6, -20, 0 },
			RightUpperArm = { 35, 0, -15 },
			RightLowerArm = { 20, 0, 0 },
			RightHand = { -55, 0, 0 },
		},
	},
	{ time = 0.5, poses = {} },
}

local function buildSequence(name: string, keyframes: { KeyframeSpec }, moved: { string }): KeyframeSequence
	local sequence = Instance.new("KeyframeSequence")
	sequence.Name = name
	sequence.Loop = false
	sequence.Priority = Enum.AnimationPriority.Action

	for _, spec in keyframes do
		local keyframe = Instance.new("Keyframe")
		keyframe.Time = spec.time

		-- Poses are nested the way the parts hang on each other. A part that is only needed to reach
		-- a moved part (like the hips for the upper body) gets weight 0: it is in the chain, but the
		-- animation does not touch it.
		local poses: { [string]: Pose } = {}
		local rootPose = Instance.new("Pose")
		rootPose.Name = "HumanoidRootPart"
		rootPose.Weight = 0
		rootPose.Parent = keyframe
		poses.HumanoidRootPart = rootPose

		local function poseFor(partName: string): Pose
			local existing = poses[partName]
			if existing then
				return existing
			end
			local pose = Instance.new("Pose")
			pose.Name = partName
			pose.Weight = 0
			pose.Parent = poseFor(PARENT_OF[partName])
			poses[partName] = pose
			return pose
		end

		for _, partName in ORDER do
			if table.find(moved, partName) then
				local angles = spec.poses[partName] or { 0, 0, 0 }
				local pose = poseFor(partName)
				pose.Weight = 1
				pose.CFrame = CFrame.Angles(math.rad(angles[1]), math.rad(angles[2]), math.rad(angles[3]))
				pose.EasingStyle = Enum.PoseEasingStyle.Cubic
				pose.EasingDirection = Enum.PoseEasingDirection.InOut
			end
		end

		if spec.marker then
			local marker = Instance.new("KeyframeMarker")
			marker.Name = spec.marker
			marker.Parent = keyframe
		end
		keyframe.Parent = sequence
	end
	return sequence
end

local assets = ReplicatedStorage:FindFirstChild("Assets")
assert(assets, "ReplicatedStorage.Assets is missing")

local rig = assets:FindFirstChild(RIG_NAME)
if not rig then
	rig = Players:CreateHumanoidModelFromDescription(Instance.new("HumanoidDescription"), Enum.HumanoidRigType.R15)
	rig.Name = RIG_NAME
	rig.Parent = assets
end

local oldSaves = rig:FindFirstChild(SAVES_NAME)
if oldSaves then
	oldSaves:Destroy()
end
-- The animation editor keeps saved animations in an ObjectValue called AnimSaves inside the rig.
local saves = Instance.new("ObjectValue")
saves.Name = SAVES_NAME
buildSequence("ThrowMain", MAIN_THROW, MAIN_PARTS).Parent = saves
buildSequence("ThrowTraining", TRAINING_THROW, TRAINING_PARTS).Parent = saves
saves.Parent = rig

return `built {RIG_NAME} with ThrowMain ({#MAIN_THROW} keyframes) and ThrowTraining ({#TRAINING_THROW} keyframes)`
