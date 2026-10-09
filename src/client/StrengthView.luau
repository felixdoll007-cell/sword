--!strict
-- Shows the current strength as plain text, abbreviated (1.5K, 3.2M, ...),
-- and a short "+1" after each training throw.
-- The value comes from the server (attribute on the Player); this script only displays it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local NumberFormatConfig = require(Shared.Config.NumberFormat)
local Ui = require(Shared.Config.Ui)
local NumberFormat = require(Shared.Rules.NumberFormat)

local StrengthView = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function makeLabel(name: string, parent: Instance): TextLabel
	local settings = Ui.strengthLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
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

function StrengthView.start()
	local player = Players.LocalPlayer
	local settings = Ui.strengthLabel

	local gui = Instance.new("ScreenGui")
	gui.Name = "StrengthGui"
	gui.ResetOnSpawn = false

	local label = makeLabel("StrengthLabel", gui)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.fromScale(0.5, settings.positionY)
	label.Size = UDim2.fromScale(settings.widthScale, settings.heightScale)

	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(0, settings.minHeight)
	limits.Parent = label

	local function refresh()
		local strength = player:GetAttribute(Remotes.Attributes.Strength)
		if typeof(strength) == "number" then
			label.Text = settings.prefix .. NumberFormat.abbreviate(NumberFormatConfig, strength)
		end
	end
	refresh()
	player:GetAttributeChangedSignal(Remotes.Attributes.Strength):Connect(refresh)

	Remotes.TrainingThrow.OnClientEvent:Connect(function(gained: unknown)
		if typeof(gained) == "number" and gained == gained then
			showGain(label, gained)
		end
	end)

	gui.Parent = player:WaitForChild("PlayerGui")
end

return StrengthView
