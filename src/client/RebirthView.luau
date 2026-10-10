--!strict
-- The REBIRTH button and its small window: progress to the next rebirth, what is lost, what is
-- kept, what is gained, and Confirm. Everything works by touch.
-- The window only shows; pressing Confirm sends the wish to the server, which checks everything.
-- The window closes by itself when the server has done the rebirth (the Rebirths value goes up).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local RebirthConfig = require(Shared.Config.Rebirth)
local StrengthConfig = require(Shared.Config.Strength)
local TestSettings = require(Shared.Config.TestSettings)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)
local Rebirth = require(Shared.Rules.Rebirth)
local StartValues = require(Shared.Rules.StartValues)

local ThrowSession = require(script.Parent.ThrowSession)

local RebirthView = {}

local player = Players.LocalPlayer

local openButton: TextButton
local window: Frame
local barFill: Frame
local progressLabel: TextLabel
local loseLabel: TextLabel
local getLabel: TextLabel
local hintLabel: TextLabel
local confirmButton: TextButton

-- os.clock() until which Confirm stays inactive after a press.
local confirmBlockedUntil = 0

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function short(value: number): string
	return NumberFormat.abbreviate(NumberFormatConfig, value)
end

local function numberAttribute(name: string): number
	local value = player:GetAttribute(name)
	return if typeof(value) == "number" then value else 0
end

local function sizeLimits(parent: Instance, minWidth: number, minHeight: number, maxWidth: number, maxHeight: number)
	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(minWidth, minHeight)
	limits.MaxSize = Vector2.new(maxWidth, maxHeight)
	limits.Parent = parent
end

local function makeText(name: string, heightShare: number, order: number, parent: Instance): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = UDim2.fromScale(1, heightShare)
	label.LayoutOrder = order
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color(Ui.rebirthWindow.textColor)
	label.Parent = parent
	return label
end

local function makeButton(
	name: string,
	text: string,
	rgb: { number },
	textPadding: number,
	parent: Instance
): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Text = text
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.TextColor3 = color(Ui.rebirthWindow.textColor)
	button.BackgroundColor3 = color(rgb)
	button.AutoButtonColor = true
	button.Parent = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(textPadding, 0)
	padding.PaddingBottom = UDim.new(textPadding, 0)
	padding.PaddingLeft = UDim.new(textPadding / 2, 0)
	padding.PaddingRight = UDim.new(textPadding / 2, 0)
	padding.Parent = button
	return button
end

local function createOpenButton(gui: ScreenGui)
	local settings = Ui.rebirthButton
	openButton = makeButton("RebirthButton", settings.text, settings.color, settings.textPadding, gui)
	openButton.TextColor3 = color(settings.textColor)
	openButton.AnchorPoint = Vector2.new(0, 0.5)
	openButton.Position = UDim2.fromScale(settings.positionX, settings.positionY)
	-- The outer box; the aspect ratio fits the button into it without changing its shape.
	openButton.Size = UDim2.fromScale(settings.widthScale, settings.heightScale)

	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = settings.aspectRatio
	aspect.Parent = openButton
	sizeLimits(openButton, settings.minWidth, settings.minHeight, settings.maxWidth, settings.maxHeight)
end

