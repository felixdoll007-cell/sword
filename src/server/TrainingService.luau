--!strict
-- Training: the server looks regularly who stands on the training pad and gives them strength
-- in its own rhythm. The client never reports training throws; it only plays the animation
-- when the server tells it a training throw happened.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local StrengthConfig = require(Shared.Config.Strength)
local TrainingConfig = require(Shared.Config.Training)
local Training = require(Shared.Rules.Training)

local PlayerStats = require(script.Parent.PlayerStats)

local TrainingService = {}

-- When the next training throw is due for each player. nil = not training.
local nextThrowAt: { [Player]: number? } = {}

local function isStandingOnPad(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false
	end
	return Training.isOnPad(TrainingConfig, root.Position.X, root.Position.Z)
end

local function checkPlayers()
	local now = Workspace:GetServerTimeNow()
	for _, player in Players:GetPlayers() do
		local throws, nextAt =
			Training.tick(nextThrowAt[player], isStandingOnPad(player), now, StrengthConfig.trainingSecondsPerThrow)
		nextThrowAt[player] = nextAt
		if throws then
			local gained = StrengthConfig.trainingStrengthPerThrow
			PlayerStats.addStrength(player, gained)
			Remotes.TrainingThrow:FireClient(player, gained)
		end
	end
end

function TrainingService.start()
	Players.PlayerRemoving:Connect(function(player: Player)
		nextThrowAt[player] = nil
	end)
	task.spawn(function()
		while true do
			checkPlayers()
			task.wait(TrainingConfig.checkSeconds)
		end
	end)
end

return TrainingService
