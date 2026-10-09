--!strict
-- Handles the meter and the throw. The client only says "start the meter" and
-- "I pressed at this moment". Everything else (may the player throw, where the pointer was,
-- the factor, the throw power, how long the throw lasts) is decided here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local MeterConfig = require(Shared.Config.Meter)
local StrengthConfig = require(Shared.Config.Strength)
local ThrowConfig = require(Shared.Config.Throw)
local WallConfig = require(Shared.Config.Walls)
local FlightPlan = require(Shared.Rules.FlightPlan)
local LaneLayout = require(Shared.Rules.LaneLayout)
local Meter = require(Shared.Rules.Meter)
local RateLimit = require(Shared.Rules.RateLimit)
local ThrowCalculation = require(Shared.Rules.ThrowCalculation)

local PlayerStats = require(script.Parent.PlayerStats)

type RunningMeter = {
	startTime: number,
	startPhase: number,
}

type PlayerState = {
	-- No new meter or throw before this time (server clock).
	lockedUntil: number,
	meter: RunningMeter?,
	meterRequestTimes: { number },
	throwRequestTimes: { number },
}

local states: { [Player]: PlayerState } = {}
local random = Random.new()

local ThrowService = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function onPlayerAdded(player: Player)
	states[player] = {
		lockedUntil = 0,
		meter = nil,
		meterRequestTimes = {},
		throwRequestTimes = {},
	}
end

local function onPlayerRemoving(player: Player)
	states[player] = nil
end

local function isStandingInThrowZone(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	local position = root.Position
	return LaneLayout.isInThrowZone(LaneConfig, ThrowConfig.throwZoneTolerance, position.X, position.Z)
end

local function isMeterRunning(meter: RunningMeter?, time: number): boolean
	return meter ~= nil and time <= meter.startTime + MeterConfig.timeoutSeconds
end

-- First press.
local function onMeterStartRequested(player: Player, ...: any)
	local state = states[player]
	if not state then
		return
	end
	local time = now()

	-- 1. Rate limit
	local allowed
	allowed, state.meterRequestTimes =
		RateLimit.check(state.meterRequestTimes, time, ThrowConfig.maxThrowRequests, ThrowConfig.requestWindowSeconds)
	if not allowed then
		return
	end

	-- 2. + 3. This message carries no values.
	if select("#", ...) > 0 then
		return
	end

	-- 4. Allowed right now? No throw running, no meter running, standing in the throw zone.
	if time < state.lockedUntil or isMeterRunning(state.meter, time) or not isStandingInThrowZone(player) then
		return
	end

	-- 5. The server decides when the meter starts and where the pointer begins.
	local meter = { startTime = time, startPhase = random:NextNumber() }
	state.meter = meter
	Remotes.MeterStarted:FireClient(player, meter.startTime, meter.startPhase)
end

-- Second press.
local function onThrowRequested(player: Player, pressTime: unknown, ...: any)
	local state = states[player]
	if not state then
		return
	end
	local time = now()

	-- 1. Rate limit
	local allowed
	allowed, state.throwRequestTimes =
		RateLimit.check(state.throwRequestTimes, time, ThrowConfig.maxThrowRequests, ThrowConfig.requestWindowSeconds)
	if not allowed then
		return
	end

	-- A meter can only be used once, whatever happens below.
	local meter = state.meter
	state.meter = nil
	if not meter then
		return
	end

	-- 2. Only one value is expected.
	if select("#", ...) > 0 then
		return
	end

	-- 3. Type and range of the press time. Too old presses count as the earliest allowed moment.
	local usedTime = Meter.timeToUse(MeterConfig, meter.startTime, pressTime, time)
	if not usedTime then
		return
	end

	-- 4. Still allowed?
	if time < state.lockedUntil or not isStandingInThrowZone(player) then
		return
	end

	-- 5. The server calculates where the pointer was and what that is worth.
	local position = Meter.position(MeterConfig, meter.startTime, meter.startPhase, usedTime)
	local factor = Meter.factor(MeterConfig, position)
	local strength = PlayerStats.getStrength(player)
	if not strength then
		return
	end
	local throwPower = strength * factor

	local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, throwPower)
	local plan = FlightPlan.create(WallConfig, LaneConfig, ThrowConfig, throwPower, result)
	state.lockedUntil = time + plan.totalSeconds

	-- Credit the rewards now, while calculating. Even if the player leaves during the flight,
	-- the throw counts. The client only shows the new values once the throw has ended.
	PlayerStats.applyThrow(player, {
		currency = result.currency,
		strength = result.strength,
		wallsBroken = #result.brokenWalls,
	})
	Remotes.ThrowStarted:FireClient(player, throwPower, factor)
end

function ThrowService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Remotes.MeterStartRequested.OnServerEvent:Connect(onMeterStartRequested)
	Remotes.ThrowRequested.OnServerEvent:Connect(onThrowRequested)
end

return ThrowService
