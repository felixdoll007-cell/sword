--!strict
-- How characters hold the weapon in the right hand while they are not throwing: one fixed pose
-- of the right arm (Config/HoldPose), whether they stand, walk, jump, fall or land. Without it
-- Roblox's own arm movement swings the blade through the body.
--
-- Made from code, on this client, for every character near the camera. Each client does this for
-- itself, so nothing is sent over the network and no uploaded animation is needed.
--
-- How: every frame, after Roblox's animations have posed the character, the three joints of the
-- right arm are overwritten with the pose (the same way as ArmSwing). Nothing else of the body
-- is touched. This is not an animation: there are no keyframes, and it needs no restart after a
-- respawn, a new weapon or a rebirth, because it looks at every character anew each frame.
-- A throw has priority: while an animation of priority Action or higher plays on the character
-- (the throw animations are such), the pose lets go of the arm and glides back in afterwards.

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
	-- 0 = Roblox's animations alone, 1 = fully the holding pose.
	holdShare: number,
	-- Animations playing right now that take the arm away from the pose.
	winning: { AnimationTrack },
	-- The pose also stays away until this time (for the arm swing from code).
	pausedUntil: number,
}

local HoldPoseView = {}

local states: { [Model]: State } = {}

local function toCFrame(angles: HoldPose.Angles): CFrame
	return CFrame.Angles(math.rad(angles.x), math.rad(angles.y), math.rad(angles.z))
end

-- The pose of each joint. It never changes, so it is worked out once.
local SHOULDER_POSE = toCFrame(HoldConfig.arm.shoulder)
local ELBOW_POSE = toCFrame(HoldConfig.arm.elbow)
local WRIST_POSE = toCFrame(HoldConfig.arm.wrist)

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

local function turn(joint: Joint, pose: CFrame, share: number)
	-- joint.Transform is what Roblox's animations have set for this frame.
	joint.Transform = if share >= 1 then pose else joint.Transform:Lerp(pose, share)
end

local function update(character: Model, state: State, deltaTime: number, now: number, cameraPosition: Vector3)
	local root = character:FindFirstChild(ROOT_NAME)
	if not root or not root:IsA("BasePart") then
		return
	end

	local shoulder, elbow, wrist = state.shoulder, state.elbow, state.wrist
	if
		not shoulder
		or not elbow
		or not wrist
		or not shoulder.Parent
		or not elbow.Parent
		or not wrist.Parent
		-- Without the animator a throw could not be noticed.
		or not state.animator
	then
		if now >= state.nextSearch then
			state.nextSearch = now + SEARCH_AGAIN_SECONDS
			search(character, state)
		end
		return
	end

	-- The pose holds the arm whenever a weapon is in the hand and no throw is playing.
	local wanted = character:FindFirstChild(WEAPON_NAME) ~= nil and not isArmTaken(state, now)
	state.holdShare = HoldPose.nextShare(HoldConfig, state.holdShare, wanted, deltaTime)
	if state.holdShare <= 0 then
		return
	end
	-- Other characters too far away to be seen: skip the work, but keep the state. The own
	-- character is always posed, so nothing pops when the camera comes back from a throw.
	local isOwn = character == Players.LocalPlayer.Character
	if not isOwn and (root.Position - cameraPosition).Magnitude > HoldConfig.maxDistance then
		return
	end

	local share = HoldPose.ease(state.holdShare)
	turn(shoulder, SHOULDER_POSE, share)
	turn(elbow, ELBOW_POSE, share)
	turn(wrist, WRIST_POSE, share)
end

local function add(character: Model)
	if states[character] then
		return
	end
	states[character] = {
		nextSearch = 0,
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
