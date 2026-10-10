--!strict
-- The weapon in a character's hand is made by the server (server/HandWeapons). This script only
-- hides it on this client while that weapon is flying, and tells where it is.
-- Hiding changes the weapon's transparency only here; other clients decide for themselves.

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

-- Where the tip of the weapon in the character's hand is right now. nil if there is none.
function HandWeaponView.tip(character: Model): CFrame?
	local weapon = character:FindFirstChild(MODEL_NAME)
	if weapon and weapon:IsA("Model") and weapon.PrimaryPart then
		return weapon:GetPivot()
	end
	return nil
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
