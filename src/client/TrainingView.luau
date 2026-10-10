--!strict
-- Everything about the training lanes that only this client sees: the walls, the sign above each
-- lane (multiplier, requirement, or LOCKED for this player) and the small training throw animation.
-- The server decides when a training throw happens and on which lane; this script only shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local TrainingConfig = require(Shared.Config.Training)
local NumberFormat = require(Shared.Rules.NumberFormat)
local Training = require(Shared.Rules.Training)

local ArmSwing = require(script.Parent.ArmSwing)
local SwordView = require(script.Parent.SwordView)
local WallEffects = require(script.Parent.WallEffects)

local FOLDER_NAME = "MyTrainingLanes"

type WallState = {
	part: BasePart,
	-- Counts how many throws are waiting to put the wall back, so overlapping throws do not fight.
	downCount: number,
}

type Sign = {
	multiplierLine: TextLabel,
	requirementLine: TextLabel,
	lockedLine: TextLabel,
}

local TrainingView = {}

local player = Players.LocalPlayer
-- walls[lane][wallNumber], wall 1 is the nearest.
local walls: { { WallState } } = {}
local signs: { Sign } = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function padFrontZ(pad: Training.Pad): number
	return pad.z - pad.length / 2
end

-- Z of the middle of a wall.
local function wallZ(pad: Training.Pad, wallNumber: number): number
	return padFrontZ(pad) - Training.wallOffset(TrainingConfig, wallNumber)
end

local function makePart(name: string, size: Vector3, position: Vector3, rgb: { number }, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanTouch = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = size
	part.Position = position
	part.Color = color(rgb)
	part.Parent = parent
	return part
end

local function buildWalls(laneIndex: number, pad: Training.Pad, folder: Folder)
	walls[laneIndex] = {}
	for wallNumber = 1, TrainingConfig.lanes[laneIndex].walls do
		local part = makePart(
			`Lane{laneIndex}Wall{wallNumber}`,
			Vector3.new(pad.width, TrainingConfig.wallHeight, TrainingConfig.wallThickness),
			Vector3.new(pad.x, LaneConfig.floorTopY + TrainingConfig.wallHeight / 2, wallZ(pad, wallNumber)),
			TrainingConfig.wallColor,
			folder
		)
		walls[laneIndex][wallNumber] = { part = part, downCount = 0 }
	end
end

local function makeSignLine(heightShare: number, yShare: number, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, heightShare)
	label.Position = UDim2.fromScale(0, yShare)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = color(TrainingConfig.sign.textColor)
	label.Parent = parent
	return label
end

-- A board above the start of the lane, readable from the pad side.
local function buildSign(laneIndex: number, pad: Training.Pad, folder: Folder)
	local settings = TrainingConfig.sign
	local board = makePart(
		`Lane{laneIndex}Sign`,
		Vector3.new(pad.width, settings.boardHeight, settings.boardThickness),
		Vector3.new(pad.x, LaneConfig.floorTopY + settings.heightAboveFloor + settings.boardHeight / 2, padFrontZ(pad)),
		settings.boardColor,
		folder
	)
	board.CanCollide = false
	board.CanQuery = false

	local gui = Instance.new("SurfaceGui")
	-- The lane runs towards negative Z, players come from positive Z: that is the board's back face.
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.LightInfluence = 0
	gui.Parent = board

	local heights = settings.lineHeights
	signs[laneIndex] = {
		multiplierLine = makeSignLine(heights[1], 0, gui),
		requirementLine = makeSignLine(heights[2], heights[1], gui),
		lockedLine = makeSignLine(heights[3], heights[1] + heights[2], gui),
	}
end

-- Sign texts depend on the rebirths of this player.
local function refreshSigns()
	local settings = TrainingConfig.sign
	local value = player:GetAttribute(Remotes.Attributes.Rebirths)
	local rebirths = if typeof(value) == "number" then value else 0

	for laneIndex, sign in signs do
		local lane = TrainingConfig.lanes[laneIndex]
		local unlocked = Training.isUnlocked(TrainingConfig, laneIndex, { rebirths = rebirths })
		local multiplier = NumberFormat.abbreviate(NumberFormatConfig, lane.multiplier)
		-- Each unlock kind has its own text. Unknown kinds show no requirement.
		local requirement = ""
		local unlock = lane.unlock
		if unlock.kind == "Rebirths" and unlock.rebirths then
			requirement = if unlock.rebirths > 0
				then string.format(settings.rebirthsRequirementText, tostring(unlock.rebirths))
				else settings.freeText
		end

		sign.multiplierLine.Text = string.format(settings.multiplierText, multiplier)
		sign.requirementLine.Text = requirement
		sign.lockedLine.Text = if unlocked then "" else settings.lockedText
		sign.lockedLine.TextColor3 = color(settings.lockedTextColor)
	end
end

local function breakWall(wall: WallState)
	wall.downCount += 1
	wall.part.Transparency = 1
	wall.part.CanCollide = false
	WallEffects.spawnPiecesAt(
		wall.part.Position,
		wall.part.Size.X,
		wall.part.Size.Y,
		TrainingConfig.wallColor,
		TrainingConfig.piecesPerWall,
		TrainingConfig.pieceSize
	)
	task.delay(TrainingConfig.wallBackSeconds, function()
		wall.downCount -= 1
		if wall.downCount == 0 then
			wall.part.Transparency = 0
			wall.part.CanCollide = true
		end
	end)
end

-- The small sword flies from the player through all walls of the lane.
local function launchSword(laneIndex: number)
	local laneWalls = walls[laneIndex]
	local pad = Training.lanePad(TrainingConfig, laneIndex)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not laneWalls or not pad or not root or not root:IsA("BasePart") then
		return
	end

	local y = LaneConfig.floorTopY + TrainingConfig.swordHeight
	local from = Vector3.new(root.Position.X, y, root.Position.Z)
	local to = Vector3.new(root.Position.X, y, wallZ(pad, #laneWalls))
	local sword = SwordView.create("MyTrainingSword", TrainingConfig.swordScale)
	sword:PivotTo(CFrame.new(from))

	local elapsed = 0
	local nextWall = 1
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local progress = math.clamp(elapsed / TrainingConfig.flightSeconds, 0, 1)
		local position = from:Lerp(to, progress)
		sword:PivotTo(CFrame.new(position))

		-- Break every wall the tip has reached.
		while nextWall <= #laneWalls and position.Z <= wallZ(pad, nextWall) do
			breakWall(laneWalls[nextWall])
			nextWall += 1
		end

		if progress >= 1 then
			connection:Disconnect()
			sword:Destroy()
		end
	end)
end

function TrainingView.start()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for laneIndex = 1, Training.laneCount(TrainingConfig) do
		local pad = Training.lanePad(TrainingConfig, laneIndex) :: Training.Pad
		buildWalls(laneIndex, pad, folder)
		buildSign(laneIndex, pad, folder)
	end
	folder.Parent = Workspace

	refreshSigns()
	player:GetAttributeChangedSignal(Remotes.Attributes.Rebirths):Connect(refreshSigns)

	Remotes.TrainingThrow.OnClientEvent:Connect(function(_gained: unknown, lane: unknown)
		if typeof(lane) ~= "number" or not walls[lane] then
			return
		end
		local laneIndex: number = lane
		-- Arm swings first, the sword leaves when the arm moves forward.
		ArmSwing.play()
		task.delay(ArmSwing.releaseDelay(), launchSword, laneIndex)
	end)
end

return TrainingView
