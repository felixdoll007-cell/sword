--!strict
-- Plays the throw animations (Config/Animations).
--
-- Three cases:
--   1. The animation is uploaded (assetId in the config): it is played on this player's own
--      character, and Roblox shows it to all other players by itself.
--   2. Not uploaded, but running in Studio: the animation from the animation rig in the place is
--      used as a preview, for the own character only. This does not work in the published game.
--   3. Otherwise: the simple arm swing from code (ArmSwing), timed so the arm comes forward at
--      the release moment.

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationConfig = require(ReplicatedStorage.Shared.Config.Animations)

local ArmSwing = require(script.Parent.ArmSwing)
local HoldPoseView = require(script.Parent.HoldPoseView)

export type Entry = {
	assetId: number,
	name: string,
	releaseSeconds: number,
}

local ThrowAnimation = {}

-- Content ids for the Studio preview, by animation name. false = looked for and not found.
local previewIds: { [string]: string | boolean } = {}
-- Loaded tracks per character's animator, by animation name.
local tracks: { [Animator]: { [string]: AnimationTrack } } = {}

local function isUploaded(entry: Entry): boolean
	return entry.assetId > 0
end

-- Studio only: the animation as it lies in the place, straight from the editor.
local function previewId(entry: Entry): string?
	if not RunService:IsStudio() then
		return nil
	end
	local known = previewIds[entry.name]
	if known ~= nil then
		return if typeof(known) == "string" then known else nil
	end

	local folder = ReplicatedStorage:FindFirstChild(AnimationConfig.rigFolder)
	local rig = folder and folder:FindFirstChild(AnimationConfig.rigName)
	local saves = rig and rig:FindFirstChild(AnimationConfig.savesName)
	local sequence = saves and saves:FindFirstChild(entry.name)
	if sequence and sequence:IsA("KeyframeSequence") then
		local ok, id = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(sequence)
		end)
		if ok and typeof(id) == "string" then
			previewIds[entry.name] = id
			return id
		end
	end
	previewIds[entry.name] = false
	return nil
end

local function animationId(entry: Entry): string?
	if isUploaded(entry) then
		return `rbxassetid://{entry.assetId}`
	end
	return previewId(entry)
end

local function getTrack(character: Model, entry: Entry): AnimationTrack?
	local id = animationId(entry)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not id or not animator then
		return nil
	end

	local loaded = tracks[animator]
	if not loaded then
		loaded = {}
		tracks[animator] = loaded
		-- Forget the tracks when the character is gone.
		animator.Destroying:Connect(function()
			tracks[animator] = nil
		end)
	end

	local track = loaded[entry.name]
	if not track then
		local animation = Instance.new("Animation")
		animation.AnimationId = id
		local ok, result = pcall(function()
			return animator:LoadAnimation(animation)
		end)
		if not ok or not result then
			return nil
		end
		track = result :: AnimationTrack
		track.Priority = Enum.AnimationPriority.Action
		track.Looped = false
		loaded[entry.name] = track
	end
	return track
end

-- The arm swing from code, started so that the arm comes forward at the release moment.
local function playArmSwing(character: Model, entry: Entry)
	local wait = math.max(entry.releaseSeconds - ArmSwing.releaseDelay(), 0)
	-- The holding pose of the arm steps aside for the swing. (A real animation makes it step
	-- aside by itself, see HoldPoseView.)
	HoldPoseView.pauseFor(character, wait + ArmSwing.duration())
	task.delay(wait, function()
		if character.Parent then
			ArmSwing.play(character)
		end
	end)
end

-- Plays the throw on this player's own character.
function ThrowAnimation.playOwn(entry: Entry)
	local character = Players.LocalPlayer.Character
	if not character then
		return
	end
	local track = getTrack(character, entry)
	if track then
		track:Play(AnimationConfig.fadeSeconds)
	else
		playArmSwing(character, entry)
	end
end

-- Another player throws. With an uploaded animation Roblox already shows it and nothing is done
-- here. Without one, the arm swing is played on that character so the throw is still visible.
function ThrowAnimation.playOther(character: Model, entry: Entry)
	if not isUploaded(entry) then
		playArmSwing(character, entry)
	end
end

-- Loads the animations of the own character ahead of time, so the first throw does not stutter.
function ThrowAnimation.preload()
	local function load(character: Model)
		task.spawn(function()
			character:WaitForChild("Humanoid"):WaitForChild("Animator")
			getTrack(character, AnimationConfig.mainThrow)
			getTrack(character, AnimationConfig.trainingThrow)
		end)
	end
	local player = Players.LocalPlayer
	player.CharacterAdded:Connect(load)
	if player.Character then
		load(player.Character)
	end
end

return ThrowAnimation
