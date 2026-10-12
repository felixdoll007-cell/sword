local ColorMath = require("../src/shared/Rules/ColorMath")
local PetConfig = require("../src/shared/Config/Pets")
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
			elseif entry.id == "pets" then
				expect(entry.enabled).toBe(true)
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

	["the egg stand floats its egg below the sign and opens its window within the server's reach"] = function(expect)
		local stand = Ui.world.eggStand
		expect(stand.pedestalWidth > 0 and stand.pedestalHeight > 0).toBe(true)
		expect(stand.eggScale > 0).toBe(true)
		expect(stand.hoverHeight > 0 and stand.bobHeight >= 0).toBe(true)
		expect(stand.bobSeconds > 0 and stand.turnSeconds > 0).toBe(true)
		-- The window must not open where the server would refuse the hatch.
		expect(stand.promptDistance <= PetConfig.useDistance).toBe(true)
		-- The glowing strips are thin and stick out of the pedestal, but only a little.
		expect(isColor(stand.trim.color)).toBe(true)
		expect(stand.trim.thickness > 0 and stand.trim.thickness < stand.pedestalHeight).toBe(true)
		expect(stand.trim.outset > 0 and stand.trim.outset < stand.trim.thickness).toBe(true)
		-- The lower edge of the sign is above the pedestal and the lowest point of the egg.
		local signBottom = stand.sign.heightAboveFloor - stand.sign.heightStuds / 2
		expect(signBottom > stand.pedestalHeight + stand.hoverHeight + stand.bobHeight).toBe(true)
		expect(stand.sign.nameHeight + stand.sign.pillHeight <= 1).toBe(true)
	end,

	["the egg window names its texts and the pill fits into the HATCH button"] = function(expect)
		local window = Ui.eggWindow
		expect(window.hatchText).toBe("HATCH")
		expect(string.format(window.chanceText, "50")).toBe("50%")
		expect(#window.notEnoughText > 0 and #window.fullText > 0).toBe(true)
		expect(window.pressWaitSeconds >= 0).toBe(true)
		-- Caption left, pill right, both on the button and not on top of each other.
		local places = Ui.button.withPill
		local captionRight = places.captionCenterX + places.captionWidth / 2
		local pillLeft = places.pillCenterX - places.pillWidth / 2
		expect(places.captionCenterX - places.captionWidth / 2 >= 0).toBe(true)
		expect(captionRight <= pillLeft).toBe(true)
		expect(places.pillCenterX + places.pillWidth / 2 <= 1).toBe(true)
		expect(places.pillHeight > 0 and places.pillHeight <= 1).toBe(true)
		expect(isColor(Ui.pill.color)).toBe(true)
		-- A filled tile: darker face, lighter border.
		expect(Ui.tile.filledDarken > 0 and Ui.tile.filledDarken < 1).toBe(true)
		expect(Ui.tile.filledBorderLighten > 0 and Ui.tile.filledBorderLighten < 1).toBe(true)
	end,

	["the hatching display opens by itself after three seconds and wobbles more and more"] = function(expect)
		local hatch = Ui.hatch
		expect(hatch.eggSeconds).toBe(3)
		expect(hatch.petMinSeconds >= 0 and hatch.petSeconds >= 0).toBe(true)
		expect(hatch.wobbleDegrees.to > hatch.wobbleDegrees.from).toBe(true)
		expect(hatch.wobbleDegrees.from >= 0).toBe(true)
		expect(hatch.wobblesPerSecond.to >= hatch.wobblesPerSecond.from).toBe(true)
		expect(hatch.wobblesPerSecond.from > 0).toBe(true)
		expect(hatch.burstSeconds > 0 and hatch.popSeconds > 0 and hatch.flashSeconds > 0).toBe(true)
		expect(hatch.blurSeconds > 0).toBe(true)
		expect(isColor(hatch.flashColor)).toBe(true)
		expect(isColor(hatch.dimColor)).toBe(true)
		expect(hatch.dimTransparency >= 0 and hatch.dimTransparency < 1).toBe(true)
		expect(hatch.hatchHintText).toBe("TAP TO HATCH")
		expect(string.format(hatch.bonusText, "5")).toBe("+5%")
		-- Picture and texts fit between the top of the screen and the line at the bottom, on a
		-- screen that is as wide as it is high or wider.
		local textsBottom = hatch.pictureCenterY
			+ hatch.pictureShare * (0.5 + hatch.nameHeight + hatch.rarityHeight + hatch.bonusHeight)
		expect(hatch.pictureCenterY - hatch.pictureShare / 2 >= 0).toBe(true)
		expect(textsBottom <= hatch.hintCenterY - hatch.hintHeight / 2).toBe(true)
		expect(hatch.hintCenterY + hatch.hintHeight / 2 <= 1).toBe(true)
	end,

	["the rays behind the egg are an even number of faint, slowly turning rays"] = function(expect)
		local rays = Ui.hatch.rays
		expect(rays.count >= 2 and rays.count % 2 == 0).toBe(true)
		expect(rays.stripsPerRay >= 1 and rays.stripsPerRay % 1 == 0).toBe(true)
		-- Sparing for weak phones: every strip is one element that turns every frame.
		expect(rays.count / 2 * rays.stripsPerRay <= 40).toBe(true)
		expect(rays.thickness > 0 and rays.thickness < 0.2).toBe(true)
		expect(rays.reach >= 0.5).toBe(true)
		expect(rays.transparency > 0 and rays.transparency < 1).toBe(true)
		expect(rays.turnSeconds >= 10).toBe(true)
		expect(isColor(rays.color)).toBe(true)
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
