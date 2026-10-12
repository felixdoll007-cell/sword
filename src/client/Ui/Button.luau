--!strict
-- Building block: the button. A rectangle with slightly round corners, the stud texture, a black
-- border and a darker edge at the bottom that makes it look raised. Pressing sinks it by the
-- height of that edge; with a mouse over it, it grows a little. Works with touch and mouse.
-- The color tells what the button means (Config/Ui, colors).
-- A button can carry a dark pill next to its caption, for a price.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local ColorMath = require(Shared.Rules.ColorMath)

local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)
local Pill = require(script.Parent.Pill)

export type Props = {
	name: string,
	parent: Instance?,
	text: string,
	color: { number },
	-- How round the corners are (default: the button corners of the style). 0.5 = a round button.
	cornerShare: number?,
	-- A dark pill inside the button, right of the caption (HATCH with its price): its symbol
	-- and the color of its text. nil = a button with only a caption.
	pill: { icon: Icon.Kind?, color: { number }? }?,
	-- The key that also presses the button ("E"), as a small badge on its top left corner.
	-- Only the badge: listening to the key is up to whoever makes the button. Hidden at first.
	key: string?,
}

export type Button = {
	-- The whole button. Give it a size and a position like any other element.
	frame: Frame,
	setText: (text: string) -> (),
	-- The text in the button's pill. Does nothing on a button without a pill.
	setPillText: (text: string) -> (),
	-- Shows or hides the badge with the key. Does nothing on a button without a key.
	setKeyShown: (shown: boolean) -> (),
	setColor: (rgb: { number }) -> (),
	-- A button that is not enabled is grey, does not move and does not call onActivated.
	setEnabled: (enabled: boolean) -> (),
	-- Called when the button is pressed (touch, mouse or gamepad).
	onActivated: (callback: () -> ()) -> (),
}

local Button = {}

function Button.new(props: Props): Button
	local settings = Ui.button
	local corner = props.cornerShare or Ui.corners.button
	local rgb = props.color
	local enabled = true

	local frame = Draw.box(props.name, nil)
	local scale = Instance.new("UIScale")
	scale.Parent = frame

	-- The edge is the whole shape; the face covers all of it except a strip at the bottom.
	local edge = Draw.panel("Edge", ColorMath.darken(rgb, settings.edgeDarken), frame)
	Draw.corner(edge, corner)
	Draw.border(edge)

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.Text = ""
	face.AutoButtonColor = false
	face.BorderSizePixel = 0
	face.BackgroundColor3 = Draw.color(rgb)
	face.Size = UDim2.fromScale(1, 1 - settings.edgeShare)
	face.ZIndex = 2
	face.Parent = frame
	Draw.corner(face, corner)

	local studs = Draw.studs(face, rgb, corner)

	local text = OutlinedText.new({ name = "Caption", parent = face, text = props.text })
	text.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	text.frame.Position = UDim2.fromScale(0.5, 0.5)
	text.frame.Size = UDim2.fromScale(settings.textWidth, settings.textHeight)
	text.frame.ZIndex = 2

	local pill: Pill.Pill? = nil
	if props.pill then
		local places = settings.withPill
		text.frame.Position = UDim2.fromScale(places.captionCenterX, 0.5)
		text.frame.Size = UDim2.fromScale(places.captionWidth, settings.textHeight)
		local made = Pill.new({ parent = face, icon = props.pill.icon, color = props.pill.color })
		made.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		made.frame.Position = UDim2.fromScale(places.pillCenterX, 0.5)
		made.frame.Size = UDim2.fromScale(places.pillWidth, places.pillHeight)
		made.frame.ZIndex = 2
		pill = made
	end

	local keyBadge: Frame? = nil
	if props.key then
		local look = settings.keyBadge
		local badge = Draw.panel("Key", look.color, face)
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.fromScale(look.x, look.y)
		-- A square, sized by the button's height.
		badge.Size = UDim2.fromScale(look.size, look.size)
		badge.SizeConstraint = Enum.SizeConstraint.RelativeYY
		badge.ZIndex = 3
		badge.Visible = false
		Draw.corner(badge, look.cornerShare)
		Draw.border(badge, nil, Ui.borderThickness - 1)
		local letter = OutlinedText.new({ name = "Letter", parent = badge, text = props.key, shadow = false })
		letter.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		letter.frame.Position = UDim2.fromScale(0.5, 0.5)
		letter.frame.Size = UDim2.fromScale(look.textHeight, look.textHeight)
		keyBadge = badge
	end

	local function paint()
		local shown = if enabled then rgb else Ui.colors.disabled
		face.BackgroundColor3 = Draw.color(shown)
		edge.BackgroundColor3 = Draw.color(ColorMath.darken(shown, settings.edgeDarken))
		studs.setColor(shown)
	end

	local function sink(down: boolean)
		local target = UDim2.fromScale(0, if down and enabled then settings.edgeShare else 0)
		TweenService:Create(face, TweenInfo.new(settings.pressSeconds), { Position = target }):Play()
	end

	local function hover(over: boolean)
		local target = if over and enabled then settings.hoverScale else 1
		TweenService:Create(scale, TweenInfo.new(settings.hoverSeconds), { Scale = target }):Play()
	end

	face.MouseButton1Down:Connect(function()
		sink(true)
	end)
	face.MouseButton1Up:Connect(function()
		sink(false)
	end)
	face.MouseEnter:Connect(function()
		hover(true)
	end)
	face.MouseLeave:Connect(function()
		hover(false)
		sink(false)
	end)

	frame.Parent = props.parent
	return {
		frame = frame,
		setText = text.setText,
		setPillText = function(newText: string)
			if pill then
				pill.setText(newText)
			end
		end,
		setKeyShown = function(shown: boolean)
			if keyBadge then
				keyBadge.Visible = shown
			end
		end,
		setColor = function(newRgb: { number })
			rgb = newRgb
			paint()
		end,
		setEnabled = function(newEnabled: boolean)
			if enabled == newEnabled then
				return
			end
			enabled = newEnabled
			paint()
			if not enabled then
				sink(false)
				hover(false)
			end
		end,
		onActivated = function(callback: () -> ())
			face.Activated:Connect(function()
				if enabled then
					callback()
				end
			end)
		end,
	}
end

return Button
