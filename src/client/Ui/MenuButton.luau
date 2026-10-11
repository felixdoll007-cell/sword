--!strict
-- Building block: a square button of the menu grid. Dark face with a light round border, a big
-- symbol in the middle that may stick out a little, the caption at the bottom and, where there
-- is one, a progress text at the top.
-- A locked button is shown dark with a lock on it. It can still be pressed, so the game can
-- answer "Coming soon".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Ui = require(ReplicatedStorage.Shared.Config.Ui)

local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)

export type Props = {
	name: string,
	parent: Instance?,
	label: string,
	-- The uploaded picture of the symbol.
	icon: string,
	locked: boolean,
}

export type MenuButton = {
	-- The whole button, a square. Give it a size and a position like any other element.
	frame: Frame,
	-- Text at the top of the button, e.g. "62%". "" shows nothing.
	setTopText: (text: string) -> (),
	-- The red dot with "!" at the top right.
	setNotice: (shown: boolean) -> (),
	onActivated: (callback: () -> ()) -> (),
}

local MenuButton = {}

function MenuButton.new(props: Props): MenuButton
	local settings = Ui.menuButton
	local corner = Ui.corners.menuButton

	local frame = Draw.box(props.name, nil)
	local scale = Instance.new("UIScale")
	scale.Parent = frame

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.Text = ""
	face.AutoButtonColor = false
	face.BorderSizePixel = 0
	face.BackgroundColor3 = Draw.color(Ui.colors.menuFace)
	face.Size = UDim2.fromScale(1, 1)
	face.Parent = frame
	Draw.corner(face, corner)
	Draw.border(face, Ui.colors.menuBorder, Ui.accentThickness)

	local icon = Icon.image("Icon", props.icon, frame)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, settings.iconCenterY)
	icon.Size = UDim2.fromScale(settings.iconSize, settings.iconSize)
	icon.ZIndex = 2

	if props.locked then
		-- Darkens the face and the symbol; the lock and the caption stay bright.
		local dim = Draw.panel("Dim", Ui.colors.border, frame)
		dim.BackgroundTransparency = 1 - settings.lockedDim
		dim.ZIndex = 3
		Draw.corner(dim, corner)
		icon.ImageColor3 = Draw.color(Ui.colors.disabled)

		local lock = Icon.new("lock", frame)
		lock.AnchorPoint = Vector2.new(0.5, 0.5)
		lock.Position = UDim2.fromScale(0.5, settings.iconCenterY)
		lock.Size = UDim2.fromScale(settings.lockSize, settings.lockSize)
		lock.ZIndex = 4
	end

	local label = OutlinedText.new({ name = "Label", parent = frame, text = props.label })
	label.frame.AnchorPoint = Vector2.new(0.5, 1)
	label.frame.Position = UDim2.fromScale(0.5, 1)
	label.frame.Size = UDim2.fromScale(settings.textWidth, settings.labelHeight)
	label.frame.ZIndex = 5

	local topText = OutlinedText.new({ name = "TopText", parent = frame, text = "" })
	topText.frame.AnchorPoint = Vector2.new(0.5, 0)
	topText.frame.Position = UDim2.fromScale(0.5, 0)
	topText.frame.Size = UDim2.fromScale(settings.textWidth, settings.topTextHeight)
	topText.frame.ZIndex = 5
	topText.frame.Visible = false

	-- Red dot, half outside the top right corner.
	local notice = Draw.panel("Notice", Ui.colors.notice, frame)
	notice.AnchorPoint = Vector2.new(0.5, 0.5)
	notice.Position = UDim2.fromScale(settings.noticeX, settings.noticeY)
	notice.Size = UDim2.fromScale(settings.noticeSize, settings.noticeSize)
	notice.ZIndex = 6
	notice.Visible = false
	Draw.corner(notice, Ui.corners.round)
	Draw.border(notice, nil, Ui.borderThickness - 1)
	local noticeText = OutlinedText.new({ name = "Mark", parent = notice, text = settings.noticeText, shadow = false })
	noticeText.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	noticeText.frame.Position = UDim2.fromScale(0.5, 0.5)
	noticeText.frame.Size = UDim2.fromScale(settings.noticeMarkSize, settings.noticeMarkSize)

	local pressed, hovered = false, false
	local function resize()
		local target = if pressed then settings.pressScale elseif hovered then settings.hoverScale else 1
		TweenService:Create(scale, TweenInfo.new(settings.scaleSeconds), { Scale = target }):Play()
	end
	face.MouseButton1Down:Connect(function()
		pressed = true
		resize()
	end)
	face.MouseButton1Up:Connect(function()
		pressed = false
		resize()
	end)
	face.MouseEnter:Connect(function()
		hovered = true
		resize()
	end)
	face.MouseLeave:Connect(function()
		pressed, hovered = false, false
		resize()
	end)

	frame.Parent = props.parent
	return {
		frame = frame,
		setTopText = function(text: string)
			topText.setText(text)
			topText.frame.Visible = text ~= ""
		end,
		setNotice = function(shown: boolean)
			notice.Visible = shown
		end,
		onActivated = function(callback: () -> ())
			face.Activated:Connect(callback)
		end,
	}
end

return MenuButton
