--!strict
-- Pure functions for the look of a themed training lane: where its frame, its themed floor, its
-- sunken throw strip with the stone edge, its start pad, its target, its props and the
-- invisible fence lie. Only looks. Where the pad is, where the player snaps in and where the
-- (now invisible) wall stands comes from Config/Training and Rules/Training and is not changed.
--
-- The field, seen from above (the lane runs towards negative Z, "front" is the far end):
--
--   +----------- frame -----------+   front (far end, behind the target)
--   | floor |  strip + stones | floor |
--   | floor |      target     | floor |
--   | floor |      strip      | floor |
--   | floor |    start pad    | floor |
--   +----------- frame -----------+   back (where the player comes from)
--
-- The middle column is exactly as wide as the pad. All pieces lie next to each other; only the
-- edge stones lie on the strip, clearly above it.

local ThrowZoneLayout = require("./ThrowZoneLayout")
local Training = require("./Training")

export type Area = ThrowZoneLayout.Area

-- Sizes of a themed field, the same for every theme. Heights are above the lane floor level.
export type FieldConfig = {
	-- Whole width of the field, frame included.
	width: number,
	-- How far the field reaches beyond the target line (the last wall), frame included.
	behindTarget: number,
	frameWidth: number,
	frameHeight: number,
	-- The themed floor left and right of the middle column, and the edge stones.
	floorHeight: number,
	-- The start pad.
	padHeight: number,
	-- The sword flies down the middle: the stones leave at least this much of the strip free.
	minFreeWidth: number,
	fenceThickness: number,
	tuftHeight: number,
}

-- One stone of the strip's edge: how much of the strip's length it takes (a weight, compared
-- with the other stones of its side) and how far it reaches into the strip.
export type Stone = { share: number, width: number }

export type Prop = {
	model: string,
	-- Sideways from the middle of the lane: negative = left (smaller X), positive = right.
	right: number,
	-- Distance from the front edge of the pad towards the target.
	forward: number,
	turnDegrees: number?,
	-- Height above the themed floor. For a prop that stands on another one.
	lift: number?,
}

export type Tuft = { right: number, forward: number, turnDegrees: number?, length: number, width: number }

export type TargetConfig = {
	model: string,
	-- Which direction of the model is its front (the side with the rings), in its own space.
	front: { x: number, z: number },
	-- How far its front face lies in front of its standing point.
	faceDistance: number,
	-- Raises (or, below 0, sinks) the target.
	lift: number?,
}

-- Where something stands: a point on the ground, its height and its turn.
export type Placement = { x: number, y: number, z: number, yawDegrees: number }
export type StoneBlock = { area: Area, topY: number }
export type TuftBlock = { area: Area, topY: number, yawDegrees: number }

local TrainingLook = {}

local function left(area: Area): number
	return area.x - area.width / 2
end
local function right(area: Area): number
	return area.x + area.width / 2
end
local function front(area: Area): number
	return area.z - area.length / 2
end
local function back(area: Area): number
	return area.z + area.length / 2
end

-- An area from its edges.
local function fromEdges(minX: number, maxX: number, minZ: number, maxZ: number): Area
	return { x = (minX + maxX) / 2, z = (minZ + maxZ) / 2, width = maxX - minX, length = maxZ - minZ }
end

-- The start pad: exactly the pad the game checks.
function TrainingLook.pad(config: Training.TrainingConfig, laneIndex: number): Area
	local pad = Training.lanePad(config, laneIndex) :: Training.Pad
	return { x = pad.x, z = pad.z, width = pad.width, length = pad.length }
end

-- Z of the target line: the middle of the lane's last wall.
function TrainingLook.targetLineZ(config: Training.TrainingConfig, laneIndex: number): number
	local pad = TrainingLook.pad(config, laneIndex)
	return front(pad) - Training.wallOffset(config, config.lanes[laneIndex].walls)
end

-- The whole field with its frame.
function TrainingLook.outline(config: Training.TrainingConfig, field: FieldConfig, laneIndex: number): Area
	local pad = TrainingLook.pad(config, laneIndex)
	local frontZ = TrainingLook.targetLineZ(config, laneIndex) - field.behindTarget
	local backZ = back(pad) + field.frameWidth
	return fromEdges(pad.x - field.width / 2, pad.x + field.width / 2, frontZ, backZ)
end

-- Everything inside the frame.
function TrainingLook.inner(config: Training.TrainingConfig, field: FieldConfig, laneIndex: number): Area
	local outline = TrainingLook.outline(config, field, laneIndex)
	local frame = field.frameWidth
	return fromEdges(left(outline) + frame, right(outline) - frame, front(outline) + frame, back(outline) - frame)
end

-- The frame: four strips along the inside of the outline. The two side strips also cover the corners.
function TrainingLook.frame(config: Training.TrainingConfig, field: FieldConfig, laneIndex: number): { Area }
	local outline = TrainingLook.outline(config, field, laneIndex)
	local inner = TrainingLook.inner(config, field, laneIndex)
	return {
		fromEdges(left(outline), left(inner), front(outline), back(outline)),
		fromEdges(right(inner), right(outline), front(outline), back(outline)),
		fromEdges(left(inner), right(inner), front(outline), front(inner)),
		fromEdges(left(inner), right(inner), back(inner), back(outline)),
	}
end

-- The themed floor: one band left and one right of the middle column, over the whole inner length.
function TrainingLook.floors(config: Training.TrainingConfig, field: FieldConfig, laneIndex: number): { Area }
	local inner = TrainingLook.inner(config, field, laneIndex)
	local pad = TrainingLook.pad(config, laneIndex)
	return {
		fromEdges(left(inner), left(pad), front(inner), back(inner)),
		fromEdges(right(pad), right(inner), front(inner), back(inner)),
	}
