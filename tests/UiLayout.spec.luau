local UiLayout = require("../src/shared/Rules/UiLayout")
local Ui = require("../src/shared/Config/Ui")

local layout = Ui.layout
local MENU_COUNT = #Ui.menu.entries
local STAT_COUNT = 3
-- Pets shown in the window at the egg stand.
local HATCH_COUNT = 5
-- A button smaller than this is hard to hit with a thumb.
local THUMB_PIXELS = 44

-- Usable screen sizes (Roblox's top bar of 58 pixels already taken off).
local SCREENS = {
	{ name = "small phone sideways", width = 568, height = 262 },
	{ name = "phone sideways", width = 667, height = 317 },
	{ name = "big phone sideways", width = 844, height = 332 },
	{ name = "small phone upright", width = 320, height = 510 },
	{ name = "phone upright", width = 375, height = 609 },
	{ name = "big phone upright", width = 390, height = 786 },
	{ name = "tablet sideways", width = 1024, height = 710 },
	{ name = "tablet upright", width = 768, height = 966 },
	{ name = "laptop", width = 1366, height = 710 },
	{ name = "monitor", width = 1920, height = 1022 },
	{ name = "square", width = 600, height = 600 },
}

local function hud(screen)
	return UiLayout.hud(layout, screen.width, screen.height, MENU_COUNT, STAT_COUNT)
end

local function eggWindow(screen): UiLayout.EggWindow
	return UiLayout.eggWindow(
		layout,
		screen.width,
		screen.height,
		MENU_COUNT,
		STAT_COUNT,
		HATCH_COUNT,
		Ui.window.paddingFactor
	)
end

local function overlap(a: UiLayout.Rect, b: UiLayout.Rect): boolean
	local tolerance = 0.001
	return a.x < b.x + b.width - tolerance
		and b.x < a.x + a.width - tolerance
		and a.y < b.y + b.height - tolerance
		and b.y < a.y + a.height - tolerance
end

local function inside(rect: UiLayout.Rect, screen): boolean
	local tolerance = 0.001
	return rect.x >= -tolerance
		and rect.y >= -tolerance
		and rect.x + rect.width <= screen.width + tolerance
		and rect.y + rect.height <= screen.height + tolerance
end

return {
	["upright and sideways are told apart"] = function(expect)
		expect(UiLayout.isPortrait(390, 786)).toBe(true)
		expect(UiLayout.isPortrait(844, 332)).toBe(false)
		expect(UiLayout.isPortrait(600, 600)).toBe(false)
		expect(UiLayout.isPortrait(0 / 0, 100)).toBe(true)
		expect(UiLayout.isPortrait(100, 0 / 0)).toBe(false)
	end,

	["scaled sizes stay within their pixel limits"] = function(expect)
		local size = { share = 0.1, min = 20, max = 50 }
		expect(UiLayout.scaled(size, 100)).toBe(20)
		expect(UiLayout.scaled(size, 300)).toBeNear(30)
		expect(UiLayout.scaled(size, 5000)).toBe(50)
		expect(UiLayout.scaled(size, 0 / 0)).toBe(20)
		expect(UiLayout.scaled(size, -100)).toBe(20)
	end,

	["everything stays on the screen"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			for _, name in { "bar", "throwButton", "meter", "factorLabel", "menu", "stats" } do
				if not inside((result :: any)[name], screen) then
					error(`{name} leaves the screen on {screen.name}`)
				end
			end
			expect(result.bar.width > 0).toBe(true)
			expect(result.throwButton.width > 0).toBe(true)
			expect(result.meter.height > 0).toBe(true)
		end
	end,

	["nothing overlaps"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			local rects = {
				bar = result.bar,
				throwButton = result.throwButton,
				meter = result.meter,
				menu = result.menu,
				stats = result.stats,
			}
			for first, a in rects do
				for second, b in rects do
					if first < second and overlap(a, b) then
						error(`{first} and {second} overlap on {screen.name}`)
					end
				end
			end
			-- The factor label is only checked against the left column: it sits above the button.
			expect(overlap(result.factorLabel, result.menu)).toBe(false)
			expect(overlap(result.factorLabel, result.stats)).toBe(false)
			expect(overlap(result.factorLabel, result.throwButton)).toBe(false)
		end
	end,

	["the egg window sits in the bottom center, on the screen and above the progress bar"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			local egg = eggWindow(screen)
			local window = egg.window
			-- Half the title sticks out above the window.
			local withTitle: UiLayout.Rect = {
				x = window.x,
				y = window.y - egg.titleHeight / 2,
				width = window.width,
				height = window.height + egg.titleHeight / 2,
			}
			if not inside(withTitle, screen) then
				error(`the egg window leaves the screen on {screen.name}`)
			end
			expect(window.x + window.width / 2).toBeNear(screen.width / 2)
			expect(window.y + window.height <= result.bar.y + 0.001).toBe(true)
			if result.portrait then
				-- Thumbstick and jump button stay free.
				local free = screen.height * (1 - layout.portraitBottomReserve)
				expect(window.y + window.height <= free + 0.001).toBe(true)
			end
			-- Phones and tablets held sideways: between the menu and the jump button.
			if screen.width >= screen.height * 1.25 then
				local menuRight = result.menu.x + result.menu.width
				expect(overlap(window, result.menu)).toBe(false)
				expect(overlap(window, result.stats)).toBe(false)
				expect(window.x + window.width <= screen.width - menuRight + 0.001).toBe(true)
			end
		end
	end,

	["the egg window shows one row of pets sideways and two rows upright, big enough to see"] = function(expect)
		for _, screen in SCREENS do
			local egg = eggWindow(screen)
			local insets = UiLayout.windowInsets(egg.titleHeight, Ui.window.paddingFactor)
			local inner = {
				width = egg.window.width - 2 * insets.side,
				height = egg.window.height - insets.top - insets.bottom,
			}
			expect(#egg.tiles).toBe(HATCH_COUNT)
			if UiLayout.isPortrait(screen.width, screen.height) then
				expect(egg.rows).toBe(2)
				expect(egg.columns).toBe(3)
			else
				expect(egg.rows).toBe(1)
				expect(egg.columns).toBe(HATCH_COUNT)
			end
			if egg.tile < layout.eggWindow.tile.min then
				error(`the pet tiles are only {egg.tile} pixels on {screen.name}`)
			end
			for index, tile in egg.tiles do
				expect(tile.width).toBeNear(egg.tile)
				expect(tile.height).toBeNear(egg.tile)
				if not inside(tile, inner) then
					error(`pet tile {index} leaves the egg window on {screen.name}`)
				end
				for other = index + 1, #egg.tiles do
					if overlap(tile, egg.tiles[other]) then
						error(`pet tiles {index} and {other} overlap on {screen.name}`)
					end
				end
				-- The button row is below every tile.
				expect(tile.y + tile.height <= egg.button.y + 0.001).toBe(true)
			end
			-- The tiles of a row that is not full sit in the middle.
			local last = egg.tiles[#egg.tiles]
			local firstOfLastRow = egg.tiles[(egg.rows - 1) * egg.columns + 1]
			expect(firstOfLastRow.x + (last.x + last.width - firstOfLastRow.x) / 2).toBeNear(inner.width / 2)
		end
	end,

	["HATCH is big enough for a thumb and leaves room for later buttons on its right"] = function(expect)
		for _, screen in SCREENS do
			local egg = eggWindow(screen)
			local insets = UiLayout.windowInsets(egg.titleHeight, Ui.window.paddingFactor)
			local inner = {
				width = egg.window.width - 2 * insets.side,
				height = egg.window.height - insets.top - insets.bottom,
			}
			expect(inside(egg.button, inner)).toBe(true)
			expect(inside(egg.spare, inner)).toBe(true)
			expect(egg.button.height >= THUMB_PIXELS).toBe(true)
			if egg.button.width < 2 * THUMB_PIXELS then
				error(`HATCH is only {egg.button.width} pixels wide on {screen.name}`)
			end
			-- The free room: right of HATCH, on the same line, wide enough for one more button.
			expect(egg.spare.x >= egg.button.x + egg.button.width).toBe(true)
			expect(egg.spare.y).toBe(egg.button.y)
			expect(egg.spare.height).toBe(egg.button.height)
			if egg.spare.width < THUMB_PIXELS then
				error(`only {egg.spare.width} pixels stay free next to HATCH on {screen.name}`)
			end
		end
		-- With the whole row for HATCH nothing stays free.
		local whole = table.clone(layout)
		whole.eggWindow = table.clone(layout.eggWindow)
		whole.eggWindow.hatchWidthShare = 1
		local full = UiLayout.eggWindow(whole, 844, 332, MENU_COUNT, STAT_COUNT, HATCH_COUNT, Ui.window.paddingFactor)
		expect(full.spare.width).toBe(0)
	end,

	["the egg window survives broken screen sizes and odd numbers of pets"] = function(expect)
		for _, size in { { 0, 0 }, { 0 / 0, 0 / 0 }, { -100, 500 }, { math.huge, 400 }, { 1, 1 } } do
			local egg = UiLayout.eggWindow(
				layout,
				size[1],
				size[2],
				MENU_COUNT,
				STAT_COUNT,
				HATCH_COUNT,
				Ui.window.paddingFactor
			)
			local rects = { egg.window, egg.button, egg.spare }
			for _, tile in egg.tiles do
				table.insert(rects, tile)
			end
			for _, rect in rects do
				for _, value in { rect.x, rect.y, rect.width, rect.height } do
					expect(value == value).toBe(true)
				end
				expect(rect.width >= 0).toBe(true)
				expect(rect.height >= 0).toBe(true)
			end
		end
		local function with(count: number): UiLayout.EggWindow
			return UiLayout.eggWindow(layout, 390, 786, MENU_COUNT, STAT_COUNT, count, Ui.window.paddingFactor)
		end
		expect(#with(0).tiles).toBe(0)
		expect(#with(0 / 0).tiles).toBe(0)
		expect(#with(-3).tiles).toBe(0)
		-- One pet upright: one row with one tile, not two rows.
		expect(with(1).rows).toBe(1)
		expect(#with(1).tiles).toBe(1)
		expect(with(6).columns).toBe(3)
		expect(with(7).columns).toBe(4)
	end,

	["the inner area of a window starts below its title"] = function(expect)
		local insets = UiLayout.windowInsets(40, 0.3)
		expect(insets.side).toBe(12)
		expect(insets.bottom).toBe(12)
		expect(insets.top).toBe(32)
		local broken = UiLayout.windowInsets(0 / 0, 0 / 0)
		expect(broken.side).toBe(0)
		expect(broken.top).toBe(0)
	end,

	["menu buttons are squares big enough for a thumb, in two columns"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			expect(result.menuColumns).toBe(2)
			if result.menuCell < THUMB_PIXELS then
				error(`menu buttons are only {result.menuCell} pixels on {screen.name}`)
			end
			expect(result.menu.width).toBeNear(2 * result.menuCell + result.gap)
			expect(result.menu.height).toBeNear(3 * result.menuCell + 2 * result.gap)
		end
	end,

	["the throw button is big enough for a thumb and sits in the middle"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			expect(result.throwButton.height >= THUMB_PIXELS).toBe(true)
			expect(result.throwButton.width >= 2 * THUMB_PIXELS).toBe(true)
			expect(result.throwButton.x + result.throwButton.width / 2).toBeNear(screen.width / 2)
			expect(result.bar.x + result.bar.width / 2).toBeNear(screen.width / 2)
		end
	end,

	["upright, the bottom of the screen stays free for thumbstick and jump button"] = function(_expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			if result.portrait then
				local free = screen.height * (1 - layout.portraitBottomReserve)
				for _, name in { "bar", "throwButton", "meter", "menu", "stats" } do
					local rect: UiLayout.Rect = (result :: any)[name]
					if rect.y + rect.height > free + 0.001 then
						error(`{name} reaches into the bottom of the screen on {screen.name}`)
					end
				end
			end
		end
	end,

	["sideways, the bottom center stays between thumbstick and jump button"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			-- Only for screens clearly wider than high: phones and tablets held sideways.
			if screen.width >= screen.height * 1.25 then
				-- The meter is the element furthest to the right. It keeps a quarter of the screen free.
				expect(result.meter.x + result.meter.width <= screen.width * 0.75).toBe(true)
				expect(result.bar.x >= result.menu.x + result.menu.width).toBe(true)
			end
		end
	end,

	["the meter stands next to the button, on the same line"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			expect(result.meter.x > result.throwButton.x + result.throwButton.width).toBe(true)
			expect(result.meter.y + result.meter.height).toBeNear(result.throwButton.y + result.throwButton.height)
			expect(result.meter.height > result.meter.width * 3).toBe(true)
		end
	end,

	["the values sit below the menu, with one row each"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			expect(result.stats.y > result.menu.y + result.menu.height).toBe(true)
			expect(result.stats.x).toBe(result.menu.x)
			expect(result.stats.height).toBeNear(
				STAT_COUNT * result.statsRowHeight + (STAT_COUNT - 1) * result.statsRowGap
			)
		end
	end,

	["the size factor of the values makes their rows bigger, and the layout still holds"] = function(expect)
		local bigger = table.clone(layout)
		bigger.stats = table.clone(layout.stats)
		bigger.stats.sizeFactor = layout.stats.sizeFactor * 2
		local normal = UiLayout.hud(layout, 1920, 1022, MENU_COUNT, STAT_COUNT)
		local doubled = UiLayout.hud(bigger, 1920, 1022, MENU_COUNT, STAT_COUNT)
		expect(doubled.statsRowHeight).toBeNear(normal.statsRowHeight * 2)
		expect(doubled.stats.y + doubled.stats.height <= 1022).toBe(true)
	end,

	["a broken or empty screen size does not crash"] = function(expect)
		for _, size in { { 0, 0 }, { 0 / 0, 0 / 0 }, { -100, 500 }, { math.huge, 400 }, { 1, 1 } } do
			local result = UiLayout.hud(layout, size[1], size[2], MENU_COUNT, STAT_COUNT)
			for _, name in { "bar", "throwButton", "meter", "factorLabel", "menu", "stats" } do
				local rect: UiLayout.Rect = (result :: any)[name]
				for _, value in { rect.x, rect.y, rect.width, rect.height } do
					expect(value == value).toBe(true)
				end
				expect(rect.width >= 0).toBe(true)
				expect(rect.height >= 0).toBe(true)
			end
		end
		expect(UiLayout.hud(layout, 800, 400, 0, 0).menu.height).toBe(0)
	end,

	["windows fit the screen and fill a phone held upright almost completely"] = function(expect)
		for _, screen in SCREENS do
			for _, settings in { Ui.rebirthWindow, Ui.itemsWindow } do
				local window =
					UiLayout.window(layout, screen.width, screen.height, settings.maxWidth, settings.maxHeight)
				-- Half the title sticks out at the top.
				expect(window.height + window.titleHeight / 2 <= screen.height).toBe(true)
				expect(window.width <= screen.width).toBe(true)
				expect(window.width <= settings.maxWidth).toBe(true)
				expect(window.height <= settings.maxHeight).toBe(true)
				expect(window.width > 0 and window.height > 0).toBe(true)
			end
		end
		local phone = UiLayout.window(layout, 390, 786, Ui.itemsWindow.maxWidth, Ui.itemsWindow.maxHeight)
		expect(phone.width >= 390 * 0.9).toBe(true)
		local broken = UiLayout.window(layout, 0 / 0, -5, 500, 400)
		expect(broken.width).toBe(0)
		expect(broken.height).toBe(0)
	end,

	["a window with tabs leaves room for them and sits in the middle together with them"] = function(expect)
		for _, screen in SCREENS do
			local settings = Ui.itemsWindow
			local plain = UiLayout.window(layout, screen.width, screen.height, settings.maxWidth, settings.maxHeight)
			local tabbed =
				UiLayout.window(layout, screen.width, screen.height, settings.maxWidth, settings.maxHeight, true)
			expect(plain.tabWidth).toBe(0)
			expect(plain.offsetX).toBe(0)
			expect(tabbed.tabWidth > 0).toBe(true)
			expect(tabbed.tabHeight > 0).toBe(true)
			expect(tabbed.width <= plain.width).toBe(true)
			-- Left end of the tabs and right end of the window, measured from the screen's left edge.
			local left = screen.width / 2 + tabbed.offsetX - tabbed.width / 2 - tabbed.tabWidth
			local right = screen.width / 2 + tabbed.offsetX + tabbed.width / 2
			expect(left >= 0).toBe(true)
			expect(right <= screen.width).toBe(true)
			expect(left).toBeNear(screen.width - right)
			expect(tabbed.width > tabbed.tabWidth).toBe(true)
		end
	end,

	["cards fill the width in as many columns as fit"] = function(expect)
		local five = UiLayout.grid(700, 5, 108, 190, 8)
		expect(five.columns).toBe(5)
		expect(five.cellWidth).toBeNear((700 - 4 * 8) / 5)
		local narrow = UiLayout.grid(330, 5, 108, 190, 8)
		expect(narrow.columns).toBe(2)
		expect(narrow.cellWidth).toBeNear((330 - 8) / 2)
		-- Never more columns than cards, never wider than the limit.
		local wide = UiLayout.grid(2000, 5, 108, 190, 8)
		expect(wide.columns).toBe(5)
		expect(wide.cellWidth).toBe(190)
		-- Too narrow for one card: still one column, as wide as there is room.
		local tiny = UiLayout.grid(60, 5, 108, 190, 8)
		expect(tiny.columns).toBe(1)
		expect(tiny.cellWidth).toBe(60)
		expect(UiLayout.grid(0 / 0, 5, 108, 190, 8).cellWidth).toBe(0)
		expect(UiLayout.grid(500, 0, 108, 190, 8).columns).toBe(1)
	end,
}
