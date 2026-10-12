--!strict
-- Building block: the tile for one item. A square with round corners and a border in the color
-- of the item's rarity. The item itself sits big in the middle (put it into `content`), its
-- value at the bottom in light green. In use: a green check mark at the top right and a lighter
-- border. Not owned: a small lock at the top right. Too expensive: darkened.
-- A filled tile (the pets at the egg stand) has a face in a darker tone of the rarity's color, a
-- border in a lighter tone of it and a white value.
-- A glossy tile (also for pets at the egg stand) has a face that runs from a light tone of the
-- rarity at the top to a strong one at the bottom, a light strip of shine at the top, a dark
-- border and a white value.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local ColorMath = require(Shared.Rules.ColorMath)

local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)

export type Look = "card" | "filled" | "glossy"

export type State = {
	equipped: boolean,
	locked: boolean,
	dimmed: boolean,
}

export type Tile = {
	-- The whole tile, a square. Give it a size and a position like any other element.
	frame: Frame,
	-- Put the item in here (e.g. a ViewportFrame with the 3D model).
	content: Frame,
	setValue: (text: string) -> (),
	setState: (state: State) -> (),
	-- Called when the tile is pressed (touch, mouse or gamepad).
	onActivated: (callback: () -> ()) -> (),
}

local Tile = {}

-- look: "filled" for a tile whose face has the color of the rarity, "glossy" for one whose face
-- runs from light to strong in that color (default: the dark card with a border in that color).
-- rarity: for a glossy tile, the name of the rarity, to look up its two tones in Config/Ui.
function Tile.new(name: string, rarityColor: { number }, parent: Instance?, look: Look?, rarity: string?): Tile
	local settings = Ui.tile
	local glossy = look == "glossy"
	local corner = if glossy then settings.glossy.cornerShare else Ui.corners.tile
	local filled = look == "filled"
	local faceColor = if filled then ColorMath.darken(rarityColor, settings.filledDarken) else Ui.colors.card
	local borderColor = if filled then ColorMath.lighten(rarityColor, settings.filledBorderLighten) else rarityColor
	if glossy then
		-- The gradient below gives the face its colors.
		faceColor = Ui.text.color
		borderColor = settings.glossy.borderColor
	end

	local frame = Draw.box(name, nil)
	local face = Draw.panel("Face", faceColor, frame)
	Draw.corner(face, corner)
	local border = Draw.border(face, borderColor, if glossy then Ui.borderThickness else Ui.accentThickness)
	if glossy then
		local gloss = settings.glossy
		local tones = (gloss.gradients :: { [string]: { top: { number }, bottom: { number } } })[rarity or ""]
		local top = if tones then tones.top else ColorMath.lighten(rarityColor, gloss.lighten)
		local bottom = if tones then tones.bottom else ColorMath.darken(rarityColor, gloss.darken)
		Draw.gradient(face, top, bottom)
		local shine = Draw.panel("Shine", gloss.glossColor, face)
		shine.BackgroundTransparency = gloss.glossTransparency
		shine.Position = UDim2.fromScale(gloss.glossInsetX, gloss.glossY)
		shine.Size = UDim2.fromScale(1 - 2 * gloss.glossInsetX, gloss.glossHeight)
		Draw.corner(shine, Ui.corners.round)
	end

	local content = Draw.box("Content", frame)
	content.ZIndex = 2

	local value = OutlinedText.new({
		name = "Value",
		parent = frame,
		color = if filled or glossy then Ui.text.color else Ui.colors.positive,
	})
	value.frame.AnchorPoint = Vector2.new(0.5, 1)
	value.frame.Position = UDim2.fromScale(0.5, 1)
	value.frame.Size =
		UDim2.fromScale(settings.valueWidth, if glossy then settings.glossy.valueHeight else settings.valueHeight)
	value.frame.ZIndex = 3

	local dim = Draw.panel("Dim", Ui.colors.border, frame)
	dim.BackgroundTransparency = 1 - settings.dimmed
	dim.ZIndex = 4
	dim.Visible = false
	Draw.corner(dim, corner)

	local function makeBadge(kind: Icon.Kind): GuiObject
		local badge = Icon.new(kind, frame)
		badge.AnchorPoint = Vector2.new(0.5, 0.5)
		badge.Position = UDim2.fromScale(settings.badgeX, settings.badgeY)
		badge.Size = UDim2.fromScale(settings.badgeSize, settings.badgeSize)
		badge.ZIndex = 5
		badge.Visible = false
		return badge
	end
	local check = makeBadge("check")
	local lock = makeBadge("lock")

	-- Invisible layer over the whole tile that takes the presses.
	local press = Instance.new("TextButton")
	press.Name = "Press"
	press.Text = ""
	press.BackgroundTransparency = 1
	press.Size = UDim2.fromScale(1, 1)
	press.ZIndex = 6
	press.Parent = frame

	frame.Parent = parent
	return {
		frame = frame,
		content = content,
		setValue = value.setText,
		onActivated = function(callback: () -> ())
			press.Activated:Connect(callback)
		end,
		setState = function(state: State)
			check.Visible = state.equipped
			lock.Visible = state.locked and not state.equipped
			dim.Visible = state.dimmed
			border.Color = Draw.color(
				if state.equipped then ColorMath.lighten(borderColor, settings.equippedLighten) else borderColor
			)
		end,
	}
end

return Tile
