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
	eggWindow: { tile: Scaled, portraitRows: number, buttonHeight: Scaled, hatchWidthShare: number },
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

-- How far the inner area of a window sits inside the window's edges.
export type Insets = { side: number, top: number, bottom: number }

export type EggWindow = {
	-- The window on the screen. Half its title sticks out above it.
	window: Rect,
	titleHeight: number,
	rows: number,
	columns: number,
	-- Edge length of one square tile.
	tile: number,
	-- Everything below is measured from the top left of the window's inner area.
	-- One tile per pet, in their order: row by row, a last row that is not full is centered.
	tiles: { Rect },
	-- The HATCH button, and the room right of it that stays free for later buttons.
	button: Rect,
	spare: Rect,
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

-- Where the inner area of a window starts. The title sticks out over the top edge, so the inner
-- area starts below it.
-- paddingFactor: space between the window's edge and its inner area, as a share of the title height.
function UiLayout.windowInsets(titleHeight: number, paddingFactor: number): Insets
	local title = safe(titleHeight)
	local padding = math.round(title * math.max(safe(paddingFactor), 0))
	return { side = padding, top = math.round(title / 2) + padding, bottom = padding }
end

-- The window at the egg stand: the pets that can hatch as square tiles (sideways one row, a
-- phone held upright several rows), below them the HATCH button on the left and free room for
-- later buttons right of it. The window is as big as what is in it and sits in the bottom
-- center, right above the progress bar.
-- Sideways it stays between the menu on the left and the jump button on the right. Where that
-- leaves too little room (a phone held upright, a square screen) it takes the whole width and
-- covers the left column while it is open.
-- menuCount, statCount: as for the always visible interface. tileCount: number of pets shown.
-- paddingFactor: space between a window's edge and its inner area (see windowInsets).
function UiLayout.eggWindow(
	config: LayoutConfig,
	screenWidth: number,
	screenHeight: number,
	menuCount: number,
	statCount: number,
	tileCount: number,
	paddingFactor: number
): EggWindow
	local settings = config.eggWindow
	local width, height = safe(screenWidth), safe(screenHeight)
	local short = math.min(width, height)
	local hud = UiLayout.hud(config, width, height, menuCount, statCount)
	local margin, gap = hud.margin, hud.gap
	local titleHeight = UiLayout.scaled(config.window.title, short)
	local insets = UiLayout.windowInsets(titleHeight, paddingFactor)

	local count = math.max(math.floor(safe(tileCount)), 0)
	local rows = if hud.portrait then math.max(math.floor(settings.portraitRows), 1) else 1
	rows = math.min(rows, math.max(count, 1))
	local columns = math.max(math.ceil(count / rows), 1)

	-- The room on the screen: from the top (the title sticks out) down to the progress bar.
	local bottom = hud.bar.y - gap
	local top = margin + titleHeight / 2
	local buttonHeight = UiLayout.scaled(settings.buttonHeight, short)
	-- What the window needs around its tiles: its edges, and a gap around and between
	-- everything in the inner area.
	local aroundX = 2 * insets.side + 2 * gap
	local aroundY = insets.top + insets.bottom + 3 * gap + buttonHeight
	local function fittingTile(roomWidth: number): number
		local byWidth = (roomWidth - aroundX - (columns - 1) * gap) / columns
		local byHeight = (bottom - top - aroundY - (rows - 1) * gap) / rows
		return math.max(math.min(UiLayout.scaled(settings.tile, short), byWidth, byHeight), 0)
	end
	local menuRight = hud.menu.x + hud.menu.width
	local tile = fittingTile(2 * (width / 2 - menuRight - gap))
	if hud.portrait or tile < settings.tile.min then
		tile = fittingTile(width - 2 * margin)
	end

	local contentWidth = columns * tile + (columns + 1) * gap
	local tilesHeight = rows * tile + (rows - 1) * gap
	local contentHeight = tilesHeight + buttonHeight + 3 * gap
	local windowWidth = contentWidth + 2 * insets.side
	local windowHeight = contentHeight + insets.top + insets.bottom

	local tiles: { Rect } = {}
	for index = 1, count do
		local row = math.floor((index - 1) / columns)
		local column = (index - 1) % columns
		local inRow = math.min(count - row * columns, columns)
		local rowWidth = inRow * tile + (inRow - 1) * gap
		table.insert(tiles, {
			x = (contentWidth - rowWidth) / 2 + column * (tile + gap),
			y = gap + row * (tile + gap),
			width = tile,
			height = tile,
		})
	end

	local buttonRow = contentWidth - 2 * gap
	local buttonY = tilesHeight + 2 * gap
	local share = settings.hatchWidthShare
	local buttonWidth = buttonRow * (if share ~= share then 1 else math.clamp(share, 0, 1))
	local spareX = gap + buttonWidth + gap
	return {
		window = {
			x = (width - windowWidth) / 2,
			y = math.max(bottom - windowHeight, 0),
			width = windowWidth,
			height = windowHeight,
		},
		titleHeight = titleHeight,
		rows = rows,
		columns = columns,
		tile = tile,
		tiles = tiles,
		button = { x = gap, y = buttonY, width = buttonWidth, height = buttonHeight },
		spare = {
			x = spareX,
			y = buttonY,
			width = math.max(contentWidth - gap - spareX, 0),
			height = buttonHeight,
		},
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
