--!strict
-- Player characters do not collide with each other. Several players can stand on the same
-- training pad (all snap to its center) or in the throw zone without pushing each other away.
-- They still collide with the floor, walls and barriers.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local GROUP_NAME = "PlayerCharacters"

local PlayerCollisions = {}

local function addPart(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = GROUP_NAME
	end
end

local function onCharacterAdded(character: Model)
	for _, descendant in character:GetDescendants() do
		addPart(descendant)
	end
	-- Accessories and tools arrive a little later.
	character.DescendantAdded:Connect(addPart)
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

function PlayerCollisions.start()
	PhysicsService:RegisterCollisionGroup(GROUP_NAME)
	PhysicsService:CollisionGroupSetCollidable(GROUP_NAME, GROUP_NAME, false)

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return PlayerCollisions