end

-- The sunken throw strip: from the front edge of the pad to the inner far end, as wide as the pad.
function TrainingLook.strip(config: Training.TrainingConfig, field: FieldConfig, laneIndex: number): Area
	local inner = TrainingLook.inner(config, field, laneIndex)
	local pad = TrainingLook.pad(config, laneIndex)
	return fromEdges(left(pad), right(pad), front(inner), front(pad))
end

-- The stone edge of the strip: blocks of different width along both of its sides, from the pad
-- to the far end. They make the strip's outline step in and out. sides: stones of the left
-- and of the right side, each from the pad towards the target.
function TrainingLook.stones(
	config: Training.TrainingConfig,
	field: FieldConfig,
	laneIndex: number,
	floorTopY: number,
	sides: { left: { Stone }, right: { Stone } }
): { StoneBlock }
	local strip = TrainingLook.strip(config, field, laneIndex)
	-- No stone reaches further into the strip than this, so the middle stays free for the sword.
	local widest = math.max((strip.width - field.minFreeWidth) / 2, 0)
	local blocks: { StoneBlock } = {}

	local function lay(stones: { Stone }, side: number)
		local total = 0
		for _, stone in stones do
			total += math.max(stone.share, 0)
		end
		if total <= 0 then
			return
		end
		-- From the pad (back end of the strip) towards the target.
		local z = back(strip)
		for _, stone in stones do
			local length = strip.length * math.max(stone.share, 0) / total
			local width = math.clamp(stone.width, 0, widest)
			if length > 0 and width > 0 then
				local outerEdge = strip.x + side * strip.width / 2
				local minX = math.min(outerEdge, outerEdge - side * width)
				table.insert(blocks, {
					area = fromEdges(minX, minX + width, z - length, z),
					topY = floorTopY + field.floorHeight,
				})
			end
			z -= length
		end
	end
	lay(sides.left, -1)
	lay(sides.right, 1)
	return blocks
end

-- Invisible walls that keep players out of everything in front of the pad: one across the field
-- at the pad's front edge, one along each side from there to the far end, one across the far
-- end. They lie inside the field's outline and do not overlap each other.
function TrainingLook.fences(config: Training.TrainingConfig, field: FieldConfig, laneIndex: number): { Area }
	local outline = TrainingLook.outline(config, field, laneIndex)
	local pad = TrainingLook.pad(config, laneIndex)
	local thickness = field.fenceThickness
	local lineZ = front(pad)
	return {
		fromEdges(left(outline), right(outline), lineZ - thickness, lineZ),
		fromEdges(left(outline), right(outline), front(outline), front(outline) + thickness),
		fromEdges(left(outline), left(outline) + thickness, front(outline) + thickness, lineZ - thickness),
		fromEdges(right(outline) - thickness, right(outline), front(outline) + thickness, lineZ - thickness),
	}
end

-- Direction of a flat vector as an angle that grows when turned with CFrame.Angles(0, angle, 0).
local function heading(x: number, z: number): number
	return math.atan2(-z, x)
end

local function wrap(degrees: number): number
	return (degrees + 180) % 360 - 180
end

-- The target: it stands on the strip so that its front face lies on the target line (where the
-- sword ends its flight) and looks at the player.
function TrainingLook.target(
	config: Training.TrainingConfig,
	laneIndex: number,
	floorTopY: number,
	target: TargetConfig
): Placement
	local pad = TrainingLook.pad(config, laneIndex)
	-- The player stands towards positive Z from the target.
	local towardsPlayer = heading(0, 1)
	return {
		x = pad.x,
		y = floorTopY + (target.lift or 0),
		z = TrainingLook.targetLineZ(config, laneIndex) - target.faceDistance,
		yawDegrees = wrap(math.deg(towardsPlayer - heading(target.front.x, target.front.z))),
	}
end

-- Where a prop (e.g. a hay bale) stands. Props stand on the themed floor.
function TrainingLook.prop(
	config: Training.TrainingConfig,
	field: FieldConfig,
	laneIndex: number,
	floorTopY: number,
	prop: Prop
): Placement
	local pad = TrainingLook.pad(config, laneIndex)
	return {
		x = pad.x + prop.right,
		y = floorTopY + field.floorHeight + (prop.lift or 0),
		z = front(pad) - prop.forward,
		yawDegrees = wrap(prop.turnDegrees or 0),
	}
end

-- A flat tuft of straw. It lies on the themed floor, or on the strip if it is in the middle column.
function TrainingLook.tuft(
	config: Training.TrainingConfig,
	field: FieldConfig,
	laneIndex: number,
	floorTopY: number,
	tuft: Tuft
): TuftBlock
	local pad = TrainingLook.pad(config, laneIndex)
	local onStrip = math.abs(tuft.right) < pad.width / 2
	local ground = if onStrip then floorTopY else floorTopY + field.floorHeight
	return {
		area = { x = pad.x + tuft.right, z = front(pad) - tuft.forward, width = tuft.width, length = tuft.length },
		topY = ground + field.tuftHeight,
		yawDegrees = wrap(tuft.turnDegrees or 0),
	}
end

-- Where the sign of a lane floats: above the lane, a little in front of the pad.
function TrainingLook.sign(
	config: Training.TrainingConfig,
	laneIndex: number,
	floorTopY: number,
	heightAboveFloor: number,
	forward: number
): { x: number, y: number, z: number }
	local pad = TrainingLook.pad(config, laneIndex)
	return { x = pad.x, y = floorTopY + heightAboveFloor, z = front(pad) - forward }
end

return TrainingLook
