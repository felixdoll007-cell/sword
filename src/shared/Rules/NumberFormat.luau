--!strict
-- Pure function that shortens big numbers for the screen: 1500 -> "1.5K".

export type NumberFormatConfig = {
	decimals: number,
	suffixes: { string },
}

-- Protects against values like 2.9 being stored as 2.8999999 and then rounded down to 2.8.
local ROUNDING_GUARD = 1e-9

local NumberFormat = {}

local function roundDown(value: number, decimals: number): number
	local scale = 10 ^ decimals
	return math.floor(value * scale + ROUNDING_GUARD) / scale
end

local function withoutTrailingZeros(text: string): string
	if text:find("%.") then
		text = text:gsub("0+$", ""):gsub("%.$", "")
	end
	return text
end

local function formatPlain(value: number, decimals: number): string
	return withoutTrailingZeros(string.format(`%.{decimals}f`, roundDown(value, decimals)))
end

function NumberFormat.abbreviate(config: NumberFormatConfig, value: number): string
	if value ~= value then
		return "NaN"
	elseif value == math.huge then
		return "inf"
	elseif value == -math.huge then
		return "-inf"
	elseif value == 0 then
		-- Also catches -0, which would otherwise show as "-0".
		return "0"
	elseif value < 0 then
		return "-" .. NumberFormat.abbreviate(config, -value)
	end

	-- Counting up instead of using a logarithm avoids rounding errors right at 1000, 1000000, ...
	local tier = 0
	while value >= 1000 ^ (tier + 1) do
		tier += 1
	end

	if tier == 0 then
		return formatPlain(value, config.decimals)
	end

	if tier > #config.suffixes then
		local exponent = math.floor(math.log10(value))
		local mantissa = value / 10 ^ exponent
		if mantissa >= 10 then
			mantissa /= 10
			exponent += 1
		elseif mantissa < 1 then
			mantissa *= 10
			exponent -= 1
		end
		return `{formatPlain(mantissa, config.decimals)}e{exponent}`
	end

	return formatPlain(value / 1000 ^ tier, config.decimals) .. config.suffixes[tier]
end

return NumberFormat
