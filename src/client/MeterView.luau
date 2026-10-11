--!strict
-- Draws the meter (upright bar, red at the ends, green in the middle, swinging pointer) next to
-- the THROW button, and the "x1.4" label above the button. Only drawing here; when to show what
-- is decided by ThrowController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local UiLayout = require(Shared.Rules.UiLayout)

local Draw = require(script.Parent.Ui.Draw)
local Hud = require(script.Parent.Ui.Hud)
local OutlinedText = require(script.Parent.Ui.OutlinedText)

local MeterView = {}

local bar: Frame
local pointer: Frame
local factorLabel: OutlinedText.OutlinedText
local hideLabelToken = 0

function MeterView.create()
	local settings = Ui.meter
	local gui = Hud.gui()

	bar = Draw.box("Meter", gui)
	bar.Visible = false

	-- Top to bottom: red, yellow, green (middle), yellow, red.
	local colors = Draw.panel("Colors", Ui.text.color, bar)
	Draw.corner(colors, Ui.corners.bar)
	Draw.border(colors)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Draw.color(settings.endColor)),
		ColorSequenceKeypoint.new(settings.betweenAt, Draw.color(settings.betweenColor)),
		ColorSequenceKeypoint.new(0.5, Draw.color(settings.middleColor)),
		ColorSequenceKeypoint.new(1 - settings.betweenAt, Draw.color(settings.betweenColor)),
		ColorSequenceKeypoint.new(1, Draw.color(settings.endColor)),
	})
	gradient.Parent = colors

	pointer = Draw.panel("Pointer", settings.pointerColor, bar)
	pointer.AnchorPoint = Vector2.new(0.5, 0.5)
	pointer.Size = UDim2.fromScale(settings.pointerWidthScale, settings.pointerHeightScale)
	pointer.ZIndex = 2
	Draw.corner(pointer, Ui.corners.bar)
	Draw.border(pointer)

	factorLabel = OutlinedText.new({ name = "FactorLabel", parent = gui })
	factorLabel.frame.Visible = false

	Hud.onLayout(function(layout: UiLayout.Hud)
		Draw.place(bar, layout.meter)
		Draw.place(factorLabel.frame, layout.factorLabel)
	end)
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
	factorLabel.setText(string.format(`x%.{Ui.factorLabel.decimals}f`, factor))
	factorLabel.frame.Visible = true
	hideLabelToken += 1
	local token = hideLabelToken
	task.delay(seconds, function()
		-- Only hide if no newer factor was shown in the meantime.
		if token == hideLabelToken then
			factorLabel.frame.Visible = false
		end
	end)
end

return MeterView
