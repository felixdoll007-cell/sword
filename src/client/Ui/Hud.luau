--!strict
-- The always visible interface: one screen layer that all parts share (menu, values, progress
-- bar, THROW button, meter). It works out where everything sits (Rules/UiLayout) and tells the
-- parts again whenever the screen changes size or is turned.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local UiLayout = require(Shared.Rules.UiLayout)

local Draw = require(script.Parent.Draw)

-- Below the windows.
local DISPLAY_ORDER = 0

local Hud = {}

-- Number of values shown below the menu: Strength, Coins, Rebirths.
Hud.STAT_COUNT = 3

local gui: ScreenGui? = nil
local current: UiLayout.Hud? = nil
local listeners: { (UiLayout.Hud) -> () } = {}

local function update()
	if not gui then
		return
	end
	local size = gui.AbsoluteSize
	local layout = UiLayout.hud(Ui.layout, size.X, size.Y, #Ui.menu.entries, Hud.STAT_COUNT)
	current = layout
	for _, listener in listeners do
		listener(layout)
	end
end

-- Makes the screen layer. Call once, before the parts are built.
function Hud.start()
	if gui then
		return
	end
	local newGui = Draw.screen("HudGui", DISPLAY_ORDER)
	gui = newGui
	newGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
end

function Hud.gui(): ScreenGui
	return gui :: ScreenGui
end

-- Size of the usable screen in pixels.
function Hud.screenSize(): Vector2
	return if gui then gui.AbsoluteSize else Vector2.zero
end

-- callback is called right away with the current layout, and again whenever it changes.
function Hud.onLayout(callback: (UiLayout.Hud) -> ())
	table.insert(listeners, callback)
	if current then
		callback(current)
	end
end

return Hud
