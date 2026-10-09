--!strict
-- Plays one throw on this client: sword flight, breaking walls, camera, frozen character.
-- Whatever happens (throw ends, character dies or respawns, an error), finish() runs once
-- and puts everything back: camera, movement, walls.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local StrengthConfig = require(Shared.Config.Strength)
local ThrowConfig = require(Shared.Config.Throw)
local ThrowVisuals = require(Shared.Config.ThrowVisuals)
local WallConfig = require(Shared.Config.Walls)
local FlightPlan = require(Shared.Rules.FlightPlan)
local ThrowCalculation = require(Shared.Rules.ThrowCalculation)

local CameraFollow = require(script.Parent.CameraFollow)
local CharacterFreeze = require(script.Parent.CharacterFreeze)
local LaneView = require(script.Parent.LaneView)
local SwordView = require(script.Parent.SwordView)
local WallEffects = require(script.Parent.WallEffects)

local RENDER_STEP_NAME = "ThrowSession"
local FREEZE_REASON = "Throw"

local ThrowSession = {}

local active = false

function ThrowSession.isActive(): boolean
	return active
end

-- Where the sword is at a time of the throw. Returns the pivot (tip) of the sword.
local function swordPose(plan: FlightPlan.Plan, time: number): CFrame
	local v = ThrowVisuals
	local x = LaneConfig.throwLine.x
	local flyingY = LaneConfig.floorTopY + v.swordHeight

	if time <= plan.flightSeconds then
		local distance = FlightPlan.distanceAt(plan, time)
		return CFrame.new(x, flyingY, LaneConfig.throwLine.z - distance)
	end

	local stopDistance = FlightPlan.distanceAt(plan, plan.flightSeconds)
	local progress = math.clamp((time - plan.flightSeconds) / plan.endingSeconds, 0, 1)

	if plan.ending == "bounce" then
		-- Pushed back, spinning, falling to the floor.
		local back = v.bounceBackDistance * math.sin(progress * math.pi / 2)
		local y = flyingY + (LaneConfig.floorTopY + v.bladeThickness - flyingY) * progress * progress
		local spin = math.rad(v.bounceSpinDegrees) * progress
		return CFrame.new(x, y, LaneConfig.throwLine.z - stopDistance + back) * CFrame.Angles(spin, 0, 0)
	end

	-- "stuck": the tip tilts down and sinks into the ground.
	local tilt = math.rad(v.stuckTiltDegrees) * progress
	local y = flyingY + (LaneConfig.floorTopY - v.stuckDepth - flyingY) * progress
	return CFrame.new(x, y, LaneConfig.throwLine.z - stopDistance) * CFrame.Angles(-tilt, 0, 0)
end

function ThrowSession.start(throwPower: number)
	if active then
		return
	end
	local player = Players.LocalPlayer
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	active = true

	local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, throwPower)
	local plan = FlightPlan.create(WallConfig, LaneConfig, ThrowConfig, throwPower, result)

	local cleanupTasks: { () -> () } = {}
	local finished = false
	local function finish()
		if finished then
			return
		end
		finished = true
		-- Every task runs, even if one of them fails.
		for _, cleanup in cleanupTasks do
			local ok, err = pcall(cleanup)
			if not ok then
				warn(`[ThrowSession] cleanup failed: {err}`)
			end
		end
		active = false
	end

	-- Freeze the character. Speed and jump come back in any case.
	CharacterFreeze.freeze(FREEZE_REASON)
	table.insert(cleanupTasks, function()
		CharacterFreeze.release(FREEZE_REASON)
	end)

	local sword = SwordView.create()
	table.insert(cleanupTasks, function()
		sword:Destroy()
	end)

	CameraFollow.start()
	table.insert(cleanupTasks, CameraFollow.stop)
	table.insert(cleanupTasks, LaneView.resetWalls)
	table.insert(cleanupTasks, WallEffects.clearScratch)

	-- Ways a throw can end early.
	local connections = {
		humanoid.Died:Connect(finish),
		player.CharacterRemoving:Connect(finish),
		player.CharacterAdded:Connect(finish),
	}
	table.insert(cleanupTasks, function()
		for _, connection in connections do
			connection:Disconnect()
		end
	end)

	local startTime = os.clock()
	local nextBreak = 1
	local scratched = false

	local function step(deltaTime: number)
		local time = os.clock() - startTime

		while nextBreak <= #plan.breaks and time >= plan.breaks[nextBreak].time do
			local wallIndex = plan.breaks[nextBreak].wallIndex
			LaneView.breakWall(wallIndex)
			WallEffects.spawnPieces(wallIndex)
			nextBreak += 1
		end

		if not scratched and plan.bounceWallIndex and time >= plan.flightSeconds then
			WallEffects.addScratch(plan.bounceWallIndex)
			scratched = true
		end

		local pose = swordPose(plan, time)
		sword:PivotTo(pose)
		if plan.ending == "bounce" and time > plan.flightSeconds then
			-- Pull the camera back and keep it on the point of impact, so sword, wall and scratch are in view.
			local progress = math.clamp((time - plan.flightSeconds) / plan.endingSeconds, 0, 1)
			local eased = 1 - (1 - progress) ^ 2
			local impact = swordPose(plan, plan.flightSeconds).Position
			CameraFollow.update(
				impact,
				deltaTime,
				ThrowVisuals.bounceCameraExtraBehind * eased,
				ThrowVisuals.bounceCameraExtraAbove * eased
			)
		else
			CameraFollow.update(pose.Position, deltaTime, 0, 0)
		end

		if time >= plan.totalSeconds then
			finish()
		end
	end

	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value + 1, function(deltaTime: number)
		local ok, err = pcall(step, deltaTime)
		if not ok then
			warn(`[ThrowSession] stopped after an error: {err}`)
			finish()
		end
	end)
	table.insert(cleanupTasks, function()
		RunService:UnbindFromRenderStep(RENDER_STEP_NAME)
	end)

	-- Last safety net: end the throw even if nothing else did.
	task.delay(plan.totalSeconds + ThrowVisuals.safetyExtraSeconds, finish)
end

return ThrowSession
