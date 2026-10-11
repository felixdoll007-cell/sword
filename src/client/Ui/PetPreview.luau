--!strict
-- Building block: a pet (or the egg) shown as its real 3D model inside the interface, seen from
-- the front, a little from the side and from above. Also makes the models themselves, for the
-- pets that follow a player and for the egg on its stand.
-- The models come from templates in ReplicatedStorage.Assets, which live only in the place.
-- If a template is missing, a plain ball is used instead, so nothing breaks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local PetConfig = require(Shared.Config.Pets)
local Ui = require(Shared.Config.Ui)
local Pets = require(Shared.Rules.Pets)

local Draw = require(script.Parent.Draw)

-- Size of the ball that stands in for a missing template.
local STAND_IN_STUDS = 2

local PetPreview = {}

local warnedAbout: { [string]: boolean } = {}

local function standIn(): Model
	local model = Instance.new("Model")
	local ball = Instance.new("Part")
	ball.Name = "Body"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * STAND_IN_STUDS
	ball.Color = Draw.color(Ui.colors.disabled)
	ball.TopSurface = Enum.SurfaceType.Smooth
	ball.BottomSurface = Enum.SurfaceType.Smooth
	ball.Parent = model
	model.PrimaryPart = ball
	return model
end

-- A model built from this template: fixed, without collision, not yet placed anywhere.
function PetPreview.model(templateName: string): Model
	local templates = ReplicatedStorage:FindFirstChild(Ui.world.decor.templateFolder)
	local template = templates and templates:FindFirstChild(templateName)
	local model: Model
	if template and template:IsA("Model") then
		model = template:Clone()
	else
		if not warnedAbout[templateName] then
			warnedAbout[templateName] = true
			warn(`[PetPreview] template {templateName} not found in ReplicatedStorage, using a plain ball`)
		end
		model = standIn()
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	return model
end

-- The model of a pet. Unknown pets become the plain ball.
function PetPreview.petModel(petId: string): Model
	local pet = Pets.get(PetConfig, petId)
	return PetPreview.model(if pet then pet.template else petId)
end

function PetPreview.eggModel(): Model
	return PetPreview.model(PetConfig.egg.template)
end

-- Shows this model in a picture that fills the room it is given.
function PetPreview.show(model: Model, parent: Instance?): ViewportFrame
	local settings = Ui.petPreview

	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "PetPreview"
	viewport.BackgroundTransparency = 1
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.Ambient = Draw.color(settings.ambient)
	viewport.LightColor = Draw.color(settings.lightColor)
	viewport.LightDirection =
		Vector3.new(settings.lightDirection[1], settings.lightDirection[2], settings.lightDirection[3])

	model:PivotTo(CFrame.new())
	model.Parent = viewport

	-- Far enough away that the whole model fits, whatever its shape.
	local boxFrame, boxSize = model:GetBoundingBox()
	local radius = boxSize.Magnitude / 2
	local halfAngle = math.rad(settings.fieldOfView) / 2
	local distance = radius / math.sin(halfAngle) / settings.fill
	local center = boxFrame.Position
	local from = center + Vector3.new(settings.from.x, settings.from.y, settings.from.z).Unit * distance

	local camera = Instance.new("Camera")
	camera.FieldOfView = settings.fieldOfView
	camera.CFrame = CFrame.lookAt(from, center)
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	viewport.Parent = parent
	return viewport
end

-- A picture of this pet.
function PetPreview.pet(petId: string, parent: Instance?): ViewportFrame
	return PetPreview.show(PetPreview.petModel(petId), parent)
end

-- A picture of the egg.
function PetPreview.egg(parent: Instance?): ViewportFrame
	return PetPreview.show(PetPreview.eggModel(), parent)
end

return PetPreview
