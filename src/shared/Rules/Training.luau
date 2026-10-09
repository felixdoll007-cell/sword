--!strict
-- Pure functions for training: is the player on the pad, and is it time for the next training throw?

export type PadConfig = {
	pad: { x: number, z: number, width: number, length: number },
	padTolerance: number,
}

local Training = {}

function Training.isOnPad(config: PadConfig, x: number, z: number): boolean
	local pad = config.pad
	local halfWidth = pad.width / 2 + config.padTolerance
	local halfLength = pad.length / 2 + config.padTolerance
	return math.abs(x - pad.x) <= halfWidth and math.abs(z - pad.z) <= halfLength
end

-- Called regularly by the server for each player.
-- nextThrowAt: when the next training throw is due, or nil if the player was not training.
-- Returns whether a training throw happens now, and the new nextThrowAt.
-- Stepping on the pad starts the clock: the first throw comes one interval later.
-- Stepping off stops it. After a long pause (lag) there is no burst of throws to catch up.
function Training.tick(nextThrowAt: number?, onPad: boolean, now: number, interval: number): (boolean, number?)
	if not onPad then
		return false, nil
	end
	if nextThrowAt == nil then
		return false, now + interval
	end
	if now < nextThrowAt then
		return false, nextThrowAt
	end
	local following = nextThrowAt + interval
	if following <= now then
		following = now + interval
	end
	return true, following
end

-- A player who let go of the pad ("training left") stays blocked until fully off the pad.
-- Returns the new blocked state. Leaving the pad is the only way to clear it.
function Training.updateBlock(blocked: boolean, onPad: boolean): boolean
	return blocked and onPad
end

-- Training only counts on the pad and when not blocked.
function Training.isTraining(onPad: boolean, blocked: boolean): boolean
	return onPad and not blocked
end

return Training
