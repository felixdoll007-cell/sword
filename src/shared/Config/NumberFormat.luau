--!strict
-- How big numbers are shown on screen (1.5K, 3.2M, ...).

return {
	-- Digits after the decimal point. Numbers are rounded down, so the screen never shows more than the player has.
	decimals = 1,
	-- One suffix per factor of 1000. Beyond the last one, numbers are shown like 1.5e36.
	suffixes = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" },
}
