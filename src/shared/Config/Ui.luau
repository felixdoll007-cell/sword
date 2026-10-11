--!strict
-- Everything about the interface in one place: the font, all colors, sizes, times and texts.
-- The rules behind it are in docs/STYLE.md.
--
-- Order of this file:
--   1. Look: font, colors, borders, corners, stud texture, symbols
--   2. Building blocks: button, menu button, tile, progress bar, window, short message
--   3. Layout: what sits where and how big
--   4. The single elements: throw button, meter, values, menu, windows, "+..." labels
--   5. World: floors, the throw zone and what surrounds it
--
-- Colors are { red, green, blue } from 0 to 255.
-- A size written as { share, min, max } is a share of the screen's shorter side, limited to
-- min and max pixels. So everything stays big enough for a thumb on a phone and does not get
-- huge on a monitor.

return {
	------------------------------------------------------------------------------------------
	-- 1. Look
	------------------------------------------------------------------------------------------

	-- The one font for everything. A name from Enum.Font.
	font = "FredokaOne",

	text = {
		color = { 255, 255, 255 },
		strokeColor = { 0, 0, 0 },
		-- Black border around every letter, as a share of the text height, with pixel limits.
		strokeShare = 0.09,
		minStroke = 1.5,
		maxStroke = 7,
		-- Small hard shadow below the text, as a share of the text height.
		shadowShare = 0.08,
		shadowColor = { 0, 0, 0 },
		-- Scaled text never gets smaller than this.
		minTextSize = 10,
	},

	colors = {
		-- Meaning colors, the same in the whole game.
		confirm = { 76, 201, 60 },
		danger = { 232, 59, 59 },
		positive = { 140, 255, 110 },
		progress = { 52, 140, 255 },
		progressBack = { 205, 210, 220 },
		notice = { 232, 59, 59 },
		-- A button that cannot be pressed right now.
		disabled = { 110, 116, 128 },
		-- The main action of the game (THROW).
		action = { 255, 122, 31 },

		-- The game's own colors.
		strength = { 255, 122, 31 },
		coins = { 255, 205, 40 },
		rebirths = { 96, 165, 230 },
		windowOuter = { 38, 48, 66 },
		windowInner = { 17, 22, 32 },

		-- Menu buttons: dark face, light border.
		menuFace = { 28, 35, 50 },
		menuBorder = { 235, 240, 250 },
		-- Cards inside a window (item tiles, before and after).
		card = { 34, 43, 60 },
		border = { 0, 0, 0 },
		-- Placeholder for the lock.
		lock = { 190, 196, 208 },
	},

	-- Rarity of items: color of the tile's border and of the name. Which weapon has which rarity
	-- is in Config/Weapons.
	rarity = {
		common = { 170, 176, 188 },
		uncommon = { 76, 201, 60 },
		rare = { 52, 140, 255 },
		epic = { 170, 90, 240 },
		legendary = { 255, 205, 40 },
	},
	defaultRarity = "common",

	-- Black border around buttons, bars, windows and tiles, in pixels.
	borderThickness = 3,
	-- Light border of menu buttons and rarity border of tiles, in pixels.
	accentThickness = 3,
	-- How round the corners are: share of the shorter side (0.5 = fully round).
	corners = {
		button = 0.24,
		menuButton = 0.2,
		window = 0.07,
		windowInner = 0.07,
		tile = 0.14,
		card = 0.1,
		bar = 0.5,
		round = 0.5,
	},

	-- Tiled stud texture on buttons, bars and offer cards. One picture for everything: a white stud
	-- on a transparent background, tinted in a lighter tone of the surface it lies on.
	-- image = "" means there is no picture yet: the surfaces are plain.
	studs = {
		image = "",
		-- Size of one tile in pixels.
		tilePixels = 26,
		-- How much lighter than the surface the studs are (0 to 1), and how see-through (0 to 1).
		lighten = 0.35,
		transparency = 0.55,
	},

	-- Pictures for the fixed symbols. "" = not drawn yet, a plain placeholder in the right color
	-- is shown instead.
	icons = {
		strength = "rbxassetid://77200114063167",
		coins = "rbxassetid://76434159593287",
		-- The same picture as on the Rebirth menu button, shown small.
		rebirths = "rbxassetid://106323553177111",
		lock = "",
		check = "",
		close = "",
	},

	------------------------------------------------------------------------------------------
	-- 2. Building blocks
	------------------------------------------------------------------------------------------

	button = {
		-- Darker edge at the bottom, as a share of the button's height. Pressing sinks the face by it.
		edgeShare = 0.13,
		-- How much darker the edge is than the face (0 to 1).
		edgeDarken = 0.35,
		pressSeconds = 0.05,
		-- Grows a little when the mouse is over it. Touch has no hover.
		hoverScale = 1.05,
		hoverSeconds = 0.08,
		-- Room for the text, as a share of the face.
		textWidth = 0.84,
		textHeight = 0.7,
	},

	menuButton = {
		-- Symbol: size as a share of the button, and where its middle sits (0 = top, 1 = bottom).
		-- It may stick out over the top edge a little.
		iconSize = 0.84,
		iconCenterY = 0.42,
		-- Caption at the bottom and progress text at the top, heights as a share of the button.
		labelHeight = 0.3,
		topTextHeight = 0.27,
		-- Room for these two texts, as a share of the button's width. The rest is space to the edge.
		-- All captions of the menu use the same text size: the one at which the longest fits.
		textWidth = 0.8,
		pressScale = 0.93,
		hoverScale = 1.05,
		scaleSeconds = 0.07,
		-- Locked: this dark (0 to 1) and with a lock of this size on it.
		lockedDim = 0.55,
		lockSize = 0.42,
		-- Red dot with "!" at the top right.
		noticeSize = 0.34,
		noticeText = "!",
		-- Middle of the dot (0, 0 = top left corner of the button, 1, 1 = bottom right corner).
		noticeX = 0.94,
		noticeY = 0.06,
		-- Size of the "!" inside the dot.
		noticeMarkSize = 0.8,
	},

	tile = {
		-- Value at the bottom ("+25%"), height as a share of the tile.
		valueHeight = 0.22,
		valueWidth = 0.9,
		-- Check mark (equipped) and lock (not owned) at the top right, as a share of the tile.
		badgeSize = 0.3,
		-- Middle of that badge (0, 0 = top left corner of the tile, 1, 1 = bottom right corner).
		badgeX = 0.9,
		badgeY = 0.1,
		-- Equipped: the border gets this much lighter (0 to 1).
		equippedLighten = 0.45,
		-- Too expensive: this dark (0 to 1).
		dimmed = 0.5,
	},

	progressBar = {
		-- Text on the bar: height as a share of the bar, and space to its ends as a share of its width.
		textHeight = 0.7,
		textInset = 0.04,
	},

	window = {
		outerTransparency = 0.12,
		-- The world behind an open window: blurred and darkened. Roblox can only blur the whole
		-- 3D view, not just the part behind the window.
		blurSize = 14,
		dimColor = { 0, 0, 0 },
		dimTransparency = 0.5,
		-- Opening pops from this scale to full size; closing is quick.
		openFromScale = 0.6,
		openSeconds = 0.2,
		closeToScale = 0.85,
		closeSeconds = 0.07,
		-- Title, symbol and close button stick out over the window's edge. Sizes relative to the
		-- title height (Layout below).
		iconFactor = 1.7,
		closeFactor = 1,
		closeText = "X",
		-- Room for the title, as a share of the window's width.
		titleWidth = 0.7,
		-- How far the middle of the symbol and of the close button sit inside the window's corner,
		-- as a share of their own size. Smaller = sticks out more.
		iconInsetX = 0.25,
		iconInsetY = 0.17,
		closeInset = 0.2,
		-- Space between the window's edge and its inner area, as a share of the title height.
		paddingFactor = 0.3,
		-- Space between the inner area's edge and what is in it, as a share of the inner area.
		innerPadding = 0.03,
		-- Tabs on the left of a window, outside of it. Their size is in the layout below.
		tab = {
			-- The active tab is this much lighter than the others (0 to 1).
			activeLighten = 0.3,
			-- How far a tab reaches under the window's edge, and the space between two tabs, in pixels.
			overlapPixels = 12,
			gapPixels = 6,
			-- Room for the caption, as a share of the tab.
			textWidth = 0.82,
			textHeight = 0.5,
		},
	},

	toast = {
		-- Short message like "Coming soon": pops in, stays, fades.
		staySeconds = 0.9,
		fadeSeconds = 0.35,
		popFromScale = 0.7,
		popSeconds = 0.12,
		-- Middle of the message, from the top of the screen (0 to 1).
		positionY = 0.22,
		height = { share = 0.1, min = 30, max = 64 },
		widthShare = 0.9,
	},

	------------------------------------------------------------------------------------------
	-- 3. Layout (worked out in Rules/UiLayout)
	------------------------------------------------------------------------------------------
	-- Left, at mid height: the menu grid, below it the values.
	-- Bottom center: progress to the next rebirth, above it the THROW button with the meter next
	-- to it. Right: free for now. Top left: free, Roblox's own buttons sit there.

	layout = {
		margin = { share = 0.02, min = 6, max = 16 },
		gap = { share = 0.018, min = 4, max = 10 },
		-- Phone held upright: the thumbstick and the jump button take the bottom of the screen.
		-- Everything at the bottom center moves up by this share of the screen height.
		portraitBottomReserve = 0.2,

		bar = {
			height = { share = 0.075, min = 22, max = 40 },
			-- Width as a share of the screen width, with pixel limits. Upright: almost full width.
			widthShare = 0.36,
			minWidth = 200,
			maxWidth = 520,
			portraitWidthShare = 0.86,
		},

		throwButton = {
			height = { share = 0.17, min = 54, max = 110 },
			-- Width = height * aspectRatio
			aspectRatio = 2.6,
		},

		-- Upright bar with the swinging pointer, right next to the THROW button, standing on the
		-- same line. It is only looked at, never touched; the button stops it.
		meter = {
			-- Height = height of the THROW button * heightFactor. Width = height * aspectRatio.
			heightFactor = 3,
			aspectRatio = 0.16,
			minWidth = 24,
			maxWidth = 60,
			-- Distance to the button, in gaps.
			gapFactor = 2,
		},

		-- "x1.4" after the press, above the THROW button. Sizes relative to the button.
		factorLabel = {
			heightFactor = 0.6,
			widthFactor = 1.5,
		},

		menu = {
			cell = { share = 0.17, min = 52, max = 92 },
			columns = 2,
			-- If the screen is too low for the whole column, the buttons shrink, but never below this.
			minCell = 40,
		},

		stats = {
			-- The one value for the size of the symbols and numbers at the bottom left:
			-- 1 = basic size, 1.25 = a quarter bigger. Change only this to make them bigger or smaller.
			sizeFactor = 1.25,
			-- Basic height of one row, before sizeFactor.
			rowHeight = { share = 0.065, min = 20, max = 36 },
			rowGap = 2,
		},

		window = {
			-- Share of the screen a window takes at most. Each window has its own pixel limits.
			widthShare = 0.9,
			heightShare = 0.84,
			-- Phone held upright: a window fills almost the whole screen.
			portraitWidthShare = 0.94,
			portraitHeightShare = 0.8,
			title = { share = 0.11, min = 30, max = 58 },
			-- Tabs on the left of a window, outside of it. Sizes relative to the title height.
			tabWidthFactor = 2.9,
			tabHeightFactor = 1,
		},
	},

	------------------------------------------------------------------------------------------
	-- 4. The single elements
	------------------------------------------------------------------------------------------

	throwButton = {
		text = "THROW",
		-- Text while the meter runs: the next press stops the pointer.
		stopText = "STOP",
		-- Extra shortcut on keyboards. Touch always works through the button.
		key = "E",
	},

	meter = {
		-- Colors from the ends to the middle.
		endColor = { 232, 59, 59 },
		betweenColor = { 255, 205, 40 },
		middleColor = { 76, 201, 60 },
		-- Where the yellow sits, from the end (0) to the middle (0.5).
		betweenAt = 0.25,
		pointerColor = { 255, 255, 255 },
		-- Pointer height as a share of the bar height, and how far it sticks out on both sides.
		pointerHeightScale = 0.04,
		pointerWidthScale = 1.7,
	},

	factorLabel = {
		decimals = 1,
	},

	-- Strength, Coins and Rebirths below the menu: symbol on the left, number next to it in its color.
	stats = {
		-- During a throw the values count up wall by wall instead of following the server
		-- (which has already credited everything). Safety: never hold them longer than this.
		maxHoldSeconds = 12,
		-- Room for the number, as a share of the row height (the rest is space above and below).
		textHeight = 0.9,
	},

	-- "+..." that rises and fades next to a value whenever it grows.
	gainPopup = {
		-- It starts right of the number. Where it starts and ends in height, as a share of the
		-- value's row (negative = above the row).
		startY = 0,
		endY = -0.9,
		-- Room for the text, as a share of the row's width.
		widthShare = 0.8,
		seconds = 0.8,
	},

	-- "+..." when the sword breaks a wall (Coins of that wall). It appears at the wall and then
	-- travels along above the sword. Sizes in studs, so it scales with the 3D view.
	-- It is drawn behind all screen elements, so it never covers a button or the values.
	wallPopup = {
		widthStuds = 8,
		heightStuds = 2.5,
		-- How far above the sword.
		heightAboveSword = 2.5,
		riseStuds = 4,
		seconds = 0.9,
		-- Zone bonus: own color (positive), bigger, a bit higher.
		zoneSizeFactor = 1.6,
		zoneExtraHeight = 3,
		-- At most this many labels at the same time. More are added into the newest label.
		maxActive = 6,
	},

	-- Progress to the next rebirth, bottom center.
	rebirthBar = {
		-- %s is replaced: current strength, needed strength.
		leftText = "%s / %s",
		-- %s: percent.
		percentText = "%s%%",
		readyText = "READY!",
	},

	-- The menu grid on the left, in this order. A new button is added by adding an entry here.
	--   id: used by the code to know what the button opens.
	--   enabled: the switch. false = shown dark with a lock, pressing it only says "Coming soon".
	--   icon: uploaded picture, 512x512, cut out, without text. The caption is real text.
	menu = {
		entries = {
			-- The shop is planned for purchases with Robux and stays locked until then.
			{ id = "shop", label = "SHOP", icon = "rbxassetid://78881260504747", enabled = false },
			{ id = "rebirth", label = "REBIRTH", icon = "rbxassetid://106323553177111", enabled = true },
			{ id = "pets", label = "PETS", icon = "rbxassetid://138261598867132", enabled = false },
			{ id = "trails", label = "TRAILS", icon = "rbxassetid://103736409902587", enabled = false },
			{ id = "inventory", label = "ITEMS", icon = "rbxassetid://79691833732200", enabled = true },
			{ id = "gifts", label = "GIFTS", icon = "rbxassetid://100679695739473", enabled = false },
		},
		comingSoonText = "Coming soon",
	},

	-- Window with everything about the next rebirth: before and after side by side, a red warning,
	-- the progress bar and the green button.
	rebirthWindow = {
		-- Symbol at the window's corner: the picture of this menu entry.
		menuEntry = "rebirth",
		maxWidth = 560,
		maxHeight = 460,
		title = "REBIRTH",
		beforeTitle = "NOW",
		afterTitle = "AFTER",
		arrowText = ">",
		-- %s: multiplier on all strength gains.
		multiplierText = "x%s",
		multiplierCaption = "STRENGTH GAINS",
		-- %s: strength.
		strengthText = "%s",
		strengthCaption = "STRENGTH",
		warningText = "Your Strength starts over! Coins and weapons stay.",
		confirmText = "REBIRTH",
		notReadyText = "NOT ENOUGH STRENGTH",
		-- After pressing the button, wait this long for the server before it works again.
		confirmWaitSeconds = 1.5,
		-- Heights as a share of the inner area, from top to bottom. The rest is space between them.
		cardsHeight = 0.44,
		warningHeight = 0.12,
		barHeight = 0.13,
		buttonHeight = 0.2,
		-- Width of one card and of the button, as a share of the inner area.
		cardWidth = 0.42,
		arrowWidth = 0.12,
		buttonWidth = 0.7,
		-- Rows inside a card, as a share of the card: title, multiplier, its caption, strength, its caption.
		cardRows = { 0.2, 0.3, 0.13, 0.22, 0.13 },
		-- Room for the text of a row, as a share of the card's width.
		cardTextWidth = 0.9,
		-- Height of the arrow between the cards, as a share of the cards.
		arrowHeight = 0.5,
	},

	-- Window with what the player owns, opened by the ITEMS menu button. It has tabs on its left;
	-- for now one, the weapons as tiles. Pressing the tile of an owned weapon equips it. Nothing is
	-- bought here: weapons are only bought at the pedestals in the world.
	itemsWindow = {
		menuEntry = "inventory",
		maxWidth = 900,
		maxHeight = 520,
		title = "ITEMS",
		weaponsTab = "WEAPONS",
		-- %s: bonus in percent, shown on the tile.
		valueText = "+%s%%",
		-- Below the tile of an owned weapon.
		equippedText = "EQUIPPED",
		equipText = "TAP TO EQUIP",
		-- Below the tile of a weapon the player does not own. %s: price.
		priceText = "%s Coins",
		pedestalHint = "Buy at the pedestal",
		-- After pressing a tile, wait this long before the next press counts.
		pressWaitSeconds = 0.6,
		-- One card per weapon: name, tile, a line of text and a smaller line. Heights as a share
		-- of the card's width.
		minCardWidth = 108,
		maxCardWidth = 190,
		cardGap = 8,
		nameHeight = 0.2,
		statusHeight = 0.2,
		hintHeight = 0.13,
		-- Width of the scroll bar on the right, in pixels.
		scrollBarWidth = 6,
	},

	-- The weapon in a tile: the real 3D model, seen from above at a slight angle, tip to the top right.
	weaponPreview = {
		fieldOfView = 30,
		-- From where the camera looks at the weapon: straight down, moved a little to these sides.
		tiltX = 0.3,
		tiltZ = 0.25,
		-- How big the weapon is in the tile. With 1 it fits whatever its shape; a bit more uses the
		-- corners of the tile, because the weapon lies diagonally.
		fill = 1.15,
		ambient = { 200, 200, 200 },
		lightColor = { 255, 255, 255 },
		lightDirection = { -0.4, -1, -0.3 },
	},

	------------------------------------------------------------------------------------------
	-- 5. World
	------------------------------------------------------------------------------------------
	-- The look of the world in the new style. First part: the throw zone, the pattern for the
	-- rest. Where the throw zone is and how big it is stays in Config/Lane.
	-- Lengths in studs.

	world = {
		-- The one floor picture of the world: a checkerboard with studs
		-- (assets/textures/floor-tile.png, made by tools/textures/make_floor_tile.py).
		-- A floor is one big part in its darker tone with this picture on it, tinted in its
		-- lighter tone. image = "" means the picture is not uploaded yet: floors are plain.
		floorTile = {
			image = "",
			-- Edge length of one checkerboard field. Floors should be a whole number of fields
			-- wide and long, so the pattern is not cut off at an edge.
			fieldStuds = 5,
			-- The picture holds 2 x 2 fields. Only change this together with the picture.
			fieldsPerPicture = 2,
		},

		throwZone = {
			-- Two tones of ember orange.
			darkColor = { 236, 106, 22 },
			lightColor = { 255, 134, 42 },

			-- Slightly raised, darker edge all around the zone. Low enough to walk over.
			rim = {
				color = { 178, 72, 10 },
				width = 1.2,
				-- How far it stands above the floor.
				height = 0.3,
			},

			-- Writing on the floor, in the font of the interface: white with a thick black border.
			label = {
				text = "THROW\nZONE",
				color = { 255, 255, 255 },
				-- Room for the writing on the floor: across the zone and along it.
				widthStuds = 24,
				heightStuds = 13,
				-- Where its middle sits between the throw line (0) and the back edge (1).
				positionShare = 0.5,
				-- How much of that room the writing fills (0 to 1).
				fill = 0.94,
				-- Black border around every letter, as a share of the text height.
				strokeShare = 0.1,
				-- How finely the writing is drawn. Roblox cannot draw text bigger than 100 pixels,
				-- so a higher value does not make it sharper.
				pixelsPerStud = 16,
				-- The writing lies on an invisible plate this far above the floor.
				aboveFloor = 0.03,
				plateThickness = 0.05,
			},
		},

		-- The floor around the throw zone: two tones of calm green. It reaches this far beyond
		-- the zone on each side (front = towards the lane). Lanes, pads and pedestals lie on it.
		surroundings = {
			darkColor = { 74, 148, 70 },
			lightColor = { 90, 166, 82 },
			left = 60,
			right = 60,
			front = 40,
			back = 40,
			-- Its top lies this far below the lane floors, so they stay visible on top of it.
			belowFloor = 0.05,
		},
	},
}
