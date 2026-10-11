--!strict
-- Shows Strength, Coins and Rebirths below the menu: the symbol on the left, the number next to
-- it in its own color, abbreviated (1.5K, 3.2M, ...). Whenever a value grows, a short "+..."
-- rises next to it.
-- The values come from the server (attributes on the Player); this script only displays them.
--
-- During a main throw the server has already credited the reward. To not give away the result
-- before the sword arrives, the display is held during the throw and updated when it ends.
-- Other parts of the interface (progress bar, menu) ask this script for the value on screen,
-- so they do not give the result away either.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)
local UiLayout = require(Shared.Rules.UiLayout)

local Draw = require(script.Parent.Ui.Draw)
local Hud = require(script.Parent.Ui.Hud)
local Icon = require(script.Parent.Ui.Icon)
local OutlinedText = require(script.Parent.Ui.OutlinedText)

-- Differences smaller than this share of the value are rounding leftovers, not a real gain.
local ROUNDING_TOLERANCE = 1e-9

local StatsView = {}

type Shown = {
	attribute: string,
	row: Frame,
	text: OutlinedText.OutlinedText,
	value: number?,
}

local shown: { Shown } = {}
local held = false
-- Counts holds, so an old safety timer cannot release a newer hold.
local holdToken = 0
local listeners: { () -> () } = {}
-- Space between symbol, number and "+...", in pixels (from the layout).
local gapPixels = 0

local function notify()
	for _, listener in listeners do
		listener()
	end
end

local function write(item: Shown)
	if item.value then
		item.text.setText(NumberFormat.abbreviate(NumberFormatConfig, item.value))
	end
end

-- "+..." in light green, right of the number, rising and fading.
local function showGain(item: Shown, gained: number)
	local settings = Ui.gainPopup
	local popup = OutlinedText.new({
		name = "GainPopup",
		parent = item.row,
		text = "+" .. NumberFormat.abbreviate(NumberFormatConfig, gained),
		color = Ui.colors.positive,
		alignX = Enum.TextXAlignment.Left,
	})
	local left = item.row.AbsoluteSize.Y + gapPixels + item.text.label.TextBounds.X + gapPixels
	popup.frame.Size = UDim2.fromScale(settings.widthShare, 1)
	popup.frame.Position = UDim2.new(0, left, settings.startY, 0)

	local rise = TweenService:Create(popup.frame, TweenInfo.new(settings.seconds), {
		Position = UDim2.new(0, left, settings.endY, 0),
	})
	rise:Play()
	popup.fadeOut(settings.seconds).Completed:Connect(function()
		popup.frame:Destroy()
	end)
end

-- Shows the current server value; pops up "+..." if it grew since it was last shown.
local function refresh(item: Shown)
	local value = Players.LocalPlayer:GetAttribute(item.attribute)
	if typeof(value) ~= "number" then
		return
	end
	if item.value and value > item.value then
		showGain(item, value - item.value)
	end
	item.value = value
	write(item)
end

local function refreshAll()
	for _, item in shown do
		refresh(item)
	end
	notify()
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

-- During a held throw: count the shown values up by one wall's reward, without a "+..." here
-- (that one appears at the wall).
function StatsView.addDuringThrow(currency: number, strength: number)
	if not held then
		return
	end
	local gains = {
		[Remotes.Attributes.Currency] = currency,
		[Remotes.Attributes.Strength] = strength,
	}
	for _, item in shown do
		local add = gains[item.attribute]
		if add and item.value then
			item.value += add
			write(item)
		end
	end
	notify()
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

-- The value that is on screen right now (during a throw: the held one). 0 before it is known.
function StatsView.shown(attribute: string): number
	for _, item in shown do
		if item.attribute == attribute then
			return item.value or 0
		end
	end
	return 0
end

-- callback is called whenever a value on screen changes.
function StatsView.onChanged(callback: () -> ())
	table.insert(listeners, callback)
end

function StatsView.start()
	local player = Players.LocalPlayer
	local frame = Draw.box("Stats", Hud.gui())

	local entries: { { attribute: string, kind: Icon.Kind, color: { number } } } = {
		{ attribute = Remotes.Attributes.Strength, kind = "strength", color = Ui.colors.strength },
		{ attribute = Remotes.Attributes.Currency, kind = "coins", color = Ui.colors.coins },
		{ attribute = Remotes.Attributes.Rebirths, kind = "rebirths", color = Ui.colors.rebirths },
	}
	for _, entry in entries do
		local row = Draw.box(entry.attribute, frame)
		local icon = Icon.new(entry.kind, row)
		icon.Name = "Icon"
		local text = OutlinedText.new({
			name = "Value",
			parent = row,
			color = entry.color,
			alignX = Enum.TextXAlignment.Left,
		})
		text.frame.AnchorPoint = Vector2.new(0, 0.5)

		local item: Shown = { attribute = entry.attribute, row = row, text = text, value = nil }
		table.insert(shown, item)
		refresh(item)
		player:GetAttributeChangedSignal(entry.attribute):Connect(function()
			if not held then
				refresh(item)
				notify()
			end
		end)
	end

	Hud.onLayout(function(layout: UiLayout.Hud)
		Draw.place(frame, layout.stats)
		gapPixels = layout.gap
		local rowHeight = layout.statsRowHeight
		for index, item in shown do
			item.row.Position = UDim2.fromOffset(0, math.round((index - 1) * (rowHeight + layout.statsRowGap)))
			item.row.Size = UDim2.new(1, 0, 0, math.round(rowHeight))
			local icon = item.row:FindFirstChild("Icon") :: GuiObject
			icon.Size = UDim2.fromOffset(math.round(rowHeight), math.round(rowHeight))
			-- The number takes the rest of the row, right of the symbol.
			local left = math.round(rowHeight + layout.gap)
			item.text.frame.Position = UDim2.new(0, left, 0.5, 0)
			item.text.frame.Size = UDim2.new(1, -left, Ui.stats.textHeight, 0)
		end
	end)
end

return StatsView
