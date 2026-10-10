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

	-- Strength, currency and rebirths, plain text side by side at the top center. Still without design (Version 4).
	stats = {
		strengthPrefix = "Strength: ",
		-- The currency has no name yet (open point in the design); this is a placeholder.
		currencyPrefix = "Coins: ",
		rebirthsPrefix = "Rebirths: ",
		heightScale = 0.06,
		minHeight = 28,
		-- Width of each of the three texts.
		widthScale = 0.26,
		positionY = 0.02,
		textColor = { 255, 255, 255 },
		strokeColor = { 0, 0, 0 },
		-- During a throw the values count up wall by wall instead of following the server
		-- (which has already credited everything). Safety: never hold them longer than this.
		maxHoldSeconds = 12,
	},

	-- "+..." when the sword breaks a wall (currency of that wall). It appears at the wall and then
	-- travels along above the sword. Sizes in studs, so it scales with the 3D view.
	-- It is drawn behind all screen elements, so it never covers the button or the values at the top.
	wallPopup = {
		color = { 255, 220, 80 },
		widthStuds = 8,
		heightStuds = 2.5,
		-- How far above the sword.
		heightAboveSword = 2.5,
		riseStuds = 4,
		seconds = 0.9,
		-- Zone bonus: own color, bigger, a bit higher.
		zoneColor = { 120, 255, 120 },
		zoneSizeFactor = 1.6,
		zoneExtraHeight = 3,
		-- At most this many labels at the same time. More are added into the newest label.
		maxActive = 6,
	},

	-- Button that opens the rebirth window. On the left edge at mid height: clear of the thumbstick
	-- (bottom left), the jump button (bottom right), the meter (right) and the THROW button (bottom center).
	rebirthButton = {
		text = "REBIRTH",
		-- The button fits inside this share of the screen (so it stays small on a phone held upright)
		-- and keeps its shape: width = height * aspectRatio.
		widthScale = 0.22,
		heightScale = 0.09,
		aspectRatio = 2.8,
		minWidth = 130,
		minHeight = 48,
		maxWidth = 260,
		maxHeight = 92,
		positionX = 0.015,
		positionY = 0.42,
		color = { 70, 70, 70 },
		-- Color when a rebirth is possible right now.
		readyColor = { 60, 160, 80 },
		textColor = { 255, 255, 255 },
		-- Space between the button's edge and its text, as a share of the button.
		textPadding = 0.12,
	},

	-- Small window with everything about the next rebirth. Sizes as a share of the screen,
	-- with pixel limits so it fits a phone held upright and does not get huge on a monitor.
	rebirthWindow = {
		widthScale = 0.86,
		heightScale = 0.62,
		minWidth = 260,
		minHeight = 300,
		maxWidth = 480,
		maxHeight = 440,
		backgroundColor = { 40, 40, 40 },
		borderColor = { 15, 15, 15 },
		borderThickness = 3,
		textColor = { 255, 255, 255 },
		-- Space around the content and between rows, as a share of the window.
		padding = 0.05,
		rowGap = 0.015,
		-- Row heights as a share of the window height.
		titleHeight = 0.13,
		barHeight = 0.11,
		lineHeight = 0.11,
		hintHeight = 0.09,
		buttonsHeight = 0.2,
		-- Space between a button's edge and its text, as a share of the button.
		buttonTextPadding = 0.12,
		barBackColor = { 20, 20, 20 },
		barFillColor = { 60, 160, 80 },
		confirmColor = { 60, 160, 80 },
		confirmDisabledColor = { 80, 80, 80 },
		closeColor = { 150, 60, 60 },
		-- Share of the buttons row each button takes, and the gap between them.
		buttonWidth = 0.47,
		-- After pressing Confirm, wait this long for the server before the button works again.
		confirmWaitSeconds = 1.5,

		title = "REBIRTH",
		-- %s is replaced: current strength, needed strength.
		progressText = "Strength %s / %s",
		-- %s: strength after the rebirth.
		loseText = "You lose: your Strength (back to %s)",
		keepText = "You keep: Coins, best wall, Rebirths",
		-- %s: multiplier after the rebirth, multiplier now.
		getText = "You get: Strength gains x%s (now x%s)",
		notReadyText = "Not enough Strength yet",
		readyText = "Ready!",
		confirmText = "CONFIRM",
		closeText = "CLOSE",
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
