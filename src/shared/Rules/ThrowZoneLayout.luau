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

-- The green floor around the zone, as pieces that lie next to the other floors and never under
-- or over one:
--   * a piece left and a piece right of the zone, reaching back behind it
--   * a piece behind the zone
--   * a piece front left and front right, beside the lane. In front of the zone runs the lane,
--     and next to the lane may run walkways, so these two pieces start walkWidth away from it.
-- left, right, front and back say how far the green reaches beyond the zone on each side.
function ThrowZoneLayout.surroundings(
	config: ZoneConfig,
	surroundings: SurroundingsConfig,
	walkWidth: number?
): { Area }
	local zone = ThrowZoneLayout.zone(config)
	local left, right = math.max(surroundings.left, 0), math.max(surroundings.right, 0)
	local front, back = math.max(surroundings.front, 0), math.max(surroundings.back, 0)
	local inset = math.max(walkWidth or 0, 0)
	local zoneLeft, zoneRight = zone.x - zone.width / 2, zone.x + zone.width / 2
	local zoneFront, zoneBack = zone.z - zone.length / 2, zone.z + zone.length / 2
	local sideLength = zone.length + back
	local sideZ = zone.z + back / 2

	local pieces: { Area } = {}
	if left > 0 then
		table.insert(pieces, { x = zoneLeft - left / 2, z = sideZ, width = left, length = sideLength })
	end
	if right > 0 then
		table.insert(pieces, { x = zoneRight + right / 2, z = sideZ, width = right, length = sideLength })
	end
	if back > 0 then
		table.insert(pieces, { x = zone.x, z = zoneBack + back / 2, width = zone.width, length = back })
	end
	if front > 0 and left > inset then
		table.insert(pieces, {
			x = zoneLeft - inset - (left - inset) / 2,
			z = zoneFront - front / 2,
			width = left - inset,
			length = front,
		})
	end
	if front > 0 and right > inset then
		table.insert(pieces, {
			x = zoneRight + inset + (right - inset) / 2,
			z = zoneFront - front / 2,
			width = right - inset,
			length = front,
		})
	end
	return pieces
end

return ThrowZoneLayout
