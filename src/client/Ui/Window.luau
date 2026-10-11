--!strict
-- Building block: the window. A dark, slightly see-through surface with a black border. The big
-- title sticks out over the top edge, a big symbol over the top left corner and the round red
-- close button over the top right corner. What the window shows goes into a darker inner area.
--
-- A window with several areas has tabs on its left, outside the window; the active tab is lighter.
-- Each tab has its own page inside the inner area.
--
-- Only one window is open at a time: opening one closes the other. While a window is open the
-- world behind it is blurred and darkened; a press next to the window closes it.
-- Opening pops from small to big, closing is quick.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local ColorMath = require(Shared.Rules.ColorMath)
local UiLayout = require(Shared.Rules.UiLayout)

local Button = require(script.Parent.Button)
local Draw = require(script.Parent.Draw)
local Icon = require(script.Parent.Icon)
local OutlinedText = require(script.Parent.OutlinedText)

-- Above the always visible interface.
local DISPLAY_ORDER = 10
-- The dark layer is this many times the screen, so it also covers the strip of Roblox's own
-- buttons at the top.
local DIM_SCREENS = 2

export type Props = {
	name: string,
	title: string,
	-- Picture for the symbol at the top left corner. nil = no symbol.
	icon: string?,
	-- The window never gets bigger than this, in pixels.
	maxWidth: number,
	maxHeight: number,
	-- Captions of the tabs on the left, from top to bottom. nil = a window without tabs.
	tabs: { string }?,
}

type Tab = {
	button: TextButton,
	caption: OutlinedText.OutlinedText,
	page: Frame,
}

export type Window = {
	-- The inner area. Put the window's content in here (window without tabs).
	content: Frame,
	-- Window with tabs: one page per tab, in the order of the tabs. Put each tab's content into
	-- its page; only the page of the active tab is shown.
	pages: { Frame },
	open: () -> (),
	close: () -> (),
	toggle: () -> (),
	isOpen: () -> boolean,
	-- Size of the inner area in pixels (at full size, also while the window is still popping open).
	contentSize: () -> Vector2,
	-- Called after every change of the window's size (and once right away).
	onResize: (callback: () -> ()) -> (),
}

local Window = {}

local gui: ScreenGui? = nil
local dim: TextButton? = nil
local blur: BlurEffect? = nil
local openWindow: Window? = nil
local resizers: { () -> () } = {}

local function setBackdrop(shown: boolean)
	local settings = Ui.window
	if dim then
		dim.Visible = shown
	end
	local effect = blur
	if effect then
		-- Switched off completely while no window is open, so it costs nothing then.
		if shown then
			effect.Enabled = true
		end
		local info = TweenInfo.new(if shown then settings.openSeconds else settings.closeSeconds)
		local tween = TweenService:Create(effect, info, { Size = if shown then settings.blurSize else 0 })
		tween.Completed:Connect(function()
			if openWindow == nil then
				effect.Enabled = false
			end
		end)
		tween:Play()
	end
end

local function getGui(): ScreenGui
	if gui then
		return gui
	end
	local settings = Ui.window
	local newGui = Draw.screen("WindowGui", DISPLAY_ORDER)

	-- Covers the whole screen behind the window: darkens it and catches presses next to the window.
	local newDim = Instance.new("TextButton")
	newDim.Name = "Dim"
	newDim.Text = ""
	newDim.AutoButtonColor = false
	newDim.BorderSizePixel = 0
	newDim.BackgroundColor3 = Draw.color(settings.dimColor)
	newDim.BackgroundTransparency = settings.dimTransparency
	newDim.AnchorPoint = Vector2.new(0.5, 0.5)
	newDim.Position = UDim2.fromScale(0.5, 0.5)
	newDim.Size = UDim2.fromScale(DIM_SCREENS, DIM_SCREENS)
	newDim.Visible = false
	newDim.Parent = newGui
	newDim.Activated:Connect(function()
		Window.closeAll()
	end)

	local newBlur = Instance.new("BlurEffect")
	newBlur.Name = "WindowBlur"
	newBlur.Size = 0
	newBlur.Enabled = false
	newBlur.Parent = Lighting

	newGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		for _, resize in resizers do
			resize()
		end
	end)

	gui, dim, blur = newGui, newDim, newBlur
	return newGui
end

function Window.closeAll()
	if openWindow then
		openWindow.close()
	end
end

function Window.anyOpen(): boolean
	return openWindow ~= nil
end

