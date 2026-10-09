--!strict
-- Shows strength and currency as plain text, abbreviated (1.5K, 3.2M, ...).
-- Whenever a value grows, a short "+..." rises below it.
-- The values come from the server (attributes on the Player); this script only displays them.
--
-- During a main throw the server has already credited the reward. To not give away the result
-- before the sword arrives, the display is held during the throw and updated when it ends.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)

-- Differences smaller than this share of the value are rounding leftovers, not a real gain.
local ROUNDING_TOLERANCE = 1e-9

local StatsView = {}

type Shown = {
	attribute: string,
	prefix: string,
	label: TextLabel,
	value: number?,
}

local shown: { Shown } = {}
local held = false
-- Counts holds, so an old safety timer cannot release a newer hold.
local holdToken = 0

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function makeLabel(name: string, parent: Instance): TextLabel
	local settings = Ui.stats
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = ""
	label.TextColor3 = color(settings.textColor)
	label.TextStrokeColor3 = color(settings.strokeColor)
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

local function showGain(label: TextLabel, gained: number)
	local settings = Ui.gainPopup
	local popup = makeLabel("GainPopup", label)
	popup.AnchorPoint = Vector2.new(0.5, 0)
	popup.Size = UDim2.fromScale(1, 1)
	popup.Position = UDim2.fromScale(0.5, settings.startY)
	popup.TextColor3 = color(settings.color)
	popup.Text = "+" .. NumberFormat.abbreviate(NumberFormatConfig, gained)

	local tween = TweenService:Create(popup, TweenInfo.new(settings.seconds), {
		Position = UDim2.fromScale(0.5, settings.endY),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
	tween:Play()
end

-- Shows the current server value; pops up "+..." if it grew since it was last shown.
local function refresh(item: Shown)
	local value = Players.LocalPlayer:GetAttribute(item.attribute)
	if typeof(value) ~= "number" then
		return
	end
	if item.value and value > item.value then
		showGain(item.label, value - item.value)
	end
	item.value = value
	item.label.Text = item.prefix .. NumberFormat.abbreviate(NumberFormatConfig, value)
end

local function refreshAll()
	for _, item in shown do
		refresh(item)
	end
end

-- Keep showing the old values until release() is called (or the safety time is over).
function StatsView.hold()
	held = true
	holdToken += 1
	local token = holdToken
	task.delay(Ui.stats.maxHoldSeconds, function()
		if held and token == holdToken then
			StatsView.release()
		end
	end)
end

-- During a held throw: count the shown values up by one wall's reward, without a "+..." at the top
-- (that one appears at the wall).
function StatsView.addDuringThrow(currency: number, strength: number)
	if not held then
		return
	end
	for _, item in shown do
		local add = if item.attribute == Remotes.Attributes.Currency then currency else strength
		if item.value then
			item.value += add
			item.label.Text = item.prefix .. NumberFormat.abbreviate(NumberFormatConfig, item.value :: number)
		end
	end
end

-- End of the throw: from now on the values follow the server again, and they are set to exactly
-- the server's values. If they were counted up wall by wall, the difference is only a rounding
-- leftover and no "+..." is shown; if not (e.g. data was missing), the gain pops up as before.
function StatsView.release()
	if not held then
		return
	end
	held = false
	for _, item in shown do
		local value = Players.LocalPlayer:GetAttribute(item.attribute)
		if typeof(value) == "number" and item.value then
			local leftover = math.abs(value - item.value)
			if leftover <= math.max(math.abs(value), 1) * ROUNDING_TOLERANCE then
				item.value = value
			end
		end
	end
	refreshAll()
end

function StatsView.start()
	local player = Players.LocalPlayer
	local settings = Ui.stats

	local gui = Instance.new("ScreenGui")
	gui.Name = "StatsGui"
	gui.ResetOnSpawn = false

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.AnchorPoint = Vector2.new(0.5, 0)
	row.Position = UDim2.fromScale(0.5, settings.positionY)
	row.Size = UDim2.fromScale(1, settings.heightScale)
	row.Parent = gui

	local rowLimits = Instance.new("UISizeConstraint")
	rowLimits.MinSize = Vector2.new(0, settings.minHeight)
	rowLimits.Parent = row

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local entries = {
		{ attribute = Remotes.Attributes.Strength, prefix = settings.strengthPrefix, name = "StrengthLabel" },
		{ attribute = Remotes.Attributes.Currency, prefix = settings.currencyPrefix, name = "CurrencyLabel" },
	}
	for order, entry in entries do
		local label = makeLabel(entry.name, row)
		label.LayoutOrder = order
		label.Size = UDim2.fromScale(settings.widthScale, 1)
		local item: Shown = { attribute = entry.attribute, prefix = entry.prefix, label = label, value = nil }
		table.insert(shown, item)
		refresh(item)
		player:GetAttributeChangedSignal(entry.attribute):Connect(function()
			if not held then
				refresh(item)
			end
		end)
	end

	gui.Parent = player:WaitForChild("PlayerGui")
end

return StatsView
