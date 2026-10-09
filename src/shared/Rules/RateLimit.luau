--!strict
-- Pure function: may a request pass, given the times of the earlier requests?
-- Returns the decision and the new list of request times to remember.

local RateLimit = {}

function RateLimit.check(
	earlierTimes: { number },
	now: number,
	maxRequests: number,
	windowSeconds: number
): (boolean, { number })
	local recent = {}
	for _, time in earlierTimes do
		if now - time < windowSeconds then
			table.insert(recent, time)
		end
	end

	if #recent >= maxRequests then
		return false, recent
	end

	table.insert(recent, now)
	return true, recent
end

return RateLimit