function Window.new(props: Props): Window
	local settings = Ui.window
	local screen = getGui()

	-- Holds the window and its tabs, so they pop open and close together.
	local holder = Draw.box(props.name, screen)
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Visible = false

	local scale = Instance.new("UIScale")
	scale.Parent = holder

	-- Catches presses on the window itself, so they do not reach the dark layer and close it.
	local frame = Instance.new("TextButton")
	frame.Name = "Surface"
	frame.Text = ""
	frame.AutoButtonColor = false
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = Draw.color(Ui.colors.windowOuter)
	frame.BackgroundTransparency = settings.outerTransparency
	frame.Size = UDim2.fromScale(1, 1)
	-- On top of the tabs, which reach a little under the window's edge.
	frame.ZIndex = 2
	frame.Parent = holder
	Draw.corner(frame, Ui.corners.window)
	Draw.border(frame)

	local content = Draw.panel("Content", Ui.colors.windowInner, frame)
	content.ZIndex = 2
	Draw.corner(content, Ui.corners.windowInner)

	local title = OutlinedText.new({ name = "Title", parent = frame, text = props.title })
	title.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	title.frame.ZIndex = 4

	local icon: ImageLabel? = nil
	if props.icon and props.icon ~= "" then
		local image = Icon.image("Icon", props.icon, frame)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.ZIndex = 4
		icon = image
	end

	local closeButton = Button.new({
		name = "CloseButton",
		parent = frame,
		text = settings.closeText,
		color = Ui.colors.danger,
		cornerShare = Ui.corners.round,
	})
	closeButton.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	closeButton.frame.ZIndex = 5

	local tabs: { Tab } = {}
	local pages: { Frame } = {}
	local function selectTab(selected: number)
		for index, tab in tabs do
			local active = index == selected
			tab.page.Visible = active
			tab.button.BackgroundColor3 = Draw.color(
				if active
					then ColorMath.lighten(Ui.colors.windowOuter, settings.tab.activeLighten)
					else Ui.colors.windowOuter
			)
		end
	end
	for index, caption in props.tabs or {} do
		local button = Instance.new("TextButton")
		button.Name = `Tab{index}`
		button.Text = ""
		button.AutoButtonColor = false
		button.BorderSizePixel = 0
		button.Parent = holder
		Draw.corner(button, Ui.corners.card)
		Draw.border(button)
		local text = OutlinedText.new({ name = "Caption", parent = button, text = caption })
		text.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		local page = Draw.box(`Page{index}`, content)
		button.Activated:Connect(function()
			selectTab(index)
		end)
		table.insert(tabs, { button = button, caption = text, page = page })
		table.insert(pages, page)
	end
	selectTab(1)

	local listeners: { () -> () } = {}
	local contentSize = Vector2.zero
	local isOpen = false
	local closeToken = 0
	local self: Window

	local function resize()
		local size = screen.AbsoluteSize
		local layout = UiLayout.window(Ui.layout, size.X, size.Y, props.maxWidth, props.maxHeight, #tabs > 0)
		local titleHeight = layout.titleHeight
		holder.Size = UDim2.fromOffset(math.round(layout.width), math.round(layout.height))
		-- A little below the middle, because the title sticks out at the top. With tabs a little
		-- to the right, so window and tabs together sit in the middle.
		holder.Position = UDim2.new(0.5, math.round(layout.offsetX), 0.5, math.round(titleHeight / 4))

		title.frame.Position = UDim2.fromScale(0.5, 0)
		title.frame.Size = UDim2.new(settings.titleWidth, 0, 0, math.round(titleHeight))

		local iconSize = math.round(titleHeight * settings.iconFactor)
		if icon then
			icon.Size = UDim2.fromOffset(iconSize, iconSize)
			icon.Position =
				UDim2.fromOffset(math.round(iconSize * settings.iconInsetX), math.round(iconSize * settings.iconInsetY))
		end
		-- The tabs hang on the left edge, below the symbol.
		local tabWidth, tabHeight = math.round(layout.tabWidth), math.round(layout.tabHeight)
		local tabTop = settings.tab.gapPixels
			+ (if icon then math.round(iconSize * (settings.iconInsetY + 1 / 2)) else math.round(titleHeight / 2))
		for index, tab in tabs do
			tab.button.Size = UDim2.fromOffset(tabWidth + settings.tab.overlapPixels, tabHeight)
			tab.button.Position =
				UDim2.fromOffset(-tabWidth, tabTop + (index - 1) * (tabHeight + settings.tab.gapPixels))
			tab.caption.frame.Position = UDim2.fromOffset(math.round(tabWidth / 2), math.round(tabHeight / 2))
			tab.caption.frame.Size = UDim2.fromOffset(
				math.round(tabWidth * settings.tab.textWidth),
				math.round(tabHeight * settings.tab.textHeight)
			)
		end

		local closeSize = math.round(titleHeight * settings.closeFactor)
		closeButton.frame.Size = UDim2.fromOffset(closeSize, closeSize)
		local closeInset = math.round(closeSize * settings.closeInset)
		closeButton.frame.Position = UDim2.new(1, -closeInset, 0, closeInset)

		-- The inner area starts below the title.
		local padding = math.round(titleHeight * settings.paddingFactor)
		local top = math.round(titleHeight / 2) + padding
		content.Position = UDim2.fromOffset(padding, top)
		content.Size = UDim2.new(1, -2 * padding, 1, -top - padding)
		contentSize = Vector2.new(
			math.max(math.round(layout.width) - 2 * padding, 0),
			math.max(math.round(layout.height) - top - padding, 0)
		)

		for _, listener in listeners do
			listener()
		end
	end
	table.insert(resizers, resize)

	local function close()
		if not isOpen then
			return
		end
		isOpen = false
		if openWindow == self then
			openWindow = nil
			setBackdrop(false)
		end
		closeToken += 1
		local token = closeToken
		local tween =
			TweenService:Create(scale, TweenInfo.new(settings.closeSeconds), { Scale = settings.closeToScale })
		tween.Completed:Connect(function()
			if token == closeToken then
				holder.Visible = false
			end
		end)
		tween:Play()
	end

	local function open()
		if isOpen then
			return
		end
		-- Only one window at a time.
		Window.closeAll()
		isOpen = true
		openWindow = self
		closeToken += 1
		resize()
		setBackdrop(true)
		scale.Scale = settings.openFromScale
		holder.Visible = true
		local info = TweenInfo.new(settings.openSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(scale, info, { Scale = 1 }):Play()
	end

	closeButton.onActivated(close)

	self = {
		content = content,
		pages = pages,
		open = open,
		close = close,
		toggle = function()
			if isOpen then
				close()
			else
				open()
			end
		end,
		isOpen = function(): boolean
			return isOpen
		end,
		contentSize = function(): Vector2
			return contentSize
		end,
		onResize = function(callback: () -> ())
			table.insert(listeners, callback)
			callback()
		end,
	}
	resize()
	return self
end

return Window
