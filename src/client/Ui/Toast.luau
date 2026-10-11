--!strict
-- Building block: a short message in the upper middle of the screen, like "Coming soon".
-- It pops in, stays a moment and fades. A new message replaces the one still showing.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local UiLayout = require(Shared.Rules.UiLayout)

local Draw = require(script.Parent.Draw)
local OutlinedText = require(script.Parent.OutlinedText)

-- Above the windows.
local DISPLAY_ORDER = 20

local Toast = {}

local gui: ScreenGui? = nil
local showing: OutlinedText.OutlinedText? = nil

local function getGui(): ScreenGui
	if gui then
		return gui
	end
	local newGui = Draw.screen("ToastGui", DISPLAY_ORDER)
	gui = newGui
	return newGui
end

function Toast.show(message: string)
	local settings = Ui.toast
	local screen = getGui()
	if showing then
		showing.frame:Destroy()
		showing = nil
	end

	local size = screen.AbsoluteSize
	local height = UiLayout.scaled(settings.height, math.min(size.X, size.Y))
	local text = OutlinedText.new({ name = "Toast", parent = screen, text = message })
	text.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	text.frame.Position = UDim2.fromScale(0.5, settings.positionY)
	text.frame.Size = UDim2.new(settings.widthShare, 0, 0, math.round(height))
	showing = text

	local scale = Instance.new("UIScale")
	scale.Scale = settings.popFromScale
	scale.Parent = text.frame
	local pop = TweenInfo.new(settings.popSeconds, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(scale, pop, { Scale = 1 }):Play()

	task.delay(settings.popSeconds + settings.staySeconds, function()
		-- Replaced by a newer message in the meantime: that one cleaned up already.
		if showing ~= text then
			return
		end
		text.fadeOut(settings.fadeSeconds).Completed:Connect(function()
			if showing == text then
				showing = nil
			end
			text.frame:Destroy()
		end)
	end)
end

return Toast
