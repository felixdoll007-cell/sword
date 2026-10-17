--!strict
-- The small movements of the themed training lanes, only on this client: a glowing crack that
-- pulses, glowing lines that pulse, crystals that circle the target, a light in the target.
-- The lanes themselves are built by the server (server/TrainingLook); this script finds their
-- target and props by name and moves them with the same movements as the decoration of the
-- main lane (DecorView). Everything adjustable is in Config/Ui (world.training.themes).
-- Only looks; the server knows nothing about it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local TrainingConfig = require(Shared.Config.Training)
local Ui = require(Shared.Config.Ui)
local Training = require(Shared.Rules.Training)

local DecorView = require(script.Parent.DecorView)

-- How long to wait for a lane of the server.
local LANE_WAIT_SECONDS = 30
local PART_WAIT_SECONDS = 10

local TrainingDecorView = {}

local function findModel(folder: Instance, name: string): Model?
	local found = folder:WaitForChild(name, PART_WAIT_SECONDS)
	return if found and found:IsA("Model") then found else nil
end

local function animateLane(laneIndex: number, theme: any)
	local folder = Workspace:WaitForChild(`TrainingLane{laneIndex}`, LANE_WAIT_SECONDS)
	if not folder then
		return
	end
	local training = Ui.world.training
	DecorView.beginGroup(training.maxLightsPerLane)
	-- A different rhythm for every lane.
	local seed = (laneIndex * Ui.world.decor.rhythmStep) % 1

	local target = findModel(folder, "Target")
	if target and theme.target.motion then
		DecorView.animate(target, theme.target.motion, seed)
	end

	for index, prop in theme.props do
		local motion = prop.motion
		local model = if motion then findModel(folder, `Prop{index}`) else nil
		if model and motion then
			local settings = table.clone(motion)
			-- Circling props go around the target.
			if motion.orbit and target then
				local orbit = table.clone(motion.orbit)
				orbit.center = target:GetPivot().Position
				settings.orbit = orbit
			end
			DecorView.animate(model, settings, seed)
		end
	end

	for _, pulse in theme.pulses or {} do
		local parts: { BasePart } = {}
		for _, part in folder:GetChildren() do
			if part:IsA("BasePart") and string.sub(part.Name, 1, #pulse.namePrefix) == pulse.namePrefix then
				table.insert(parts, part)
			end
		end
		DecorView.glowParts(parts, pulse, seed)
	end
end

function TrainingDecorView.start()
	local training = Ui.world.training
	for laneIndex = 1, Training.laneCount(TrainingConfig) do
		local name = (training.laneThemes :: { [number]: string })[laneIndex]
		local theme = if name then (training.themes :: { [string]: any })[name] else nil
		if theme then
			-- One lane after the other, so each lane counts its own lights.
			animateLane(laneIndex, theme)
		end
	end
end

return TrainingDecorView
