--!strict
-- Screen elements. Sizes are a share of the screen (0 to 1), with pixel limits so buttons
-- stay big enough for a thumb on phones and do not get huge on big screens.

return {
	throwButton = {
		text = "THROW",
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
}
