--!strict
-- Takes over the camera during a throw and gives it back afterwards.
-- At the start the camera glides from where it was to behind the sword. After that it
-- stays tightly behind the sword, so it never falls behind, even on very fast throws.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)

local CameraFollow = {}

local startCFrame = CFrame.new()
local elapsed = 0

function CameraFollow.start()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	startCFrame = camera.CFrame
	elapsed = 0
end

-- target: tip of the sword. The lane runs towards negative Z, so "behind" is positive Z.
function CameraFollow.update(target: Vector3, deltaTime: number)
	local v = ThrowVisuals
	local desired = CFrame.lookAt(
		target + Vector3.new(0, v.cameraAbove, v.cameraBehind),
		target + Vector3.new(0, 0, -v.cameraLookAhead)
	)

	elapsed += deltaTime
	local blend = math.clamp(elapsed / v.cameraBlendInSeconds, 0, 1)
	-- Ease out: fast at first, gentle at the end of the glide.
	local eased = 1 - (1 - blend) ^ 2
	Workspace.CurrentCamera.CFrame = startCFrame:Lerp(desired, eased)
end

-- Gives the camera back to the player. Safe to call any time, also if the character is gone.
function CameraFollow.stop()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

return CameraFollow
