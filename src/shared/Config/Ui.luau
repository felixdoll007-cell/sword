--!strict
-- Screen elements. Sizes are a share of the screen (0 to 1), with pixel limits so buttons
-- stay big enough for a thumb on phones and do not get huge on big screens.

return {
	throwButton = {
		text = "THROW",
		-- Text while the meter runs: the next press stops the pointer.
		stopText = "STOP",
		-- Extra shortcut on keyboards. Touch always works through the button.
		key = "E",
		heightScale = 0.14,
		-- Width = height * aspectRatio
		aspectRatio = 2.6,
		minWidth = 160,
		minHeight = 62,
		maxWidth = 360,
		maxHeight = 138,
		-- Bottom center, between the thumbstick (bottom left) and the jump button (bottom right).
		positionX = 0.5,
		positionY = 0.96,
		color = { 70, 70, 70 },
		textColor = { 255, 255, 255 },
	},

	-- Upright bar with the swinging pointer. On the right, so it does not cover the lane in the middle.
	-- It is only looked at, never touched; the THROW button stops it.
	meter = {
		heightScale = 0.45,
		-- Width = height * aspectRatio
		aspectRatio = 0.16,
		minWidth = 30,
		minHeight = 180,
		maxWidth = 70,
		maxHeight = 440,
		positionX = 0.78,
		positionY = 0.5,
		-- Colors from the ends to the middle.
		endColor = { 220, 50, 50 },
		betweenColor = { 240, 200, 40 },
		middleColor = { 60, 200, 80 },
		-- Where the yellow sits, from the end (0) to the middle (0.5).
		betweenAt = 0.25,
		borderColor = { 20, 20, 20 },
		borderThickness = 3,
		pointerColor = { 255, 255, 255 },
		-- Pointer height as a share of the bar height, and how far it sticks out on both sides.
		pointerHeightScale = 0.035,
		pointerWidthScale = 1.6,
	},

	-- "x1.4" after the press, above the THROW button.
	factorLabel = {
		heightScale = 0.09,
		minHeight = 36,
		widthScale = 0.4,
		-- Bottom edge of the label, just above the button.
		positionY = 0.8,
		textColor = { 255, 255, 255 },
		strokeColor = { 0, 0, 0 },
		decimals = 1,
	},

	-- Strength and currency, plain text side by side at the top center. Still without design (Version 4).
	stats = {
		strengthPrefix = "Strength: ",
		-- The currency has no name yet (open point in the design); this is a placeholder.
		currencyPrefix = "Coins: ",
		heightScale = 0.06,
		minHeight = 28,
		-- Width of each of the two texts.
		widthScale = 0.28,
		positionY = 0.02,
		textColor = { 255, 255, 255 },
		strokeColor = { 0, 0, 0 },
		-- During a throw the new values are held back and shown when the throw has ended.
		-- Safety: never hold them longer than this.
		maxHoldSeconds = 12,
	},

	-- "+..." that rises and fades below a value whenever it grows.
	gainPopup = {
		color = { 120, 255, 120 },
		-- Start and end height, as a share of the text height below its top edge.
		startY = 1.6,
		endY = 0.9,
		seconds = 0.7,
	},
}
