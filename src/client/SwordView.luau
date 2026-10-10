--!strict
-- The weapon that this client draws by itself: for the main throw, the training throw, the throws
-- of other players and the display in the shop. (The weapon in a character's hand is made by the
-- server, see server/HandWeapons.)
--
-- The models come from shared/WeaponModel. Convention: the pivot is the tip, and with no rotation
-- the tip points along the lane (negative Z) with the flat side facing up.
-- Moving a weapon sets the position of its one anchored root part; the welded parts follow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local WeaponModel = require(ReplicatedStorage.Shared.WeaponModel)

local SwordView = {}

-- weaponId: which weapon to draw (see Config/Weapons). scale 1 = normal size.
function SwordView.create(name: string, scale: number, weaponId: unknown): Model
	local sword = WeaponModel.create(weaponId, scale, true)
	sword.Name = name
	sword.Parent = Workspace
	return sword
end

-- Length of a weapon from its tip to its other end, in studs.
function SwordView.length(scale: number, weaponId: unknown): number
	return WeaponModel.length(weaponId, scale)
end

-- Puts the tip of the weapon at this position and rotation.
function SwordView.moveTo(sword: Model, tip: CFrame)
	local root = sword.PrimaryPart
	if root then
		root.CFrame = tip * root.PivotOffset:Inverse()
	end
end

return SwordView
