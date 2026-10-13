--!strict
-- Builds and breaks this player's own walls. Parts created on the client are not sent
-- to the server, so no other player sees them or sees them break.
-- How a wall looks comes from the look of its zone (Config/Ui, world.lane): its color, and for
-- zones that have them a pattern (stripes, a band) and a thin frame, drawn on the side the
-- thrower sees. The pattern is a picture on the wall, not extra parts.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LaneConfig = require(ReplicatedStorage.Shared.Config.Lane)
local Ui = require(ReplicatedStorage.Shared.Config.Ui)
local WallConfig = require(ReplicatedStorage.Shared.Config.Walls)
local Walls = require(ReplicatedStorage.Shared.Rules.Walls)
local LaneLayout = require(ReplicatedStorage.Shared.Rules.LaneLayout)
local ZoneLook = require(ReplicatedStorage.Shared.Rules.ZoneLook)

local FOLDER_NAME = "MyWalls"
local FRAME_NAME = "Frame"

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

-- Frame and pattern are a picture on the wall, not a part, so they have to be hidden with the wall.
local function showFrame(part: BasePart, shown: boolean)
	local frame = part:FindFirstChild(FRAME_NAME)
	if frame and frame:IsA("SurfaceGui") then
		frame.Enabled = shown
	end
end

-- What is drawn on the wall, on the side that faces the throw zone: the pattern of its zone and
-- a thin frame around it.
local function addFace(part: BasePart, pattern: { ZoneLook.FaceRect }, frameRgb: { number }?)
	local settings = Ui.world.lane.wallFrame
	local gui = Instance.new("SurfaceGui")
	gui.Name = FRAME_NAME
	-- The lane runs towards negative Z, so the thrower looks at the wall's back face.
	gui.Face = Enum.NormalId.Back
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = settings.pixelsPerStud
	gui.LightInfluence = 1
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Later ones lie on top of earlier ones.
	for index, rect in pattern do
		local shape = Instance.new("Frame")
		shape.Name = "Pattern"
		shape.BorderSizePixel = 0
		shape.BackgroundColor3 = Color3.fromRGB(rect.color[1], rect.color[2], rect.color[3])
		shape.Position = UDim2.fromScale(rect.x, rect.y)
		shape.Size = UDim2.fromScale(rect.width, rect.height)
		shape.ZIndex = index
		shape.Parent = gui
	end

	if frameRgb then
		local thickness = settings.widthStuds * settings.pixelsPerStud
		local outline = Instance.new("Frame")
		outline.Name = "Outline"
		outline.BackgroundTransparency = 1
		outline.BorderSizePixel = 0
		outline.ZIndex = #pattern + 1
		-- The line is drawn around this box, so the box is smaller than the wall by the line's width.
		outline.AnchorPoint = Vector2.new(0.5, 0.5)
		outline.Position = UDim2.fromScale(0.5, 0.5)
		outline.Size = UDim2.new(1, -2 * thickness, 1, -2 * thickness)
		outline.Parent = gui

		local line = Instance.new("UIStroke")
		line.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		line.LineJoinMode = Enum.LineJoinMode.Miter
		line.Color = Color3.fromRGB(frameRgb[1], frameRgb[2], frameRgb[3])
		line.Thickness = thickness
		line.Parent = outline
	end

	gui.Parent = part
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
		local color = ZoneLook.wallColor(LaneConfig, Ui.world.lane, wall.material)
		local frameColor = ZoneLook.wallFrameColor(Ui.world.lane, wall.material)
		local pattern = ZoneLook.wallPattern(Ui.world.lane, wall.material)

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
		if frameColor or #pattern > 0 then
			addFace(part, pattern, frameColor)
		end
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
		showFrame(part, false)
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
			showFrame(part, true)
		end
	end
end

return LaneView
