--!strict
-- The weapon that flies, built only on this client: for the main throw, the training throw, the
-- throws of other players and the display in the shop.
--
-- Every weapon in Config/Weapons can name a template: a model in ReplicatedStorage.Assets that
-- lives in the place itself. The templates are not in the repo, their meshes are uploaded Roblox
-- assets. A weapon without a template, or whose template is missing, is shown as a plain grey
-- sword, so the game always works. A new model only needs the config entry and the template.
--
-- Convention for every weapon: the pivot of the model is the tip of the blade, and with no rotation
-- the tip points along the lane (negative Z) with the flat side of the blade facing up.
--
-- The parts are welded to one anchored root part. Moving the sword sets the position of that one
-- part; the others follow as a rigid body. That is cheaper than moving every part by itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.Weapons)
local Weapons = require(ReplicatedStorage.Shared.Rules.Weapons)

local SwordView = {}

-- One finished model per weapon and scale, kept outside the world and cloned for every throw.
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

-- The weapon to draw for an id. Unknown or missing ids are drawn as the start weapon.
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
	-- The tip is the front end of the blade.
	blade.PivotOffset = CFrame.new(0, 0, -v.bladeLength / 2)
	return model
end

-- Scales the sword and joins its parts into one rigid body around an anchored root part.
local function makeRigid(model: Model, scale: number)
	model:ScaleTo(scale)
	local root = model.PrimaryPart :: BasePart
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.Anchored = descendant == root
			if descendant ~= root then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = root
				weld.Part1 = descendant
				weld.Parent = root
			end
		end
	end
end

local function getPrototype(weapon: Weapons.Weapon, scale: number): Model
	local key = `{weapon.id}@{scale}`
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
				`[SwordView] template {WeaponConfig.templateFolder}.{weapon.template} for {weapon.id} `
					.. "not found in ReplicatedStorage, using the plain grey sword"
			)
		end
		prototype = buildGreySword()
	end
	makeRigid(prototype, scale)
	prototypes[key] = prototype
	return prototype
end

-- weaponId: which weapon to draw (see Config/Weapons). scale 1 = normal size; training uses a smaller one.
function SwordView.create(name: string, scale: number, weaponId: unknown): Model
	local sword = getPrototype(resolve(weaponId), scale):Clone()
	sword.Name = name
	sword.Parent = Workspace
	return sword
end

-- Length of a weapon from its tip to its other end, in studs.
function SwordView.length(scale: number, weaponId: unknown): number
	local _, size = getPrototype(resolve(weaponId), scale):GetBoundingBox()
	return size.Z
end

-- Puts the tip of the sword at this position and rotation. Only the root part is moved;
-- the welded parts follow.
function SwordView.moveTo(sword: Model, tip: CFrame)
	local root = sword.PrimaryPart
	if root then
		root.CFrame = tip * root.PivotOffset:Inverse()
	end
end

return SwordView
