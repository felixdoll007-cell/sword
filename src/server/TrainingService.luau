--!strict
-- Training: the server looks regularly who stands on which training pad and gives them strength
-- in its own rhythm. A lane only counts if the player has enough rebirths for it; that is
-- calculated here from the player's rebirths, the client has no say in it. The client never reports training throws; it only plays the animation
-- when the server tells it a training throw happened.
--
-- The client may report "training left" (the player let go of the pad). That can only STOP
-- training: the player stays blocked until fully off the pad. It can never start training.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local StrengthConfig = require(Shared.Config.Strength)
local TrainingConfig = require(Shared.Config.Training)
local RateLimit = require(Shared.Rules.RateLimit)
local Training = require(Shared.Rules.Training)

local PlayerStats = require(script.Parent.PlayerStats)
local Spectators = require(script.Parent.Spectators)

type PlayerState = {
	-- When the next training throw is due. nil = not training.
	nextThrowAt: number?,
	-- The lane the player is training on. nil = not training.
	lane: number?,
	-- Let go of the pad and not yet fully off it.
	blocked: boolean,
	leaveMessageTimes: { number },
}

local TrainingService = {}

local states: { [Player]: PlayerState } = {}

local function getState(player: Player): PlayerState
	local state = states[player]
	if not state then
		state = { nextThrowAt = nil, lane = nil, blocked = false, leaveMessageTimes = {} }
		states[player] = state
	end
	return state
end

-- The lane whose pad the player stands on (locked or not). nil if on none or not alive.
local function padUnderPlayer(player: Player): number?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil
	end
	return Training.laneAt(TrainingConfig, root.Position.X, root.Position.Z)
end

local function checkPlayers()
	local now = Workspace:GetServerTimeNow()
	for _, player in Players:GetPlayers() do
		local state = getState(player)
		local padLane = padUnderPlayer(player)
		state.blocked = Training.updateBlock(state.blocked, padLane ~= nil)

		-- Only an unlocked lane counts. Unlocking comes from the rebirths the server has stored.
		local rebirths = PlayerStats.getRebirths(player)
		local lane: number? = nil
		if padLane and rebirths and Training.isUnlocked(TrainingConfig, padLane, { rebirths = rebirths }) then
			lane = padLane
		end
		if lane ~= state.lane then
			-- New lane (or none): the rhythm starts fresh.
			state.lane = lane
			state.nextThrowAt = nil
		end

		local throws, nextAt = Training.tick(
			state.nextThrowAt,
			Training.isTraining(lane ~= nil, state.blocked),
			now,
			StrengthConfig.trainingSecondsPerThrow
		)
		state.nextThrowAt = nextAt
		if throws and lane then
			-- Base gain times the lane's multiplier and the bonus of the equipped weapon;
			-- gainStrength adds the rebirth multiplier on top.
			local base = StrengthConfig.trainingStrengthPerThrow
				* TrainingConfig.lanes[lane].multiplier
				* (PlayerStats.trainingBonus(player) or 1)
			local gained = PlayerStats.gainStrength(player, base)
			if gained > 0 then
				Remotes.TrainingThrow:FireClient(player, gained, lane)
				-- Players nearby see the throw. This comes from the server's own rhythm.
				Spectators.tell(player, Remotes.ThrowKind.Training, lane)
			end
		end
	end
end

local function onTrainingLeft(player: Player, ...: any)
	local state = states[player]
	if not state then
		return
	end

	-- 1. Rate limit
	local allowed
	allowed, state.leaveMessageTimes = RateLimit.check(
		state.leaveMessageTimes,
		Workspace:GetServerTimeNow(),
		TrainingConfig.maxLeaveMessages,
		TrainingConfig.leaveMessageWindowSeconds
	)
	if not allowed then
		return
	end

	-- 2. + 3. This message carries no values.
	if select("#", ...) > 0 then
		return
	end

	-- 4. Only meaningful while standing on the pad. Off the pad there is nothing to stop.
	if not padUnderPlayer(player) then
		return
	end

	-- 5. Stop training until the player has fully left the pad.
	state.blocked = true
	state.nextThrowAt = nil
end

function TrainingService.start()
	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)
	Remotes.TrainingLeft.OnServerEvent:Connect(onTrainingLeft)
	task.spawn(function()
		while true do
			checkPlayers()
			task.wait(TrainingConfig.checkSeconds)
		end
	end)
end

return TrainingService
