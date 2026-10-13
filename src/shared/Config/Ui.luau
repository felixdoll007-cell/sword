--!strict
-- Everything about the interface in one place: the font, all colors, sizes, times and texts.
-- The rules behind it are in docs/STYLE.md.
--
-- Order of this file:
--   1. Look: font, colors, borders, corners, stud texture, symbols
--   2. Building blocks: button, pill, menu button, tile, progress bar, window, short message
--   3. Layout: what sits where and how big
--   4. The single elements: throw button, meter, values, menu, windows, "+..." labels
--   5. World: sky and light, the ground, floors, the throw zone and what surrounds it, the
--      zones of the lane, signs, shop pedestals, training lanes, decoration
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
		-- A button with a pill in it (a price): the caption sits left, the pill right. Where
		-- their middles are and how much room they have, as shares of the face.
		withPill = {
			captionCenterX = 0.25,
			captionWidth = 0.38,
			pillCenterX = 0.7,
			pillWidth = 0.5,
			pillHeight = 0.62,
		},
		-- A button with its pill below it (HATCH with its price): the pill lies half on the
		-- button's lower edge and hangs out of it. Where its middle is (1 = the button's lower
		-- edge) and its size, as shares of the button.
		pillBelow = {
			centerY = 1.06,
			width = 0.62,
			height = 0.48,
		},
		-- A button with a symbol left of its caption (the lock on MULTI and AUTO): the symbol is
		-- a square of this share of the face's height; where the middles are and how wide the
		-- caption may be, as shares of the face.
		withIcon = {
			iconSize = 0.5,
			iconCenterX = 0.19,
			captionCenterX = 0.62,
			captionWidth = 0.56,
		},
		-- A glossy button (the buttons of the egg card): its face runs from a light tone at the
		-- top to a strong one at the bottom, with a light strip of shine at the top. No studs.
		gloss = {
			color = { 255, 255, 255 },
			transparency = 0.62,
			-- Space to the left and right and to the top, and the strip's height, as shares of
			-- the face.
			insetX = 0.065,
			y = 0.08,
			height = 0.22,
		},
		-- The key that also presses the button, as a small light badge on its top left corner,
		-- slightly tilted. Size as a share of the button's height; where its middle sits (0, 0 =
		-- top left corner of the button, 1, 1 = bottom right corner).
		keyBadge = {
			size = 0.46,
			x = 0.04,
			y = 0.03,
			-- From this color at the top to the other at the bottom.
			color = { 255, 255, 255 },
			bottomColor = { 217, 221, 230 },
			letterColor = { 20, 22, 28 },
			degrees = -8,
			cornerShare = 0.28,
			textHeight = 0.72,
		},
	},

	-- The dark pill with a symbol and a short text (what something needs or costs). On the signs
	-- in the world and inside buttons.
	pill = {
		color = { 17, 22, 32 },
		-- Black border, as a share of the pill's height.
		borderShare = 0.07,
		-- Symbol and text: heights as a share of the pill's height.
		iconShare = 0.8,
		textShare = 0.72,
		-- Space at both ends, as a share of the pill's width.
		padShare = 0.07,
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
		-- A filled tile (the pets at the egg stand): its face has the color of the rarity, this
		-- much darker, and its border is this much lighter than that color (0 to 1). Its value
		-- is white.
		filledDarken = 0.45,
		-- A glossy tile (the pets at the egg stand): its face runs from a light tone of the
		-- rarity at the top to a strong one at the bottom, with a light strip of shine at the
		-- top and a dark border. Its value is white.
		glossy = {
			-- Top and bottom color per rarity.
			gradients = {
				common = { top = { 213, 220, 229 }, bottom = { 135, 148, 164 } },
				uncommon = { top = { 157, 245, 138 }, bottom = { 46, 165, 74 } },
				rare = { top = { 134, 208, 255 }, bottom = { 42, 110, 224 } },
				epic = { top = { 221, 165, 255 }, bottom = { 130, 56, 220 } },
				legendary = { top = { 255, 240, 122 }, bottom = { 240, 156, 24 } },
			},
			-- A rarity without an entry above: its color, this much lighter at the top and this
			-- much darker at the bottom (0 to 1).
			lighten = 0.5,
			darken = 0.15,
			borderColor = { 20, 22, 28 },
			cornerShare = 0.15,
			-- The strip of shine: color, how see-through, space to the left and right and to the
			-- top, and its height, as shares of the tile.
			glossColor = { 255, 255, 255 },
			glossTransparency = 0.72,
			glossInsetX = 0.057,
			glossY = 0.034,
			glossHeight = 0.17,
			-- The chance at the bottom, height as a share of the tile.
			valueHeight = 0.2,
		},
		filledBorderLighten = 0.4,
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

		-- The card at the egg stand: a title, one square tile per pet that can hatch, below them
		-- the row of buttons. The card is as big as what is in it and sits above the middle of
		-- the screen, right of the menu.
		eggCard = {
			columns = 3,
			-- How high the whole card is, as a share of the screen's height: on a screen that is
			-- wider than high, and on one held upright (bigger there, for the thumb).
			heightShare = 0.36,
			portraitHeightShare = 0.42,
			-- Edge length of a tile in pixels: never smaller or bigger than this, whatever the
			-- share above says. The tiles still shrink if the screen has less room.
			tile = { min = 46, max = 120 },
			-- Everything else in the card, as shares of a tile's edge length.
			titleShare = 0.25,
			-- Between the tiles, and between title and tiles.
			gapShare = 0.09,
			-- From the card's edge to what is in it.
			padShare = 0.14,
			-- Between the tiles and the buttons.
			buttonGapShare = 0.16,
			buttonShare = 0.5,
			-- A button is never lower than this many pixels, so a thumb hits it.
			buttonMin = 48,
			-- And, where the screen has the room, never narrower than this: with small tiles
			-- the card gets wider than its tiles, which then sit in its middle.
			buttonMinWidth = 76,
			-- Room below the buttons for the price pill that hangs out of HATCH.
			pillHangShare = 0.16,
			-- Where the card's lower edge sits (0 = top of the screen, 0.5 = the middle). On a low
			-- screen the card reaches further down.
			bottomY = 0.46,
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
			{ id = "pets", label = "PETS", icon = "rbxassetid://138261598867132", enabled = true },
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
		-- The tabs on the left of the window, from top to bottom.
		weaponsTab = "WEAPONS",
		petsTab = "PETS",
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

	-- The PETS tab of the items window: every pet as a tile with its 3D model, name and bonus.
	-- Pressing a tile equips the pet or takes it off.
	petsPage = {
		-- %s: how many, of how many.
		equippedText = "EQUIPPED %s/%s",
		ownedText = "PETS %s/%s",
		equipBestText = "EQUIP BEST",
		deleteText = "DELETE",
		-- While choosing a pet to delete.
		cancelText = "CANCEL",
		deleteHintText = "Tap the pet you want to delete",
		-- The question before a pet is deleted. %s: name, bonus.
		confirmText = "Delete %s (%s)?",
		confirmYesText = "DELETE",
		confirmNoText = "KEEP",
		emptyText = "No pets yet. Hatch an egg at the egg stand!",
		-- When a further pet does not fit. %s: how many fit.
		limitText = "Only %s pets at once",
		-- %s: bonus in percent, shown on the tile.
		valueText = "+%s%%",
		-- After pressing a tile or a button, wait this long before the next press counts.
		pressWaitSeconds = 0.3,
		-- The strip at the top with the two counts and the two buttons, as a share of the page.
		-- In a window narrower than narrowBelowPixels (phone held upright) the strip has two
		-- rows, counts above buttons, and is twice as high.
		headerHeight = 0.17,
		narrowBelowPixels = 460,
		-- Share of the strip's width each of the two buttons takes, and the room for each count.
		buttonWidth = 0.22,
		countWidth = 0.25,
		-- Heights of counts and buttons as shares of the strip, and the space at its sides.
		countHeight = 0.5,
		buttonHeight = 0.76,
		sidePadding = 0.02,
		-- "No pets yet": where its middle sits (0 = top of the page) and how much room it has.
		emptyCenterY = 0.55,
		emptyWidth = 0.8,
		emptyHeight = 0.2,
		-- One card per pet: name and tile. Height of the name as a share of the card's width.
		-- As many cards side by side as fit without getting narrower than minCardWidth.
		minCardWidth = 108,
		maxCardWidth = 150,
		cardGap = 8,
		nameHeight = 0.2,
		scrollBarWidth = 6,
		-- The question before deleting: a bar over the lower part of the page. Its height and its
		-- distance from the page's edge as shares of the page; inside it, shares of the bar.
		confirmHeight = 0.34,
		confirmInset = 0.03,
		confirmPadding = 0.08,
		confirmTextHeight = 0.34,
		confirmButtonWidth = 0.3,
		confirmButtonHeight = 0.42,
		confirmButtonGap = 0.06,
	},

	-- The card that shows while the player stands at the egg stand: the name of the egg
	-- (Config/Pets), the pets that can hatch as glossy tiles with their chances, and a row of
	-- buttons: HATCH with the price below it, and two that are planned and still locked.
	-- Its sizes are in the layout above (eggCard).
	eggCard = {
		hatchText = "HATCH",
		-- Extra shortcut on keyboards, shown on the button unless the player uses touch.
		-- Touch always works through the button.
		key = "E",
		-- %s: chance in percent.
		chanceText = "%s%%",
		notEnoughText = "Not enough Coins",
		fullText = "Pet inventory full",
		-- After a press, wait this long before the next press counts.
		pressWaitSeconds = 1,
		-- The surface behind it: dark, a little see-through, round corners, a thin light border.
		backColor = { 28, 36, 52 },
		backTransparency = 0.16,
		cornerShare = 0.065,
		borderColor = { 255, 255, 255 },
		borderTransparency = 0.58,
		borderThickness = 2,
		titleColor = { 70, 236, 224 },
		-- How big a pet is in its tile. 1 fits whatever its shape, more fills the tile better.
		petFill = 1.2,
		-- The picture of the pet leaves this share of the tile free at the bottom, for the chance.
		petBottomShare = 0.1,
		-- HATCH: face from top to bottom, and the darker edge below it.
		hatchColors = { top = { 142, 245, 106 }, bottom = { 60, 194, 58 }, edge = { 29, 122, 44 } },
		-- Buttons that are planned but do nothing yet, right of HATCH in this order. They show a
		-- lock, and pressing one only shows the short message below.
		lockedButtons = {
			{
				id = "multi",
				text = "MULTI",
				colors = { top = { 255, 235, 106 }, bottom = { 255, 188, 31 }, edge = { 168, 112, 10 } },
			},
			{
				id = "auto",
				text = "AUTO",
				colors = { top = { 207, 150, 255 }, bottom = { 141, 75, 239 }, edge = { 85, 36, 163 } },
			},
		},
		lockedText = "Coming soon",
	},

	-- What is shown when an egg hatches. The world behind is blurred and darkened, rays turn
	-- slowly behind the egg, and the egg in the middle wobbles more and more. A press opens it
	-- at once, otherwise it opens by itself: a white flash, then the pet with its name, its
	-- rarity in its color and its bonus, and the rays take the color of the rarity. A press closes.
	hatch = {
		-- The egg opens by itself after this many seconds.
		eggSeconds = 3,
		-- The pet stays until the player presses. A press sooner than petMinSeconds after the egg
		-- opened does not count, so a double press does not skip the pet.
		-- petSeconds: closes by itself after this many seconds; 0 = only a press closes.
		petMinSeconds = 0.5,
		petSeconds = 0,

		-- The egg tilts to both sides, more and faster the longer it takes: how far to each side
		-- and how many times per second, from the first moment to the last.
		wobbleDegrees = { from = 2, to = 20 },
		wobblesPerSecond = { from = 2, to = 6 },
		-- Opening: the egg grows to this scale under the flash, then the pet pops in.
		burstScale = 1.5,
		burstSeconds = 0.12,
		popSeconds = 0.3,
		-- The white flash covers the whole screen and fades within this time.
		flashColor = { 255, 255, 255 },
		flashSeconds = 0.45,

		-- The world behind: darkness (0 = black, 1 = not darkened) and how quickly the blur
		-- comes and goes. How strong the blur is, is the same as behind a window (window, blurSize).
		dimColor = { 0, 0, 0 },
		dimTransparency = 0.42,
		blurSeconds = 0.2,

		-- The rays behind the egg, from the middle of the picture outwards, in turns a wide and a
		-- narrow one. Each ray is made of a few narrow strips fanned out, so it gets wider and
		-- fainter towards the outside. No picture.
		rays = {
			-- How many rays. A multiple of four: every strip runs through the middle and makes
			-- two rays, and wide and narrow ones take turns.
			count = 16,
			-- Strips in a wide and in a narrow ray. More strips = a wider ray.
			strips = { wide = 5, narrow = 3 },
			-- Thickness of one strip as a share of the screen's shorter side.
			thickness = 0.05,
			-- How far a ray reaches from the middle, as a share of the screen's longer side.
			-- It fades towards its end.
			reach = 0.55,
			-- How see-through one strip is in the middle (0 = solid, 1 = invisible). Where
			-- strips lie on top of each other the ray is brighter.
			transparency = 0.62,
			-- Color while the egg is closed. After it opened: the color of the pet's rarity.
			color = { 255, 240, 180 },
			-- A full turn takes this many seconds.
			turnSeconds = 28,
		},

		-- A soft, light, round glow right behind the egg and the pet. No picture: rings of the
		-- same faint color lie on top of each other, each smaller than the one before, so the
		-- glow is brightest in the middle.
		glow = {
			color = { 255, 246, 196 },
			-- Across, as a share of the picture's edge length.
			size = 1.3,
			rings = 22,
			-- How see-through one ring is (0 = solid, 1 = invisible).
			ringTransparency = 0.9,
		},

		-- The picture of egg and pet: edge length as a share of the screen's shorter side, and
		-- where its middle sits (0 = top of the screen). A little above the middle, the texts
		-- come below it.
		pictureShare = 0.66,
		pictureCenterY = 0.39,
		-- The egg is this many times as big as the picture; the pet is as big as the picture.
		eggSize = 1.5,
		-- Texts below the pet: heights as shares of the screen's shorter side. They reach into
		-- the lower edge of the picture by textOverlap (there is nothing of the pet down there).
		nameHeight = 0.092,
		rarityHeight = 0.06,
		bonusHeight = 0.069,
		textOverlap = 0.04,
		-- %s: bonus in percent.
		bonusText = "+%s%%",

		-- The line at the bottom of the screen: what a press does now. "" = no line.
		hatchHintText = "TAP TO HATCH",
		closeHintText = "TAP TO CONTINUE",
		-- Where its middle sits (0 = top of the screen), and its height and room as shares of
		-- the screen's shorter side. While the egg is closed the line is big, afterwards small,
		-- below the texts of the pet.
		hatchHintCenterY = 0.89,
		hatchHintHeight = 0.09,
		hintCenterY = 0.95,
		hintHeight = 0.06,
		hintWidth = 0.9,
		-- The line grows to this scale and back, one way in this many seconds.
		hintPulseScale = 1.06,
		hintPulseSeconds = 0.7,
	},

	-- A pet (or the egg) as a 3D model in the interface: seen from the front, a little from the
	-- side and from above.
	petPreview = {
		fieldOfView = 30,
		-- From where the camera looks, in the model's own space (its front is negative Z).
		from = { x = 0.5, y = 0.3, z = -1 },
		-- How big the model is in its tile. 1 fits whatever its shape.
		fill = 1.05,
		ambient = { 205, 205, 205 },
		lightColor = { 255, 255, 255 },
		lightDirection = { -0.4, -1, 0.5 },
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
		-- Sky and light. A mood is one complete set of values; the game starts with startMood.
		-- A later zone can get its own mood by adding one here.
		startMood = "afternoon",
		moods = {
			-- Bright, friendly afternoon: warm sun, soft shadows, lit-up shadow sides.
			afternoon = {
				-- Time of day, 0 to 24. 14.5 = half past two. Later = lower sun, longer shadows.
				clockTime = 14.5,
				-- How high the sun climbs: 0 = straight overhead at noon, more = flatter.
				latitude = 28,
				-- Strength of the sunlight (Roblox default: 2 to 3).
				brightness = 2.0,
				-- Overall exposure: 0 = normal, above = everything brighter, below = darker.
				exposure = 0,
				-- Light inside shadows and on sides turned away from the sun. Brighter = softer.
				shadowLight = { 138, 134, 142 },
				skyLight = { 158, 162, 176 },
				-- Tint of surfaces in the sun (warm) and of those turned away from it.
				sunTint = { 255, 236, 200 },
				shadeTint = { 196, 208, 235 },
				-- How soft the edges of shadows are, 0 to 1 (only with sharper lighting technology).
				shadowSoftness = 0.6,
				-- How much the sky itself lights and tints things, 0 to 1.
				environmentLight = 0.55,
				environmentShine = 0.3,

				-- Haze: the distance fades softly into the sky, no hard end of the world.
				haze = {
					-- How thick the air is, 0 to 1. More = things fade nearer. 0 = no haze.
					density = 0.2,
					-- 0 to 1: how the haze is spread between ground and sky. Lower = more of it low down.
					offset = 0.2,
					-- Extra bright veil at the horizon, 0 to 10.
					horizon = 1.8,
					-- Bright shine around the sun, 0 to 10.
					glare = 0.2,
					-- Color of the haze, and its color towards the sun.
					color = { 206, 226, 250 },
					sunsetColor = { 255, 244, 228 },
				},

				-- Roblox's own sky picture is used (no upload). Size of sun and moon, number of stars.
				sky = {
					sunSize = 14,
					moonSize = 9,
					stars = 0,
				},

				-- Slight glow around bright parts (lanterns, neon).
				glow = {
					intensity = 0.45,
					size = 22,
					-- Only parts brighter than this glow. Lower = more things glow.
					threshold = 1.5,
				},

				-- Color tuning: strong but not garish. 0 = unchanged.
				color = {
					saturation = 0.25,
					contrast = 0.1,
					brightness = 0.01,
					tint = { 255, 251, 244 },
				},
			},
		},

		-- The ground of the whole map: plain calm green, matching the green at the throw zone,
		-- without a pattern. It reaches far beyond everything, so with the haze no end of the
		-- world is seen. Laid from a few very big tiles next to each other.
		ground = {
			color = { 80, 154, 74 },
			-- Height of its surface. Clearly below all floors (they lie at 0.1), so no floor
			-- lies on top of it at almost the same height.
			topY = -0.2,
			thickness = 20,
			-- A part can be at most 2048 studs wide. The ground is tilesPerSide tiles wide and long.
			tileStuds = 2048,
			tilesPerSide = 2,
			-- Middle of the ground: the middle of the lane.
			centerX = 0,
			centerZ = -420,
		},

		-- The one floor picture of the world: a checkerboard with studs
		-- (assets/textures/floor-tile.png, made by tools/textures/make_floor_tile.py).
		-- A floor is one big part in its darker tone with this picture on it, tinted in its
		-- lighter tone. image = "" means the picture is not uploaded yet: floors are plain.
		floorTile = {
			image = "rbxassetid://107582760541822",
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

		-- The main lane. Every zone can have its own look; the paper zone is the first and the
		-- pattern for the others. A zone is named after its material in Config/Walls.
		lane = {
			-- Raised walkways left and right of a zone with a look, along its whole length. They are
			-- scenery, not ground to walk on. From the lane outwards: the edge, a lower inner step
			-- and a higher outer step. Decoration stands on the outer step.
			-- Edge, inner and outer step together should be a whole number of floor pictures wide
			-- (10 studs), see surroundings below.
			walk = {
				-- The edge towards the lane: its width, and how far it stands above the inner step.
				curbWidth = 1,
				curbAbove = 0.2,
				-- Width of each step, and how far it stands above the lane floor.
				innerWidth = 9,
				innerHeight = 1,
				outerWidth = 10,
				outerHeight = 2.5,
				-- Invisible walls around the walkways keep players off them (height as the lane's
				-- barriers, Config/Lane). This is their thickness.
				fenceThickness = 1,
			},

			-- The name of the next zone, floating at the end of a zone, turned towards the camera.
			sign = {
				-- Height of its middle above the lane floor. High enough to be seen over the
				-- first walls from the throw zone.
				heightAboveFloor = 44,
				-- How far behind the last wall of the zone it floats.
				behindZoneEnd = 0,
				-- Room for the name, in studs.
				widthStuds = 44,
				heightStuds = 13,
				-- Further away than this it is not drawn.
				maxDistance = 600,
			},

			-- Thin frame on walls of zones that have one, drawn on the side the thrower sees.
			wallFrame = {
				widthStuds = 0.6,
				-- How finely it is drawn.
				pixelsPerStud = 10,
			},

			-- The look of each zone. A new zone needs only an entry here:
			--   name, nameColor: shown at the end of the zone before it.
			--   floor: two tones of the lane floor. Without it the zone stays plain grey and has
			--     no walkways and no name floating at its end.
			--   walk: two tones of the walkways and the color of their edge.
			--   wall: color of the walls (and of their pieces). On the side the thrower sees it
			--     can carry a thin frame (frameColor), upright stripes (stripes: how many, their
			--     color, and the width of one as a share of the wall's width) and a level band
			--     (band: its color, where its middle sits, 0 = top of the wall and 1 = bottom,
			--     and its height as a share of the wall's height). All three are drawn on the
			--     wall, they are not extra parts.
			--     scratch: true = the wall the weapon bounces off gets a dark scratch.
			--     model: a model shown instead of the plain wall (leave it out for none). The
			--       wall itself stays where it is, invisible, and still decides everything; the
			--       model is only what the player sees. It is made evenly bigger until the part
			--       of it that has to hide the wall (coverWidth x coverHeight x coverDepth, in
			--       studs as modelled) covers the whole wall, its front level with the wall's
			--       front. sinkStuds: it stands this far in the floor, so a foot beam that
			--       reaches into the walkway's edge does not lie level with it.
			--       hit: what the model does when the weapon bounces off it: it rocks by up to
			--       wobbleDegrees, wobbleSwings times within wobbleSeconds, calming down, and it
			--       turns darker by darken (0.3 = 30 %) until the throw is over.
			--   decor: see the paper zone.
			zones = {
				Paper = {
					name = "PAPER",
					nameColor = { 250, 244, 226 },
					-- Two tones of cream.
					floor = { darkColor = { 236, 224, 194 }, lightColor = { 248, 238, 212 } },
					-- Walkways: two tones of calm sand beige, dark red edge towards the lane.
					walk = {
						darkColor = { 214, 190, 150 },
						lightColor = { 228, 206, 168 },
						curbColor = { 140, 28, 40 },
					},
					-- Cream white with a dark red frame, like a paper wall.
					wall = { color = { 250, 245, 230 }, frameColor = { 140, 28, 40 }, scratch = true },
					-- Decoration: scenery on the outer step of the walkways. A fixed list, set by hand,
					-- so it does not look lined up. For every piece:
					--   model: a name from decor.models below.
					--   side: "left" or "right" of the lane, seen from the throw zone.
					--   along: distance from the start of the zone (the throw line), in studs.
					--   across: where on the outer step: 0 = its inner edge, 1 = its outer edge.
					--   turnDegrees: turned this much away from looking straight at the lane.
					--   scale: size, 1 = as modelled. At most decor.maxScaleChange away from 1.
					decor = {
						pieces = {
							-- A lantern on each side at the start of the zone, like a gate.
							{
								model = "paper_lantern",
								side = "left",
								along = 5,
								across = 0.25,
								turnDegrees = 5,
								scale = 1.1,
							},
							{
								model = "paper_lantern",
								side = "right",
								along = 5,
								across = 0.25,
								turnDegrees = -7,
								scale = 1.1,
							},
							-- Left side.
							{
								model = "origami_crane",
								side = "left",
								along = 27,
								across = 0.35,
								turnDegrees = 16,
								scale = 1.08,
							},
							{
								model = "paper_pinwheel",
								side = "left",
								along = 58,
								across = 0.2,
								turnDegrees = -22,
								scale = 0.9,
							},
							{
								model = "paper_lantern",
								side = "left",
								along = 92,
								across = 0.4,
								turnDegrees = 11,
								scale = 0.95,
							},
							-- Right side.
							{
								model = "paper_pinwheel",
								side = "right",
								along = 19,
								across = 0.3,
								turnDegrees = 18,
								scale = 1.05,
							},
							{
								model = "paper_lantern",
								side = "right",
								along = 46,
								across = 0.4,
								turnDegrees = -13,
								scale = 1,
							},
							{
								model = "origami_crane",
								side = "right",
								along = 79,
								across = 0.25,
								turnDegrees = -9,
								scale = 0.92,
							},
							-- Trees at the very outside, behind the other pieces.
							{
								model = "cherry_tree",
								side = "left",
								along = 42,
								across = 0.85,
								turnDegrees = 25,
								scale = 1.12,
							},
							{
								model = "cherry_tree",
								side = "right",
								along = 30,
								across = 0.9,
								turnDegrees = -40,
								scale = 0.9,
							},
							{
								model = "cherry_tree",
								side = "right",
								along = 99,
								across = 0.8,
								turnDegrees = 70,
								scale = 1.05,
							},
						},
					},
				},
				Bamboo = {
					name = "BAMBOO",
					nameColor = { 124, 196, 84 },
					-- Two tones of light, fresh green.
					floor = { darkColor = { 166, 212, 118 }, lightColor = { 184, 226, 136 } },
					-- Walkways: two tones of warm stone grey, dark bamboo green edge towards the lane.
					walk = {
						darkColor = { 150, 143, 132 },
						lightColor = { 168, 161, 149 },
						curbColor = { 44, 96, 52 },
					},
					-- A bamboo wall as a model: canes tied with a cord on a foot beam. color is
					-- the color of its pieces when it breaks.
					wall = {
						color = { 116, 180, 76 },
						scratch = false,
						model = {
							template = "bamboo_wall",
							-- The row of canes.
							coverWidth = 19.9,
							coverHeight = 12,
							coverDepth = 2.4,
							sinkStuds = 0.2,
							hit = {
								wobbleDegrees = 4,
								wobbleSeconds = 0.5,
								wobbleSwings = 3,
								darken = 0.3,
							},
						},
					},
					decor = {
						pieces = {
							-- A stone lantern on each side at the start of the zone, like a gate.
							{
								model = "stone_lantern",
								side = "left",
								along = 6,
								across = 0.5,
								turnDegrees = 6,
								scale = 1.05,
							},
							{
								model = "stone_lantern",
								side = "right",
								along = 6,
								across = 0.5,
								turnDegrees = -8,
								scale = 1.05,
							},
							-- Left side.
							{
								model = "shishi_odoshi",
								side = "left",
								along = 31,
								across = 0.5,
								turnDegrees = 14,
								scale = 1.05,
							},
							{
								model = "stone_lantern",
								side = "left",
								along = 77,
								across = 0.55,
								turnDegrees = 9,
								scale = 0.95,
							},
							-- Right side.
							{
								model = "taiko_drum",
								side = "right",
								along = 52,
								across = 0.55,
								turnDegrees = -12,
								scale = 1.05,
							},
							{
								model = "shishi_odoshi",
								side = "right",
								along = 115,
								across = 0.55,
								turnDegrees = -18,
								scale = 1,
							},
							-- Bamboo at the very outside, behind the other pieces.
							{
								model = "bamboo_cluster",
								side = "left",
								along = 48,
								across = 0.85,
								turnDegrees = 30,
								scale = 1.2,
							},
							{
								model = "bamboo_cluster",
								side = "left",
								along = 109,
								across = 0.8,
								turnDegrees = -65,
								scale = 0.95,
							},
							{
								model = "bamboo_cluster",
								side = "right",
								along = 24,
								across = 0.85,
								turnDegrees = 110,
								scale = 1.05,
							},
							{
								model = "bamboo_cluster",
								side = "right",
								along = 86,
								across = 0.8,
								turnDegrees = -20,
								scale = 1,
							},
						},
					},
				},
				-- The yard of a dojo, the training ground of a fighting school.
				Wood = {
					name = "WOOD",
					nameColor = { 178, 114, 58 },
					-- Two tones of warm, light wood (honey brown).
					floor = { darkColor = { 218, 168, 100 }, lightColor = { 232, 184, 118 } },
					-- Walkways like tatami mats: two tones of greenish beige, dark brown edge
					-- towards the lane.
					walk = {
						darkColor = { 184, 184, 128 },
						lightColor = { 200, 200, 146 },
						curbColor = { 84, 58, 38 },
					},
					-- A wall of planks as a model, modelled as big as the wall. Its planks are
					-- flat, so the scratch stays; color is the color of its pieces.
					wall = {
						color = { 176, 120, 70 },
						scratch = true,
						model = {
							template = "wooden_wall",
							-- Posts and planks together; coverDepth is the planks alone, so their
							-- front lies level with the wall's front and carries the scratch.
							coverWidth = 30,
							coverHeight = 16,
							coverDepth = 1.2,
							sinkStuds = 0,
						},
					},
					decor = {
						pieces = {
							-- A weapon rack on each side at the start of the zone, like a gate.
							{
								model = "weapon_rack",
								side = "left",
								along = 7,
								across = 0.5,
								turnDegrees = 4,
								scale = 1,
							},
							{
								model = "weapon_rack",
								side = "right",
								along = 7,
								across = 0.5,
								turnDegrees = -6,
								scale = 1,
							},
							-- Left side.
							{
								model = "training_dummy",
								side = "left",
								along = 30,
								across = 0.5,
								turnDegrees = 14,
								scale = 1.05,
							},
							{
								model = "ema_rack",
								side = "left",
								along = 67,
								across = 0.55,
								turnDegrees = -7,
								scale = 1,
							},
							{
								model = "training_dummy",
								side = "left",
								along = 86,
								across = 0.55,
								turnDegrees = -22,
								scale = 0.95,
							},
							{
								model = "sake_barrels",
								side = "left",
								along = 121,
								across = 0.55,
								turnDegrees = 9,
								scale = 1,
							},
							-- Right side.
							{
								model = "sake_barrels",
								side = "right",
								along = 28,
								across = 0.55,
								turnDegrees = -11,
								scale = 1.05,
							},
							{
								model = "training_dummy",
								side = "right",
								along = 58,
								across = 0.5,
								turnDegrees = 26,
								scale = 1,
							},
							{
								model = "ema_rack",
								side = "right",
								along = 101,
								across = 0.5,
								turnDegrees = 13,
								scale = 1.05,
							},
						},
					},
				},
				-- No look yet; only its name, announced at the end of the wood zone.
				Stone = {
					name = "STONE",
					nameColor = { 152, 156, 162 },
				},
			},
		},

		-- Signs in the world: floating, always turned to the camera, no board behind them. Built
		-- on each client, because what they say depends on the player looking at them.
		signs = {
			-- Further away than this a sign is not drawn.
			maxDistance = 260,

			-- The dark pill with a symbol and a number (what something needs or costs). Its look
			-- is the same everywhere (pill, further up).
			pill = {
				-- Width as a share of the sign's width.
				widthShare = 0.62,
			},

			-- Above every training lane: what it needs, whether it is open, what it gives.
			training = {
				widthStuds = 16,
				heightStuds = 8.5,
				-- Height of its middle above the lane floor, and how far in front of the pad it floats.
				heightAboveFloor = 13,
				forward = 4,
				-- Heights of its three rows as shares of the sign: pill, status, effect.
				pillHeight = 0.24,
				statusHeight = 0.2,
				effectHeight = 0.44,
				-- %s: the lane's multiplier.
				effectText = "%sx STRENGTH",
				unlockedText = "UNLOCKED",
				lockedText = "LOCKED",
				-- In the pill of a lane that needs no rebirths.
				freeText = "FREE",
			},

			-- Above every shop pedestal: name, bonus, price, and whether this player has it.
			shop = {
				widthStuds = 13,
				heightStuds = 8,
				-- Height of its middle above the lane floor. Above the tip of the longest weapon.
				heightAboveFloor = 14.5,
				-- Heights of its four rows as shares of the sign: name, bonus, pill, status.
				nameHeight = 0.24,
				bonusHeight = 0.19,
				pillHeight = 0.22,
				statusHeight = 0.2,
				-- %s: the bonus in percent: 1.25 becomes "+25% STRENGTH".
				bonusText = "+%s%% STRENGTH",
				-- In the pill of the weapon that costs nothing.
				freeText = "FREE",
				ownedText = "OWNED",
				equippedText = "EQUIPPED",
				lockedText = "LOCKED",
			},
		},

		-- The egg stand: a pedestal in the look of the shop pedestals with glowing top edges, the
		-- egg floating above it, a sign above that. Where it stands is in Config/Pets.
		eggStand = {
			pedestalWidth = 7,
			pedestalHeight = 2,
			-- The top edges of the pedestal are glowing strips. They stick out of the pedestal
			-- by `outset`, so their faces never lie in the faces of the pedestal.
			trim = {
				color = { 60, 232, 226 },
				thickness = 0.4,
				outset = 0.1,
			},
			-- The egg is this many times as big as its template (about twice the old egg).
			eggScale = 1.9,
			-- Its lowest point floats this far above the pedestal; it rises by bobHeight and
			-- sinks again once in bobSeconds, and turns once around itself in turnSeconds.
			hoverHeight = 1,
			bobHeight = 0.5,
			bobSeconds = 2.8,
			turnSeconds = 10,
			-- The card with the HATCH button shows when the player is this close. Must not be
			-- more than the server's useDistance (Config/Pets).
			promptDistance = 10,
			-- The sign above it: the egg's name and a pill with the coin symbol and the price.
			-- High enough to stay clear of the floating egg.
			sign = {
				widthStuds = 13,
				heightStuds = 4.6,
				heightAboveFloor = 14.5,
				nameHeight = 0.46,
				pillHeight = 0.42,
			},
		},

		-- Equipped pets float side by side behind their player. Moved on each client.
		petFollow = {
			-- How far behind the player, and how far apart from each other.
			behind = 4.5,
			spacing = 3.4,
			-- Height of a pet's middle above the middle of the player's body.
			height = 0.3,
			-- They bob up and down this far, once in this many seconds.
			bobHeight = 0.35,
			bobSeconds = 1.7,
			-- How quickly they catch up with their place (bigger = tighter).
			followSpeed = 7,
			-- Pets of players further away from the camera than this are not drawn.
			maxDistance = 140,
			-- Further away from their place than this (teleport, respawn) they jump instead of flying.
			jumpDistance = 60,
		},

		-- The shop pedestals: dark blue-grey with studs.
		shop = {
			pedestal = {
				darkColor = { 38, 48, 66 },
				lightColor = { 54, 66, 90 },
				-- Edge length of one checkerboard field on the pedestal.
				fieldStuds = 2,
			},
		},

		-- Training lanes in their finished look. A lane without a theme stays plain grey and
		-- only gets the new sign.
		training = {
			-- Which lane has which theme: lane number = theme name. Lane 1 is the one next to
			-- the throw zone. A further lane needs a line here and its theme below.
			laneThemes = {
				[1] = "straw",
			},

			-- Sizes of a themed field, the same for every theme. Heights are above the lane floor.
			field = {
				-- Whole width, frame included. The middle column is as wide as the pad (Config/Training).
				width = 20,
				-- How far the field reaches behind the target line, frame included.
				behindTarget = 8,
				-- a) The frame all around.
				frameWidth = 2,
				frameHeight = 0.5,
				-- b) The themed floor left and right of the middle. The stones of the strip's edge
				-- are as high.
				floorHeight = 0.3,
				-- d) The start pad.
				padHeight = 0.3,
				-- c) The stones of the strip's edge leave at least this much of the strip free in
				-- the middle, where the weapon flies.
				minFreeWidth = 3.5,
				-- Invisible walls keep players out of everything in front of the pad.
				fenceThickness = 1,
				-- Tufts of litter are this thick (flat, but clearly above the floor they lie on).
				tuftHeight = 0.25,
			},

			-- White marks on the start pad: a bracket in each corner and an arrow in throw direction.
			padMark = {
				color = { 255, 255, 255 },
				-- Thickness of the lines, length of a bracket's arms and distance of the brackets
				-- from the pad's edge, as shares of the pad's shorter side.
				lineShare = 0.07,
				cornerShare = 0.22,
				insetShare = 0.1,
				-- Length of the arrow as a share of the pad's length, and length of each of the two
				-- bars of its head as a share of the pad's shorter side.
				arrowShare = 0.46,
				arrowHeadShare = 0.24,
				pixelsPerStud = 20,
				aboveFloor = 0.03,
			},

			themes = {
				-- Lane 1x: straw, yellow.
				straw = {
					-- a) Frame: wood brown with studs.
					frame = { darkColor = { 150, 108, 66 }, lightColor = { 170, 126, 80 }, fieldStuds = 1 },
					-- b) Floor: two tones of strong, rich straw yellow with studs.
					floor = { darkColor = { 214, 160, 20 }, lightColor = { 232, 178, 34 }, fieldStuds = 2 },
					-- c) Throw strip: warm light brown like trodden earth, a little lower. Its edge: light stones of different
					-- widths on both sides, from the pad towards the target. share = how much of the
					-- strip's length a stone takes (compared with the others of its side), width = how
					-- far it reaches into the strip.
					strip = {
						color = { 186, 142, 98 },
						stoneColor = { 246, 238, 216 },
						stones = {
							left = {
								{ share = 3, width = 1.6 },
								{ share = 2, width = 0.7 },
								{ share = 3, width = 2.1 },
								{ share = 2, width = 1.1 },
								{ share = 2, width = 1.8 },
							},
							right = {
								{ share = 2, width = 0.8 },
								{ share = 3, width = 2 },
								{ share = 2, width = 1.2 },
								{ share = 3, width = 0.6 },
								{ share = 2, width = 1.5 },
							},
						},
					},
					-- d) Start pad: strong orange with studs.
					pad = { darkColor = { 236, 106, 22 }, lightColor = { 255, 134, 42 }, fieldStuds = 2 },
					-- Pieces that fly off when the weapon hits the target.
					pieceColor = { 240, 196, 64 },

					-- The target at the end of the strip, looking at the player. Its front face lies
					-- where the weapon's flight ends.
					target = {
						model = "straw_target",
						-- The rings are on this side of the model, this far in front of its standing point.
						front = { x = 0, z = -1 },
						faceDistance = 3,
						-- Raises (or, below 0, sinks) the target. The weapon flies 3 studs above the floor.
						lift = 0,
					},

					-- Props on the themed floor. right: sideways from the middle of the lane (negative
					-- = left). forward: distance from the front edge of the pad towards the target.
					-- lift: height above the floor, for a prop that lies on another one.
					props = {
						{ model = "hay_bale", right = -6, forward = 7, turnDegrees = 96 },
						{ model = "hay_bale", right = -6.1, forward = 18, turnDegrees = 82 },
						{ model = "hay_bale", right = -5.9, forward = 17.4, turnDegrees = 104, lift = 2.56 },
						{ model = "hay_bale", right = 6, forward = 12, turnDegrees = 85 },
					},

					-- Flat tufts of straw as litter, simple blocks.
					tuftColor = { 250, 220, 110 },
					tufts = {
						{ right = 5.6, forward = 2.5, turnDegrees = 30, length = 1.5, width = 0.5 },
						{ right = -5.4, forward = 12.5, turnDegrees = -55, length = 1.3, width = 0.45 },
						{ right = 6.4, forward = 20.5, turnDegrees = 70, length = 1.6, width = 0.5 },
						{ right = 1.1, forward = 9, turnDegrees = -20, length = 1.2, width = 0.4 },
						{ right = -0.9, forward = 19, turnDegrees = 48, length = 1.4, width = 0.45 },
						{ right = 5.2, forward = 26, turnDegrees = -35, length = 1.3, width = 0.5 },
					},
				},
			},
		},

		-- Decoration models. They are built on each client from templates in ReplicatedStorage
		-- (the templates live only in the place, see docs). Which zone uses which models is in
		-- the zone's decor entry above.
		--   template: name of the model in the template folder.
		--   front: which direction of the model is its front, in the model's own space. The
		--     front is turned towards the lane.
		--   turnTowardsThrowZoneDegrees: 0 = looks straight at the lane, 90 = looks at the throw zone.
		--   size: the model is shown this many times as big as it was modelled (left out = 1).
		--     A piece's own scale in a zone's list comes on top of it.
		--   maxScaleChange: for a model that may differ more in size than the others (below).
		--   light, float, spin, sway, tip: its small movement. Leave them out and the model
		--     stands still.
		--     sway: the named part rocks by this many degrees to each side, once there and
		--     back in this many seconds: around its own middle, or with aroundTop = true around
		--     its upper edge, like something that hangs.
		decor = {
			templateFolder = "Assets",
			-- Each piece starts its movement this much later than the one before (share of a
			-- whole round), so pieces of the same kind do not move in step.
			rhythmStep = 0.37,
			-- A piece may be this much bigger or smaller than modelled (0.15 = 15 %). Sizes in a
			-- zone's list beyond that are pulled back to this limit.
			maxScaleChange = 0.15,
			-- A zone never shows more pieces than this; further ones in its list are left out.
			maxPiecesPerZone = 12,

			models = {
				paper_lantern = {
					template = "paper_lantern",
					front = { x = -1, z = 0 },
					turnTowardsThrowZoneDegrees = 0,
					-- Weak warm light inside this part, without shadows.
					light = {
						part = "Glow",
						color = { 255, 190, 110 },
						brightness = 0.9,
						-- How far the light reaches, in studs.
						range = 12,
						-- How much the brightness wavers (0 = steady, 0.12 = up to 12 %), and how fast.
						flickerStrength = 0.12,
						flickerSpeed = 2.5,
					},
				},
				origami_crane = {
					template = "origami_crane",
					front = { x = -1, z = 0 },
					turnTowardsThrowZoneDegrees = 0,
					-- Floats up and down: this far from its middle height, one up and down in this
					-- many seconds. The named parts stand still.
					float = {
						stillParts = { "Base", "Rod" },
						heightStuds = 0.25,
						seconds = 4,
					},
				},
				paper_pinwheel = {
					template = "paper_pinwheel",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 0,
					-- The named parts turn around the middle of the axis part; one turn in this
					-- many seconds.
					spin = {
						axisPart = "Hub",
						parts = { "BladesPink", "BladesWhite", "Hub" },
						secondsPerTurn = 6,
					},
				},
				-- Stands still.
				cherry_tree = {
					template = "cherry_tree",
					front = { x = -1, z = 0 },
					turnTowardsThrowZoneDegrees = 0,
				},

				-- The bamboo zone.
				bamboo_cluster = {
					template = "bamboo_cluster",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 0,
					size = 1.4,
					-- One group may be up to 20 % bigger.
					maxScaleChange = 0.2,
					-- The named part rocks very slightly around its own middle: this many degrees
					-- to each side, once there and back in this many seconds.
					sway = {
						part = "Leaves",
						degrees = 1.5,
						seconds = 4.5,
					},
				},
				stone_lantern = {
					template = "stone_lantern",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 0,
					size = 1.8,
					light = {
						part = "Glow",
						color = { 255, 200, 120 },
						brightness = 0.8,
						range = 14,
						flickerStrength = 0.12,
						flickerSpeed = 2.2,
					},
				},
				-- Stands still. Its drum skin looks half at the lane, half at the throw zone.
				taiko_drum = {
					template = "taiko_drum",
					front = { x = 1, z = 0 },
					turnTowardsThrowZoneDegrees = 35,
					size = 1.8,
				},
				shishi_odoshi = {
					template = "shishi_odoshi",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 20,
					size = 1.8,
					-- The named part (the cane) tips around its own middle. The cane was modelled
					-- pouring, its open end 16 degrees below level. At rest it is turned back by
					-- restDegrees, so the open end points slightly up and fills. Every everySeconds
					-- it sinks forward by degrees within downSeconds (pours out), stays down for
					-- holdSeconds and swings back within backSeconds.
					tip = {
						part = "Rocker",
						restDegrees = 26,
						degrees = 28,
						everySeconds = 7,
						downSeconds = 1.2,
						holdSeconds = 0.6,
						backSeconds = 0.9,
					},
				},

				-- The wood zone.
				training_dummy = {
					template = "training_dummy",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 25,
					size = 1.8,
					-- Its cloth waves slightly.
					sway = {
						part = "Cloth",
						degrees = 3,
						seconds = 3,
						aroundTop = true,
					},
				},
				-- Stands still.
				weapon_rack = {
					template = "weapon_rack",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 0,
					size = 1.8,
				},
				-- Stands still.
				sake_barrels = {
					template = "sake_barrels",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 15,
					size = 1.8,
				},
				ema_rack = {
					template = "ema_rack",
					front = { x = 0, z = -1 },
					turnTowardsThrowZoneDegrees = 15,
					size = 1.8,
					-- Its plaques swing very slightly.
					sway = {
						part = "Plaques",
						degrees = 2,
						seconds = 3.6,
						aroundTop = true,
					},
				},
			},
		},

		-- The floor around the throw zone: two tones of calm green. It reaches this far beyond
		-- the zone on each side (front = along the lane). It is laid in pieces next to the zone,
		-- the lane and the lane's walkways, at the same height, never under or over another floor.
		-- Keep each value a whole number of pictures (fieldStuds x fieldsPerPicture = 10 studs),
		-- so the checkerboard continues from one piece to the next.
		-- left stops short of the first training lane, which keeps its old look.
		surroundings = {
			darkColor = { 74, 148, 70 },
			lightColor = { 90, 166, 82 },
			left = 20,
			-- Wide enough that all shop pedestals stand on it.
			right = 70,
			front = 40,
			back = 40,
		},
	},
}
