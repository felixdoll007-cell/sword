--!strict
-- Building block: the tile for one item. A square with round corners and a border in the color
-- of the item's rarity. The item itself sits big in the middle (put it into `content`), its
-- value at the bottom in light green. In use: a green check mark at the top right and a lighter
-- border. Not owned: a small lock at the top right. Too expensive: darkened.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local ColorMath = require(Shared.Rules.ColorMath)

local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)

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

function Tile.new(name: string, rarityColor: { number }, parent: Instance?): Tile
	local settings = Ui.tile
	local corner = Ui.corners.tile

	local frame = Draw.box(name, nil)
	local face = Draw.panel("Face", Ui.colors.card, frame)
	Draw.corner(face, corner)
	local border = Draw.border(face, rarityColor, Ui.accentThickness)

	local content = Draw.box("Content", frame)
	content.ZIndex = 2

	local value = OutlinedText.new({ name = "Value", parent = frame, color = Ui.colors.positive })
	value.frame.AnchorPoint = Vector2.new(0.5, 1)
	value.frame.Position = UDim2.fromScale(0.5, 1)
	value.frame.Size = UDim2.fromScale(settings.valueWidth, settings.valueHeight)
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
				if state.equipped then ColorMath.lighten(rarityColor, settings.equippedLighten) else rarityColor
			)
		end,
	}
end

return Tile
