--!strict
-- The decoration on the walkways of the lane: lanterns, cranes, pinwheels, trees, bamboo,
-- drums, water features. Scenery on
-- the outer step. Built on this client from the templates in ReplicatedStorage.Assets, each
-- piece at its listed place, turned and sized a little differently, and moved a little:
--   * a lantern has a weak, warm light that flickers slightly
--   * a crane floats slowly up and down (its base and rod stand still)
--   * a pinwheel's wheel turns slowly (its stick stands still)
--   * the leaves of a bamboo group rock very slightly
--   * the cane of a water feature tips forward every few seconds and comes back
--   * the cloth of a training dummy waves slightly, the plaques of a plaque rack swing
--   * a tree, a drum, a weapon rack and a stack of barrels stand still
-- Which model stands where is worked out in Rules/Decor; everything adjustable is in Config/Ui
-- (world.decor and the decor entry of each zone).
-- Decoration has no collision and cannot be hit by anything, so it never gets in the way of a
-- throw or of the camera. Only looks; the server knows nothing about it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local WallConfig = require(Shared.Config.Walls)
local Decor = require(Shared.Rules.Decor)

local FOLDER_NAME = "MyDecor"
-- How long to wait for the templates when the game starts.
local TEMPLATES_WAIT_SECONDS = 10

-- A group of parts that moves as one, each frame, relative to where it was built.
type Mover = {
	kind: "float" | "spin" | "sway" | "tip",
	-- Where this group's parts start in the shared lists below.
	first: number,
	last: number,
	-- phase: the piece's own rhythm. axis: for spin the axis the wheel turns around, for sway
	-- and tip the middle of the part, turned like its model.
	phase: number,
	axis: CFrame,
	settings: any,
}

type Flicker = {
	light: PointLight,
	brightness: number,
	strength: number,
	speed: number,
	seed: number,
}

local DecorView = {}

-- All moving parts and where they were built, in one list each, so they can be moved in one go.
local movingParts: { BasePart } = {}
local builtFrames: { CFrame } = {}
local currentFrames: { CFrame } = {}
local movers: { Mover } = {}
local flickers: { Flicker } = {}
local warnedAbout: { [string]: boolean } = {}

local function color(rgb: { number }): Color3
	return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
end

local function findPart(model: Model, name: string): BasePart?
	local part = model:FindFirstChild(name, true)
	return if part and part:IsA("BasePart") then part else nil
end

-- Adds parts to the shared lists and returns their places in them.
local function track(parts: { BasePart }): (number, number)
	local first = #movingParts + 1
	for _, part in parts do
		table.insert(movingParts, part)
		table.insert(builtFrames, part.CFrame)
		table.insert(currentFrames, part.CFrame)
	end
	return first, #movingParts
end

-- The lantern's light.
local function addLight(model: Model, settings: any, seed: number)
	local part = findPart(model, settings.part)
	if not part then
		return
	end
	local light = Instance.new("PointLight")
	light.Name = "LanternLight"
	light.Color = color(settings.color)
	light.Brightness = settings.brightness
	light.Range = settings.range
	light.Shadows = false
	light.Parent = part
	table.insert(flickers, {
		light = light,
		brightness = settings.brightness,
		strength = settings.flickerStrength,
		speed = settings.flickerSpeed,
		seed = seed,
	})
end

-- Everything of the model floats, except the parts named as standing still.
local function addFloat(model: Model, settings: any, seed: number)
	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and not table.find(settings.stillParts, part.Name) then
			table.insert(parts, part)
		end
	end
	if #parts == 0 then
		return
	end
	local first, last = track(parts)
	-- Every piece starts at another point of the movement, so they do not move in step.
	table.insert(
		movers,
		{ kind = "float", first = first, last = last, phase = seed, axis = CFrame.identity, settings = settings }
	)
end

-- The named parts turn around the axis part, around that part's own front-to-back line.
local function addSpin(model: Model, settings: any, seed: number)
	local axisPart = findPart(model, settings.axisPart)
	if not axisPart then
		return
	end
	local parts = {}
	for _, name in settings.parts do
		local part = findPart(model, name)
		if part then
			table.insert(parts, part)
		end
	end
	if #parts == 0 then
		return
	end
	local first, last = track(parts)
	table.insert(
		movers,
		{ kind = "spin", first = first, last = last, phase = seed, axis = axisPart.CFrame, settings = settings }
	)
end

