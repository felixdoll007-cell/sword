--!strict
-- Builds what every player sees: throw zone, main lane floor, training pads and training lane floors,
-- plus invisible barriers so nobody walks onto a lane.
-- The walls are NOT built here. Each client builds its own (see client/LaneView, client/TrainingView).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local TrainingConfig = require(Shared.Config.Training)
local WallConfig = require(Shared.Config.Walls)
local LaneLayout = require(Shared.Rules.LaneLayout)
local Training = require(Shared.Rules.Training)

local LaneBuilder = {}

local function addPart(
	folder: Folder,
	part: BasePart,
	name: string,
	size: Vector3,
	position: Vector3,
	color: { number }
): BasePart
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = Color3.fromRGB(color[1], color[2], color[3])
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = folder
	return part
end

local function floorCenterY(): number
	return LaneConfig.floorTopY - LaneConfig.floorThickness / 2
end

local function addInvisibleBarrier(folder: Folder, name: string, size: Vector3, x: number, z: number)
	local barrier = addPart(
		folder,
		Instance.new("Part"),
		name,
		size,
		Vector3.new(x, LaneConfig.floorTopY + LaneConfig.barrierHeight / 2, z),
		LaneConfig.floorColor
	)
	barrier.Transparency = 1
	barrier.CastShadow = false
end

-- A lane floor that starts at startZ and runs towards negative Z, fenced on the front and both sides.
local function addFencedLane(
	folder: Folder,
	x: number,
	startZ: number,
	width: number,
	length: number,
	color: { number }
)
	addPart(
		folder,
		Instance.new("Part"),
		"Floor",
		Vector3.new(width, LaneConfig.floorThickness, length),
		Vector3.new(x, floorCenterY(), startZ - length / 2),
		color
	)

	local thickness = LaneConfig.barrierThickness
	local height = LaneConfig.barrierHeight
	addInvisibleBarrier(folder, "FrontBarrier", Vector3.new(width, height, thickness), x, startZ - thickness / 2)
	for _, side in { -1, 1 } do
		addInvisibleBarrier(
			folder,
			"SideBarrier",
			Vector3.new(thickness, height, length),
			x + side * (width + thickness) / 2,
			startZ - length / 2
		)
	end
end

local function buildMainLane()
	local folder = Instance.new("Folder")
	folder.Name = "Lane"

	local x = LaneConfig.throwLine.x
	local z = LaneConfig.throwLine.z
	addFencedLane(
		folder,
		x,
		z,
		LaneConfig.laneWidth,
		LaneLayout.laneLength(LaneConfig, WallConfig),
		LaneConfig.floorColor
	)

	-- The throw zone lies behind the throw line. It is also where players spawn.
	local throwZone = addPart(
		folder,
		Instance.new("SpawnLocation"),
		"ThrowZone",
		Vector3.new(LaneConfig.laneWidth, LaneConfig.floorThickness, LaneConfig.throwZoneLength),
		Vector3.new(x, floorCenterY(), z + LaneConfig.throwZoneLength / 2),
		LaneConfig.throwZoneColor
	) :: SpawnLocation
	throwZone.Duration = 0 -- no force field after spawning

	folder.Parent = Workspace
end

local function buildTrainingLanes()
	for laneIndex = 1, Training.laneCount(TrainingConfig) do
		local pad = Training.lanePad(TrainingConfig, laneIndex) :: Training.Pad
		local folder = Instance.new("Folder")
		folder.Name = `TrainingLane{laneIndex}`

		local padFrontZ = pad.z - pad.length / 2
		addFencedLane(folder, pad.x, padFrontZ, pad.width, TrainingConfig.laneLength, TrainingConfig.laneColor)

		addPart(
			folder,
			Instance.new("Part"),
			"TrainingPad",
			Vector3.new(pad.width, LaneConfig.floorThickness, pad.length),
			Vector3.new(pad.x, floorCenterY(), pad.z),
			TrainingConfig.padColor
		)

		folder.Parent = Workspace
	end
end

function LaneBuilder.build()
	buildMainLane()
	buildTrainingLanes()
end

return LaneBuilder
