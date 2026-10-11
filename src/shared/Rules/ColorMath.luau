--!strict
-- Pure functions for lighter and darker tones of a color. A color is { red, green, blue },
-- each from 0 to 255.

export type Rgb = { number }

local ColorMath = {}

local function channel(value: number): number
	if value ~= value then
		return 0
	end
	return math.clamp(math.round(value), 0, 255)
end

local function share(value: number): number
	if value ~= value then
		return 0
	end
	return math.clamp(value, 0, 1)
end

-- amount 0 = the same color, 1 = black.
function ColorMath.darken(rgb: Rgb, amount: number): Rgb
	local keep = 1 - share(amount)
	return { channel(rgb[1] * keep), channel(rgb[2] * keep), channel(rgb[3] * keep) }
end

-- amount 0 = the same color, 1 = white.
function ColorMath.lighten(rgb: Rgb, amount: number): Rgb
	local add = share(amount)
	return {
		channel(rgb[1] + (255 - rgb[1]) * add),
		channel(rgb[2] + (255 - rgb[2]) * add),
		channel(rgb[3] + (255 - rgb[3]) * add),
	}
end

return ColorMath
