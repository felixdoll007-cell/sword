--!strict
-- Draws the meter (upright bar, red at the ends, green in the middle, swinging pointer)
-- and the "x1.4" label. Only drawing here; when to show what is decided by ThrowController.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)

local MeterView = {}

local bar: Frame
local pointer: Frame
local factorLabel: TextLabel
local hideLabelToken = 0

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

function MeterView.create()
	local settings = Ui.meter
	local gui = Instance.new("ScreenGui")
	gui.Name = "MeterGui"
	gui.ResetOnSpawn = false

	bar = Instance.new("Frame")
	bar.Name = "MeterBar"
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Position = UDim2.fromScale(settings.positionX, settings.positionY)
	-- Full width as the outer box; the aspect ratio makes it as wide as the height allows.
	bar.Size = UDim2.fromScale(1, settings.heightScale)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.Visible = false
	bar.Parent = gui

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = settings.aspectRatio
	aspect.Parent = bar

	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(settings.minWidth, settings.minHeight)
	limits.MaxSize = Vector2.new(settings.maxWidth, settings.maxHeight)
	limits.Parent = bar

	-- Top to bottom: red, yellow, green (middle), yellow, red.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color(settings.endColor)),
		ColorSequenceKeypoint.new(settings.betweenAt, color(settings.betweenColor)),
		ColorSequenceKeypoint.new(0.5, color(settings.middleColor)),
		ColorSequenceKeypoint.new(1 - settings.betweenAt, color(settings.betweenColor)),
		ColorSequenceKeypoint.new(1, color(settings.endColor)),
	})
	gradient.Parent = bar

	local border = Instance.new("UIStroke")
	border.Color = color(settings.borderColor)
	border.Thickness = settings.borderThickness
	border.Parent = bar

	pointer = Instance.new("Frame")
	pointer.Name = "Pointer"
	pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Size = UDim2.fromScale(settings.pointerWidthScale, settings.pointerHeightScale)
	pointer.BackgroundColor3 = color(settings.pointerColor)
	pointer.BorderSizePixel = 0
	pointer.ZIndex = 2
	pointer.Parent = bar

	local pointerBorder = Instance.new("UIStroke")
	pointerBorder.Color = color(settings.borderColor)
	pointerBorder.Thickness = settings.borderThickness
	pointerBorder.Parent = pointer

	local labelSettings = Ui.factorLabel
	factorLabel = Instance.new("TextLabel")
	factorLabel.Name = "FactorLabel"
	factorLabel.AnchorPoint = Vector2.new(0.5, 1)
	factorLabel.Position = UDim2.fromScale(0.5, labelSettings.positionY)
	factorLabel.Size = UDim2.fromScale(labelSettings.widthScale, labelSettings.heightScale)
	factorLabel.BackgroundTransparency = 1
	factorLabel.Font = Enum.Font.GothamBlack
	factorLabel.TextScaled = true
	factorLabel.TextColor3 = color(labelSettings.textColor)
	factorLabel.TextStrokeColor3 = color(labelSettings.strokeColor)
	factorLabel.TextStrokeTransparency = 0
	factorLabel.Visible = false
	factorLabel.Parent = gui

	local labelLimits = Instance.new("UISizeConstraint")
	labelLimits.MinSize = Vector2.new(0, labelSettings.minHeight)
	labelLimits.Parent = factorLabel

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function MeterView.show()
	bar.Visible = true
end

function MeterView.hide()
	bar.Visible = false
end

-- position: -1 = bottom end, 0 = middle, 1 = top end.
function MeterView.setPointer(position: number)
	pointer.Position = UDim2.fromScale(0.5, 0.5 - position / 2)
end

-- Shows "x1.4" for a few seconds.
function MeterView.showFactor(factor: number, seconds: number)
	-- Rounded normally (not down like other numbers), so a perfect 1.497 shows as "x1.5".
	factorLabel.Text = string.format(`x%.{Ui.factorLabel.decimals}f`, factor)
	factorLabel.Visible = true
	hideLabelToken += 1
	local token = hideLabelToken
	task.delay(seconds, function()
		-- Only hide if no newer factor was shown in the meantime.
		if token == hideLabelToken then
			factorLabel.Visible = false
		end
	end)
end

return MeterView
