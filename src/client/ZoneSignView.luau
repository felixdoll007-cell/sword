--!strict
-- The name of the next zone, floating high above the lane at the end of a zone that has a look
-- (e.g. "WOOD" at the end of the paper zone). Big, in the font of the interface with its black
-- border, always turned towards the camera.
-- Built on this client, like the walls: the border of the text has to follow the size the text
-- has on this player's screen. Only looks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local WallConfig = require(Shared.Config.Walls)
local ZoneLook = require(Shared.Rules.ZoneLook)

local OutlinedText = require(script.Parent.Ui.OutlinedText)

local FOLDER_NAME = "MyZoneSigns"

local ZoneSignView = {}

function ZoneSignView.build()
	local old = Workspace:FindFirstChild(FOLDER_NAME)
	if old then
		old:Destroy()
	end
	local look = Ui.world.lane
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME

	for zone in WallConfig.materials do
		local sign = ZoneLook.sign(LaneConfig, WallConfig, look, zone)
		if sign then
			-- An invisible point in the world that the name hangs on.
			local anchor = Instance.new("Part")
			anchor.Name = `ZoneSign{zone}`
			anchor.Anchored = true
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.CastShadow = false
			anchor.Transparency = 1
			anchor.Size = Vector3.one
			anchor.Position = Vector3.new(sign.x, sign.y, sign.z)

			local gui = Instance.new("BillboardGui")
			gui.Name = "Name"
			-- Sizes in studs, so the name gets smaller with distance like everything else.
			gui.Size = UDim2.fromScale(look.sign.widthStuds, look.sign.heightStuds)
			gui.LightInfluence = 0
			gui.MaxDistance = look.sign.maxDistance
			-- Needed so the text lies on top of its own shadow.
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Adornee = anchor
			gui.Parent = anchor

			OutlinedText.new({ name = "Text", parent = gui, text = sign.text, color = sign.color })
			anchor.Parent = folder
		end
	end

	folder.Parent = Workspace
end

return ZoneSignView
