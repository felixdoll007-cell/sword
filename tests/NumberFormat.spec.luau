local NumberFormat = require("../src/shared/Rules/NumberFormat")
local NumberFormatConfig = require("../src/shared/Config/NumberFormat")

local function abbreviate(value: number): string
	return NumberFormat.abbreviate(NumberFormatConfig, value)
end

return {
	["small numbers stay as they are"] = function(expect)
		expect(abbreviate(0)).toBe("0")
		expect(abbreviate(7)).toBe("7")
		expect(abbreviate(999)).toBe("999")
	end,

	["decimals below 1000 are rounded down to one digit"] = function(expect)
		expect(abbreviate(10.5)).toBe("10.5")
		expect(abbreviate(10.59)).toBe("10.5")
		expect(abbreviate(999.99)).toBe("999.9")
	end,

	["exactly on a boundary gets the next suffix"] = function(expect)
		expect(abbreviate(1000)).toBe("1K")
		expect(abbreviate(1e6)).toBe("1M")
		expect(abbreviate(1e9)).toBe("1B")
		expect(abbreviate(1e12)).toBe("1T")
	end,

	["typical values"] = function(expect)
		expect(abbreviate(1500)).toBe("1.5K")
		expect(abbreviate(3.2e6)).toBe("3.2M")
		expect(abbreviate(2.9e9)).toBe("2.9B")
		expect(abbreviate(1e15)).toBe("1Qa")
		expect(abbreviate(1e30)).toBe("1No")
	end,

	["rounds down, never up"] = function(expect)
		expect(abbreviate(1999)).toBe("1.9K")
		expect(abbreviate(999999)).toBe("999.9K")
	end,

	["beyond the last suffix uses e notation"] = function(expect)
		expect(abbreviate(1e33)).toBe("1Dc")
		expect(abbreviate(1.5e36)).toBe("1.5e36")
		expect(abbreviate(1e300)).toBe("1e300")
	end,

	["negative numbers keep their sign"] = function(expect)
		expect(abbreviate(-1500)).toBe("-1.5K")
		expect(abbreviate(-0)).toBe("0")
	end,

	["NaN and infinity do not crash"] = function(expect)
		expect(abbreviate(0 / 0)).toBe("NaN")
		expect(abbreviate(math.huge)).toBe("inf")
		expect(abbreviate(-math.huge)).toBe("-inf")
	end,
}