-- The named part turns a little around its own middle (or, if its settings say aroundTop,
-- around its upper edge), around the line that runs from the model's left to its right: to
-- both sides (sway) or forward and back (tip).
local function addTilt(model: Model, kind: "sway" | "tip", settings: any, seed: number)
	local part = findPart(model, settings.part)
	if not part then
		return
	end
	local first, last = track({ part })
	local around = part.Position
	if settings.aroundTop then
		around += Vector3.new(0, part.ExtentsSize.Y / 2, 0)
	end
	table.insert(movers, {
		kind = kind,
		first = first,
		last = last,
		phase = seed,
		axis = CFrame.new(around) * model:GetPivot().Rotation,
		settings = settings,
	})
end

local function buildPiece(placement: Decor.Placement, templates: Instance, folder: Folder, seed: number)
	local settings = (Ui.world.decor.models :: { [string]: any })[placement.model]
	local template = templates:FindFirstChild(settings.template)
	if not template or not template:IsA("Model") then
		if not warnedAbout[placement.model] then
			warnedAbout[placement.model] = true
			warn(`[DecorView] template {settings.template} not found in ReplicatedStorage, decoration left out`)
		end
		return
	end

	local model = template:Clone()
	-- The whole model evenly bigger or smaller; its shape is not changed.
	if placement.scale ~= 1 then
		model:ScaleTo(model:GetScale() * placement.scale)
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	model:PivotTo(
		CFrame.new(placement.x, placement.y, placement.z) * CFrame.Angles(0, math.rad(placement.yawDegrees), 0)
	)
	model.Parent = folder

	-- The movements are recorded after the piece stands at its place.
	if settings.light then
		addLight(model, settings.light, seed)
	end
	if settings.float then
		addFloat(model, settings.float, seed)
	end
	if settings.spin then
		addSpin(model, settings.spin, seed)
	end
	if settings.sway then
		addTilt(model, "sway", settings.sway, seed)
	end
	if settings.tip then
		addTilt(model, "tip", settings.tip, seed)
	end
end

local function update()
	local time = os.clock()
	for _, mover in movers do
		local settings = mover.settings
		if mover.kind == "float" then
			local wave = math.sin((time / settings.seconds + mover.phase) * 2 * math.pi)
			local offset = Vector3.new(0, wave * settings.heightStuds, 0)
			for index = mover.first, mover.last do
				currentFrames[index] = builtFrames[index] + offset
			end
		elseif mover.kind == "sway" or mover.kind == "tip" then
			local degrees: number
			if mover.kind == "sway" then
				degrees = settings.degrees * math.sin((time / settings.seconds + mover.phase) * 2 * math.pi)
			else
				-- The model's front is negative Z: a positive turn lifts its front end.
				degrees = Decor.tipDegrees(settings, time + mover.phase * settings.everySeconds)
			end
			local turned = mover.axis * CFrame.Angles(math.rad(degrees), 0, 0) * mover.axis:Inverse()
			for index = mover.first, mover.last do
				currentFrames[index] = turned * builtFrames[index]
			end
		else
			local angle = (time / settings.secondsPerTurn + mover.phase) * 2 * math.pi
			local turned = mover.axis * CFrame.Angles(0, 0, angle) * mover.axis:Inverse()
			for index = mover.first, mover.last do
				currentFrames[index] = turned * builtFrames[index]
			end
		end
	end
	if #movingParts > 0 then
		Workspace:BulkMoveTo(movingParts, currentFrames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for _, flicker in flickers do
		-- Smooth noise between -1 and 1, different for every lantern.
		local noise = math.clamp(math.noise(time * flicker.speed, flicker.seed * 10) * 2, -1, 1)
		flicker.light.Brightness = flicker.brightness * (1 + flicker.strength * noise)
	end
end

function DecorView.start()
	local world = Ui.world
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	local templates = ReplicatedStorage:WaitForChild(world.decor.templateFolder, TEMPLATES_WAIT_SECONDS)
	if not templates then
		warn("[DecorView] no templates in ReplicatedStorage, the world stays without decoration")
		return
	end

	local count = 0
	for zone, material in WallConfig.materials do
		local zoneStyle = (world.lane.zones :: { [string]: any })[material]
		local decor = zoneStyle and zoneStyle.decor
		local placements =
			Decor.placements(LaneConfig, WallConfig, world.lane, decor, world.decor.models, world.decor, zone)
		for _, placement in placements do
			count += 1
			-- A different number for every piece: its own rhythm.
			buildPiece(placement, templates, folder, (count * world.decor.rhythmStep) % 1)
		end
	end
	folder.Parent = Workspace

	if #movers > 0 or #flickers > 0 then
		RunService.Heartbeat:Connect(update)
	end
end

return DecorView
