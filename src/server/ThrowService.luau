--!strict
-- Handles throw requests. The client only says "I want to throw".
-- Everything else (may the player throw, how strong, how long) is decided here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local LaneConfig = require(Shared.Config.Lane)
local StrengthConfig = require(Shared.Config.Strength)
local TestSettings = require(Shared.Config.TestSettings)
local ThrowConfig = require(Shared.Config.Throw)
local WallConfig = require(Shared.Config.Walls)
local FlightPlan = require(Shared.Rules.FlightPlan)
local LaneLayout = require(Shared.Rules.LaneLayout)
local RateLimit = require(Shared.Rules.RateLimit)
local StartValues = require(Shared.Rules.StartValues)
local ThrowCalculation = require(Shared.Rules.ThrowCalculation)

type PlayerState = {
	-- Kept in memory only for now. Saving comes in Etappe 6.
	strength: number,
	-- No new throw before this time (os.clock).
	lockedUntil: number,
	requestTimes: { number },
}

local states: { [Player]: PlayerState } = {}

local ThrowService = {}

local function onPlayerAdded(player: Player)
	states[player] = {
		strength = StartValues.startStrength(StrengthConfig, TestSettings, RunService:IsStudio()),
		lockedUntil = 0,
		requestTimes = {},
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

local function onThrowRequested(player: Player, ...: any)
	local state = states[player]
	if not state then
		return
	end

	-- 1. Rate limit
	local now = os.clock()
	local allowed
	allowed, state.requestTimes =
		RateLimit.check(state.requestTimes, now, ThrowConfig.maxThrowRequests, ThrowConfig.requestWindowSeconds)
	if not allowed then
		return
	end

	-- 2. + 3. Data: this message carries no values. Anything sent along is suspicious.
	if select("#", ...) > 0 then
		return
	end

	-- 4. Is the throw allowed right now?
	if now < state.lockedUntil or not isStandingInThrowZone(player) then
		return
	end

	-- 5. Calculate with values only the server knows. The meter factor comes in Etappe 4.
	local throwPower = state.strength
	local result = ThrowCalculation.calculate(WallConfig, StrengthConfig, throwPower)
	local plan = FlightPlan.create(WallConfig, LaneConfig, ThrowConfig, throwPower, result)
	state.lockedUntil = now + plan.totalSeconds

	-- Currency and strength from the throw are awarded in Etappe 6.
	Remotes.ThrowStarted:FireClient(player, throwPower)
end

function ThrowService.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Remotes.ThrowRequested.OnServerEvent:Connect(onThrowRequested)
end

return ThrowService
