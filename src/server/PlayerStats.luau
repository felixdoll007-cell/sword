--!strict
-- The one place on the server that holds each player's strength.
-- Kept in memory only for now; saving comes in Etappe 6.
-- The value is copied into an attribute on the Player so the client can show it.
-- The client can read it, but changes it makes stay on its own screen; the server never reads it back.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local StrengthConfig = require(Shared.Config.Strength)
local TestSettings = require(Shared.Config.TestSettings)
local StartValues = require(Shared.Rules.StartValues)

local PlayerStats = {}

local strengths: { [Player]: number } = {}

local function setStrength(player: Player, value: number)
	strengths[player] = value
	player:SetAttribute(Remotes.Attributes.Strength, value)
end

function PlayerStats.getStrength(player: Player): number?
	return strengths[player]
end

function PlayerStats.addStrength(player: Player, amount: number)
	local current = strengths[player]
	if current then
		setStrength(player, current + amount)
	end
end

function PlayerStats.start()
	local function onPlayerAdded(player: Player)
		setStrength(player, StartValues.startStrength(StrengthConfig, TestSettings, RunService:IsStudio()))
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerRemoving:Connect(function(player: Player)
		strengths[player] = nil
	end)
end

return PlayerStats
