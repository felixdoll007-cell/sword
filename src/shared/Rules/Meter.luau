--!strict
-- Pure functions for the meter. Server and client use the same formulas, so the client shows
-- the pointer exactly where the server calculates it.
--
-- Position of the pointer: -1 = bottom end, 0 = middle, 1 = top end.

export type MeterConfig = {
	minFactor: number,
	maxFactor: number,
	swingSeconds: number,
	maxDelaySeconds: number,
	clockToleranceSeconds: number,
	timeoutSeconds: number,
}

local Meter = {}

-- startPhase (0 to 1) is where in the swing the pointer starts. The server picks it at random.
function Meter.position(config: MeterConfig, startTime: number, startPhase: number, time: number): number
	local cycle = ((time - startTime) / config.swingSeconds + startPhase) % 1
	-- Even speed: from -1 up to 1 in the first half of the swing, back down in the second half.
	return 1 - 4 * math.abs(cycle - 0.5)
end

-- The closer to the middle, the higher the factor.
function Meter.factor(config: MeterConfig, position: number): number
	local distanceFromMiddle = math.clamp(math.abs(position), 0, 1)
	if distanceFromMiddle ~= distanceFromMiddle then
		-- NaN: treat it as the worst position.
		distanceFromMiddle = 1
	end
	return config.maxFactor - (config.maxFactor - config.minFactor) * distanceFromMiddle
end

-- Decides which moment of the meter counts for a press.
-- pressTime: when the client says it pressed. receiveTime: when the server got the message.
-- Returns nil if the press is impossible, otherwise the time to use.
function Meter.timeToUse(config: MeterConfig, startTime: number, pressTime: unknown, receiveTime: number): number?
	if typeof(pressTime) ~= "number" or pressTime ~= pressTime or math.abs(pressTime) == math.huge then
		return nil
	end
	local tolerance = config.clockToleranceSeconds

	-- Before the meter started, or in the future: impossible.
	if pressTime < startTime - tolerance or pressTime > receiveTime + tolerance then
		return nil
	end

	-- Too old: count the earliest moment that is still allowed. Never outside start and arrival.
	local time = math.max(pressTime, receiveTime - config.maxDelaySeconds, startTime)
	time = math.min(time, receiveTime)

	-- Meter already ran out at that moment: impossible.
	if time > startTime + config.timeoutSeconds then
		return nil
	end
	return time
end

return Meter
