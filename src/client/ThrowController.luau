--!strict
-- The THROW button (touch and mouse) plus a keyboard shortcut. It sits above the progress bar at
-- the bottom center and is only there in the throw zone.
-- First press: ask the server to start the meter. Second press: tell the server WHEN it was pressed.
-- The server answers with the throw power and the factor, then the throw is played.
--
-- Steps of the client:
--   idle            nothing running, button shown in the throw zone
--   waitingForMeter first press sent, waiting for the server
--   meterRunning    pointer swings, character frozen, button stops it
--   waitingForThrow second press sent, pointer stopped, waiting for the server
--   (then ThrowSession plays the throw)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local MeterConfig = require(Shared.Config.Meter)
local Ui = require(Shared.Config.Ui)
local LaneLayout = require(Shared.Rules.LaneLayout)
local Meter = require(Shared.Rules.Meter)
local Rewards = require(Shared.Rules.Rewards)
local UiLayout = require(Shared.Rules.UiLayout)

local Button = require(script.Parent.Ui.Button)
local Draw = require(script.Parent.Ui.Draw)
local Hud = require(script.Parent.Ui.Hud)
local CharacterFreeze = require(script.Parent.CharacterFreeze)
local MeterView = require(script.Parent.MeterView)
local StatsView = require(script.Parent.StatsView)
local ThrowSession = require(script.Parent.ThrowSession)

local FREEZE_REASON = "Meter"

type Step = "idle" | "waitingForMeter" | "meterRunning" | "waitingForThrow"

local ThrowController = {}

local step: Step = "idle"
-- Server clock time when the current step started (for timeouts).
local stepStartedAt = 0
local meterStartTime = 0
local meterStartPhase = 0
-- Whether the button currently reads STOP.
local showsStop = false

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function setStep(newStep: Step)
	step = newStep
	stepStartedAt = now()
end

-- Back to the start: meter hidden, character free.
local function backToIdle()
	setStep("idle")
	MeterView.hide()
	CharacterFreeze.release(FREEZE_REASON)
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

local function onPress()
	if ThrowSession.isActive() then
		return
	end
	if step == "idle" and isInThrowZone() then
		setStep("waitingForMeter")
		Remotes.MeterStartRequested:FireServer()
	elseif step == "meterRunning" then
		local pressTime = now()
		-- Stop the pointer where the player saw it.
		MeterView.setPointer(Meter.position(MeterConfig, meterStartTime, meterStartPhase, pressTime))
		setStep("waitingForThrow")
		-- The server credits the reward right away; keep the old values on screen until the throw ends.
		StatsView.hold()
		Remotes.ThrowRequested:FireServer(pressTime)
	end
end

local function isRealNumber(value: unknown): boolean
	return typeof(value) == "number" and value == value and math.abs(value) ~= math.huge
end

local function onMeterStarted(startTime: unknown, startPhase: unknown)
	-- The server is trusted, but a broken value must not break the client.
	if step ~= "waitingForMeter" or not isRealNumber(startTime) or not isRealNumber(startPhase) then
		return
	end
	meterStartTime = startTime :: number
	meterStartPhase = startPhase :: number
	setStep("meterRunning")
	CharacterFreeze.freeze(FREEZE_REASON)
	MeterView.setPointer(Meter.position(MeterConfig, meterStartTime, meterStartPhase, now()))
	MeterView.show()
end

-- The reward of each broken wall, as sent by the server. nil if anything is off;
-- then the values simply update at the end of the throw.
local function readPerWall(value: unknown): { Rewards.WallReward }?
	if typeof(value) ~= "table" then
		return nil
	end
	local list = {}
	for index, entry in value :: { any } do
		if
			typeof(entry) ~= "table"
			or not isRealNumber(entry.currency)
			or not isRealNumber(entry.strength)
			or not isRealNumber(entry.zoneBonus)
		then
			return nil
		end
		list[index] = { currency = entry.currency, strength = entry.strength, zoneBonus = entry.zoneBonus }
	end
	return list
end

local function onThrowStarted(throwPower: unknown, factor: unknown, perWall: unknown)
	if not isRealNumber(throwPower) or not isRealNumber(factor) or (throwPower :: number) < 0 then
		warn("[ThrowController] ignored throw with invalid values")
		backToIdle()
		StatsView.release()
		return
	end
	backToIdle()
	MeterView.showFactor(factor :: number, MeterConfig.factorDisplaySeconds)
	ThrowSession.start(throwPower :: number, readPerWall(perWall))
	if not ThrowSession.isActive() then
		-- The throw could not be played (e.g. character just died): show the values now.
		StatsView.release()
	end
end

-- Runs every frame: moves the pointer and ends steps that took too long.
local function update(button: Button.Button)
	local time = now()

	if step == "meterRunning" then
		if time > meterStartTime + MeterConfig.timeoutSeconds then
			backToIdle()
		else
			MeterView.setPointer(Meter.position(MeterConfig, meterStartTime, meterStartPhase, time))
		end
	elseif step == "waitingForMeter" or step == "waitingForThrow" then
		if time - stepStartedAt > MeterConfig.responseTimeoutSeconds then
			if step == "waitingForThrow" then
				StatsView.release()
			end
			backToIdle()
		end
	end

	-- The button is there when it can do something: start the meter or stop it.
	button.frame.Visible = not ThrowSession.isActive()
		and ((step == "idle" and isInThrowZone()) or step == "meterRunning")
	-- THROW in the game's action color, STOP in red.
	local stopping = step == "meterRunning"
	if stopping ~= showsStop then
		showsStop = stopping
		button.setText(if stopping then Ui.throwButton.stopText else Ui.throwButton.text)
		button.setColor(if stopping then Ui.colors.danger else Ui.colors.action)
	end
end

local function createButton(): Button.Button
	local button = Button.new({
		name = "ThrowButton",
		parent = Hud.gui(),
		text = Ui.throwButton.text,
		color = Ui.colors.action,
	})
	button.frame.Visible = false
	Hud.onLayout(function(layout: UiLayout.Hud)
		Draw.place(button.frame, layout.throwButton)
	end)
	return button
end

function ThrowController.start()
	MeterView.create()
	local button = createButton()
	button.onActivated(onPress)

	local key = (Enum.KeyCode :: any)[Ui.throwButton.key]
	UserInputService.InputBegan:Connect(function(input: InputObject, typingInTextBox: boolean)
		if not typingInTextBox and input.KeyCode == key then
			onPress()
		end
	end)

	RunService.Heartbeat:Connect(function()
		update(button)
	end)

	-- Dying or respawning during the meter ends it.
	Players.LocalPlayer.CharacterAdded:Connect(backToIdle)

	Remotes.MeterStarted.OnClientEvent:Connect(onMeterStarted)
	Remotes.ThrowStarted.OnClientEvent:Connect(onThrowStarted)
end

return ThrowController
