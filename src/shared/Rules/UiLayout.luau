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
	menu: { cell: Scaled, columns: number, minCell: number },
	stats: { rowHeight: Scaled, rowGap: number },
	window: {
		widthShare: number,
		heightShare: number,
		portraitWidthShare: number,
		portraitHeightShare: number,
		title: Scaled,
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
	local rowHeight = UiLayout.scaled(config.stats.rowHeight, short)
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
function UiLayout.window(
	config: LayoutConfig,
	screenWidth: number,
	screenHeight: number,
	maxWidth: number,
	maxHeight: number
): Window
	local width, height = safe(screenWidth), safe(screenHeight)
	local portrait = UiLayout.isPortrait(width, height)
	local window = config.window
	local titleHeight = UiLayout.scaled(window.title, math.min(width, height))
	local widthShare = if portrait then window.portraitWidthShare else window.widthShare
	local heightShare = if portrait then window.portraitHeightShare else window.heightShare
	return {
		width = math.min(width * widthShare, maxWidth),
		-- The title sticks out over the top edge: leave room for it.
		height = math.max(math.min(height * heightShare - titleHeight / 2, maxHeight), 0),
		titleHeight = titleHeight,
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
