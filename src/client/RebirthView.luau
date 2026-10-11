--!strict
-- Everything the player sees about rebirth:
--   * the progress bar to the next rebirth at the bottom center, always visible
--   * the rebirth window: now and after side by side, a red warning, the progress bar and the
--     green button. It is opened from the menu (MenuView).
-- The window only shows; pressing the button sends the wish to the server, which checks
-- everything. The window closes by itself when the server has done the rebirth (the Rebirths
-- value goes up).

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
local UiLayout = require(Shared.Rules.UiLayout)

local StatsView = require(script.Parent.StatsView)
local Button = require(script.Parent.Ui.Button)
local Draw = require(script.Parent.Ui.Draw)
local Hud = require(script.Parent.Ui.Hud)
local OutlinedText = require(script.Parent.Ui.OutlinedText)
local ProgressBar = require(script.Parent.Ui.ProgressBar)
local Window = require(script.Parent.Ui.Window)

local RebirthView = {}

-- One of the two cards: what the player has now, or what the player has after the rebirth.
type Card = {
	multiplier: OutlinedText.OutlinedText,
	strength: OutlinedText.OutlinedText,
}

local player = Players.LocalPlayer

local hudBar: ProgressBar.ProgressBar
local window: Window.Window
local windowBar: ProgressBar.ProgressBar
local beforeCard: Card
local afterCard: Card
local confirmButton: Button.Button

-- os.clock() until which the button stays inactive after a press.
local confirmBlockedUntil = 0

local function short(value: number): string
	return NumberFormat.abbreviate(NumberFormatConfig, value)
end

local function rebirths(): number
	local value = player:GetAttribute(Remotes.Attributes.Rebirths)
	return if typeof(value) == "number" then value else 0
end

-- The strength on screen. During a throw that is the held value, so the bar gives nothing away.
local function strength(): number
	return StatsView.shown(Remotes.Attributes.Strength)
end

-- The picture of the menu entry a window belongs to.
local function menuIcon(id: string): string?
	for _, entry in Ui.menu.entries do
		if entry.id == id then
			return entry.icon
		end
	end
	return nil
end

local function fillBar(bar: ProgressBar.ProgressBar)
	local settings = Ui.rebirthBar
	local count = rebirths()
	local value = strength()
	local percent = Rebirth.progressPercent(RebirthConfig, value, count)
	bar.set(
		Rebirth.progress(RebirthConfig, value, count),
		string.format(settings.leftText, short(value), short(Rebirth.threshold(RebirthConfig, count))),
		if percent >= 100 then settings.readyText else string.format(settings.percentText, tostring(percent))
	)
end

