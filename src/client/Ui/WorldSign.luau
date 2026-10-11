--!strict
-- Building block: a sign in the world, in the style of the interface. It floats at a place,
-- always turned towards the camera, without a board behind it. From top to bottom it has rows:
--   * a text row: text in the game's font with its black border, in any color
--   * a pill row: a dark pill with a symbol and a number (what something needs or costs)
-- Rules in docs/STYLE.md, "Schilder in der Welt". Sizes are in studs, so a sign gets smaller
-- with distance like everything else; its borders shrink and grow with it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)

local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)

export type RowSpec = {
	kind: "text" | "pill",
	-- Height of the row as a share of the sign's height.
	height: number,
	text: string?,
	color: { number }?,
	-- Pill rows: the symbol left of the text. nil = no symbol.
	icon: Icon.Kind?,
}

export type Props = {
	name: string,
	parent: Instance,
	position: Vector3,
	widthStuds: number,
	heightStuds: number,
	rows: { RowSpec },
}

export type WorldSign = {
	-- The invisible point in the world the sign hangs on.
	anchor: Part,
	setText: (row: number, text: string) -> (),
	setColor: (row: number, rgb: { number }) -> (),
	-- Pill rows only: shows or hides the symbol.
	setIconShown: (row: number, shown: boolean) -> (),
}

type Row = {
	text: OutlinedText.OutlinedText,
	icon: GuiObject?,
	-- Puts symbol and text of a pill row where they belong.
	arrange: (() -> ())?,
}

local WorldSign = {}

-- heightPerWidth: the pill's height divided by its width.
local function makePill(spec: RowSpec, holder: Frame, heightPerWidth: number): Row
	local settings = Ui.world.signs.pill
	-- The symbol is a square; this is its width as a share of the pill's width.
	local iconWidthShare = settings.iconShare * heightPerWidth
	local pill = Draw.panel("Pill", settings.color, holder)
	pill.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.Position = UDim2.fromScale(0.5, 0.5)
	pill.Size = UDim2.fromScale(settings.widthShare, 1)
	Draw.corner(pill, Ui.corners.round)
	local border = Draw.border(pill)
	-- The border keeps its share of the pill's height at every distance.
	local function fitBorder()
		border.Thickness = math.max(pill.AbsoluteSize.Y * settings.borderShare, 1)
	end
	pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitBorder)
	fitBorder()

	local icon: GuiObject? = nil
	if spec.icon then
		local made = Icon.new(spec.icon, pill)
		made.AnchorPoint = Vector2.new(0, 0.5)
		-- A square as high as the inside of the pill.
		made.Size = UDim2.fromScale(settings.iconShare, settings.iconShare)
		made.SizeConstraint = Enum.SizeConstraint.RelativeYY
		made.Position = UDim2.fromScale(settings.padShare, 0.5)
		icon = made
	end

	local text = OutlinedText.new({ name = "Text", parent = pill, text = spec.text, color = spec.color })
	text.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	local function arrange()
		if icon and icon.Visible then
			-- The text takes the room right of the symbol.
			local taken = settings.padShare + iconWidthShare
			text.frame.Position = UDim2.fromScale(taken + (1 - taken - settings.padShare) / 2, 0.5)
			text.frame.Size = UDim2.fromScale(1 - taken - settings.padShare, settings.textShare)
		else
			text.frame.Position = UDim2.fromScale(0.5, 0.5)
			text.frame.Size = UDim2.fromScale(1 - 2 * settings.padShare, settings.textShare)
		end
	end
	arrange()
	return { text = text, icon = icon, arrange = arrange }
end

function WorldSign.new(props: Props): WorldSign
	local settings = Ui.world.signs

	local anchor = Instance.new("Part")
	anchor.Name = props.name
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.CastShadow = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = props.position

	local gui = Instance.new("BillboardGui")
	gui.Name = "Sign"
	gui.Size = UDim2.fromScale(props.widthStuds, props.heightStuds)
	gui.LightInfluence = 0
	gui.MaxDistance = settings.maxDistance
	-- Needed so text lies on top of its own shadow.
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Adornee = anchor
	gui.Parent = anchor

	-- The rows from top to bottom, with the same space between them.
	local used = 0
	for _, spec in props.rows do
		used += spec.height
	end
	local space = if #props.rows > 1 then math.max(1 - used, 0) / (#props.rows - 1) else 0
	local rows: { Row } = {}
	local y = 0
	for index, spec in props.rows do
		local holder = Draw.box(`Row{index}`, gui)
		holder.Position = UDim2.fromScale(0, y)
		holder.Size = UDim2.fromScale(1, spec.height)
		y += spec.height + space
		if spec.kind == "pill" then
			local pillWidth = props.widthStuds * settings.pill.widthShare
			table.insert(rows, makePill(spec, holder, props.heightStuds * spec.height / pillWidth))
		else
			local text = OutlinedText.new({ name = "Text", parent = holder, text = spec.text, color = spec.color })
			table.insert(rows, { text = text, icon = nil, arrange = nil })
		end
	end

	anchor.Parent = props.parent
	return {
		anchor = anchor,
		setText = function(row: number, text: string)
			rows[row].text.setText(text)
		end,
		setColor = function(row: number, rgb: { number })
			rows[row].text.setColor(rgb)
		end,
		setIconShown = function(row: number, shown: boolean)
			local target = rows[row]
			if target.icon then
				target.icon.Visible = shown
			end
			if target.arrange then
				target.arrange()
			end
		end,
	}
end

return WorldSign
