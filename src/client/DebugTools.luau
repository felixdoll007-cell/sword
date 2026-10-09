--!strict
-- Test helpers for Studio: keys to break and reset walls, and a label naming this window.
-- Does nothing unless TestSettings.debugTools is true AND the game runs in Studio.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local TestSettings = require(ReplicatedStorage.Shared.Config.TestSettings)
local TestMode = require(ReplicatedStorage.Shared.Rules.TestMode)
local LaneView = require(script.Parent.LaneView)

local DebugTools = {}

local function showLabel(player: Player)
	local gui = Instance.new("ScreenGui")
	gui.Name = "DebugLabel"
	gui.ResetOnSpawn = false

	local label = Instance.new("TextLabel")
	-- Bottom left, because the chat sits at the top left.
	label.AnchorPoint = Vector2.new(0, 1)
	label.Position = UDim2.fromScale(0, 1)
	label.AutomaticSize = Enum.AutomaticSize.XY
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = TestSettings.labelTextSize
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text =
		`CLIENT: {player.Name}  |  {TestSettings.breakNextWallKey} = break next wall, {TestSettings.resetWallsKey} = reset walls`
	label.Parent = gui

	gui.Parent = player:WaitForChild("PlayerGui")
end

function DebugTools.start()
	if not TestMode.isOn(TestSettings.debugTools, RunService:IsStudio()) then
		return
	end

	local player = Players.LocalPlayer
	showLabel(player)

	local breakKey = (Enum.KeyCode :: any)[TestSettings.breakNextWallKey]
	local resetKey = (Enum.KeyCode :: any)[TestSettings.resetWallsKey]

	UserInputService.InputBegan:Connect(function(input: InputObject, typingInTextBox: boolean)
		if typingInTextBox then
			return
		end
		if input.KeyCode == breakKey then
			local index = LaneView.breakNextWall()
			print(`[DebugTools] {player.Name} broke wall {index or "none (all broken)"}`)
		elseif input.KeyCode == resetKey then
			LaneView.resetWalls()
			print(`[DebugTools] {player.Name} reset all walls`)
		end
	end)
end

return DebugTools
