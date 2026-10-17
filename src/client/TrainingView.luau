--!strict
-- Everything about the training lanes that only this client sees: the walls, the sign floating
-- above each lane (what it needs, UNLOCKED or LOCKED for this player, what it gives) and the
-- small training throw animation.
-- On a lane with a theme (Config/Ui, world.training) a target stands where the wall is. The wall
-- is still there, because the throw is timed against it, but it is invisible; pieces in the
-- theme's color fly off when the weapon arrives.
-- The server decides when a training throw happens and on which lane; this script only shows it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local AnimationConfig = require(Shared.Config.Animations)
local LaneConfig = require(Shared.Config.Lane)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local TrainingConfig = require(Shared.Config.Training)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)
local Training = require(Shared.Rules.Training)
local TrainingLook = require(Shared.Rules.TrainingLook)

local HandWeaponView = require(script.Parent.HandWeaponView)
local TrainingDecorView = require(script.Parent.TrainingDecorView)
local SwordView = require(script.Parent.SwordView)
local ThrowAnimation = require(script.Parent.ThrowAnimation)
local WallEffects = require(script.Parent.WallEffects)
local WorldSign = require(script.Parent.Ui.WorldSign)

local FOLDER_NAME = "MyTrainingLanes"
-- The rows of a sign, from top to bottom.
local PILL_ROW = 1
local STATUS_ROW = 2

type WallState = {
	part: BasePart,
	-- 1 on a themed lane (the target stands there instead), 0 on a plain lane.
	standingTransparency: number,
	pieceColor: { number },
	-- Counts how many throws are waiting to put the wall back, so overlapping throws do not fight.
	downCount: number,
}

local TrainingView = {}

local player = Players.LocalPlayer
-- walls[lane][wallNumber], wall 1 is the nearest.
local walls: { { WallState } } = {}
local signs: { WorldSign.WorldSign } = {}

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

-- The theme of a lane, or nil if the lane is plain.
local function themeOf(laneIndex: number): any?
	local training = Ui.world.training
	local name = (training.laneThemes :: { [number]: string })[laneIndex]
	return if name then (training.themes :: { [string]: any })[name] else nil
end

local function buildWalls(laneIndex: number, pad: Training.Pad, folder: Folder)
	walls[laneIndex] = {}
	local theme = themeOf(laneIndex)
	for wallNumber = 1, TrainingConfig.lanes[laneIndex].walls do
		local part = makePart(
			`Lane{laneIndex}Wall{wallNumber}`,
			Vector3.new(pad.width, TrainingConfig.wallHeight, TrainingConfig.wallThickness),
			Vector3.new(pad.x, LaneConfig.floorTopY + TrainingConfig.wallHeight / 2, wallZ(pad, wallNumber)),
			TrainingConfig.wallColor,
			folder
		)
		-- On a themed lane the wall is never seen and blocks nothing.
		if theme then
			part.Transparency = 1
			part.CanCollide = false
			part.CanQuery = false
			part.CastShadow = false
		end
		walls[laneIndex][wallNumber] = {
			part = part,
			downCount = 0,
			standingTransparency = if theme then 1 else 0,
			pieceColor = if theme then theme.pieceColor else TrainingConfig.wallColor,
		}
	end
end

-- The sign floating above a lane: a pill with the rebirth symbol and the number needed,
-- UNLOCKED or LOCKED, and what the lane gives.
local function buildSign(laneIndex: number, folder: Folder)
	local settings = Ui.world.signs.training
	local lane = TrainingConfig.lanes[laneIndex]
	local place =
		TrainingLook.sign(TrainingConfig, laneIndex, LaneConfig.floorTopY, settings.heightAboveFloor, settings.forward)
	-- The Robux lane can not be bought yet: where it counts, COMING SOON instead of a price,
	-- and LOCKED. It never changes.
	if lane.unlock.kind == "Purchase" then
		local robux = Ui.world.signs.robuxLane
		WorldSign.new({
			name = `Lane{laneIndex}Sign`,
			parent = folder,
			position = Vector3.new(place.x, place.y, place.z),
			widthStuds = settings.widthStuds,
			heightStuds = settings.heightStuds,
			rows = {
				{ kind = "text", height = robux.topHeight, text = robux.topText },
				{ kind = "pill", height = robux.pillHeight, text = robux.pillText },
				{ kind = "text", height = robux.statusHeight, text = robux.lockedText, color = Ui.colors.danger },
			},
		})
		return
	end
	signs[laneIndex] = WorldSign.new({
		name = `Lane{laneIndex}Sign`,
		parent = folder,
		position = Vector3.new(place.x, place.y, place.z),
		widthStuds = settings.widthStuds,
		heightStuds = settings.heightStuds,
		rows = {
			{ kind = "pill", height = settings.pillHeight, icon = "rebirths", text = "", color = Ui.colors.rebirths },
			{ kind = "text", height = settings.statusHeight, text = "" },
			{
				kind = "text",
				height = settings.effectHeight,
				text = string.format(settings.effectText, NumberFormat.abbreviate(NumberFormatConfig, lane.multiplier)),
			},
		},
	})
