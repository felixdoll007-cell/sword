--!strict
-- Small drawing helpers that every building block of the interface uses: colors, the font,
-- round corners, borders and the stud texture. All values come from Config/Ui.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local ColorMath = require(Shared.Rules.ColorMath)

local Draw = {}

function Draw.color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

-- The one font of the game.
function Draw.font(): Enum.Font
	return (Enum.Font :: any)[Ui.font]
end

-- A new screen layer. Layers with a higher order lie on top of those with a lower one.
function Draw.screen(name: string, displayOrder: number): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.DisplayOrder = displayOrder
	-- Inside a layer, a thing always lies on top of the thing it is in.
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return gui
end

-- An invisible frame, to group or to position things.
function Draw.box(name: string, parent: Instance?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent
	return frame
end

-- A plain colored surface.
function Draw.panel(name: string, rgb: { number }, parent: Instance?): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = Draw.color(rgb)
	frame.BorderSizePixel = 0
	frame.Size = UDim2.fromScale(1, 1)
	frame.Parent = parent
	return frame
end

-- share: share of the shorter side (0.5 = fully round).
function Draw.corner(parent: Instance, share: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(share, 0)
	corner.Parent = parent
	return corner
end

-- Border around a surface. Without a color: the black border of the style.
function Draw.border(parent: Instance, rgb: { number }?, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = Draw.color(rgb or Ui.colors.border)
	stroke.Thickness = thickness or Ui.borderThickness
	stroke.Parent = parent
	return stroke
end

-- Keeps a thing square inside the room it is given.
function Draw.square(parent: Instance): UIAspectRatioConstraint
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.Parent = parent
	return aspect
end

-- Puts a thing at a place worked out in pixels (Rules/UiLayout).
function Draw.place(thing: GuiObject, rect: { x: number, y: number, width: number, height: number })
	thing.AnchorPoint = Vector2.zero
	thing.Position = UDim2.fromOffset(math.round(rect.x), math.round(rect.y))
	thing.Size = UDim2.fromOffset(math.round(rect.width), math.round(rect.height))
end

export type Studs = {
	-- nil while there is no picture for the texture.
	image: ImageLabel?,
	setColor: (rgb: { number }) -> (),
}

-- The tiled stud texture on a surface of this color, in a lighter tone of it.
-- Does nothing while Config/Ui names no picture.
function Draw.studs(parent: Instance, rgb: { number }, cornerShare: number): Studs
	local settings = Ui.studs
	if settings.image == "" then
		return { image = nil, setColor = function() end }
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Studs"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromScale(1, 1)
	image.Image = settings.image
	image.ScaleType = Enum.ScaleType.Tile
	image.TileSize = UDim2.fromOffset(settings.tilePixels, settings.tilePixels)
	image.ImageTransparency = settings.transparency
	image.ImageColor3 = Draw.color(ColorMath.lighten(rgb, settings.lighten))
	image.Parent = parent
	Draw.corner(image, cornerShare)
	return {
		image = image,
		setColor = function(newRgb: { number })
			image.ImageColor3 = Draw.color(ColorMath.lighten(newRgb, settings.lighten))
		end,
	}
end

return Draw
