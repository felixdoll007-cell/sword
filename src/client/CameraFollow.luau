--!strict
-- Takes over the camera during a throw and gives it back afterwards.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)

local CameraFollow = {}

function CameraFollow.start()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
end

-- target: tip of the sword. The lane runs towards negative Z, so "behind" is positive Z.
function CameraFollow.update(target: Vector3, deltaTime: number)
	local camera = Workspace.CurrentCamera
	local v = ThrowVisuals
	local desired = CFrame.lookAt(
		target + Vector3.new(0, v.cameraAbove, v.cameraBehind),
		target + Vector3.new(0, 0, -v.cameraLookAhead)
	)
	-- Smooth follow that behaves the same at any frame rate.
	local alpha = 1 - math.exp(-v.cameraFollowSpeed * deltaTime)
	camera.CFrame = camera.CFrame:Lerp(desired, alpha)
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
