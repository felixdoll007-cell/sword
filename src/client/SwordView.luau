--!strict
-- The sword model, built only on this client. Its pivot is the tip of the blade,
-- and with no rotation the tip points along the lane (negative Z).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ThrowVisuals = require(ReplicatedStorage.Shared.Config.ThrowVisuals)

local SwordView = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function addPart(model: Model, name: string, size: Vector3, offsetBehindTip: number, rgb: { number })
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = true
	part.Size = size
	part.Color = color(rgb)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CFrame = CFrame.new(0, 0, offsetBehindTip)
	part.Parent = model
end

-- scale 1 = the normal throw sword; training uses a smaller one.
function SwordView.create(name: string, scale: number): Model
	local v = ThrowVisuals
	local model = Instance.new("Model")
	model.Name = name

	addPart(model, "Blade", Vector3.new(v.bladeWidth, v.bladeThickness, v.bladeLength), v.bladeLength / 2, v.bladeColor)
	addPart(
		model,
		"Guard",
		Vector3.new(v.guardWidth, v.guardThickness, v.guardThickness),
		v.bladeLength + v.guardThickness / 2,
		v.handleColor
	)
	addPart(
		model,
		"Handle",
		Vector3.new(v.handleThickness, v.handleThickness, v.handleLength),
		v.bladeLength + v.guardThickness + v.handleLength / 2,
		v.handleColor
	)

	model.WorldPivot = CFrame.new()
	model:ScaleTo(scale)
	model.Parent = Workspace
	return model
end

return SwordView
