--!strict
-- Building block: a fixed symbol (Strength, Coins, Rebirths, lock, check mark).
-- If Config/Ui names a picture for it, that picture is shown. Until then a plain placeholder in
-- the right color is drawn from simple shapes, so no picture has to exist for the game to work.
-- The numbers below only describe those simple shapes (sizes and places as a share of the
-- symbol). They are gone as soon as real pictures exist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local ColorMath = require(Shared.Rules.ColorMath)
local Draw = require(script.Parent.Draw)

export type Kind = "strength" | "coins" | "rebirths" | "lock" | "check"

-- How much darker the ring on the coin is than the coin.
local COIN_RING_DARKEN = 0.3

local Icon = {}

local function shape(name: string, rgb: { number }, size: UDim2, position: UDim2, parent: Instance): Frame
	local frame = Draw.panel(name, rgb, parent)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Size = size
	frame.Position = position
	return frame
end

local function circle(name: string, rgb: { number }, size: number, parent: Instance, bordered: boolean): Frame
	local frame = shape(name, rgb, UDim2.fromScale(size, size), UDim2.fromScale(0.5, 0.5), parent)
	Draw.corner(frame, Ui.corners.round)
	if bordered then
		Draw.border(frame, nil, Ui.borderThickness - 1)
	end
	return frame
end

-- Strength: an orange diamond.
local function drawStrength(parent: Instance)
	local diamond = shape("Diamond", Ui.colors.strength, UDim2.fromScale(0.62, 0.62), UDim2.fromScale(0.5, 0.5), parent)
	diamond.Rotation = 45
	Draw.corner(diamond, 0.18)
	Draw.border(diamond, nil, Ui.borderThickness - 1)
end

-- Coins: a golden coin.
local function drawCoins(parent: Instance)
	local coin = circle("Coin", Ui.colors.coins, 0.84, parent, true)
	local inner = circle("Inner", Ui.colors.coins, 0.56, coin, false)
	inner.BackgroundTransparency = 1
	Draw.border(inner, ColorMath.darken(Ui.colors.coins, COIN_RING_DARKEN), Ui.borderThickness - 1)
end

-- Rebirths: a steel-blue ring.
local function drawRebirths(parent: Instance)
	local ring = circle("Ring", Ui.colors.rebirths, 0.84, parent, true)
	local hole = circle("Hole", Ui.colors.windowInner, 0.42, ring, true)
	hole.ZIndex = 2
end

-- Lock: a body with a shackle behind it.
local function drawLock(parent: Instance)
	local shackle = shape("Shackle", Ui.colors.lock, UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.5, 0.36), parent)
	Draw.corner(shackle, Ui.corners.round)
	Draw.border(shackle, nil, Ui.borderThickness - 1)
	local hole = shape("Hole", Ui.colors.border, UDim2.fromScale(0.4, 0.5), UDim2.fromScale(0.5, 0.56), shackle)
	Draw.corner(hole, Ui.corners.round)
	local body = shape("Body", Ui.colors.lock, UDim2.fromScale(0.78, 0.5), UDim2.fromScale(0.5, 0.7), parent)
	body.ZIndex = 2
	Draw.corner(body, 0.2)
	Draw.border(body, nil, Ui.borderThickness - 1)
end

-- Check mark: a green circle with a white tick made of two bars.
local function drawCheck(parent: Instance)
	local disc = circle("Disc", Ui.colors.confirm, 0.92, parent, true)
	local short = shape("Short", Ui.text.color, UDim2.fromScale(0.16, 0.34), UDim2.fromScale(0.34, 0.6), disc)
	short.Rotation = -45
	Draw.corner(short, Ui.corners.round)
	local long = shape("Long", Ui.text.color, UDim2.fromScale(0.16, 0.58), UDim2.fromScale(0.58, 0.5), disc)
	long.Rotation = 45
	Draw.corner(long, Ui.corners.round)
end

local DRAWERS: { [string]: (Instance) -> () } = {
	strength = drawStrength,
	coins = drawCoins,
	rebirths = drawRebirths,
	lock = drawLock,
	check = drawCheck,
}

-- A picture that keeps its shape inside the room it is given.
function Icon.image(name: string, image: string, parent: Instance?): ImageLabel
	local label = Instance.new("ImageLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.ScaleType = Enum.ScaleType.Fit
	label.Image = image
	label.Parent = parent
	return label
end

-- The symbol of this kind, square, filling the room it is given.
function Icon.new(kind: Kind, parent: Instance?): GuiObject
	local image = (Ui.icons :: { [string]: string })[kind]
	if image and image ~= "" then
		return Icon.image(kind, image, parent)
	end
	local frame = Draw.box(kind, nil)
	Draw.square(frame)
	DRAWERS[kind](frame)
	frame.Parent = parent
	return frame
end

return Icon
