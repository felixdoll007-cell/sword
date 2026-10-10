--!strict
-- Shows the throws of other players nearby: their arm swings and a sword flies off.
--   Training throw: the small sword flies down their training lane. Their wall does not break here;
--     walls only break for the player who throws.
--   Main throw: the sword flies a short way and fades out before it reaches any wall.
-- The server decides who is told about which throw. This script only draws, and draws at most
-- a few at the same time so weak phones stay smooth.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local AnimationConfig = require(Shared.Config.Animations)
local LaneConfig = require(Shared.Config.Lane)
local OtherPlayersConfig = require(Shared.Config.OtherPlayers)
local ThrowVisuals = require(Shared.Config.ThrowVisuals)
local TrainingConfig = require(Shared.Config.Training)
local Training = require(Shared.Rules.Training)
local Visibility = require(Shared.Rules.Visibility)

local HandWeaponView = require(script.Parent.HandWeaponView)
local SwordView = require(script.Parent.SwordView)
local ThrowAnimation = require(script.Parent.ThrowAnimation)
local ThrowSession = require(script.Parent.ThrowSession)

local OtherThrowsView = {}

-- How many throws of other players are being drawn right now.
local shownNow = 0

local function rootPosition(character: Model): Vector3?
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position
	end
	return nil
end

-- Where the flying weapon starts: at the tip of the weapon in the character's hand, pointing the
-- way that weapon points. Without a weapon in the hand: at the fallback point, pointing along the lane.
local function launchPoint(character: Model, fallback: Vector3): CFrame
	return HandWeaponView.launchPose(character) or CFrame.new(fallback)
end

local function setTransparency(sword: Model, transparency: number)
	for _, part in sword:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = transparency
		end
	end
end

-- One sword flying in a straight line, optionally fading out on the way. Calls done() when it is gone.
local function flySword(
	weaponId: unknown,
	from: CFrame,
	to: CFrame,
	seconds: number,
	scale: number,
	fades: boolean,
	done: () -> ()
)
	local sword = SwordView.create("OtherPlayerSword", scale, weaponId)
	SwordView.moveTo(sword, from)

	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local progress = math.clamp(elapsed / seconds, 0, 1)
		SwordView.moveTo(sword, from:Lerp(to, progress))
		if fades then
			setTransparency(sword, progress)
		end
		if progress >= 1 then
			connection:Disconnect()
			sword:Destroy()
			done()
		end
	end)
end

-- Draws one throw: the throw movement first, the weapon leaves the hand at the release moment.
-- animation: which throw animation it is (Config/Animations).
-- path: returns where the weapon flies from and to (place and direction), or nil if it cannot be
-- shown any more.
local function show(
	character: Model,
	weaponId: unknown,
	animation: ThrowAnimation.Entry,
	seconds: number,
	scale: number,
	fades: boolean,
	path: () -> (CFrame?, CFrame?)
)
	if not Visibility.canShowAnother(shownNow, OtherPlayersConfig.maxShownAtOnce) then
		return
	end
	shownNow += 1
	local function done()
		shownNow -= 1
	end

	-- An uploaded animation is shown by Roblox itself; otherwise the simple arm swing is played.
	ThrowAnimation.playOther(character, animation)
	task.delay(animation.releaseSeconds, function()
		local from, to = path()
		if not from or not to then
			done()
			return
		end
		-- The weapon in their hand is hidden on this client while it flies.
		HandWeaponView.hideFor(character, seconds)
		flySword(weaponId, from, to, seconds, scale, fades, done)
	end)
end

-- Another player's training throw on a lane. weaponId: the weapon that player has equipped.
function OtherThrowsView.showTraining(character: Model, laneIndex: number, weaponId: unknown)
	local pad = Training.lanePad(TrainingConfig, laneIndex)
	local lane = TrainingConfig.lanes[laneIndex]
	if not pad or not lane then
		return
	end
	local lastWallZ = pad.z - pad.length / 2 - Training.wallOffset(TrainingConfig, lane.walls)
	show(
		character,
		weaponId,
		AnimationConfig.trainingThrow,
		TrainingConfig.flightSeconds,
		TrainingConfig.swordScale,
		false,
		function()
			local position = rootPosition(character)
			if not position then
				return nil, nil
			end
			local y = LaneConfig.floorTopY + TrainingConfig.swordHeight
			return launchPoint(character, Vector3.new(position.X, y, position.Z)), CFrame.new(position.X, y, lastWallZ)
		end
	)
end

-- Another player's main throw: flies a short way along the lane and fades out.
function OtherThrowsView.showMain(character: Model, weaponId: unknown)
	show(character, weaponId, AnimationConfig.mainThrow, OtherPlayersConfig.mainThrowSeconds, 1, true, function()
		local position = rootPosition(character)
		if not position then
			return nil, nil
		end
		local y = LaneConfig.floorTopY + ThrowVisuals.swordHeight
		local from = launchPoint(character, Vector3.new(position.X, y, position.Z))
		return from, CFrame.new(position.X, y, position.Z - OtherPlayersConfig.mainThrowFadeDistance)
	end)
end

function OtherThrowsView.start()
	Remotes.OtherPlayerThrew.OnClientEvent:Connect(function(thrower: unknown, kind: unknown, lane: unknown)
		-- The server is trusted, but a broken value must not break the client.
		if typeof(thrower) ~= "Instance" or not thrower:IsA("Player") or thrower == Players.LocalPlayer then
			return
		end
		local character = thrower.Character
		if not character then
			return
		end
		-- During the own throw the camera is far down the lane; nothing here would be seen.
		if ThrowSession.isActive() then
			return
		end

		-- The equipped weapon of every player is visible to all (attribute on the Player).
		local weaponId = thrower:GetAttribute(Remotes.Attributes.EquippedWeapon)
		if kind == Remotes.ThrowKind.Training and typeof(lane) == "number" then
			OtherThrowsView.showTraining(character, lane, weaponId)
		elseif kind == Remotes.ThrowKind.Main then
			OtherThrowsView.showMain(character, weaponId)
		end
	end)
end

return OtherThrowsView
