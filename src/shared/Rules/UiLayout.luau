--!strict
-- Pure functions that work out where the screen elements sit and how big they are, for any
-- screen size and for a phone held upright or sideways. No Roblox objects here, so "nothing
-- overlaps, everything stays on the screen" can be tested without Studio.
-- All results are in pixels. x and y are measured from the top left of the usable screen.

-- A share of the screen's shorter side, limited to min and max pixels.
export type Scaled = { share: number, min: number, max: number }

export type Rect = { x: number, y: number, width: number, height: number }

export type LayoutConfig = {
	margin: Scaled,
	gap: Scaled,
	portraitBottomReserve: number,
	bar: {
		height: Scaled,
		widthShare: number,
		minWidth: number,
		maxWidth: number,
		portraitWidthShare: number,
	},
	throwButton: { height: Scaled, aspectRatio: number },
	meter: { heightFactor: number, aspectRatio: number, minWidth: number, maxWidth: number, gapFactor: number },
	factorLabel: { heightFactor: number, widthFactor: number },
	eggCard: {
		columns: number,
		heightShare: number,
		portraitHeightShare: number,
		tile: { min: number, max: number },
		titleShare: number,
		gapShare: number,
		padShare: number,
		buttonGapShare: number,
		buttonShare: number,
		buttonMin: number,
		buttonMinWidth: number,
		pillHangShare: number,
		bottomY: number,
	},
	menu: { cell: Scaled, columns: number, minCell: number },
	stats: { sizeFactor: number, rowHeight: Scaled, rowGap: number },
	window: {
		widthShare: number,
		heightShare: number,
		portraitWidthShare: number,
		portraitHeightShare: number,
		title: Scaled,
		tabWidthFactor: number,
		tabHeightFactor: number,
	},
}

export type Hud = {
	portrait: boolean,
	margin: number,
	gap: number,
	bar: Rect,
	throwButton: Rect,
	meter: Rect,
	factorLabel: Rect,
	-- The menu grid: the whole area, and the size of one square button in it.
	menu: Rect,
	menuCell: number,
	menuColumns: number,
	-- The values below the menu: the whole area, and the height of one row in it.
	stats: Rect,
	statsRowHeight: number,
	statsRowGap: number,
}

export type Window = {
	width: number,
	height: number,
	titleHeight: number,
	-- Size of one tab on the left of the window. The width is 0 for a window without tabs.
	tabWidth: number,
	tabHeight: number,
	-- How far the window sits right of the screen's middle, so that window and tabs together
	-- are in the middle.
	offsetX: number,
}

export type EggCard = {
	-- The card on the screen.
	card: Rect,
	rows: number,
	columns: number,
	-- Edge length of one square tile.
	tile: number,
	-- Everything below is measured from the top left of the card.
	title: Rect,
	-- One tile per pet, in their order: row by row, a last row that is not full is centered.
	tiles: { Rect },
	-- The buttons below the tiles, side by side, sharing the whole row.
	buttons: { Rect },
}

export type Grid = {
	columns: number,
	cellWidth: number,
}

local UiLayout = {}

-- Broken sizes (NaN, negative, infinite) count as an empty screen.
local function safe(value: number): number
	if value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return value
end

function UiLayout.isPortrait(width: number, height: number): boolean
	return safe(height) > safe(width)
end

function UiLayout.scaled(size: Scaled, shortSide: number): number
	return math.clamp(safe(shortSide) * size.share, size.min, size.max)
end

