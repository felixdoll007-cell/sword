local ColorMath = require("../src/shared/Rules/ColorMath")
local Ui = require("../src/shared/Config/Ui")

local function isColor(value: any): boolean
	if typeof(value) ~= "table" or #value ~= 3 then
		return false
	end
	for _, part in value do
		if typeof(part) ~= "number" or part < 0 or part > 255 then
			return false
		end
	end
	return true
end

return {
	["darker and lighter tones stay real colors"] = function(expect)
		local orange = { 255, 122, 31 }
		local dark = ColorMath.darken(orange, 0.5)
		expect(dark[1]).toBe(128)
		expect(dark[2]).toBe(61)
		expect(dark[3]).toBe(16)
		local light = ColorMath.lighten(orange, 0.5)
		expect(light[1]).toBe(255)
		expect(light[2]).toBe(189)
		expect(light[3]).toBe(143)
		expect(ColorMath.darken(orange, 0)[2]).toBe(122)
		expect(ColorMath.darken(orange, 1)[1]).toBe(0)
		expect(ColorMath.lighten(orange, 1)[3]).toBe(255)
		-- Out of range and broken amounts are limited, the input is not changed.
		expect(ColorMath.darken(orange, 5)[1]).toBe(0)
		expect(ColorMath.lighten(orange, -5)[3]).toBe(31)
		expect(ColorMath.darken(orange, 0 / 0)[1]).toBe(255)
		expect(isColor(ColorMath.lighten({ 300, -20, 0 / 0 }, 0.3))).toBe(true)
		expect(orange[1]).toBe(255)
	end,

	["every color in the config is a real color"] = function(expect)
		for name, value in Ui.colors do
			if not isColor(value) then
				error(`colors.{name} is not a color`)
			end
		end
		for name, value in Ui.rarity do
			if not isColor(value) then
				error(`rarity.{name} is not a color`)
			end
		end
		expect(isColor(Ui.text.color)).toBe(true)
		expect(isColor(Ui.text.strokeColor)).toBe(true)
	end,

	["the menu has the six buttons in the planned order, each with caption and picture"] = function(expect)
		local order = { "shop", "rebirth", "pets", "trails", "inventory", "gifts" }
		expect(#Ui.menu.entries).toBe(#order)
		local seen = {}
		for index, entry in Ui.menu.entries do
			expect(entry.id).toBe(order[index])
			expect(typeof(entry.enabled)).toBe("boolean")
			expect(#entry.label > 0).toBe(true)
			expect(entry.icon:match("^rbxassetid://%d+$") ~= nil).toBe(true)
			expect(seen[entry.icon]).toBe(nil)
			seen[entry.icon] = true
		end
	end,

	["windows name a menu entry that exists for their symbol"] = function(expect)
		for _, settings in { Ui.rebirthWindow, Ui.itemsWindow } do
			local found = false
			for _, entry in Ui.menu.entries do
				found = found or entry.id == settings.menuEntry
			end
			expect(found).toBe(true)
		end
	end,

	["the shop button is locked and the items button is open"] = function(expect)
		for _, entry in Ui.menu.entries do
			if entry.id == "shop" then
				expect(entry.enabled).toBe(false)
			elseif entry.id == "inventory" then
				expect(entry.enabled).toBe(true)
				expect(entry.label).toBe("ITEMS")
			end
		end
	end,

	["the rows of the rebirth window fit into it"] = function(expect)
		local window = Ui.rebirthWindow
		expect(window.cardsHeight + window.warningHeight + window.barHeight + window.buttonHeight <= 1).toBe(true)
		expect(2 * window.cardWidth + window.arrowWidth <= 1).toBe(true)
		local rows = 0
		for _, share in window.cardRows do
			rows += share
		end
		expect(rows <= 1).toBe(true)
	end,

	["missing symbols are marked as missing, not as broken ids"] = function(expect)
		for name, image in Ui.icons do
			if image ~= "" and not image:match("^rbxassetid://%d+$") then
				error(`icons.{name} is neither empty nor an asset id`)
			end
		end
		expect(Ui.studs.image == "" or Ui.studs.image:match("^rbxassetid://%d+$") ~= nil).toBe(true)
	end,
}
