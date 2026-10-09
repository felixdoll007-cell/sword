--!strict
-- Comfort on the training pad: stepping on snaps the character to the pad center, facing the wall,
-- and holds it still. Holding a direction for a moment or jumping lets go. After letting go,
-- the character only snaps again once it has fully left the pad.
--
-- This is only comfort on this client. Whether training happens is still decided by the server
-- from the character's position; snapping gives no strength by itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TrainingConfig = require(ReplicatedStorage.Shared.Config.Training)
local Training = require(ReplicatedStorage.Shared.Rules.Training)

local CharacterFreeze = require(script.Parent.CharacterFreeze)

local FREEZE_REASON = "Training"

local TrainingSnap = {}

local snapped = false
-- false right after letting go, true again once the character has fully left the pad.
local armed = true
local heldSeconds = 0

type Controls = { GetMoveVector: (Controls) -> Vector3 }
local controls: Controls? = nil

-- The direction the player is pushing, from keyboard, touch joystick or gamepad alike.
-- Read from Roblox's own control module: it reports the raw input, no matter the walk speed.
local function moveInput(): Vector3
	if controls then
		return controls:GetMoveVector()
	end
	return Vector3.zero
end

local function loadControls()
	local ok, result = pcall(function()
		local playerModule = Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
		return (require(playerModule :: ModuleScript) :: any):GetControls()
	end)
	if ok then
		controls = result
	else
		warn(`[TrainingSnap] could not read the controls, leaving works by jumping only: {result}`)
	end
end

local function snap(character: Model, root: BasePart)
	local pad = TrainingConfig.pad
	local position = Vector3.new(pad.x, root.Position.Y, pad.z)
	-- Facing the wall: the lane runs towards negative Z.
	character:PivotTo(CFrame.lookAt(position, position + Vector3.new(0, 0, -1)))
	root.AssemblyLinearVelocity = Vector3.zero
	CharacterFreeze.freeze(FREEZE_REASON)
	snapped = true
	heldSeconds = 0
end

local function letGo(): boolean
	if not snapped then
		return false
	end
	snapped = false
	armed = false
	heldSeconds = 0
	CharacterFreeze.release(FREEZE_REASON)
	return true
end

local function update(deltaTime: number)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return
	end

	if snapped then
		if moveInput().Magnitude >= TrainingConfig.leaveInputThreshold then
			heldSeconds += deltaTime
		else
			heldSeconds = 0
		end
		if heldSeconds >= TrainingConfig.leaveHoldSeconds then
			letGo()
		end
		return
	end

	local onPad = Training.isOnPad(TrainingConfig, root.Position.X, root.Position.Z)
	if not onPad then
		armed = true
	elseif armed then
		snap(character, root)
	end
end

function TrainingSnap.start()
	task.spawn(loadControls)

	RunService.Heartbeat:Connect(update)

	-- Jumping lets go at once, and the jump then really happens.
	UserInputService.JumpRequest:Connect(function()
		if letGo() then
			local character = Players.LocalPlayer.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Jump = true
			end
		end
	end)

	-- A new character starts free (CharacterFreeze forgets the old one by itself).
	Players.LocalPlayer.CharacterAdded:Connect(function()
		snapped = false
		armed = true
		heldSeconds = 0
	end)
end

return TrainingSnap