-- Where everything of the always visible interface sits.
-- menuCount: number of menu buttons. statCount: number of values shown below them.
function UiLayout.hud(
	config: LayoutConfig,
	screenWidth: number,
	screenHeight: number,
	menuCount: number,
	statCount: number
): Hud
	local width, height = safe(screenWidth), safe(screenHeight)
	local short = math.min(width, height)
	local portrait = UiLayout.isPortrait(width, height)
	local margin = UiLayout.scaled(config.margin, short)
	local gap = UiLayout.scaled(config.gap, short)

	-- The menu grid and the values, first only their sizes.
	local columns = math.max(config.menu.columns, 1)
	local rows = math.ceil(math.max(menuCount, 0) / columns)
	local cell = UiLayout.scaled(config.menu.cell, short)
	local rowHeight = UiLayout.scaled(config.stats.rowHeight, short) * math.max(config.stats.sizeFactor, 0)
	local rowGap = config.stats.rowGap
	local statsHeight = statCount * rowHeight + math.max(statCount - 1, 0) * rowGap

	-- Bottom center: the bar, above it the button, the meter next to the button.
	local bottom = height - (if portrait then height * config.portraitBottomReserve else margin)
	local barHeight = UiLayout.scaled(config.bar.height, short)
	local barWidth = if portrait
		then width * config.bar.portraitWidthShare
		else math.clamp(width * config.bar.widthShare, config.bar.minWidth, config.bar.maxWidth)
	if not portrait then
		-- Sideways the bar must not reach under the menu on the left.
		local menuRight = margin + columns * cell + (columns - 1) * gap
		barWidth = math.min(barWidth, (width / 2 - menuRight - gap) * 2)
	end
	barWidth = math.max(math.min(barWidth, width - 2 * margin), 0)
	local bar: Rect = { x = (width - barWidth) / 2, y = bottom - barHeight, width = barWidth, height = barHeight }

	local buttonHeight = UiLayout.scaled(config.throwButton.height, short)
	local buttonWidth = buttonHeight * config.throwButton.aspectRatio
	local meterHeight = math.max(math.min(buttonHeight * config.meter.heightFactor, bar.y - gap - margin), 0)
	local meterWidth = math.clamp(meterHeight * config.meter.aspectRatio, config.meter.minWidth, config.meter.maxWidth)
	local meterGap = gap * config.meter.gapFactor
	-- The button stays in the middle, so it must leave room for the meter on its right.
	buttonWidth = math.max(math.min(buttonWidth, (width / 2 - margin - meterGap - meterWidth) * 2), 0)
	local throwButton: Rect = {
		x = (width - buttonWidth) / 2,
		y = bar.y - gap - buttonHeight,
		width = buttonWidth,
		height = buttonHeight,
	}
	local meter: Rect = {
		x = throwButton.x + buttonWidth + meterGap,
		y = throwButton.y + buttonHeight - meterHeight,
		width = meterWidth,
		height = meterHeight,
	}
	local factorHeight = buttonHeight * config.factorLabel.heightFactor
	local factorWidth = math.max(math.min(buttonWidth * config.factorLabel.widthFactor, width - 2 * margin), 0)
	local factorLabel: Rect = {
		x = (width - factorWidth) / 2,
		y = throwButton.y - gap - factorHeight,
		width = factorWidth,
		height = factorHeight,
	}

	-- The left column sits at mid height of the room it has. On a narrow screen (a phone held
	-- upright) the column and the bottom center would overlap, so there the room ends above the
	-- "x1.4" label.
	local top = margin
	local columnRight = margin + columns * cell + (columns - 1) * gap
	local narrow = portrait or math.min(throwButton.x, factorLabel.x) < columnRight + gap
	local roomBottom = if narrow then factorLabel.y - gap else height - margin
	local room = math.max(roomBottom - top, 0)

	local betweenMenuAndStats = gap * 2
	local function columnHeight(): number
		return rows * cell + math.max(rows - 1, 0) * gap + betweenMenuAndStats + statsHeight
	end
	if columnHeight() > room and rows > 0 then
		-- Too low for the whole column: smaller buttons, but never below the smallest size.
		local fitting = (room - statsHeight - betweenMenuAndStats - (rows - 1) * gap) / rows
		cell = math.max(math.min(cell, fitting), config.menu.minCell)
	end
	local menuWidth = columns * cell + (columns - 1) * gap
	local menuHeight = rows * cell + math.max(rows - 1, 0) * gap
	local columnTop = top + math.max((room - columnHeight()) / 2, 0)
	local menu: Rect = { x = margin, y = columnTop, width = menuWidth, height = menuHeight }
	local stats: Rect = {
		x = margin,
		y = columnTop + menuHeight + betweenMenuAndStats,
		width = menuWidth,
		height = statsHeight,
	}

	return {
		portrait = portrait,
		margin = margin,
		gap = gap,
		bar = bar,
		throwButton = throwButton,
		meter = meter,
		factorLabel = factorLabel,
		menu = menu,
		menuCell = cell,
		menuColumns = columns,
		stats = stats,
		statsRowHeight = rowHeight,
		statsRowGap = rowGap,
	}
