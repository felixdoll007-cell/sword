--!strict
-- The meter before a throw: a pointer swings up and down, the middle gives the best factor.
-- All times in seconds, measured on the shared server clock.

return {
	-- Factor at the very ends and exactly in the middle.
	minFactor = 0.5,
	maxFactor = 1.5,

	-- Time for one full swing: from the bottom to the top and back.
	swingSeconds = 1.6,

	-- Presses that took longer than this to reach the server count as if pressed this long ago.
	maxDelaySeconds = 0.3,
	-- The clocks of client and server can differ by a tiny bit. Presses this far "in the future" still count.
	clockToleranceSeconds = 0.1,

	-- Without a second press, the meter disappears after this time.
	timeoutSeconds = 6,

	-- How long "x1.4" stays on screen after the press.
	factorDisplaySeconds = 1.2,
}
