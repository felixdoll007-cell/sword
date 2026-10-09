--!strict
-- The training wall (only on this client) and the small training throw animation.
-- The server decides when a training throw happens; this script only shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local TrainingConfig = require(Shared.Config.Training)

local SwordView = require(script.Parent.SwordView)
local WallEffects = require(script.Parent.WallEffects)

local TrainingView = {}

local wall: BasePart
-- Counts how many throws are waiting to put the wall back, so overlapping throws do not fight.
local wallDownCount = 0

local function wallFrontZ(): number
	local pad = TrainingConfig.pad
	return pad.z - pad.length / 2 - TrainingConfig.wallDistance + TrainingConfig.wallThickness / 2
end

local function buildWall()
	local pad = TrainingConfig.pad
	local c = TrainingConfig.wallColor
	wall = Instance.new("Part")
	wall.Name = "MyTrainingWall"
	wall.Anchored = true
	wall.CanTouch = false
	wall.TopSurface = Enum.SurfaceType.Smooth
	wall.BottomSurface = Enum.SurfaceType.Smooth
	wall.Size = Vector3.new(pad.width, TrainingConfig.wallHeight, TrainingConfig.wallThickness)
	wall.Position = Vector3.new(
		pad.x,
		LaneConfig.floorTopY + TrainingConfig.wallHeight / 2,
		wallFrontZ() - TrainingConfig.wallThickness / 2
	)
	wall.Color = Color3.fromRGB(c[1], c[2], c[3])
	wall.Parent = Workspace
end

local function breakWall()
	wallDownCount += 1
	wall.Transparency = 1
	wall.CanCollide = false
	WallEffects.spawnPiecesAt(
		wall.Position,
		wall.Size.X,
		wall.Size.Y,
		TrainingConfig.wallColor,
		TrainingConfig.piecesPerThrow,
		TrainingConfig.pieceSize
	)
	task.delay(TrainingConfig.wallBackSeconds, function()
		wallDownCount -= 1
		if wallDownCount == 0 then
			wall.Transparency = 0
			wall.CanCollide = true
		end
	end)
end

local function playThrow()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return
	end

	-- The small sword flies from the player straight to the wall.
	local y = LaneConfig.floorTopY + TrainingConfig.swordHeight
	local from = Vector3.new(root.Position.X, y, root.Position.Z)
	local to = Vector3.new(root.Position.X, y, wallFrontZ())
	local sword = SwordView.create("MyTrainingSword", TrainingConfig.swordScale)
	sword:PivotTo(CFrame.new(from))

	local elapsed = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local progress = math.clamp(elapsed / TrainingConfig.flightSeconds, 0, 1)
		sword:PivotTo(CFrame.new(from:Lerp(to, progress)))
		if progress >= 1 then
			connection:Disconnect()
			sword:Destroy()
			breakWall()
		end
	end)
end

function TrainingView.start()
	buildWall()
	Remotes.TrainingThrow.OnClientEvent:Connect(playThrow)
end

return TrainingView
