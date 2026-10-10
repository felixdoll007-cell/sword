--!strict
-- Tells players near a thrower that a throw happened, so they can see it.
-- Only the server calls this, from its own training rhythm and its own throw check.
-- There is no message from a client that leads here: a client cannot make others see a throw.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local OtherPlayersConfig = require(Shared.Config.OtherPlayers)
local Visibility = require(Shared.Rules.Visibility)

local Spectators = {}

local function groundPosition(player: Player): (number?, number?)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root.Position.X, root.Position.Z
	end
	return nil, nil
end

-- kind: Remotes.ThrowKind. lane: the training lane, nil for a main throw.
function Spectators.tell(thrower: Player, kind: string, lane: number?)
	local throwerX, throwerZ = groundPosition(thrower)
	if not throwerX or not throwerZ then
		return
	end
	for _, other in Players:GetPlayers() do
		if other ~= thrower then
			local x, z = groundPosition(other)
			if x and z and Visibility.isNear(OtherPlayersConfig.visibleDistance, throwerX, throwerZ, x, z) then
				Remotes.OtherPlayerThrew:FireClient(other, thrower, kind, lane)
			end
		end
	end
end

return Spectators
