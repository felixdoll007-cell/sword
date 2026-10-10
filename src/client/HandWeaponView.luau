--!strict
-- The weapon in a character's hand is made by the server (server/HandWeapons). This script only
-- hides it on this client while that weapon is flying, and tells where it is.
-- Hiding changes the weapon's transparency only here; other clients decide for themselves.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)

local HandWeaponView = {}

-- Name given by the server (server/HandWeapons).
local MODEL_NAME = "HandWeapon"

-- Counts the hides per weapon model, so overlapping throws do not show it too early.
local hiddenCount: { [Instance]: number } = {}

local function setHidden(weapon: Instance, hidden: boolean)
	for _, part in weapon:GetDescendants() do
		if part:IsA("BasePart") then
			part.Transparency = if hidden then 1 else 0
		end
	end
end

-- Where a thrown weapon starts: at the tip of the weapon in the character's hand, pointing the
-- way that weapon points. nil if there is no weapon in the hand.
-- All lanes run along -Z. If the weapon in the hand points far away from that (for example
-- straight up, with the simple arm swing instead of a real animation), only its place is used
-- and the thrown weapon points along the lane, so it does not tumble.
function HandWeaponView.launchPose(character: Model): CFrame?
	local weapon = character:FindFirstChild(MODEL_NAME)
	if not weapon or not weapon:IsA("Model") or not weapon.PrimaryPart then
		return nil
	end
	local tip = weapon:GetPivot()
	local alongLane = Vector3.new(0, 0, -1)
	local angle = math.deg(tip.LookVector:Angle(alongLane))
	if angle > ThrowVisuals.launchMaxAngleDegrees then
		return CFrame.new(tip.Position)
	end
	return tip
end

-- Hides the weapon in the character's hand for this many seconds: it is flying.
function HandWeaponView.hideFor(character: Model, seconds: number)
	local weapon = character:FindFirstChild(MODEL_NAME)
	if not weapon then
		return
	end
	hiddenCount[weapon] = (hiddenCount[weapon] or 0) + 1
	setHidden(weapon, true)
	task.delay(seconds, function()
		local count = (hiddenCount[weapon] or 1) - 1
		hiddenCount[weapon] = if count > 0 then count else nil
		if count <= 0 and weapon.Parent then
			setHidden(weapon, false)
		end
	end)
end

return HandWeaponView
