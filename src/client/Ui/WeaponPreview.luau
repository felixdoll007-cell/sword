--!strict
-- Building block: a weapon shown as its real 3D model inside the interface (a ViewportFrame),
-- seen from above at a slight angle with the tip pointing to the top right. So weapons need no
-- picture of their own and look like in the game.
-- Roblox draws such a model more simply than in the world: no glow, no shadows.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Ui = require(Shared.Config.Ui)
local WeaponModel = require(Shared.WeaponModel)

local Draw = require(script.Parent.Draw)

local WeaponPreview = {}

-- On screen "up" is this direction of the weapon's own space: between its tip (negative Z) and
-- its left side, so the tip ends up at the top right.
local SCREEN_UP = Vector3.new(-1, 0, -1).Unit

function WeaponPreview.new(weaponId: string, parent: Instance?): ViewportFrame
	local settings = Ui.weaponPreview

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "WeaponPreview"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Draw.color(settings.ambient)
	viewport.LightColor = Draw.color(settings.lightColor)
	viewport.LightDirection =
		Vector3.new(settings.lightDirection[1], settings.lightDirection[2], settings.lightDirection[3])

	local model = WeaponModel.create(weaponId, 1, true)
	model:PivotTo(CFrame.new())
	model.Parent = viewport

	-- Far enough away that the whole weapon fits, whatever its shape.
	local boxFrame, boxSize = model:GetBoundingBox()
	local radius = boxSize.Magnitude / 2
	local halfAngle = math.rad(settings.fieldOfView) / 2
	local distance = radius / math.sin(halfAngle) / settings.fill
	local center = boxFrame.Position
	local from = center + Vector3.new(settings.tiltX, 1, settings.tiltZ).Unit * distance

	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.fieldOfView
	camera.CFrame = CFrame.lookAt(from, center, SCREEN_UP)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	viewport.Parent = parent
	return viewport
end

return WeaponPreview