local function makeCard(
	name: string,
	title: string,
	multiplierColor: { number },
	strengthColor: { number },
	parent: Instance
): (Frame, Card)
	local settings = Ui.rebirthWindow
	local frame = Draw.panel(name, Ui.colors.card, parent)
	Draw.corner(frame, Ui.corners.card)
	Draw.border(frame)

	-- Five rows from top to bottom, spread evenly over the card.
	local rows = settings.cardRows
	local used = 0
	for _, share in rows do
		used += share
	end
	local space = (1 - used) / (#rows + 1)
	local y = space
	local function row(index: number, text: string, rgb: { number }?): OutlinedText.OutlinedText
		local line = OutlinedText.new({ name = `Row{index}`, parent = frame, text = text, color = rgb })
		line.frame.AnchorPoint = Vector2.new(0.5, 0)
		line.frame.Position = UDim2.fromScale(0.5, y)
		line.frame.Size = UDim2.fromScale(settings.cardTextWidth, rows[index])
		y += rows[index] + space
		return line
	end

	row(1, title)
	local multiplier = row(2, "", multiplierColor)
	row(3, settings.multiplierCaption)
	local strengthLine = row(4, "", strengthColor)
	row(5, settings.strengthCaption)
	return frame, { multiplier = multiplier, strength = strengthLine }
end

local function createWindow()
	local settings = Ui.rebirthWindow
	window = Window.new({
		name = "RebirthWindow",
		title = settings.title,
		icon = menuIcon(settings.menuEntry),
		maxWidth = settings.maxWidth,
		maxHeight = settings.maxHeight,
	})
	local content = window.content

	-- Four rows from top to bottom with the same space between them.
	local space = (1 - settings.cardsHeight - settings.warningHeight - settings.barHeight - settings.buttonHeight) / 5
	local y = space

	local cards = Draw.box("Cards", content)
	cards.Position = UDim2.fromScale(0, y)
	cards.Size = UDim2.fromScale(1, settings.cardsHeight)
	y += settings.cardsHeight + space

	local sideSpace = (1 - 2 * settings.cardWidth - settings.arrowWidth) / 2
	local before, beforeTexts = makeCard("Before", settings.beforeTitle, Ui.colors.rebirths, Ui.colors.strength, cards)
	before.Position = UDim2.fromScale(sideSpace, 0)
	before.Size = UDim2.fromScale(settings.cardWidth, 1)
	beforeCard = beforeTexts

	local arrow = OutlinedText.new({ name = "Arrow", parent = cards, text = settings.arrowText })
	arrow.frame.Position = UDim2.fromScale(sideSpace + settings.cardWidth, (1 - settings.arrowHeight) / 2)
	arrow.frame.Size = UDim2.fromScale(settings.arrowWidth, settings.arrowHeight)

	-- After: the multiplier is the gain (green), the strength is the loss (red).
	local after, afterTexts = makeCard("After", settings.afterTitle, Ui.colors.positive, Ui.colors.danger, cards)
	after.Position = UDim2.fromScale(sideSpace + settings.cardWidth + settings.arrowWidth, 0)
	after.Size = UDim2.fromScale(settings.cardWidth, 1)
	afterCard = afterTexts

	local warning = OutlinedText.new({
		name = "Warning",
		parent = content,
		text = settings.warningText,
		color = Ui.colors.danger,
	})
	warning.frame.AnchorPoint = Vector2.new(0.5, 0)
	warning.frame.Position = UDim2.fromScale(0.5, y)
	warning.frame.Size = UDim2.fromScale(1 - 2 * sideSpace, settings.warningHeight)
	y += settings.warningHeight + space

	windowBar = ProgressBar.new("ProgressBar", content)
	windowBar.frame.AnchorPoint = Vector2.new(0.5, 0)
	windowBar.frame.Position = UDim2.fromScale(0.5, y)
	windowBar.frame.Size = UDim2.fromScale(1 - 2 * sideSpace, settings.barHeight)
	y += settings.barHeight + space

	confirmButton = Button.new({
		name = "ConfirmButton",
		parent = content,
		text = settings.confirmText,
		color = Ui.colors.confirm,
	})
	confirmButton.frame.AnchorPoint = Vector2.new(0.5, 0)
	confirmButton.frame.Position = UDim2.fromScale(0.5, y)
	confirmButton.frame.Size = UDim2.fromScale(settings.buttonWidth, settings.buttonHeight)
end

-- Fills in the numbers of the window from the values the server shows.
local function refreshWindow()
	if not window.isOpen() then
		return
	end
	local settings = Ui.rebirthWindow
	local count = rebirths()
	local value = strength()
	local ready = Rebirth.canRebirth(RebirthConfig, value, count)

	beforeCard.multiplier.setText(
		string.format(settings.multiplierText, short(Rebirth.multiplier(RebirthConfig, count)))
	)
	beforeCard.strength.setText(string.format(settings.strengthText, short(value)))
	afterCard.multiplier.setText(
		string.format(settings.multiplierText, short(Rebirth.multiplier(RebirthConfig, count + 1)))
	)
	local strengthAfter = StartValues.startStrength(StrengthConfig, TestSettings, RunService:IsStudio())
	afterCard.strength.setText(string.format(settings.strengthText, short(strengthAfter)))
	fillBar(windowBar)

	confirmButton.setEnabled(ready and os.clock() >= confirmBlockedUntil)
	confirmButton.setText(if ready then settings.confirmText else settings.notReadyText)
end

local function onConfirm()
	local count = rebirths()
	-- Only ask when it can work. The server checks again with its own values.
	if os.clock() < confirmBlockedUntil or not Rebirth.canRebirth(RebirthConfig, strength(), count) then
		return
	end
	confirmBlockedUntil = os.clock() + Ui.rebirthWindow.confirmWaitSeconds
	Remotes.RebirthRequested:FireServer()
end

-- Opens the window, or closes it if it is open.
function RebirthView.toggle()
	window.toggle()
	refreshWindow()
end

function RebirthView.start()
	hudBar = ProgressBar.new("RebirthBar", Hud.gui())
	Hud.onLayout(function(layout: UiLayout.Hud)
		Draw.place(hudBar.frame, layout.bar)
	end)

	createWindow()
	confirmButton.onActivated(onConfirm)

	local function refreshBar()
		fillBar(hudBar)
	end
	StatsView.onChanged(refreshBar)
	refreshBar()

	-- The rebirth happened: close the window.
	player:GetAttributeChangedSignal(Remotes.Attributes.Rebirths):Connect(function()
		window.close()
		confirmBlockedUntil = 0
		refreshBar()
	end)

	-- While the window is open, keep its numbers and the button up to date.
	RunService.Heartbeat:Connect(refreshWindow)
end

return RebirthView
