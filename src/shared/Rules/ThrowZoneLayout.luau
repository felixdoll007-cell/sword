--!strict
-- Pure functions for the look of the throw zone: where its raised edge, the writing on its
-- floor and the green floor around it lie. Only looks; whether a player stands in the throw
-- zone is decided by Rules/LaneLayout and is not changed by anything here.
-- The lane runs towards negative Z, so "front" is the side of the throw line (smaller Z) and
-- "back" is the side away from the lane (bigger Z).

-- A rectangle on the ground: its middle and its size. width runs along X, length along Z.
export type Area = { x: number, z: number, width: number, length: number }

export type ZoneConfig = {
	throwLine: { x: number, z: number },
	laneWidth: number,
	throwZoneLength: number,
}

export type RimConfig = { width: number }

export type LabelConfig = {
	widthStuds: number,
	heightStuds: number,
	-- Where the middle of the writing sits between the throw line (0) and the back edge (1).
	positionShare: number,
}

export type SurroundingsConfig = {
	left: number,
	right: number,
	front: number,
	back: number,
}

local ThrowZoneLayout = {}

-- The throw zone itself: the same rectangle the game uses to decide whether a player is in it.
function ThrowZoneLayout.zone(config: ZoneConfig): Area
	return {
		x = config.throwLine.x,
		z = config.throwLine.z + config.throwZoneLength / 2,
		width = config.laneWidth,
		length = config.throwZoneLength,
	}
end

-- The raised edge: four strips right outside the zone. The two side strips also cover the
-- corners, so the edge is closed all around.
function ThrowZoneLayout.rim(config: ZoneConfig, rim: RimConfig): { Area }
	local zone = ThrowZoneLayout.zone(config)
	local width = math.max(rim.width, 0)
	local sideLength = zone.length + 2 * width
	local sideOffset = zone.width / 2 + width / 2
	local endOffset = zone.length / 2 + width / 2
	return {
		{ x = zone.x - sideOffset, z = zone.z, width = width, length = sideLength },
		{ x = zone.x + sideOffset, z = zone.z, width = width, length = sideLength },
		{ x = zone.x, z = zone.z - endOffset, width = zone.width, length = width },
		{ x = zone.x, z = zone.z + endOffset, width = zone.width, length = width },
	}
end

-- The room for the writing on the floor. It never reaches beyond the zone.
function ThrowZoneLayout.label(config: ZoneConfig, label: LabelConfig): Area
	local zone = ThrowZoneLayout.zone(config)
	local width = math.clamp(label.widthStuds, 0, zone.width)
	local length = math.clamp(label.heightStuds, 0, zone.length)
	local share = if label.positionShare == label.positionShare then math.clamp(label.positionShare, 0, 1) else 0.5
	local front = zone.z - zone.length / 2
	-- Keep the whole writing inside the zone.
	local z = math.clamp(front + zone.length * share, front + length / 2, front + zone.length - length / 2)
	return { x = zone.x, z = z, width = width, length = length }
end

-- The green floor around the zone: the zone plus this much room on each side.
function ThrowZoneLayout.surroundings(config: ZoneConfig, surroundings: SurroundingsConfig): Area
	local zone = ThrowZoneLayout.zone(config)
	local left, right = math.max(surroundings.left, 0), math.max(surroundings.right, 0)
	local front, back = math.max(surroundings.front, 0), math.max(surroundings.back, 0)
	return {
		x = zone.x + (right - left) / 2,
		z = zone.z + (back - front) / 2,
		width = zone.width + left + right,
		length = zone.length + front + back,
	}
end

return ThrowZoneLayout
