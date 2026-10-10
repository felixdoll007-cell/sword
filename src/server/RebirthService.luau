--!strict
-- Handles rebirth requests. The client only says "I want to rebirth".
-- Whether the player has enough strength, and what the rebirth changes, is decided here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local RebirthConfig = require(Shared.Config.Rebirth)
local RateLimit = require(Shared.Rules.RateLimit)

local PlayerStats = require(script.Parent.PlayerStats)
local ThrowService = require(script.Parent.ThrowService)

local RebirthService = {}

local requestTimes: { [Player]: { number } } = {}

local function onRebirthRequested(player: Player, ...: any)
	-- 1. Rate limit
	local allowed, times = RateLimit.check(
		requestTimes[player] or {},
		Workspace:GetServerTimeNow(),
		RebirthConfig.maxRequests,
		RebirthConfig.requestWindowSeconds
	)
	requestTimes[player] = times
	if not allowed then
		return
	end

	-- 2. + 3. This message carries no values.
	if select("#", ...) > 0 then
		return
	end

	-- 4. Not in the middle of a meter or a throw: the reward of that throw is still being shown.
	if ThrowService.isBusy(player) then
		return
	end

	-- 5. PlayerStats checks the strength against the threshold with its own values and does the rebirth.
	PlayerStats.rebirth(player)
end

function RebirthService.start()
	Players.PlayerRemoving:Connect(function(player: Player)
		requestTimes[player] = nil
	end)
	Remotes.RebirthRequested.OnServerEvent:Connect(onRebirthRequested)
end

return RebirthService
