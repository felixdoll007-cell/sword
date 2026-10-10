--!strict
-- Pure functions for training: where the lanes are, which lane a player stands on, whether it is
-- unlocked, and whether it is time for the next training throw.
-- Lanes are numbered from 1 (next to the throw zone) to the left.

-- How a lane is unlocked. Only "Rebirths" exists so far; "Purchase" is planned.
export type Unlock = {
	kind: string,
	rebirths: number?,
}

export type Lane = {
	unlock: Unlock,
	multiplier: number,
	walls: number,
}

-- What the game knows about a player that can unlock lanes. More fields come with new unlock kinds.
export type Progress = {
	rebirths: number,
}

export type Pad = { x: number, z: number, width: number, length: number }

export type TrainingConfig = {
	lanes: { Lane },
	pad: Pad,
	laneSpacing: number,
	padTolerance: number,
	laneLength: number,
	wallDistance: number,
	wallSpacing: number,
}

-- The rectangle on the ground a lane takes up: its pad plus the lane floor in front of it.
export type Area = { minX: number, maxX: number, minZ: number, maxZ: number }

local Training = {}

function Training.laneCount(config: TrainingConfig): number
	return #config.lanes
end

-- The pad of a lane: center and size on the ground. nil if the lane does not exist.
function Training.lanePad(config: TrainingConfig, laneIndex: number): Pad?
	if not config.lanes[laneIndex] then
		return nil
	end
	local first = config.pad
	return {
		x = first.x - (laneIndex - 1) * config.laneSpacing,
		z = first.z,
		width = first.width,
		length = first.length,
	}
end

-- The ground a lane takes up (pad and lane floor). nil if the lane does not exist.
function Training.laneArea(config: TrainingConfig, laneIndex: number): Area?
	local pad = Training.lanePad(config, laneIndex)
	if not pad then
		return nil
	end
	return {
		minX = pad.x - pad.width / 2,
		maxX = pad.x + pad.width / 2,
		-- The lane runs towards negative Z from the front edge of the pad.
		minZ = pad.z - pad.length / 2 - config.laneLength,
		maxZ = pad.z + pad.length / 2,
	}
end

-- Which lane's pad is this position on? nil if on none.
function Training.laneAt(config: TrainingConfig, x: number, z: number): number?
	for laneIndex = 1, #config.lanes do
		local pad = Training.lanePad(config, laneIndex) :: Pad
		local halfWidth = pad.width / 2 + config.padTolerance
		local halfLength = pad.length / 2 + config.padTolerance
		if math.abs(x - pad.x) <= halfWidth and math.abs(z - pad.z) <= halfLength then
			return laneIndex
		end
	end
	return nil
end

-- Is this lane unlocked for a player with this progress?
-- Each unlock kind has its own rule. A kind the game does not know keeps the lane locked.
function Training.isUnlocked(config: TrainingConfig, laneIndex: number, progress: Progress): boolean
	local lane = config.lanes[laneIndex]
	if not lane then
		return false
	end
	local unlock = lane.unlock
	if unlock.kind == "Rebirths" then
		-- Always calculated from the rebirths, never saved.
		return unlock.rebirths ~= nil and progress.rebirths >= unlock.rebirths
	end
	return false
end

-- The lane a player trains on right now: standing on its pad AND unlocked. nil otherwise.
function Training.trainingLane(config: TrainingConfig, x: number, z: number, progress: Progress): number?
	local laneIndex = Training.laneAt(config, x, z)
	if laneIndex and Training.isUnlocked(config, laneIndex, progress) then
		return laneIndex
	end
	return nil
end

-- Distance from the front edge of the pad to the middle of a lane's wall (1 = nearest).
function Training.wallOffset(config: TrainingConfig, wallNumber: number): number
	return config.wallDistance + (wallNumber - 1) * config.wallSpacing
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
