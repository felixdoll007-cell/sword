--!strict
-- The THROW button (touch and mouse) plus a keyboard shortcut. Asks the server for a throw
-- and plays the throw when the server answers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local ThrowConfig = require(Shared.Config.Throw)
local Ui = require(Shared.Config.Ui)
local LaneLayout = require(Shared.Rules.LaneLayout)

local ThrowSession = require(script.Parent.ThrowSession)

local ThrowController = {}

-- Time of the last request, so the button cannot be spammed while waiting for the server.
local lastRequestTime = -math.huge

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function isInThrowZone(): boolean
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	-- No tolerance here: the button only shows when the player clearly stands in the zone.
	return LaneLayout.isInThrowZone(LaneConfig, 0, root.Position.X, root.Position.Z)
end

local function canRequest(): boolean
	return not ThrowSession.isActive()
		and os.clock() - lastRequestTime >= ThrowConfig.requestWindowSeconds / ThrowConfig.maxThrowRequests
		and isInThrowZone()
end

local function requestThrow()
	if not canRequest() then
		return
	end
	lastRequestTime = os.clock()
	Remotes.ThrowRequested:FireServer()
end

local function createButton(): TextButton
	local settings = Ui.throwButton
	local gui = Instance.new("ScreenGui")
	gui.Name = "ThrowGui"
	gui.ResetOnSpawn = false

	local button = Instance.new("TextButton")
	button.Name = "ThrowButton"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(settings.positionX, settings.positionY)
	-- Full width as the outer box; the aspect ratio below makes it as wide as the height allows.
	button.Size = UDim2.fromScale(1, settings.heightScale)
	button.BackgroundColor3 = color(settings.color)
	button.TextColor3 = color(settings.textColor)
	button.Text = settings.text
	button.Font = Enum.Font.GothamBlack
	button.TextScaled = true
	button.Parent = gui

	-- Width follows the height, so the button keeps its shape on every screen.
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = settings.aspectRatio
	aspect.Parent = button

	local limits = Instance.new("UISizeConstraint")
	limits.MinSize = Vector2.new(settings.minWidth, settings.minHeight)
	limits.MaxSize = Vector2.new(settings.maxWidth, settings.maxHeight)
	limits.Parent = button

	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	return button
end

function ThrowController.start()
	local button = createButton()
	button.Activated:Connect(requestThrow)

	local key = (Enum.KeyCode :: any)[Ui.throwButton.key]
	UserInputService.InputBegan:Connect(function(input: InputObject, typingInTextBox: boolean)
		if not typingInTextBox and input.KeyCode == key then
			requestThrow()
		end
	end)

	-- Show the button only when a throw is possible.
	RunService.Heartbeat:Connect(function()
		button.Visible = not ThrowSession.isActive() and isInThrowZone()
	end)

	Remotes.ThrowStarted.OnClientEvent:Connect(function(throwPower: unknown)
		-- The server is trusted, but a broken value must not break the client.
		if typeof(throwPower) ~= "number" or throwPower ~= throwPower or throwPower < 0 then
			warn("[ThrowController] ignored throw with invalid power")
			return
		end
		ThrowSession.start(throwPower)
	end)
end

return ThrowController
