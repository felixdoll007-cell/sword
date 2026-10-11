--!strict
-- Building block: text in the game's one font, with a thick black border around every letter
-- and a small hard shadow below it. Every text of the interface is made with this.
--
-- The text fills the box it is given (it scales). Border and shadow grow and shrink with the
-- text, so they look the same on a phone and on a monitor.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)
local Draw = require(script.Parent.Draw)

export type Props = {
	name: string?,
	parent: Instance?,
	text: string?,
	color: { number }?,
	-- Left, Center (default) or Right inside its box.
	alignX: Enum.TextXAlignment?,
	alignY: Enum.TextYAlignment?,
	-- false for text without the shadow (default: with shadow).
	shadow: boolean?,
}

export type OutlinedText = {
	-- The box. Give it a size and a position like any other element.
	frame: Frame,
	label: TextLabel,
	setText: (text: string) -> (),
	setColor: (rgb: { number }) -> (),
	-- 0 = fully visible, 1 = invisible. Text, border and shadow together.
	setTransparency: (transparency: number) -> (),
	-- Fades the text out within this time and returns the animation.
	fadeOut: (seconds: number) -> Tween,
}

local OutlinedText = {}

local function makeLabel(name: string, parent: Instance): (TextLabel, UIStroke)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Draw.font()
	label.TextScaled = true
	label.Text = ""
	label.Parent = parent

	local smallest = Instance.new("UITextSizeConstraint")
	smallest.MinTextSize = Ui.text.minTextSize
	smallest.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.LineJoinMode = Enum.LineJoinMode.Round
	stroke.Thickness = Ui.text.minStroke
	stroke.Parent = label
	return label, stroke
end

function OutlinedText.new(props: Props): OutlinedText
	local settings = Ui.text
	local frame = Draw.box(props.name or "Text", nil)

	local shadow: TextLabel? = nil
	local shadowStroke: UIStroke? = nil
	if props.shadow ~= false then
		local label, stroke = makeLabel("Shadow", frame)
		label.TextColor3 = Draw.color(settings.shadowColor)
		stroke.Color = Draw.color(settings.shadowColor)
		shadow, shadowStroke = label, stroke
	end

	local label, stroke = makeLabel("Label", frame)
	label.ZIndex = 2
	label.TextColor3 = Draw.color(props.color or settings.color)
	stroke.Color = Draw.color(settings.strokeColor)

	local function forBoth(apply: (TextLabel) -> ())
		apply(label)
		if shadow then
			apply(shadow)
		end
	end
	forBoth(function(each: TextLabel)
		each.TextXAlignment = props.alignX or Enum.TextXAlignment.Center
		each.TextYAlignment = props.alignY or Enum.TextYAlignment.Center
		each.Text = props.text or ""
	end)

	-- Border and shadow follow the height the text really has on screen.
	local function fitToTextSize()
		local height = label.TextBounds.Y
		local thickness = math.clamp(height * settings.strokeShare, settings.minStroke, settings.maxStroke)
		stroke.Thickness = thickness
		if shadow and shadowStroke then
			shadowStroke.Thickness = thickness
			shadow.Position = UDim2.fromOffset(0, math.max(math.round(height * settings.shadowShare), 1))
		end
	end
	label:GetPropertyChangedSignal("TextBounds"):Connect(fitToTextSize)
	fitToTextSize()

	local function setTransparency(transparency: number)
		label.TextTransparency = transparency
		stroke.Transparency = transparency
		if shadow and shadowStroke then
			shadow.TextTransparency = transparency
			shadowStroke.Transparency = transparency
		end
	end

	local function fadeOut(seconds: number): Tween
		local info = TweenInfo.new(seconds)
		if shadow and shadowStroke then
			TweenService:Create(shadow, info, { TextTransparency = 1 }):Play()
			TweenService:Create(shadowStroke, info, { Transparency = 1 }):Play()
		end
		TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		local tween = TweenService:Create(label, info, { TextTransparency = 1 })
		tween:Play()
		return tween
	end

	frame.Parent = props.parent
	return {
		frame = frame,
		label = label,
		setText = function(text: string)
			forBoth(function(each: TextLabel)
				each.Text = text
			end)
		end,
		setColor = function(rgb: { number })
			label.TextColor3 = Draw.color(rgb)
		end,
		setTransparency = setTransparency,
		fadeOut = fadeOut,
	}
end

return OutlinedText
