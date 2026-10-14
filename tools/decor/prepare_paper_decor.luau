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
	-- Pets (second version, imported on 2026-10-12) and the egg. All pets: EyeWhite white, Pupil
	-- very dark brown, EyeShine white and glowing. AccentPink of the panda is a small pink detail on its face.
	{
		inside = "bunny_pet",
		template = "pet_bunny",
		colors = {
			Body = Color3.fromRGB(250, 250, 250),
			Accent = Color3.fromRGB(255, 150, 190),
			EyeWhite = Color3.fromRGB(250, 250, 250),
			Pupil = Color3.fromRGB(46, 28, 18),
			EyeShine = Color3.fromRGB(255, 255, 255),
		},
		neon = { EyeShine = true },
	},
	{
		inside = "fox_pet",
		template = "pet_fox",
		colors = {
			Body = Color3.fromRGB(255, 122, 31),
			AccentWhite = Color3.fromRGB(250, 250, 250),
			AccentDark = Color3.fromRGB(74, 48, 32),
			EyeWhite = Color3.fromRGB(250, 250, 250),
			Pupil = Color3.fromRGB(46, 28, 18),
			EyeShine = Color3.fromRGB(255, 255, 255),
		},
		neon = { EyeShine = true },
	},
	{
		inside = "panda_pet",
		template = "pet_panda",
		colors = {
			Body = Color3.fromRGB(250, 250, 250),
			Accent = Color3.fromRGB(20, 20, 24),
			AccentPink = Color3.fromRGB(255, 150, 190),
			EyeWhite = Color3.fromRGB(250, 250, 250),
			Pupil = Color3.fromRGB(46, 28, 18),
			EyeShine = Color3.fromRGB(255, 255, 255),
		},
		neon = { EyeShine = true },
	},
	{
		inside = "dragon_pet",
		template = "pet_dragon",
		colors = {
			Body = Color3.fromRGB(150, 70, 230),
			Accent = Color3.fromRGB(120, 235, 225),
			Gold = GOLD,
			EyeWhite = Color3.fromRGB(250, 250, 250),
			Pupil = Color3.fromRGB(46, 28, 18),
			EyeShine = Color3.fromRGB(255, 255, 255),
		},
		neon = { EyeShine = true },
	},
	{
		inside = "phoenix_pet",
		template = "pet_phoenix",
		colors = {
			Body = Color3.fromRGB(255, 84, 30),
			Glow = Color3.fromRGB(255, 220, 70),
			Gold = GOLD,
			EyeWhite = Color3.fromRGB(250, 250, 250),
			Pupil = Color3.fromRGB(46, 28, 18),
			EyeShine = Color3.fromRGB(255, 255, 255),
		},
		neon = { Glow = true, EyeShine = true },
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
	-- The bamboo zone (imported on 2026-10-13). Water of the water feature is also made 30 percent see-through
	-- and slightly mirroring by hand (SmoothPlastic, Reflectance 0.25).
	{
		inside = "bamboo_cluster",
		template = "bamboo_cluster",
		colors = {
			Stalks = Color3.fromRGB(96, 176, 62),
			Nodes = Color3.fromRGB(52, 110, 44),
			Leaves = Color3.fromRGB(150, 214, 84),
			Mound = Color3.fromRGB(84, 58, 38),
		},
		neon = {},
	},
	{
		inside = "stone_lantern",
		template = "stone_lantern",
		colors = {
			Stone = Color3.fromRGB(190, 190, 186),
			StoneDark = Color3.fromRGB(128, 130, 128),
			Moss = Color3.fromRGB(92, 140, 62),
			Glow = Color3.fromRGB(255, 214, 120),
		},
		neon = { Glow = true },
	},
	{
		inside = "taiko_drum",
		template = "taiko_drum",
		colors = {
			Body = Color3.fromRGB(200, 38, 38),
			Skin = Color3.fromRGB(244, 232, 200),
			Symbol = Color3.fromRGB(20, 20, 24),
			Studs = GOLD,
			Stand = Color3.fromRGB(84, 58, 38),
			Sticks = Color3.fromRGB(222, 184, 130),
		},
		neon = {},
	},
	{
		inside = "shishi_odoshi",
		template = "shishi_odoshi",
		colors = {
			Basin = Color3.fromRGB(140, 142, 144),
			Water = Color3.fromRGB(64, 200, 196),
			Posts = Color3.fromRGB(96, 176, 62),
			Rocker = Color3.fromRGB(96, 176, 62),
			Stream = Color3.fromRGB(170, 236, 232),
			Pebbles = Color3.fromRGB(200, 200, 196),
		},
		neon = {},
	},
	-- The wall of the bamboo zone (imported on 2026-10-13). Its pivot is also set to the middle
	-- of its foot by hand.
	{
		inside = "bamboo_wall",
		template = "bamboo_wall",
		colors = {
			Stalks = Color3.fromRGB(96, 176, 62),
			Nodes = Color3.fromRGB(52, 110, 44),
			Rope = Color3.fromRGB(150, 98, 52),
			Beam = Color3.fromRGB(84, 58, 38),
		},
		neon = {},
	},
	-- The wood zone (imported on 2026-10-13). Pivots are also set to the middle of the foot by hand.
	{
		inside = "training_dummy",
		template = "training_dummy",
		colors = {
			Post = Color3.fromRGB(206, 160, 104),
			Arms = Color3.fromRGB(206, 160, 104),
			Frame = Color3.fromRGB(84, 58, 38),
			Cloth = Color3.fromRGB(245, 245, 240),
		},
		neon = {},
	},
	{
		inside = "weapon_rack",
		template = "weapon_rack",
		colors = {
			Rack = Color3.fromRGB(84, 58, 38),
			Weapons = Color3.fromRGB(222, 184, 130),
			Grips = Color3.fromRGB(140, 28, 40),
			Roof = Color3.fromRGB(72, 78, 88),
		},
		neon = {},
	},
	{
		inside = "sake_barrels",
		template = "sake_barrels",
		colors = {
			Straw = Color3.fromRGB(232, 206, 132),
			Ropes = Color3.fromRGB(84, 58, 38),
			Lids = Color3.fromRGB(222, 184, 130),
			LabelRed = Color3.fromRGB(214, 40, 40),
			LabelBlue = Color3.fromRGB(40, 96, 210),
			LabelYellow = Color3.fromRGB(245, 200, 40),
			Symbols = Color3.fromRGB(255, 255, 255),
		},
		neon = {},
	},
	{
		inside = "ema_rack",
		template = "ema_rack",
		colors = {
			Frame = Color3.fromRGB(84, 58, 38),
			Plaques = Color3.fromRGB(222, 184, 130),
			Cords = Color3.fromRGB(214, 40, 40),
			Roof = Color3.fromRGB(140, 28, 40),
		},
		neon = {},
	},
	{
		inside = "wooden_wall",
		template = "wooden_wall",
		colors = {
			Planks = Color3.fromRGB(176, 120, 70),
			Posts = Color3.fromRGB(84, 58, 38),
			Nails = Color3.fromRGB(28, 26, 26),
			Roof = Color3.fromRGB(104, 110, 120),
			Base = Color3.fromRGB(130, 130, 128),
		},
		neon = {},
	},
	-- The stone zone (imported on 2026-10-14). Pivots are also set to the middle of the foot by hand.
	{
		inside = "torii_gate",
		template = "torii_gate",
		colors = {
			Red = Color3.fromRGB(227, 66, 52),
			Black = Color3.fromRGB(24, 24, 24),
			Plaque = Color3.fromRGB(70, 70, 72),
		},
		neon = {},
	},
	{
		inside = "komainu",
		template = "komainu",
		colors = {
			Statue = Color3.fromRGB(196, 196, 192),
			Mane = Color3.fromRGB(160, 160, 156),
			Base = Color3.fromRGB(96, 96, 96),
			Moss = Color3.fromRGB(92, 128, 60),
			Mouth = Color3.fromRGB(140, 28, 40),
		},
		neon = {},
	},
	{
		inside = "bonsai",
		template = "bonsai",
		colors = {
			Trunk = Color3.fromRGB(84, 58, 38),
			Foliage = Color3.fromRGB(40, 110, 48),
			FoliageLight = Color3.fromRGB(120, 190, 90),
			Pot = Color3.fromRGB(40, 80, 170),
			Moss = Color3.fromRGB(92, 128, 60),
			Stand = Color3.fromRGB(130, 130, 128),
		},
		neon = {},
	},
	{
		inside = "mossy_rocks",
		template = "mossy_rocks",
		colors = {
			Rock = Color3.fromRGB(140, 140, 138),
			RockDark = Color3.fromRGB(104, 104, 102),
			Moss = Color3.fromRGB(92, 128, 60),
			Grass = Color3.fromRGB(140, 200, 90),
		},
		neon = {},
	},
	{
		inside = "stone_wall",
		template = "stone_wall",
		colors = {
			Stones = Color3.fromRGB(140, 140, 138),
			StonesDark = Color3.fromRGB(104, 104, 102),
			Gaps = Color3.fromRGB(28, 28, 28),
			Moss = Color3.fromRGB(92, 128, 60),
			Cap = Color3.fromRGB(200, 200, 196),
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
