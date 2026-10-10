--!strict
-- The sword that flies, built only on this client: for the main throw, the training throw and
-- the throws of other players.
--
-- The model is cloned from a template that lives in the place itself
-- (ReplicatedStorage.Assets, see Config/ThrowVisuals). The template is not in the repo: its meshes
-- are uploaded Roblox assets. If it is missing, a plain grey sword is built instead, so the game
-- still works.
--
-- Convention for every sword: the pivot of the model is the tip of the blade, and with no rotation
-- the tip points along the lane (negative Z) with the flat side of the blade facing up.
--
-- The parts are welded to one anchored root part. Moving the sword sets the position of that one
-- part; the others follow as a rigid body. That is cheaper than moving every part by itself.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)

local SwordView = {}

-- One finished sword per scale, kept outside the world and cloned for every throw.
local prototypes: { [number]: Model } = {}
local warnedAboutTemplate = false

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function findTemplate(): Model?
	local folder = ReplicatedStorage:FindFirstChild(ThrowVisuals.swordTemplateFolder)
	local template = folder and folder:FindFirstChild(ThrowVisuals.swordTemplateName)
	if template and template:IsA("Model") and template.PrimaryPart then
		return template
	end
	return nil
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

local function getPrototype(scale: number): Model
	local prototype = prototypes[scale]
	if prototype then
		return prototype
	end

	local template = findTemplate()
	if template then
		prototype = template:Clone()
	else
		if not warnedAboutTemplate then
			warnedAboutTemplate = true
			warn(
				`[SwordView] sword template {ThrowVisuals.swordTemplateFolder}.{ThrowVisuals.swordTemplateName} `
					.. "not found in ReplicatedStorage, using the plain grey sword"
			)
		end
		prototype = buildGreySword()
	end
	makeRigid(prototype, scale)
	prototypes[scale] = prototype
	return prototype
end

-- scale 1 = the normal throw sword; training uses a smaller one.
function SwordView.create(name: string, scale: number): Model
	local sword = getPrototype(scale):Clone()
	sword.Name = name
	sword.Parent = Workspace
	return sword
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
