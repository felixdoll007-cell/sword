--!strict
-- The menu grid on the left: square buttons in two columns, in the order of Config/Ui.
-- A button opens its window. Buttons that are switched off in the config, and buttons that have
-- nothing to open yet, are shown dark with a lock and only answer "Coming soon".
-- The Rebirth button shows the progress to the next rebirth as percent at its top.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local RebirthConfig = require(Shared.Config.Rebirth)
local Ui = require(Shared.Config.Ui)
local Rebirth = require(Shared.Rules.Rebirth)
local UiLayout = require(Shared.Rules.UiLayout)

local ItemsWindowView = require(script.Parent.ItemsWindowView)
local RebirthView = require(script.Parent.RebirthView)
local StatsView = require(script.Parent.StatsView)
local ThrowSession = require(script.Parent.ThrowSession)
local Draw = require(script.Parent.Ui.Draw)
local Hud = require(script.Parent.Ui.Hud)
local MenuButton = require(script.Parent.Ui.MenuButton)
local Toast = require(script.Parent.Ui.Toast)
local Window = require(script.Parent.Ui.Window)

-- What the button with this id opens. An id without an entry here has nothing to open yet.
local OPENERS: { [string]: () -> () } = {
	rebirth = RebirthView.toggle,
	inventory = function()
		ItemsWindowView.toggle("weapons")
	end,
	pets = function()
		ItemsWindowView.toggle("pets")
	end,
}
local REBIRTH_ID = "rebirth"

local MenuView = {}

function MenuView.start()
	local player = Players.LocalPlayer
	local frame = Draw.box("Menu", Hud.gui())

	local buttons: { MenuButton.MenuButton } = {}
	local captions: { string } = {}
	local rebirthButton: MenuButton.MenuButton? = nil
	for _, entry in Ui.menu.entries do
		local open = OPENERS[entry.id]
		local locked = not entry.enabled or open == nil
		local button = MenuButton.new({
			name = entry.id,
			parent = frame,
			label = entry.label,
			icon = entry.icon,
			locked = locked,
		})
		button.onActivated(function()
			if locked then
				Toast.show(Ui.menu.comingSoonText)
			else
				open()
			end
		end)
		table.insert(buttons, button)
		table.insert(captions, entry.label)
		if entry.id == REBIRTH_ID and not locked then
			rebirthButton = button
		end
	end

	Hud.onLayout(function(layout: UiLayout.Hud)
		Draw.place(frame, layout.menu)
		local step = layout.menuCell + layout.gap
		local captionSize = MenuButton.captionSize(captions, layout.menuCell)
		for index, button in buttons do
			local column = (index - 1) % layout.menuColumns
			local row = (index - 1) // layout.menuColumns
			button.frame.Position = UDim2.fromOffset(math.round(column * step), math.round(row * step))
			button.frame.Size = UDim2.fromOffset(math.round(layout.menuCell), math.round(layout.menuCell))
			button.setCaptionSize(captionSize)
		end
	end)

	-- Progress to the next rebirth on its button, from the strength that is on screen.
	local function refreshRebirth()
		if not rebirthButton then
			return
		end
		local value = player:GetAttribute(Remotes.Attributes.Rebirths)
		local rebirths = if typeof(value) == "number" then value else 0
		local percent = Rebirth.progressPercent(RebirthConfig, StatsView.shown(Remotes.Attributes.Strength), rebirths)
		rebirthButton.setTopText(string.format(Ui.rebirthBar.percentText, tostring(percent)))
		rebirthButton.setNotice(percent >= 100)
	end
	StatsView.onChanged(refreshRebirth)
	refreshRebirth()

	-- Not during a throw: the reward is still being counted up on screen.
	RunService.Heartbeat:Connect(function()
		local throwing = ThrowSession.isActive()
		frame.Visible = not throwing
		if throwing then
			Window.closeAll()
		end
	end)
end

return MenuView
