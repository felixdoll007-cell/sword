--!strict
-- A training lane in its finished look, for lanes that have a theme (Config/Ui, world.training).
-- Built in layers from the outside to the inside:
--   a) a slightly raised frame all around the field
--   b) the themed floor inside it, with props (e.g. hay bales) and flat tufts as litter
--   c) the sunken throw strip in the middle with a stepped stone edge, and the target at its end
--   d) the raised start pad, with four corner marks and an arrow in throw direction
-- Only looks. Where the pad is and what training does is not changed (Config/Training). The
-- one thing that differs from a plain lane: the invisible fence follows the outline of the
-- field instead of the old narrow floor, so players stay out of everything in front of the pad.
--
-- Where each piece lies is worked out in Rules/TrainingLook. All pieces lie next to each
-- other; only the stones and tufts lie on a floor, clearly above it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local TrainingConfig = require(Shared.Config.Training)
local Ui = require(Shared.Config.Ui)
local Layout = require(Shared.Rules.TrainingLook)

local WorldParts = require(script.Parent.WorldParts)

local TrainingLook = {}

-- The theme of a lane, or nil if the lane is plain.
function TrainingLook.themeOf(laneIndex: number): any?
	local training = Ui.world.training
	local name = (training.laneThemes :: { [number]: string })[laneIndex]
	return if name then (training.themes :: { [string]: any })[name] else nil
end

local function whiteBar(
	gui: SurfaceGui,
	name: string,
	x: number,
	y: number,
	width: number,
	height: number,
	turn: number?
)
	local bar = Instance.new("Frame")
	bar.Name = name
	bar.BorderSizePixel = 0
	bar.BackgroundColor3 = WorldParts.color(Ui.world.training.padMark.color)
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromOffset(math.round(x), math.round(y))
	bar.Size = UDim2.fromOffset(math.round(width), math.round(height))
	bar.Rotation = turn or 0
	bar.Parent = gui
end

-- White marks on the pad: a bracket in each corner and an arrow pointing in throw direction.
-- Drawn from plain bars, so no picture is needed. On the drawing, "up" is the throw direction.
local function addPadMarks(folder: Instance, pad: Layout.Area, topY: number)
	local settings = Ui.world.training.padMark
	local gui =
		WorldParts.addFloorCanvas(folder, "TrainingPadMarks", pad, topY + settings.aboveFloor, settings.pixelsPerStud)
	local width, height = pad.width * settings.pixelsPerStud, pad.length * settings.pixelsPerStud
	local short = math.min(width, height)
	local line = short * settings.lineShare
	local arm = short * settings.cornerShare
	local inset = short * settings.insetShare

	-- Corners: a bar along the edge across and one along the edge up and down, meeting in the corner.
	for _, sideX in { -1, 1 } do
		for _, sideY in { -1, 1 } do
			local cornerX = width / 2 + sideX * (width / 2 - inset)
			local cornerY = height / 2 + sideY * (height / 2 - inset)
			whiteBar(gui, "Corner", cornerX - sideX * arm / 2, cornerY - sideY * line / 2, arm, line)
			whiteBar(gui, "Corner", cornerX - sideX * line / 2, cornerY - sideY * arm / 2, line, arm)
		end
	end

	-- Arrow: a shaft and two bars forming its head, tip at the top.
	local length = height * settings.arrowShare
	local head = short * settings.arrowHeadShare
	local tipY = height / 2 - length / 2
	whiteBar(gui, "ArrowShaft", width / 2, tipY + length / 2 + line / 2, line, length - line)
	local reach = head / 2 * math.sqrt(0.5)
	whiteBar(gui, "ArrowHead", width / 2 - reach, tipY + reach, line, head, 45)
	whiteBar(gui, "ArrowHead", width / 2 + reach, tipY + reach, line, head, -45)
end

-- Builds the themed lane into this folder. Call only for a lane that has a theme.
function TrainingLook.build(folder: Instance, laneIndex: number)
	local theme = TrainingLook.themeOf(laneIndex)
	if not theme then
		return
	end
	local field = Ui.world.training.field
	local floorTopY = LaneConfig.floorTopY

	-- a) Frame.
	for index, strip in Layout.frame(TrainingConfig, field, laneIndex) do
		local part =
			WorldParts.addBlock(folder, `Frame{index}`, strip, floorTopY + field.frameHeight, theme.frame.darkColor)
		WorldParts.addFloorTile(part, theme.frame.lightColor, theme.frame.fieldStuds)
	end

	-- b) Themed floor.
	for index, band in Layout.floors(TrainingConfig, field, laneIndex) do
		local part =
			WorldParts.addBlock(folder, `ThemeFloor{index}`, band, floorTopY + field.floorHeight, theme.floor.darkColor)
		WorldParts.addFloorTile(part, theme.floor.lightColor, theme.floor.fieldStuds)
	end

	-- c) Throw strip with its stone edge.
	WorldParts.addBlock(folder, "Floor", Layout.strip(TrainingConfig, field, laneIndex), floorTopY, theme.strip.color)
	for index, stone in Layout.stones(TrainingConfig, field, laneIndex, floorTopY, theme.strip.stones) do
		WorldParts.addBlock(folder, `StripStone{index}`, stone.area, stone.topY, theme.strip.stoneColor)
	end

	-- d) Start pad.
	local padArea = Layout.pad(TrainingConfig, laneIndex)
	local padTopY = floorTopY + field.padHeight
	local pad = WorldParts.addBlock(folder, "TrainingPad", padArea, padTopY, theme.pad.darkColor)
	WorldParts.addFloorTile(pad, theme.pad.lightColor, theme.pad.fieldStuds)
	addPadMarks(folder, padArea, padTopY)

	-- Players stay out of everything in front of the pad.
	for index, fence in Layout.fences(TrainingConfig, field, laneIndex) do
		WorldParts.addInvisibleWall(folder, `Fence{index}`, fence, LaneConfig.barrierHeight)
	end

	-- Target and props: decoration without collision.
	WorldParts.addProp(
		folder,
		"Target",
		theme.target.model,
		Layout.target(TrainingConfig, laneIndex, floorTopY, theme.target)
	)
	for index, prop in theme.props do
		WorldParts.addProp(
			folder,
			`Prop{index}`,
			prop.model,
			Layout.prop(TrainingConfig, field, laneIndex, floorTopY, prop)
		)
	end

	-- Flat tufts as litter.
	for index, tuft in theme.tufts do
		local block = Layout.tuft(TrainingConfig, field, laneIndex, floorTopY, tuft)
		local part = WorldParts.addBlock(folder, `Tuft{index}`, block.area, block.topY, theme.tuftColor)
		-- Only as thick as it stands above its floor, and turned.
		part.Size = Vector3.new(block.area.width, field.tuftHeight, block.area.length)
		part.CFrame = CFrame.new(block.area.x, block.topY - field.tuftHeight / 2, block.area.z)
			* CFrame.Angles(0, math.rad(block.yawDegrees), 0)
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.CastShadow = false
	end
end

return TrainingLook
