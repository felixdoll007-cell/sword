--!strict
-- Builds the 3D model of a weapon. Used by the client (flying weapon, shop display) and by the
-- server (weapon in the character's hand).
--
-- Every weapon in Config/Weapons can name a template: a model in ReplicatedStorage.Assets that
-- lives in the place itself. The templates are not in the repo, their meshes are uploaded Roblox
-- assets. A weapon without a template, or whose template is missing, becomes a plain grey sword,
-- so the game always works. A new model only needs the config entry and the template.
--
-- Convention for every weapon: the pivot of the model is the tip, and with no rotation the tip
-- points along negative Z with the flat side facing up. The grip lies behind the tip; how far is
-- stored on the model as the attribute "GripFromTip" (see assets/weapon-templates.NOTES.md).
--
-- The parts are welded to one root part and move as one rigid body.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ThrowVisuals = require(script.Parent.Config.ThrowVisuals)
local WeaponConfig = require(script.Parent.Config.Weapons)
local Weapons = require(script.Parent.Rules.Weapons)

local GRIP_ATTRIBUTE = "GripFromTip"

local WeaponModel = {}

-- One finished model per weapon, scale and kind, kept outside the world and cloned when needed.
local prototypes: { [string]: Model } = {}
local warnedAbout: { [string]: boolean } = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function findTemplate(templateName: string): Model?
	local folder = ReplicatedStorage:FindFirstChild(WeaponConfig.templateFolder)
	local template = folder and folder:FindFirstChild(templateName)
	if template and template:IsA("Model") and template.PrimaryPart then
		return template
	end
	return nil
end

-- The weapon to build for an id. Unknown or missing ids become the start weapon.
local function resolve(weaponId: unknown): Weapons.Weapon
	return Weapons.get(WeaponConfig, weaponId) or Weapons.get(WeaponConfig, WeaponConfig.startWeapon) :: Weapons.Weapon
end

-- The plain grey sword from Version 1, with the same convention (pivot at the tip).
local function buildGreySword(): Model
	local v = ThrowVisuals
	local model = Instance.new("Model")

	local function addPart(name: string, size: Vector3, offsetBehindTip: number, rgb: { number }): Part
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.Color = color(rgb)
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.CFrame = CFrame.new(0, 0, offsetBehindTip)
		part.Parent = model
		return part
	end

	local blade =
		addPart("Blade", Vector3.new(v.bladeWidth, v.bladeThickness, v.bladeLength), v.bladeLength / 2, v.bladeColor)
	addPart(
		"Guard",
		Vector3.new(v.guardWidth, v.guardThickness, v.guardThickness),
		v.bladeLength + v.guardThickness / 2,
		v.handleColor
	)
	addPart(
		"Handle",
		Vector3.new(v.handleThickness, v.handleThickness, v.handleLength),
		v.bladeLength + v.guardThickness + v.handleLength / 2,
		v.handleColor
	)

	model.PrimaryPart = blade
	-- The tip is the front end of the blade, the grip is the middle of the handle.
	blade.PivotOffset = CFrame.new(0, 0, -v.bladeLength / 2)
	model:SetAttribute(GRIP_ATTRIBUTE, v.bladeLength + v.guardThickness + v.handleLength / 2)
	return model
end

-- Scales the model and joins its parts into one rigid body around the root part.
-- anchoredRoot: true for models moved by code (flying, shop), false for the weapon in a hand.
local function makeRigid(model: Model, scale: number, anchoredRoot: boolean)
	local _, unscaledSize = model:GetBoundingBox()
	local grip = model:GetAttribute(GRIP_ATTRIBUTE)
	if typeof(grip) ~= "number" then
		-- Template without the attribute: assume the grip sits near the far end.
		grip = unscaledSize.Z * ThrowVisuals.gripFallbackShare
	end
	model:ScaleTo(scale)
	model:SetAttribute(GRIP_ATTRIBUTE, (grip :: number) * scale)

	local root = model.PrimaryPart :: BasePart
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.Anchored = anchoredRoot and descendant == root
			if descendant ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = root
			end
		end
	end
end

local function getPrototype(weapon: Weapons.Weapon, scale: number, anchoredRoot: boolean): Model
	local key = `{weapon.id}@{scale}@{anchoredRoot}`
	local prototype = prototypes[key]
	if prototype then
		return prototype
	end

	local template = if weapon.template then findTemplate(weapon.template) else nil
	if template then
		prototype = template:Clone()
	else
		-- No template named: the grey sword is the planned placeholder. Named but missing: say so once.
		if weapon.template and not warnedAbout[weapon.id] then
			warnedAbout[weapon.id] = true
			warn(
				`[WeaponModel] template {WeaponConfig.templateFolder}.{weapon.template} for {weapon.id} `
					.. "not found in ReplicatedStorage, using the plain grey sword"
			)
		end
		prototype = buildGreySword()
	end
	makeRigid(prototype, scale, anchoredRoot)
	prototypes[key] = prototype
	return prototype
end

-- A new model of the weapon, not yet placed in the world.
-- weaponId: see Config/Weapons. scale 1 = normal size.
-- anchoredRoot: true if the model is moved by code, false if it is welded to something that moves.
function WeaponModel.create(weaponId: unknown, scale: number, anchoredRoot: boolean): Model
	return getPrototype(resolve(weaponId), scale, anchoredRoot):Clone()
end

-- Length of a weapon from its tip to its other end, in studs.
function WeaponModel.length(weaponId: unknown, scale: number): number
	local _, size = getPrototype(resolve(weaponId), scale, true):GetBoundingBox()
	return size.Z
end

-- Where the grip of a model is, relative to its pivot (the tip): straight behind the tip.
function WeaponModel.gripFromPivot(model: Model): CFrame
	local distance = model:GetAttribute(GRIP_ATTRIBUTE)
	return CFrame.new(0, 0, if typeof(distance) == "number" then distance else 0)
end

return WeaponModel
