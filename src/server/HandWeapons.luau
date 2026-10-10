--!strict
-- Puts the equipped weapon into the right hand of every character. Built on the server, so all
-- players see it. It follows the hand by a weld, so it moves with every animation.
--
-- Hiding the weapon while it flies is done by each client for itself (client/HandWeaponView):
-- that costs no network traffic, and players far away simply keep seeing it in the hand.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local ThrowVisuals = require(Shared.Config.ThrowVisuals)
local WeaponModel = require(Shared.WeaponModel)

-- Names the clients look for (client/HandWeaponView).
local MODEL_NAME = "HandWeapon"
local HAND_NAME = "RightHand"
local GRIP_ATTACHMENT_NAME = "RightGripAttachment"

local HandWeapons = {}

local function build(player: Player, character: Model)
	local old = character:FindFirstChild(MODEL_NAME)
	if old then
		old:Destroy()
	end

	-- Only the R15 body has a right hand part. Without one there is simply no weapon in the hand.
	local hand = character:FindFirstChild(HAND_NAME)
	if not hand or not hand:IsA("BasePart") then
		return
	end

	local weapon = WeaponModel.create(player:GetAttribute(Remotes.Attributes.EquippedWeapon), 1, false)
	weapon.Name = MODEL_NAME
	local root = weapon.PrimaryPart
	if not root then
		weapon:Destroy()
		return
	end

	-- Where the hand holds things, and how the weapon is turned in the hand.
	local gripAttachment = hand:FindFirstChild(GRIP_ATTACHMENT_NAME)
	local handGrip = if gripAttachment and gripAttachment:IsA("Attachment") then gripAttachment.CFrame else CFrame.new()
	local rotation = ThrowVisuals.handRotationDegrees
	local turned = CFrame.Angles(math.rad(rotation.x), math.rad(rotation.y), math.rad(rotation.z))

	-- A weld holds: hand.CFrame * C0 == root.CFrame * C1. Both sides describe the weapon's grip.
	local weld = Instance.new("Weld")
	weld.Name = "HandWeld"
	weld.Part0 = hand
	weld.Part1 = root
	weld.C0 = handGrip * turned
	weld.C1 = root.PivotOffset * WeaponModel.gripFromPivot(weapon)
	weld.Parent = root

	weapon.Parent = character
end

local function onCharacterAdded(player: Player, character: Model)
	-- The body parts arrive one after the other.
	character:WaitForChild("Humanoid")
	character:WaitForChild(HAND_NAME, 5)
	if character.Parent then
		build(player, character)
	end
end

local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		task.spawn(onCharacterAdded, player, player.Character)
	end
	-- A new weapon was equipped (or the data was loaded): swap the model.
	player:GetAttributeChangedSignal(Remotes.Attributes.EquippedWeapon):Connect(function()
		local character = player.Character
		if character then
			build(player, character)
		end
	end)
end

function HandWeapons.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return HandWeapons
