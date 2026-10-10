--!strict
-- Pure functions for showing other players' throws: who is near enough to be told,
-- and whether one more throw may be drawn.

local Visibility = {}

-- Are two positions on the ground within maxDistance of each other?
function Visibility.isNear(maxDistance: number, ax: number, az: number, bx: number, bz: number): boolean
	local dx = ax - bx
	local dz = az - bz
	-- Compared squared: no square root needed. NaN positions are never near.
	return dx * dx + dz * dz <= maxDistance * maxDistance
end

-- May one more throw of another player be drawn, with this many already on screen?
function Visibility.canShowAnother(shownNow: number, maxShownAtOnce: number): boolean
	return shownNow < maxShownAtOnce
end

return Visibility
