--!strict
-- Stops the character from walking and jumping. Several parts of the game can freeze at the
-- same time (meter, throw); the character only moves again when all of them released it.

local Players = game:GetService("Players")

local CharacterFreeze = {}

type Saved = {
	humanoid: Humanoid,
	walkSpeed: number,
	jumpPower: number,
	jumpHeight: number,
}

local reasons: { [string]: boolean } = {}
local saved: Saved? = nil

local function currentHumanoid(): Humanoid?
	local character = Players.LocalPlayer.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

function CharacterFreeze.freeze(reason: string)
	reasons[reason] = true
	if saved then
		return
	end
	local humanoid = currentHumanoid()
	if not humanoid then
		return
	end
	saved = {
		humanoid = humanoid,
		walkSpeed = humanoid.WalkSpeed,
		jumpPower = humanoid.JumpPower,
		jumpHeight = humanoid.JumpHeight,
	}
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
end

function CharacterFreeze.release(reason: string)
	reasons[reason] = nil
	if next(reasons) ~= nil then
		return
	end
	local values = saved
	saved = nil
	if values then
		values.humanoid.WalkSpeed = values.walkSpeed
		values.humanoid.JumpPower = values.jumpPower
		values.humanoid.JumpHeight = values.jumpHeight
	end
end

-- A new character starts unfrozen. Forget everything about the old one.
Players.LocalPlayer.CharacterAdded:Connect(function()
	reasons = {}
	saved = nil
end)

return CharacterFreeze
