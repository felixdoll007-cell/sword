local RateLimit = require("../src/shared/Rules/RateLimit")

return {
	["requests below the limit pass"] = function(expect)
		local allowed, times = RateLimit.check({}, 10, 3, 2)
		expect(allowed).toBe(true)
		expect(#times).toBe(1)
	end,

	["the request over the limit is blocked"] = function(expect)
		local times = {}
		local allowed
		for _ = 1, 3 do
			allowed, times = RateLimit.check(times, 10, 3, 2)
			expect(allowed).toBe(true)
		end
		allowed, times = RateLimit.check(times, 10.5, 3, 2)
		expect(allowed).toBe(false)
		expect(#times).toBe(3)
	end,

	["old requests run out of the window"] = function(expect)
		local _, times = RateLimit.check({ 1, 1.5, 2 }, 2.1, 3, 2)
		expect(#times).toBe(3)
		local allowed
		allowed, times = RateLimit.check(times, 5, 3, 2)
		expect(allowed).toBe(true)
		expect(#times).toBe(1)
	end,

	["exactly at the window edge an old request no longer counts"] = function(expect)
		local allowed = RateLimit.check({ 0, 0, 0 }, 2, 3, 2)
		expect(allowed).toBe(true)
	end,
}
