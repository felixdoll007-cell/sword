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
local Pill = require(script.Parent.Pill)

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
	setText: (text: string) -> (),
	setColor: (rgb: { number }) -> (),
	-- Pill rows only.
	setIconShown: ((shown: boolean) -> ())?,
}

local WorldSign = {}

-- heightPerWidth: the pill's height divided by its width.
local function makePill(spec: RowSpec, holder: Frame, heightPerWidth: number): Row
	local pill = Pill.new({
		parent = holder,
		icon = spec.icon,
		text = spec.text,
		color = spec.color,
		heightPerWidth = heightPerWidth,
	})
	pill.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	pill.frame.Position = UDim2.fromScale(0.5, 0.5)
	pill.frame.Size = UDim2.fromScale(Ui.world.signs.pill.widthShare, 1)
	return { setText = pill.setText, setColor = pill.setColor, setIconShown = pill.setIconShown }
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
			table.insert(rows, { setText = text.setText, setColor = text.setColor, setIconShown = nil })
		end
	end

	anchor.Parent = props.parent
	return {
		anchor = anchor,
		setText = function(row: number, text: string)
			rows[row].setText(text)
		end,
		setColor = function(row: number, rgb: { number })
			rows[row].setColor(rgb)
		end,
		setIconShown = function(row: number, shown: boolean)
			local setShown = rows[row].setIconShown
			if setShown then
				setShown(shown)
			end
		end,
	}
end

return WorldSign
