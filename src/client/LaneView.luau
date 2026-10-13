--!strict
-- Builds and breaks this player's own walls. Parts created on the client are not sent
-- to the server, so no other player sees them or sees them break.
-- How a wall looks comes from the look of its zone (Config/Ui, world.lane): its color, and for
-- zones that have them a pattern (stripes, a band) and a thin frame, drawn on the side the
-- thrower sees. The pattern is a picture on the wall, not extra parts.
-- A zone can show a model instead (Config/Ui, wall.model): then the wall stays where it is,
-- invisible, and the model stands at the same place as its shell, without collision. A shell
-- has no scratch; it rocks and turns darker when the weapon bounces off it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LaneConfig = require(ReplicatedStorage.Shared.Config.Lane)
local Ui = require(ReplicatedStorage.Shared.Config.Ui)
local WallConfig = require(ReplicatedStorage.Shared.Config.Walls)
local Walls = require(ReplicatedStorage.Shared.Rules.Walls)
local LaneLayout = require(ReplicatedStorage.Shared.Rules.LaneLayout)
local ZoneLook = require(ReplicatedStorage.Shared.Rules.ZoneLook)

local FOLDER_NAME = "MyWalls"
local FRAME_NAME = "Frame"
-- How long to wait for the templates when the game starts.
local TEMPLATES_WAIT_SECONDS = 10

-- The model shown instead of a wall.
type Shell = {
	model: Model,
	-- Where it stands when nothing moves it.
	home: CFrame,
	parts: { BasePart },
	colors: { Color3 },
	hit: ZoneLook.WallHit?,
	-- When it was last hit, while it still rocks.
	hitAt: number?,
}

local LaneView = {}

local shells: { [number]: Shell } = {}
local rocking: RBXScriptConnection? = nil
local warnedAbout: { [string]: boolean } = {}

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

local function findTemplate(name: string): Model?
	local templates = ReplicatedStorage:WaitForChild(Ui.world.decor.templateFolder, TEMPLATES_WAIT_SECONDS)
	local template = templates and templates:FindFirstChild(name)
	if template and template:IsA("Model") then
		return template
	end
	if not warnedAbout[name] then
		warnedAbout[name] = true
		warn(`[LaneView] template {name} not found in ReplicatedStorage, the plain wall is shown instead`)
	end
	return nil
end

-- The model of a wall, standing where the wall stands. nil if it cannot be built.
local function buildShell(settings: ZoneLook.WallModel, wallPosition: Vector3, folder: Folder, index: number): Shell?
	local place =
		ZoneLook.wallModelPlace(settings, LaneConfig.laneWidth, LaneConfig.wallHeight, LaneConfig.wallThickness)
	local template = findTemplate(settings.template)
	if not place or not template then
		return nil
	end
	local model = template:Clone()
	model.Name = `WallModel{index}`
	-- The whole model evenly bigger; its shape is not changed.
	model:ScaleTo(model:GetScale() * place.scale)
	local parts: { BasePart } = {}
	local colors: { Color3 } = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			table.insert(parts, part)
			table.insert(colors, part.Color)
		end
	end
	-- The model's pivot is the middle of its foot. The thrower stands towards positive Z.
	local home =
		CFrame.new(wallPosition.X, LaneConfig.floorTopY - place.sinkStuds, wallPosition.Z + place.towardsThrower)
	model:PivotTo(home)
	model.Parent = folder
	return { model = model, home = home, parts = parts, colors = colors, hit = settings.hit }
end

local function rock()
	local now = os.clock()
	local busy = false
	for _, shell in shells do
		local hit, hitAt = shell.hit, shell.hitAt
		if hit and hitAt then
			local time = now - hitAt
			if time >= hit.wobbleSeconds then
				shell.hitAt = nil
				shell.model:PivotTo(shell.home)
			else
				-- Hit from the front, so the top goes back first.
				local lean = -math.rad(ZoneLook.wobbleDegrees(hit, time))
				shell.model:PivotTo(shell.home * CFrame.Angles(lean, 0, 0))
				busy = true
			end
		end
	end
	if not busy and rocking then
		rocking:Disconnect()
		rocking = nil
	end
end

function LaneView.build()
	local old = getFolder()
	if old then
		old:Destroy()
	end
	shells = {}

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
		local wallModel = ZoneLook.wallModel(Ui.world.lane, wall.material)
		local shell = if wallModel then buildShell(wallModel, part.Position, folder, index) else nil
		if shell then
			-- The model is what the player sees; the wall itself only stops the player.
			shells[index] = shell
			part.Transparency = 1
		elseif frameColor or #pattern > 0 then
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
	local shell = shells[index]
	if shell then
		shell.model.Parent = nil
	end
end

-- The weapon bounced off this wall. A wall shown as a model rocks briefly and turns darker
-- until the walls are reset; other walls do nothing here (they get a scratch).
function LaneView.hitWall(index: number)
	local shell = shells[index]
	local hit = shell and shell.hit
	if not shell or not hit then
		return
	end
	local darken = ZoneLook.hitDarken(hit)
	for at, part in shell.parts do
		part.Color = shell.colors[at]:Lerp(Color3.new(0, 0, 0), darken)
	end
	shell.hitAt = os.clock()
	if not rocking then
		rocking = RunService.Heartbeat:Connect(rock)
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
		local shell = shells[index]
		if part then
			part.Transparency = if shell then 1 else 0
			part.CanCollide = true
			part:SetAttribute("Broken", nil)
			showFrame(part, true)
		end
		if shell then
			shell.hitAt = nil
			for at, shellPart in shell.parts do
				shellPart.Color = shell.colors[at]
			end
			shell.model:PivotTo(shell.home)
			shell.model.Parent = getFolder()
		end
	end
end

return LaneView
