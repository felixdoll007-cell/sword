--!strict
-- How characters hold the weapon in the right hand while they are not throwing: one pose for
-- standing, one for walking (Config/HoldPose). Without it Roblox's own arm movement swings the
-- blade through the body.
--
-- Made from code, on this client, for every character near the camera. Each client does this for
-- itself, so nothing is sent over the network and no uploaded animation is needed.
--
-- How: every frame, after Roblox's animations have posed the character, the three joints of the
-- right arm are overwritten with the pose (the same way as ArmSwing).
-- A throw has priority: while an animation of priority Action or higher plays on the character
-- (the throw animations are such), the pose lets go of the arm and takes it back afterwards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local HoldConfig = require(Shared.Config.HoldPose)
local HoldPose = require(Shared.Rules.HoldPose)

-- Name given by the server (server/HandWeapons).
local WEAPON_NAME = "HandWeapon"
local ROOT_NAME = "HumanoidRootPart"
local SHOULDER_NAME = "RightShoulder"
local ELBOW_NAME = "RightElbow"
local WRIST_NAME = "RightWrist"
-- A character whose arm is not there yet is looked at again after this many seconds.
local SEARCH_AGAIN_SECONDS = 0.5

-- Animations of these priorities take the arm away from the pose.
local WINNING_PRIORITIES: { [Enum.AnimationPriority]: boolean } = {
	[Enum.AnimationPriority.Action] = true,
	[Enum.AnimationPriority.Action2] = true,
	[Enum.AnimationPriority.Action3] = true,
	[Enum.AnimationPriority.Action4] = true,
}

type Joint = AnimationConstraint | Motor6D

type State = {
	shoulder: Joint?,
	elbow: Joint?,
	wrist: Joint?,
	animator: Animator?,
	played: RBXScriptConnection?,
	nextSearch: number,
	-- 0 = standing pose, 1 = walking pose.
	walkShare: number,
	-- 0 = Roblox's animations alone, 1 = fully the holding pose.
	holdShare: number,
	-- Animations playing right now that take the arm away from the pose.
	winning: { AnimationTrack },
	-- The pose also stays away until this time (for the arm swing from code).
	pausedUntil: number,
}

local HoldPoseView = {}

local states: { [Model]: State } = {}

local function findJoint(character: Model, name: string): Joint?
	local joint = character:FindFirstChild(name, true)
	if joint and (joint:IsA("AnimationConstraint") or joint:IsA("Motor6D")) then
		return joint
	end
	return nil
end

-- Looks for the arm joints and the animator of a character. They arrive one after the other.
local function search(character: Model, state: State)
	state.shoulder = findJoint(character, SHOULDER_NAME)
	state.elbow = findJoint(character, ELBOW_NAME)
	state.wrist = findJoint(character, WRIST_NAME)

	if not state.animator then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			state.animator = animator
			state.played = animator.AnimationPlayed:Connect(function(track: AnimationTrack)
				if WINNING_PRIORITIES[track.Priority] then
					table.insert(state.winning, track)
				end
			end)
		end
	end
end

-- Is a throw (or another animation that wins) using the arm right now?
local function isArmTaken(state: State, now: number): boolean
	local winning = state.winning
	for index = #winning, 1, -1 do
		if not winning[index].IsPlaying then
			table.remove(winning, index)
		end
	end
	return #winning > 0 or now < state.pausedUntil
end

-- sideDegrees: extra lift of the arm to the side (only used for the shoulder).
local function turn(
	joint: Joint,
	from: HoldPose.Angles,
	to: HoldPose.Angles,
	walkShare: number,
	holdShare: number,
	sideDegrees: number
)
	local x, y, z = HoldPose.mix(from, to, walkShare)
	local pose = CFrame.Angles(math.rad(x), math.rad(y), math.rad(z + sideDegrees))
	-- joint.Transform is what Roblox's animations have set for this frame.
	joint.Transform = if holdShare >= 1 then pose else joint.Transform:Lerp(pose, holdShare)
end

local function update(character: Model, state: State, deltaTime: number, now: number, cameraPosition: Vector3)
	local root = character:FindFirstChild(ROOT_NAME)
	if
		not root
		or not root:IsA("BasePart")
		or not character:FindFirstChild(WEAPON_NAME)
		or (root.Position - cameraPosition).Magnitude > HoldConfig.maxDistance
	then
		-- Nothing in the hand, or too far away to matter: Roblox's animations alone.
		state.holdShare = 0
		return
	end

	local shoulder, elbow, wrist = state.shoulder, state.elbow, state.wrist
	if not shoulder or not elbow or not wrist or not shoulder.Parent or not elbow.Parent or not wrist.Parent then
		if now >= state.nextSearch then
			state.nextSearch = now + SEARCH_AGAIN_SECONDS
			search(character, state)
		end
		return
	end

	local holdTarget = if isArmTaken(state, now) then 0 else 1
	state.holdShare = HoldPose.approach(state.holdShare, holdTarget, deltaTime, HoldConfig.throwBlendSeconds)

	local velocity = root.AssemblyLinearVelocity
	local groundSpeed = math.sqrt(velocity.X * velocity.X + velocity.Z * velocity.Z)
	local walkTarget = if HoldPose.isWalking(HoldConfig, groundSpeed) then 1 else 0
	state.walkShare = HoldPose.approach(state.walkShare, walkTarget, deltaTime, HoldConfig.blendSeconds)

	if state.holdShare <= 0 then
		return
	end
	local standing, walking = HoldConfig.standing, HoldConfig.walking
	local walkShare = HoldPose.ease(state.walkShare)
	local holdShare = HoldPose.ease(state.holdShare)
	local sideSwing = HoldPose.sideSwing(HoldConfig, walkShare)
	turn(shoulder, standing.shoulder, walking.shoulder, walkShare, holdShare, sideSwing)
	turn(elbow, standing.elbow, walking.elbow, walkShare, holdShare, 0)
	turn(wrist, standing.wrist, walking.wrist, walkShare, holdShare, 0)
end

local function add(character: Model)
	if states[character] then
		return
	end
	states[character] = {
		nextSearch = 0,
		walkShare = 0,
		holdShare = 0,
		winning = {},
		pausedUntil = 0,
	}
end

local function remove(character: Model)
	local state = states[character]
	if not state then
		return
	end
	if state.played then
		state.played:Disconnect()
	end
	states[character] = nil
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(add)
	player.CharacterRemoving:Connect(remove)
	if player.Character then
		add(player.Character)
	end
end

-- The pose stays away from this character's arm for this many seconds. For arm movements made
-- from code; real animations make the pose step aside by themselves.
function HoldPoseView.pauseFor(character: Model, seconds: number)
	local state = states[character]
	if state then
		state.pausedUntil = math.max(state.pausedUntil, os.clock() + seconds)
	end
end

function HoldPoseView.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		if player.Character then
			remove(player.Character)
		end
	end)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	-- PreSimulation runs after Roblox's animations have set the pose for this frame.
	RunService.PreSimulation:Connect(function(deltaTime: number)
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local now = os.clock()
		local cameraPosition = camera.CFrame.Position
		for character, state in states do
			update(character, state, deltaTime, now, cameraPosition)
		end
	end)
end

return HoldPoseView
