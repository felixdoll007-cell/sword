--!strict
-- Builds and breaks this player's own walls. Parts created on the client are not sent
-- to the server, so no other player sees them or sees them break.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LaneConfig = require(ReplicatedStorage.Shared.Config.Lane)
local WallConfig = require(ReplicatedStorage.Shared.Config.Walls)
local Walls = require(ReplicatedStorage.Shared.Rules.Walls)
local LaneLayout = require(ReplicatedStorage.Shared.Rules.LaneLayout)

local FOLDER_NAME = "MyWalls"

local LaneView = {}

local function getFolder(): Folder?
	return Workspace:FindFirstChild(FOLDER_NAME) :: Folder?
end

local function getWallPart(index: number): BasePart?
	local folder = getFolder()
	if not folder then
		return nil
	end
	return folder:FindFirstChild(`Wall{index}`) :: BasePart?
end

function LaneView.build()
	local old = getFolder()
	if old then
		old:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	for index = 1, Walls.count(WallConfig) do
		local wall = Walls.get(WallConfig, index) :: Walls.Wall
		local distance = LaneLayout.wallDistance(LaneConfig, WallConfig, index)
		local color = LaneConfig.materialColors[wall.material]

		local part = Instance.new("Part")
		part.Name = `Wall{index}`
		part.Anchored = true
		part.CanTouch = false
		part.Size = Vector3.new(LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness)
		part.Position = Vector3.new(
			LaneConfig.throwLine.x,
			LaneConfig.floorTopY + LaneConfig.wallHeight / 2,
			LaneConfig.throwLine.z - distance
		)
		part.Color = Color3.fromRGB(color[1], color[2], color[3])
		part:SetAttribute("Material", wall.material)
		part:SetAttribute("Hardness", wall.hardness)
		part.Parent = folder
	end

	folder.Parent = Workspace
end

-- For now a broken wall just disappears. Pieces and effects come with the throw in Etappe 3.
function LaneView.breakWall(index: number)
	local part = getWallPart(index)
	if part then
		part.Transparency = 1
		part.CanCollide = false
		part:SetAttribute("Broken", true)
	end
end

-- Breaks the first wall that is still standing. Returns its number, or nil if all are broken.
function LaneView.breakNextWall(): number?
	for index = 1, Walls.count(WallConfig) do
		local part = getWallPart(index)
		if part and not part:GetAttribute("Broken") then
			LaneView.breakWall(index)
			return index
		end
	end
	return nil
end

-- After a throw all walls stand again.
function LaneView.resetWalls()
	for index = 1, Walls.count(WallConfig) do
		local part = getWallPart(index)
		if part then
			part.Transparency = 0
			part.CanCollide = true
			part:SetAttribute("Broken", nil)
		end
	end
end

return LaneView
