--!strict
-- Builds what every player sees: the throw zone and the lane floor.
-- The walls are NOT built here. Each client builds its own (see client/LaneView).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LaneConfig = require(ReplicatedStorage.Shared.Config.Lane)
local WallConfig = require(ReplicatedStorage.Shared.Config.Walls)
local LaneLayout = require(ReplicatedStorage.Shared.Rules.LaneLayout)

local LaneBuilder = {}

local function setUpPart(part: BasePart, name: string, size: Vector3, position: Vector3, color: { number })
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = Color3.fromRGB(color[1], color[2], color[3])
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

function LaneBuilder.build()
	local folder = Instance.new("Folder")
	folder.Name = "Lane"

	local x = LaneConfig.throwLine.x
	local z = LaneConfig.throwLine.z
	local floorCenterY = LaneConfig.floorTopY - LaneConfig.floorThickness / 2

	-- The lane runs towards negative Z, the throw zone lies behind the throw line.
	local laneLength = LaneLayout.laneLength(LaneConfig, WallConfig)
	local floor = Instance.new("Part")
	setUpPart(
		floor,
		"Floor",
		Vector3.new(LaneConfig.laneWidth, LaneConfig.floorThickness, laneLength),
		Vector3.new(x, floorCenterY, z - laneLength / 2),
		LaneConfig.floorColor
	)
	floor.Parent = folder

	-- The throw zone is also where players spawn.
	local throwZone = Instance.new("SpawnLocation")
	setUpPart(
		throwZone,
		"ThrowZone",
		Vector3.new(LaneConfig.laneWidth, LaneConfig.floorThickness, LaneConfig.throwZoneLength),
		Vector3.new(x, floorCenterY, z + LaneConfig.throwZoneLength / 2),
		LaneConfig.throwZoneColor
	)
	throwZone.Duration = 0 -- no force field after spawning
	throwZone.Parent = folder

	folder.Parent = Workspace
end

return LaneBuilder
