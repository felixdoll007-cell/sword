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

local function eggCard(screen, buttons: number?): UiLayout.EggCard
	return UiLayout.eggCard(layout, screen.width, screen.height, MENU_COUNT, STAT_COUNT, HATCH_COUNT, buttons or 1)
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

	["the egg card sits above the middle of the screen and never covers menu, values or bar"] = function(expect)
		for _, screen in SCREENS do
			local result = hud(screen)
			local card = eggCard(screen).card
			if not inside(card, screen) then
				error(`the egg card leaves the screen on {screen.name}`)
			end
			for _, name in { "menu", "stats", "bar" } do
				if overlap(card, (result :: any)[name]) then
					error(`the egg card covers {name} on {screen.name}`)
				end
			end
			-- Above the middle, so the egg and its stand below stay visible.
			if card.y + card.height / 2 >= screen.height / 2 then
				error(`the egg card sits too low on {screen.name}`)
			end
			-- Phones and tablets held sideways: in the middle of the screen.
			if screen.width >= screen.height * 1.25 then
				expect(card.x + card.width / 2).toBeNear(screen.width / 2)
			end
		end
	end,

	["the egg card shows the pets in three columns, small but big enough to see"] = function(expect)
		for _, screen in SCREENS do
			local egg = eggCard(screen)
			local card = { width = egg.card.width, height = egg.card.height }
			expect(egg.columns).toBe(3)
			expect(egg.rows).toBe(2)
			expect(#egg.tiles).toBe(HATCH_COUNT)
			if egg.tile < layout.eggCard.tile.min then
				error(`the pet tiles are only {egg.tile} pixels on {screen.name}`)
			end
			expect(inside(egg.title, card)).toBe(true)
			for index, tile in egg.tiles do
				expect(tile.width).toBeNear(egg.tile)
				expect(tile.height).toBeNear(egg.tile)
				if not inside(tile, card) then
					error(`pet tile {index} leaves the egg card on {screen.name}`)
				end
				for other = index + 1, #egg.tiles do
					if overlap(tile, egg.tiles[other]) then
						error(`pet tiles {index} and {other} overlap on {screen.name}`)
					end
				end
				-- Below the title, above the buttons.
				expect(tile.y >= egg.title.y + egg.title.height).toBe(true)
				expect(tile.y + tile.height <= egg.buttons[1].y + 0.001).toBe(true)
			end
			-- Three above, two below, the two in the middle.
			expect(egg.tiles[4].y > egg.tiles[3].y).toBe(true)
			local lastRowMiddle = (egg.tiles[4].x + egg.tiles[5].x + egg.tiles[5].width) / 2
			expect(lastRowMiddle).toBeNear(card.width / 2)
		end
	end,

	["HATCH is as wide as the row and big enough for a thumb; later buttons share the row"] = function(expect)
		for _, screen in SCREENS do
			local egg = eggCard(screen)
			local card = { width = egg.card.width, height = egg.card.height }
			expect(#egg.buttons).toBe(1)
			local button = egg.buttons[1]
			expect(inside(button, card)).toBe(true)
			expect(button.height >= THUMB_PIXELS).toBe(true)
			if button.width < 2 * THUMB_PIXELS then
				error(`HATCH is only {button.width} pixels wide on {screen.name}`)
			end
			-- From the first tile's left edge to the last column's right edge: no empty room.
			expect(button.x).toBeNear(egg.tiles[1].x)
			expect(button.x + button.width).toBeNear(egg.tiles[3].x + egg.tiles[3].width)

			local three = eggCard(screen, 3)
			expect(#three.buttons).toBe(3)
			expect(three.card.width).toBeNear(egg.card.width)
			for index, each in three.buttons do
				expect(inside(each, card)).toBe(true)
				expect(each.width).toBeNear(three.buttons[1].width)
				if index > 1 then
					expect(overlap(each, three.buttons[index - 1])).toBe(false)
				end
			end
			expect(three.buttons[3].x + three.buttons[3].width).toBeNear(button.x + button.width)
		end
	end,

	["the egg card survives broken screen sizes and odd numbers of pets and buttons"] = function(expect)
		for _, size in { { 0, 0 }, { 0 / 0, 0 / 0 }, { -100, 500 }, { math.huge, 400 }, { 1, 1 } } do
			local egg = UiLayout.eggCard(layout, size[1], size[2], MENU_COUNT, STAT_COUNT, HATCH_COUNT, 1)
			local rects = { egg.card, egg.title }
			for _, rect in egg.tiles do
				table.insert(rects, rect)
			end
			for _, rect in egg.buttons do
				table.insert(rects, rect)
			end
			for _, rect in rects do
				for _, value in { rect.x, rect.y, rect.width, rect.height } do
					expect(value == value).toBe(true)
				end
				expect(rect.width >= 0).toBe(true)
				expect(rect.height >= 0).toBe(true)
			end
		end
		local function with(count: number, buttons: number): UiLayout.EggCard
			return UiLayout.eggCard(layout, 390, 786, MENU_COUNT, STAT_COUNT, count, buttons)
		end
		expect(#with(0, 1).tiles).toBe(0)
		expect(#with(0 / 0, 1).tiles).toBe(0)
		expect(#with(-3, 1).tiles).toBe(0)
		expect(#with(5, 0).buttons).toBe(0)
		expect(#with(5, 0 / 0).buttons).toBe(0)
		-- Fewer pets than columns: one row, as many columns as pets.
		expect(with(2, 1).columns).toBe(2)
		expect(with(2, 1).rows).toBe(1)
		expect(with(7, 1).rows).toBe(3)
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