end

-- Size of a window. maxWidth and maxHeight are the window's own pixel limits.
-- hasTabs: the window has tabs on its left, outside of it; they need room on the screen too.
function UiLayout.window(
	config: LayoutConfig,
	screenWidth: number,
	screenHeight: number,
	maxWidth: number,
	maxHeight: number,
	hasTabs: boolean?
): Window
	local width, height = safe(screenWidth), safe(screenHeight)
	local portrait = UiLayout.isPortrait(width, height)
	local window = config.window
	local titleHeight = UiLayout.scaled(window.title, math.min(width, height))
	local widthShare = if portrait then window.portraitWidthShare else window.widthShare
	local heightShare = if portrait then window.portraitHeightShare else window.heightShare
	local tabWidth = if hasTabs then titleHeight * window.tabWidthFactor else 0
	return {
		width = math.max(math.min((width - tabWidth) * widthShare, maxWidth), 0),
		-- The title sticks out over the top edge: leave room for it.
		height = math.max(math.min(height * heightShare - titleHeight / 2, maxHeight), 0),
		titleHeight = titleHeight,
		tabWidth = tabWidth,
		tabHeight = titleHeight * window.tabHeightFactor,
		offsetX = tabWidth / 2,
	}
end

-- The card at the egg stand: a title, the pets that can hatch as square tiles in a grid, below
-- them a row of buttons that share its whole width.
-- Everything in the card is sized by the edge length of a tile. The tile is chosen so that the
-- whole card takes its share of the screen's height, within the smallest and biggest tile and
-- within the room there is. It sits above the middle of the screen, so the egg and its stand
-- below stay visible, and always right of the left column: it never covers the menu or the
-- values. Where the screen is wide enough it sits in the middle of the screen, otherwise in the
-- middle of the room right of the column.
-- menuCount, statCount: as for the always visible interface. tileCount: number of pets shown.
-- buttonCount: number of buttons in the row.
function UiLayout.eggCard(
	config: LayoutConfig,
	screenWidth: number,
	screenHeight: number,
	menuCount: number,
	statCount: number,
	tileCount: number,
	buttonCount: number
): EggCard
	local settings = config.eggCard
	local width, height = safe(screenWidth), safe(screenHeight)
	local hud = UiLayout.hud(config, width, height, menuCount, statCount)

	local count = math.max(math.floor(safe(tileCount)), 0)
	local columns = math.clamp(math.floor(settings.columns), 1, math.max(count, 1))
	local rows = math.max(math.ceil(count / columns), 1)

	-- Height and width of the card in tiles, the height without the buttons.
	local tilesHigh = 2 * settings.padShare
		+ settings.titleShare
		+ settings.gapShare
		+ rows
		+ (rows - 1) * settings.gapShare
		+ settings.buttonGapShare
		+ settings.pillHangShare
	local tilesWide = columns + (columns - 1) * settings.gapShare + 2 * settings.padShare
	-- The tile with which the card is this high. The buttons do not shrink below their minimum.
	local function tileForHeight(cardHeight: number): number
		local tile = cardHeight / (tilesHigh + settings.buttonShare)
		if tile * settings.buttonShare < settings.buttonMin then
			tile = (cardHeight - settings.buttonMin) / tilesHigh
		end
		return tile
	end

	-- The room on the screen: right of the left column, above the progress bar.
	local left = hud.menu.x + hud.menu.width + hud.gap
	local roomWidth = math.max(width - hud.margin - left, 0)
	local roomHeight = math.max(hud.bar.y - hud.gap - hud.margin, 0)
	local share = if width >= height then settings.heightShare else settings.portraitHeightShare
	local tile = math.clamp(tileForHeight(height * share), settings.tile.min, settings.tile.max)
	tile = math.max(math.min(tile, roomWidth / tilesWide, tileForHeight(roomHeight)), 0)

	local gap, pad = tile * settings.gapShare, tile * settings.padShare
	local titleHeight = tile * settings.titleShare
	local buttonHeight = math.max(tile * settings.buttonShare, settings.buttonMin)
	-- Wide enough for the tiles, and for buttons a thumb hits where the screen has the room.
	local buttonTotal = math.max(math.floor(safe(buttonCount)), 0)
	local buttonsWide = buttonTotal * settings.buttonMinWidth + math.max(buttonTotal - 1, 0) * gap + 2 * pad
	local cardWidth = math.max(tile * tilesWide, math.min(buttonsWide, roomWidth))
	local cardHeight = tile * tilesHigh + buttonHeight
	local tilesHeight = rows * tile + (rows - 1) * gap
	-- In the middle of the screen if that keeps it clear of the left column.
	local x = (width - cardWidth) / 2
	if x < left then
		x = left + math.max(roomWidth - cardWidth, 0) / 2
	end
	-- Its lower edge sits above the middle of the screen; on a low screen it moves down as far
	-- as it must to stay on the screen.
	local y = math.max(height * settings.bottomY - cardHeight, hud.margin)

	local inner = cardWidth - 2 * pad
	local tilesTop = pad + titleHeight + gap
	local tiles: { Rect } = {}
	for index = 1, count do
		local row = math.floor((index - 1) / columns)
		local column = (index - 1) % columns
		local inRow = math.min(count - row * columns, columns)
		local rowWidth = inRow * tile + (inRow - 1) * gap
		table.insert(tiles, {
			x = (cardWidth - rowWidth) / 2 + column * (tile + gap),
			y = tilesTop + row * (tile + gap),
			width = tile,
			height = tile,
		})
	end

	local buttonWidth = if buttonTotal > 0 then math.max(inner - (buttonTotal - 1) * gap, 0) / buttonTotal else 0
	local buttons: { Rect } = {}
	for index = 1, buttonTotal do
		table.insert(buttons, {
			x = pad + (index - 1) * (buttonWidth + gap),
			y = tilesTop + tilesHeight + tile * settings.buttonGapShare,
			width = buttonWidth,
			height = buttonHeight,
		})
	end

	return {
		card = { x = x, y = y, width = cardWidth, height = cardHeight },
		rows = rows,
		columns = columns,
		tile = tile,
		title = { x = pad, y = pad, width = inner, height = titleHeight },
		tiles = tiles,
		buttons = buttons,
	}
end

-- How many cards fit side by side into this width, and how wide each one gets.
-- At most `count` columns; cards are never narrower than minCell (except if not even one fits)
-- and never wider than maxCell.
function UiLayout.grid(availableWidth: number, count: number, minCell: number, maxCell: number, gap: number): Grid
	local width = safe(availableWidth)
	local columns = math.floor((width + gap) / (minCell + gap))
	columns = math.clamp(columns, 1, math.max(count, 1))
	local cellWidth = (width - (columns - 1) * gap) / columns
	return { columns = columns, cellWidth = math.max(math.min(cellWidth, maxCell), 0) }
end

return UiLayout