end

-- Sign texts depend on the rebirths of this player.
local function refreshSigns()
	local settings = Ui.world.signs.training
	local value = player:GetAttribute(Remotes.Attributes.Rebirths)
	local rebirths = if typeof(value) == "number" then value else 0

	for laneIndex, sign in signs do
		local unlock = TrainingConfig.lanes[laneIndex].unlock
		local unlocked = Training.isUnlocked(TrainingConfig, laneIndex, { rebirths = rebirths })

		-- Each unlock kind has its own pill. Unknown kinds show an empty one.
		local needed = if unlock.kind == "Rebirths" then unlock.rebirths else nil
		if needed and needed > 0 then
			sign.setText(PILL_ROW, tostring(needed))
			sign.setIconShown(PILL_ROW, true)
		else
			sign.setText(PILL_ROW, if needed then settings.freeText else "")
			sign.setIconShown(PILL_ROW, false)
		end

		sign.setText(STATUS_ROW, if unlocked then settings.unlockedText else settings.lockedText)
		sign.setColor(STATUS_ROW, if unlocked then Ui.colors.confirm else Ui.colors.danger)
	end
end

local function breakWall(wall: WallState)
	wall.downCount += 1
	local wasSolid = wall.standingTransparency < 1
	wall.part.Transparency = 1
	wall.part.CanCollide = false
	WallEffects.spawnPiecesAt(
		wall.part.Position,
		wall.part.Size.X,
		wall.part.Size.Y,
		{ wall.pieceColor },
		TrainingConfig.piecesPerWall,
		TrainingConfig.pieceSize
	)
	task.delay(TrainingConfig.wallBackSeconds, function()
		wall.downCount -= 1
		if wall.downCount == 0 then
			wall.part.Transparency = wall.standingTransparency
			wall.part.CanCollide = wasSolid
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

	-- The weapon leaves the hand: it starts where the tip of the weapon in the hand is, and the
	-- one in the hand is hidden while it flies.
	local y = LaneConfig.floorTopY + TrainingConfig.swordHeight
	local from = HandWeaponView.launchPose(character :: Model) or CFrame.new(root.Position.X, y, root.Position.Z)
	local to = CFrame.new(root.Position.X, y, wallZ(pad, #laneWalls))
	HandWeaponView.hideFor(character :: Model, TrainingConfig.flightSeconds)
	local sword = SwordView.create(
		"MyTrainingSword",
		TrainingConfig.swordScale,
		player:GetAttribute(Remotes.Attributes.EquippedWeapon)
	)
	SwordView.moveTo(sword, from)

	local elapsed = 0
	local nextWall = 1
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local progress = math.clamp(elapsed / TrainingConfig.flightSeconds, 0, 1)
		-- From the hand (place and direction) straight to the last wall, turning to point along the lane.
		local pose = from:Lerp(to, progress)
		local position = pose.Position
		SwordView.moveTo(sword, pose)

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
		buildSign(laneIndex, folder)
	end
	folder.Parent = Workspace

	refreshSigns()
	player:GetAttributeChangedSignal(Remotes.Attributes.Rebirths):Connect(refreshSigns)
	-- The small movements of the themed lanes, once the server's lanes have arrived.
	task.spawn(TrainingDecorView.start)

	Remotes.TrainingThrow.OnClientEvent:Connect(function(_gained: unknown, lane: unknown)
		if typeof(lane) ~= "number" or not walls[lane] then
			return
		end
		local laneIndex: number = lane
		-- The throw animation first; the weapon leaves the hand at its release moment.
		ThrowAnimation.playOwn(AnimationConfig.trainingThrow)
		task.delay(AnimationConfig.trainingThrow.releaseSeconds, launchSword, laneIndex)
	end)
end

return TrainingView
