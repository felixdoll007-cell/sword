--!strict
-- The ground of the whole map: plain calm green as far as anyone can see, instead of a small
-- grey plate. Laid from a few very big tiles next to each other (Rules/Ground), with its surface
-- clearly below all floors, so nothing lies on top of it at almost the same height.
-- Only looks. All values are in Config/Ui (world.ground).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local Ground = require(Shared.Rules.Ground)

-- The plate that exists before the game starts (see default.project.json). It becomes the
-- first tile, so there is ground at every moment.
local PLATE_NAME = "Baseplate"
local FOLDER_NAME = "Ground"

local GroundLook = {}

local function shape(part: BasePart, tile: Ground.Tile)
	local settings = Ui.world.ground
	part.Anchored = true
	part.Locked = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Color = Color3.fromRGB(settings.color[1], settings.color[2], settings.color[3])
	part.Size = Vector3.new(tile.size, tile.thickness, tile.size)
	part.Position = Vector3.new(tile.x, tile.y, tile.z)
end

function GroundLook.build()
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	for index, tile in Ground.tiles(Ui.world.ground) do
		local plate = if index == 1 then Workspace:FindFirstChild(PLATE_NAME) else nil
		if plate and plate:IsA("BasePart") then
			shape(plate, tile)
		else
			local part = Instance.new("Part")
			part.Name = `GroundTile{index}`
			shape(part, tile)
			part.Parent = folder
		end
	end
	folder.Parent = Workspace
end

return GroundLook
