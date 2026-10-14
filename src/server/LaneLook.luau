--!strict
-- The floor of the main lane and the walkways along it, in the look of each zone.
--   * A zone with a look (Config/Ui, world.lane.zones) gets its own floor stretch: a
--     checkerboard in its two tones with studs. Zones without a look stay plain.
--   * Left and right of such a zone run raised walkways in two steps, with an edge towards the
--     lane. They are scenery: an invisible fence keeps players off them. The fence only stops
--     players; the thrown weapon is moved by script and the camera ignores invisible parts.
-- The stretches lie one behind the other and the walkways next to the lane: no floor lies on
-- top of another one (that would flicker).
-- Only looks. Walls, barriers and everything a throw does are untouched.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local LaneConfig = require(Shared.Config.Lane)
local Ui = require(Shared.Config.Ui)
local WallConfig = require(Shared.Config.Walls)
local ZoneLook = require(Shared.Rules.ZoneLook)

local WorldParts = require(script.Parent.WorldParts)

local LaneLook = {}

-- Builds the whole floor of the main lane and the walkways into this folder.
function LaneLook.build(folder: Instance)
	local look = Ui.world.lane

	for _, segment in ZoneLook.floorSegments(LaneConfig, WallConfig, look) do
		local area = ZoneLook.laneArea(LaneConfig, segment.from, segment.to)
		local zoneStyle = if segment.material then look.zones[segment.material] else nil
		if segment.material and zoneStyle and zoneStyle.floor then
			local floor = WorldParts.addBlock(
				folder,
				`Floor{segment.material}`,
				area,
				LaneConfig.floorTopY,
				zoneStyle.floor.darkColor
			)
			WorldParts.addFloorTile(floor, zoneStyle.floor.lightColor)
		else
			WorldParts.addBlock(folder, "Floor", area, LaneConfig.floorTopY, LaneConfig.floorColor)
		end
	end

	for zone in WallConfig.materials do
		for index, walkPart in ZoneLook.walks(LaneConfig, WallConfig, look, zone) do
			local walk = look.zones[walkPart.material].walk
			if walk then
				if walkPart.kind == "curb" then
					local curb = WorldParts.addBlock(
						folder,
						`Curb{walkPart.material}{index}`,
						walkPart.area,
						walkPart.topY,
						walk.curbColor
					)
					-- An edge of glowing embers.
					if walk.curbGlow then
						curb.Material = Enum.Material.Neon
					end
				else
					-- The two steps look the same; the name tells them apart.
					local name = if walkPart.kind == "outer" then "WalkOuter" else "WalkInner"
					local part = WorldParts.addBlock(
						folder,
						`{name}{walkPart.material}{index}`,
						walkPart.area,
						walkPart.topY,
						walk.darkColor
					)
					WorldParts.addFloorTile(part, walk.lightColor)
				end
			end
		end
		-- Players stay off the walkways.
		for index, fence in ZoneLook.fences(LaneConfig, WallConfig, look, zone) do
			WorldParts.addInvisibleWall(folder, `WalkFence{zone}_{index}`, fence, LaneConfig.barrierHeight)
		end
	end
end

return LaneLook
