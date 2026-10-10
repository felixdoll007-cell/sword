local Visibility = require("../src/shared/Rules/Visibility")

return {
	["the same spot is near"] = function(expect)
		expect(Visibility.isNear(150, 10, 20, 10, 20)).toBe(true)
	end,

	["exactly at the distance counts, just beyond does not"] = function(expect)
		expect(Visibility.isNear(150, 0, 0, 150, 0)).toBe(true)
		expect(Visibility.isNear(150, 0, 0, 150.01, 0)).toBe(false)
		-- 90 and 120 studs apart on the two axes are exactly 150 studs.
		expect(Visibility.isNear(150, 0, 0, 90, 120)).toBe(true)
		expect(Visibility.isNear(150, 0, 0, 91, 120)).toBe(false)
	end,

	["direction does not matter"] = function(expect)
		expect(Visibility.isNear(150, -45, 7, 0, 10)).toBe(true)
		expect(Visibility.isNear(150, 0, 10, -45, 7)).toBe(true)
	end,

	["far away and broken positions are not near"] = function(expect)
		expect(Visibility.isNear(150, 0, 0, 0, -800)).toBe(false)
		expect(Visibility.isNear(150, 0 / 0, 0, 0, 0)).toBe(false)
		expect(Visibility.isNear(150, 0, 0, math.huge, 0)).toBe(false)
	end,

	["zero distance shows only the same spot"] = function(expect)
		expect(Visibility.isNear(0, 5, 5, 5, 5)).toBe(true)
		expect(Visibility.isNear(0, 5, 5, 5, 5.1)).toBe(false)
	end,

	["one more throw is drawn only below the cap"] = function(expect)
		expect(Visibility.canShowAnother(0, 6)).toBe(true)
		expect(Visibility.canShowAnother(5, 6)).toBe(true)
		expect(Visibility.canShowAnother(6, 6)).toBe(false)
		expect(Visibility.canShowAnother(7, 6)).toBe(false)
		expect(Visibility.canShowAnother(0, 0)).toBe(false)
	end,
}