local function createWindow(gui: ScreenGui)
	local settings = Ui.rebirthWindow
	window = Instance.new("Frame")
	window.Name = "RebirthWindow"
	window.AnchorPoint = Vector2.new(0.5, 0.5)
	window.Position = UDim2.fromScale(0.5, 0.5)
	window.Size = UDim2.fromScale(settings.widthScale, settings.heightScale)
	window.BackgroundColor3 = color(settings.backgroundColor)
	window.Visible = false
	window.Parent = gui
	sizeLimits(window, settings.minWidth, settings.minHeight, settings.maxWidth, settings.maxHeight)

	local border = Instance.new("UIStroke")
	border.Color = color(settings.borderColor)
	border.Thickness = settings.borderThickness
	border.Parent = window

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(settings.padding, 0)
	padding.PaddingBottom = UDim.new(settings.padding, 0)
	padding.PaddingLeft = UDim.new(settings.padding, 0)
	padding.PaddingRight = UDim.new(settings.padding, 0)
	padding.Parent = window

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(settings.rowGap, 0)
	layout.Parent = window

	local title = makeText("Title", settings.titleHeight, 1, window)
	title.Font = Enum.Font.GothamBlack
	title.Text = settings.title

	-- Progress bar with the numbers on top of it.
	local bar = Instance.new("Frame")
	bar.Name = "ProgressBar"
	bar.Size = UDim2.fromScale(1, settings.barHeight)
	bar.LayoutOrder = 2
	bar.BackgroundColor3 = color(settings.barBackColor)
	bar.BorderSizePixel = 0
	bar.Parent = window

	barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.fromScale(0, 1)
	barFill.BackgroundColor3 = color(settings.barFillColor)
	barFill.BorderSizePixel = 0
	barFill.Parent = bar

	progressLabel = makeText("ProgressText", 1, 1, bar)
	progressLabel.ZIndex = 2

	loseLabel = makeText("LoseText", settings.lineHeight, 3, window)
	local keepLabel = makeText("KeepText", settings.lineHeight, 4, window)
	keepLabel.Text = settings.keepText
	getLabel = makeText("GetText", settings.lineHeight, 5, window)
	hintLabel = makeText("HintText", settings.hintHeight, 6, window)

	local buttons = Instance.new("Frame")
	buttons.Name = "Buttons"
	buttons.Size = UDim2.fromScale(1, settings.buttonsHeight)
	buttons.LayoutOrder = 7
	buttons.BackgroundTransparency = 1
	buttons.Parent = window

	confirmButton =
		makeButton("ConfirmButton", settings.confirmText, settings.confirmColor, settings.buttonTextPadding, buttons)
	confirmButton.Size = UDim2.fromScale(settings.buttonWidth, 1)

	local closeButton =
		makeButton("CloseButton", settings.closeText, settings.closeColor, settings.buttonTextPadding, buttons)
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.fromScale(1, 0)
	closeButton.Size = UDim2.fromScale(settings.buttonWidth, 1)
	closeButton.Activated:Connect(function()
		window.Visible = false
	end)
end

-- Fills in the numbers from the values the server shows.
local function refresh()
	local settings = Ui.rebirthWindow
	local strength = numberAttribute(Remotes.Attributes.Strength)
	local rebirths = numberAttribute(Remotes.Attributes.Rebirths)
	local threshold = Rebirth.threshold(RebirthConfig, rebirths)
	local ready = Rebirth.canRebirth(RebirthConfig, strength, rebirths)

	openButton.BackgroundColor3 = color(if ready then Ui.rebirthButton.readyColor else Ui.rebirthButton.color)
	-- Not during a throw: the reward is still being counted up on screen.
	openButton.Visible = not ThrowSession.isActive()
	if ThrowSession.isActive() then
		window.Visible = false
	end
	if not window.Visible then
		return
	end

	barFill.Size = UDim2.fromScale(Rebirth.progress(RebirthConfig, strength, rebirths), 1)
	progressLabel.Text = string.format(settings.progressText, short(strength), short(threshold))
	local strengthAfter = StartValues.startStrength(StrengthConfig, TestSettings, RunService:IsStudio())
	loseLabel.Text = string.format(settings.loseText, short(strengthAfter))
	getLabel.Text = string.format(
		settings.getText,
		short(Rebirth.multiplier(RebirthConfig, rebirths + 1)),
		short(Rebirth.multiplier(RebirthConfig, rebirths))
	)
	hintLabel.Text = if ready then settings.readyText else settings.notReadyText

	local canPress = ready and os.clock() >= confirmBlockedUntil
	confirmButton.Active = canPress
	confirmButton.AutoButtonColor = canPress
	confirmButton.BackgroundColor3 = color(if canPress then settings.confirmColor else settings.confirmDisabledColor)
end

local function onConfirm()
	local strength = numberAttribute(Remotes.Attributes.Strength)
	local rebirths = numberAttribute(Remotes.Attributes.Rebirths)
	-- Only ask when it can work. The server checks again with its own values.
	if os.clock() < confirmBlockedUntil or not Rebirth.canRebirth(RebirthConfig, strength, rebirths) then
		return
	end
	confirmBlockedUntil = os.clock() + Ui.rebirthWindow.confirmWaitSeconds
	Remotes.RebirthRequested:FireServer()
end

function RebirthView.start()
	local gui = Instance.new("ScreenGui")
	gui.Name = "RebirthGui"
	gui.ResetOnSpawn = false
	-- Above the other screen elements, so the window is never hidden behind a button.
	gui.DisplayOrder = 1

	createOpenButton(gui)
	createWindow(gui)

	openButton.Activated:Connect(function()
		window.Visible = not window.Visible
	end)
	confirmButton.Activated:Connect(onConfirm)

	-- The rebirth happened: close the window.
	player:GetAttributeChangedSignal(Remotes.Attributes.Rebirths):Connect(function()
		window.Visible = false
		confirmBlockedUntil = 0
	end)

	RunService.Heartbeat:Connect(refresh)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return RebirthView
