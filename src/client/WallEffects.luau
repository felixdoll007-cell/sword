--!strict
-- Pieces of broken walls and the scratch on the wall the sword bounced off. Client only.
-- The number of pieces is capped (per wall and in total) so weak phones stay smooth.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local ThrowVisuals = require(Shared.Config.ThrowVisuals)
local WallConfig = require(Shared.Config.Walls)
local LaneLayout = require(Shared.Rules.LaneLayout)
local Walls = require(Shared.Rules.Walls)

local FOLDER_NAME = "MyEffects"

local WallEffects = {}

local activePieces = 0
local random = Random.new()
local scratch: BasePart? = nil

local function getFolder(): Folder
	local folder = Workspace:FindFirstChild(FOLDER_NAME) :: Folder?
	if not folder then
		local newFolder = Instance.new("Folder")
		newFolder.Name = FOLDER_NAME
		newFolder.Parent = Workspace
		return newFolder
	end
	return folder
end

local function wallZ(index: number): number
	return LaneConfig.throwLine.z - LaneLayout.wallDistance(LaneConfig, WallConfig, index)
end

function WallEffects.spawnPieces(index: number)
	local wall = Walls.get(WallConfig, index)
	if not wall then
		return
	end
	local v = ThrowVisuals
	local count = math.min(v.piecesPerWall, v.maxActivePieces - activePieces)
	if count <= 0 then
		return
	end

	local rgb = LaneConfig.materialColors[wall.material]
	local folder = getFolder()
	for _ = 1, count do
		local piece = Instance.new("Part")
		piece.Name = "Piece"
		piece.Size = Vector3.one * v.pieceSize
		piece.Color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		piece.TopSurface = Enum.SurfaceType.Smooth
		piece.BottomSurface = Enum.SurfaceType.Smooth
		piece.CanTouch = false
		piece.CanQuery = false
		piece.CastShadow = false
		piece.Position = Vector3.new(
			LaneConfig.throwLine.x + random:NextNumber(-0.5, 0.5) * LaneConfig.laneWidth,
			LaneConfig.floorTopY + random:NextNumber(0.2, 0.8) * LaneConfig.wallHeight,
			wallZ(index)
		)
		piece.AssemblyLinearVelocity = Vector3.new(
			random:NextNumber(-1, 1) * v.pieceSideSpeed,
			random:NextNumber(0.3, 1) * v.pieceUpSpeed,
			-v.pieceForwardSpeed
		)
		piece.Parent = folder
		activePieces += 1

		task.delay(v.pieceLifetimeSeconds, function()
			piece:Destroy()
			activePieces -= 1
		end)
	end
end

-- Dark scratch on the front of the wall, at the height where the sword hit it.
function WallEffects.addScratch(index: number)
	WallEffects.clearScratch()
	local v = ThrowVisuals
	local part = Instance.new("Part")
	part.Name = "Scratch"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Size = Vector3.new(v.scratchLength, v.scratchWidth, LaneConfig.wallThickness / 10)
	part.Color = Color3.fromRGB(v.scratchColor[1], v.scratchColor[2], v.scratchColor[3])
	part.CFrame = CFrame.new(
		LaneConfig.throwLine.x,
		LaneConfig.floorTopY + v.swordHeight,
		wallZ(index) + LaneConfig.wallThickness / 2
	) * CFrame.Angles(0, 0, math.rad(v.scratchTiltDegrees))
	part.Parent = getFolder()
	scratch = part
end

function WallEffects.clearScratch()
	if scratch then
		scratch:Destroy()
		scratch = nil
	end
end

return WallEffects
