-- Prepares imported models as templates (paper zone, training lane 1x, pets).
-- Run in Roblox Studio (Edit mode) after importing models; it was run through the Studio
-- connection on 2026-10-11 (lantern, crane, pinwheel, later the cherry tree, the straw target,
-- the hay bale, the five pets and the egg) and on 2026-10-12 (the egg without a nest). Models
-- that already are templates are left alone. Kept here as a record of what was done to the place.
--
-- What it does, and nothing else:
--   1. Finds the imported models in the Workspace by the name of the model inside them.
--   2. Colors every mesh by its name. Shape and size are not touched.
--   3. Makes the parts fixed and without collision (decoration must not block anything).
--   4. Renames the model and moves it into ReplicatedStorage.Assets as a template.
-- The templates live only in the place, not in the repo: save the place afterwards.

local ChangeHistoryService = game:GetService("ChangeHistoryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GOLD = Color3.fromRGB(255, 200, 40)
local DARK_RED = Color3.fromRGB(120, 22, 30)

-- inside: name of the model inside the imported one. template: its name in Assets.
-- colors: color per mesh name. neon: meshes that glow.
local MODELS = {
	{
		inside = "lantern_post",
		template = "paper_lantern",
		colors = {
			Post = Color3.fromRGB(74, 48, 32),
			Lantern = Color3.fromRGB(214, 40, 40),
			Caps = DARK_RED,
			Tassel = GOLD,
			Glow = Color3.fromRGB(255, 214, 120),
		},
		neon = { Glow = true },
	},
	{
		inside = "origami_crane",
		template = "origami_crane",
		colors = {
			Body = Color3.fromRGB(22, 186, 190),
			WingTips = Color3.fromRGB(176, 240, 214),
			Beak = GOLD,
			Base = DARK_RED,
			Rod = GOLD,
		},
		neon = {},
	},
	{
		inside = "pinwheel",
		template = "paper_pinwheel",
		colors = {
			Stick = Color3.fromRGB(214, 170, 112),
			BladesPink = Color3.fromRGB(255, 84, 150),
			BladesWhite = Color3.fromRGB(250, 250, 250),
			Hub = GOLD,
		},
		neon = {},
	},
	-- Imported later, for the outer step of the walkways.
	{
		inside = "cherry_tree",
		template = "cherry_tree",
		colors = {
			Trunk = Color3.fromRGB(74, 48, 32),
			BlossomPink = Color3.fromRGB(255, 120, 165),
			BlossomLight = Color3.fromRGB(255, 196, 214),
			Mound = Color3.fromRGB(40, 104, 52),
		},
		neon = {},
	},
	-- Training lane 1x (straw).
	{
		inside = "straw_target",
		template = "straw_target",
		colors = {
			Straw = Color3.fromRGB(240, 196, 64),
			RingsRed = Color3.fromRGB(214, 40, 40),
			RingsWhite = Color3.fromRGB(250, 250, 250),
			Stand = Color3.fromRGB(74, 48, 32),
			Rope = Color3.fromRGB(232, 214, 176),
		},
		neon = {},
	},
	{
		inside = "hay_bale",
		template = "hay_bale",
		colors = {
			Hay = Color3.fromRGB(240, 196, 64),
			HayDark = Color3.fromRGB(204, 156, 40),
			Rope = Color3.fromRGB(232, 214, 176),
		},
		neon = {},
	},
	-- Pets and the egg. All pets: Eyes black, EyeShine white. The mesh "Nose" is the nose of the
	-- bunny and the panda, the dark accent of the fox, horns and spikes of the dragon and the
	-- beak of the phoenix.
	{
		inside = "bunny_pet",
		template = "pet_bunny",
		colors = {
			Body = Color3.fromRGB(250, 250, 250),
			Accent = Color3.fromRGB(255, 150, 190),
			Nose = Color3.fromRGB(255, 150, 190),
			Eyes = Color3.fromRGB(20, 20, 24),
			EyeShine = Color3.fromRGB(250, 250, 250),
		},
		neon = {},
	},
	{
		inside = "fox_pet",
		template = "pet_fox",
		colors = {
			Body = Color3.fromRGB(255, 122, 31),
			Accent = Color3.fromRGB(250, 250, 250),
			Nose = Color3.fromRGB(74, 48, 32),
			Eyes = Color3.fromRGB(20, 20, 24),
			EyeShine = Color3.fromRGB(250, 250, 250),
		},
		neon = {},
	},
	{
		inside = "panda_pet",
		template = "pet_panda",
		colors = {
			Body = Color3.fromRGB(250, 250, 250),
			Accent = Color3.fromRGB(20, 20, 24),
			Nose = Color3.fromRGB(20, 20, 24),
			Eyes = Color3.fromRGB(20, 20, 24),
			EyeShine = Color3.fromRGB(250, 250, 250),
		},
		neon = {},
	},
	{
		inside = "dragon_pet",
		template = "pet_dragon",
		colors = {
			Body = Color3.fromRGB(150, 70, 230),
			Accent = Color3.fromRGB(120, 235, 225),
			Nose = GOLD,
			Eyes = Color3.fromRGB(20, 20, 24),
			EyeShine = Color3.fromRGB(250, 250, 250),
		},
		neon = {},
	},
	{
		inside = "phoenix_pet",
		template = "pet_phoenix",
		colors = {
			Body = Color3.fromRGB(255, 84, 30),
			Glow = Color3.fromRGB(255, 220, 70),
			Nose = GOLD,
			Eyes = Color3.fromRGB(20, 20, 24),
			EyeShine = Color3.fromRGB(250, 250, 250),
		},
		neon = { Glow = true },
	},
	{
		inside = "pet_egg",
		template = "pet_egg",
		colors = {
			Shell = Color3.fromRGB(250, 244, 226),
			Spots = Color3.fromRGB(40, 200, 200),
			Nest = Color3.fromRGB(240, 196, 64),
		},
		neon = {},
	},
	-- The egg without a nest (imported on 2026-10-12). It replaces pet_egg at the egg stand and
	-- in the hatching animation; pet_egg stays in the place but is not used any more.
	{
		inside = "crystal_egg",
		template = "crystal_egg",
		colors = {
			Shell = Color3.fromRGB(18, 184, 196),
			Band = GOLD,
			Stars = Color3.fromRGB(184, 246, 214),
			Glow = Color3.fromRGB(120, 240, 232),
		},
		neon = { Glow = true },
	},
}

local assets = ReplicatedStorage:FindFirstChild("Assets")
assert(assets, "ReplicatedStorage.Assets not found")

local report = {}
for _, entry in MODELS do
	local model: Model? = nil
	for _, child in Workspace:GetChildren() do
		if child:IsA("Model") and child:FindFirstChild(entry.inside) then
			model = child
			break
		end
	end
	if not model then
		table.insert(report, `{entry.inside}: NOT FOUND in the Workspace`)
		continue
	end
	if assets:FindFirstChild(entry.template) then
		table.insert(report, `{entry.inside}: a template named {entry.template} already exists, left alone`)
		continue
	end

	local colored, unknown = {}, {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local color = entry.colors[part.Name]
			if color then
				part.Color = color
				table.insert(colored, part.Name)
			else
				table.insert(unknown, part.Name)
			end
			if entry.neon[part.Name] then
				part.Material = Enum.Material.Neon
			end
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	model.Name = entry.template
	model.Parent = assets
	table.insert(
		report,
		`{entry.inside} -> Assets.{entry.template}: colored {table.concat(colored, ", ")}`
			.. (if #unknown > 0 then `; UNKNOWN meshes left grey: {table.concat(unknown, ", ")}` else "")
	)
end

ChangeHistoryService:SetWaypoint("Prepare paper zone decoration templates")
return report
