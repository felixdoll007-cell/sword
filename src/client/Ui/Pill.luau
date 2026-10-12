--!strict
-- Building block: the dark pill with a symbol and a short text (what something needs or costs).
-- Used on the signs in the world and inside buttons. Its look is in Config/Ui (pill).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)

local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)

export type Props = {
	name: string?,
	parent: Instance?,
	-- The symbol left of the text. nil = no symbol.
	icon: Icon.Kind?,
	text: string?,
	color: { number }?,
	-- The pill's height divided by its width, where that never changes (signs in the world,
	-- whose size on screen changes all the time). nil = measured on screen.
	heightPerWidth: number?,
}

export type Pill = {
	-- The whole pill. Give it a size and a position like any other element.
	frame: Frame,
	setText: (text: string) -> (),
	setColor: (rgb: { number }) -> (),
	-- Shows or hides the symbol; the text takes the room.
	setIconShown: (shown: boolean) -> (),
}

local Pill = {}

function Pill.new(props: Props): Pill
	local settings = Ui.pill
	local pill = Draw.panel(props.name or "Pill", settings.color, nil)
	Draw.corner(pill, Ui.corners.round)
	local border = Draw.border(pill)

	local icon: GuiObject? = nil
	if props.icon then
		local made = Icon.new(props.icon, pill)
		made.AnchorPoint = Vector2.new(0, 0.5)
		-- A square as high as the inside of the pill.
		made.Size = UDim2.fromScale(settings.iconShare, settings.iconShare)
		made.SizeConstraint = Enum.SizeConstraint.RelativeYY
		made.Position = UDim2.fromScale(settings.padShare, 0.5)
		icon = made
	end

	local text = OutlinedText.new({ name = "Text", parent = pill, text = props.text, color = props.color })
	text.frame.AnchorPoint = Vector2.new(0.5, 0.5)

	local function heightPerWidth(): number
		if props.heightPerWidth then
			return props.heightPerWidth
		end
		local size = pill.AbsoluteSize
		return if size.X > 0 then size.Y / size.X else 0
	end

	-- Puts symbol and text where they belong.
	local function arrange()
		if icon and icon.Visible then
			-- The symbol is a square; the text takes the room right of it.
			local taken = settings.padShare + settings.iconShare * heightPerWidth()
			local room = math.max(1 - taken - settings.padShare, 0)
			text.frame.Position = UDim2.fromScale(taken + room / 2, 0.5)
			text.frame.Size = UDim2.fromScale(room, settings.textShare)
		else
			text.frame.Position = UDim2.fromScale(0.5, 0.5)
			text.frame.Size = UDim2.fromScale(1 - 2 * settings.padShare, settings.textShare)
		end
	end

	-- The border keeps its share of the pill's height at every size.
	local function fit()
		border.Thickness = math.max(pill.AbsoluteSize.Y * settings.borderShare, 1)
		if not props.heightPerWidth then
			arrange()
		end
	end
	pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
	fit()
	arrange()

	pill.Parent = props.parent
	return {
		frame = pill,
		setText = text.setText,
		setColor = text.setColor,
		setIconShown = function(shown: boolean)
			if icon then
				icon.Visible = shown
			end
			arrange()
		end,
	}
end

return Pill
