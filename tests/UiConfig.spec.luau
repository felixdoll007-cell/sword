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

	["the egg card names its texts and colors, and its buttons carry what the design shows"] = function(expect)
		local card = Ui.eggCard
		expect(card.hatchText).toBe("HATCH")
		expect(card.key).toBe("E")
		expect(string.format(card.chanceText, "50")).toBe("50%")
		expect(#card.notEnoughText > 0 and #card.fullText > 0).toBe(true)
		expect(card.pressWaitSeconds >= 0).toBe(true)
		-- Dark and a little see-through, with a thin light border and a turquoise title.
		expect(isColor(card.backColor)).toBe(true)
		expect(isColor(card.titleColor)).toBe(true)
		expect(isColor(card.borderColor)).toBe(true)
		expect(card.backTransparency > 0 and card.backTransparency < 1).toBe(true)
		expect(card.borderTransparency >= 0 and card.borderTransparency < 1).toBe(true)
		expect(card.borderThickness > 0).toBe(true)
		expect(card.petFill >= 1 and card.petFill <= 1.5).toBe(true)
		expect(card.petBottomShare >= 0 and card.petBottomShare < 0.5).toBe(true)
		-- HATCH and the two planned buttons, each with its own colors.
		local sets = { card.hatchColors }
		expect(#card.lockedButtons).toBe(2)
		expect(card.lockedButtons[1].text).toBe("MULTI")
		expect(card.lockedButtons[2].text).toBe("AUTO")
		expect(card.lockedText).toBe("Coming soon")
		for _, button in card.lockedButtons do
			expect(#button.id > 0).toBe(true)
			table.insert(sets, button.colors)
		end
		for _, colors in sets do
			expect(isColor(colors.top) and isColor(colors.bottom) and isColor(colors.edge)).toBe(true)
		end
		-- The key: a small light badge, slightly tilted.
		local badge = Ui.button.keyBadge
		expect(isColor(badge.color) and isColor(badge.bottomColor) and isColor(badge.letterColor)).toBe(true)
		expect(badge.size > 0 and badge.size < 1).toBe(true)
		expect(math.abs(badge.degrees) <= 20).toBe(true)
		-- The pill below HATCH lies on the button's lower edge and is not wider than the button.
		local below = Ui.button.pillBelow
		expect(below.centerY - below.height / 2 < 1 and below.centerY + below.height / 2 > 1).toBe(true)
		expect(below.width > 0 and below.width <= 1).toBe(true)
		-- What hangs out fits into the room the layout leaves below the buttons.
		local hang = (below.centerY + below.height / 2 - 1) * Ui.layout.eggCard.buttonShare
		expect(hang <= Ui.layout.eggCard.pillHangShare + Ui.layout.eggCard.padShare).toBe(true)
		-- The lock and the caption share the face without lying on top of each other.
		local icon = Ui.button.withIcon
		expect(icon.iconSize > 0 and icon.iconSize < 1).toBe(true)
		expect(icon.captionCenterX - icon.captionWidth / 2 > icon.iconCenterX).toBe(true)
		expect(icon.captionCenterX + icon.captionWidth / 2 <= 1).toBe(true)
		local gloss = Ui.button.gloss
		expect(isColor(gloss.color)).toBe(true)
		expect(gloss.transparency > 0 and gloss.transparency < 1).toBe(true)
		expect(gloss.y + gloss.height < 0.5 and gloss.insetX < 0.5).toBe(true)
		-- Caption left, pill right inside a button: both on it and not on top of each other.
		local places = Ui.button.withPill
		expect(places.captionCenterX + places.captionWidth / 2 <= places.pillCenterX - places.pillWidth / 2).toBe(true)
		expect(places.pillCenterX + places.pillWidth / 2 <= 1).toBe(true)
		expect(isColor(Ui.pill.color)).toBe(true)
	end,

	["tiles have their filled and their glossy look for every rarity"] = function(expect)
		-- A filled tile: darker face, lighter border.
		expect(Ui.tile.filledDarken > 0 and Ui.tile.filledDarken < 1).toBe(true)
		expect(Ui.tile.filledBorderLighten > 0 and Ui.tile.filledBorderLighten < 1).toBe(true)
		-- A glossy tile: two tones per rarity, light at the top, strong at the bottom.
		local glossy = Ui.tile.glossy
		for rarity in Ui.rarity do
			local tones = (glossy.gradients :: any)[rarity]
			if not tones or not isColor(tones.top) or not isColor(tones.bottom) then
				error(`the glossy tile has no two tones for {rarity}`)
			end
			local top, bottom = tones.top, tones.bottom
			expect(top[1] + top[2] + top[3] > bottom[1] + bottom[2] + bottom[3]).toBe(true)
		end
		for rarity in glossy.gradients do
			expect((Ui.rarity :: any)[rarity] ~= nil).toBe(true)
		end
		expect(glossy.lighten > 0 and glossy.lighten < 1 and glossy.darken >= 0 and glossy.darken < 1).toBe(true)
		expect(isColor(glossy.borderColor) and isColor(glossy.glossColor)).toBe(true)
		expect(glossy.glossTransparency > 0 and glossy.glossTransparency < 1).toBe(true)
		expect(glossy.glossY + glossy.glossHeight < 0.5 and glossy.glossInsetX < 0.5).toBe(true)
		expect(glossy.valueHeight > 0 and glossy.valueHeight < 0.5).toBe(true)
		expect(glossy.cornerShare > 0 and glossy.cornerShare <= 0.5).toBe(true)
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
			+ hatch.pictureShare / 2
			- hatch.textOverlap
			+ hatch.nameHeight
			+ hatch.rarityHeight
			+ hatch.bonusHeight
		expect(hatch.pictureCenterY - hatch.pictureShare / 2 >= 0).toBe(true)
		expect(textsBottom <= hatch.hintCenterY - hatch.hintHeight / 2).toBe(true)
		expect(hatch.hintCenterY + hatch.hintHeight / 2 <= 1).toBe(true)
		-- While the egg is closed: the egg is 1.5 times the picture, and the big line sits at
		-- the bottom of the screen.
		expect(hatch.eggSize).toBe(1.5)
		expect(hatch.hatchHintText).toBe("TAP TO HATCH")
		expect(hatch.hatchHintHeight > hatch.hintHeight).toBe(true)
		expect(hatch.hatchHintCenterY > 0.75).toBe(true)
		expect(hatch.hatchHintCenterY + hatch.hatchHintHeight / 2 * hatch.hintPulseScale <= 1).toBe(true)
		expect(hatch.hintPulseScale >= 1 and hatch.hintPulseSeconds > 0).toBe(true)
		-- The glow: light, round, made of a sparing number of faint rings.
		expect(isColor(hatch.glow.color)).toBe(true)
		expect(hatch.glow.size > 0).toBe(true)
		expect(hatch.glow.rings >= 4 and hatch.glow.rings <= 24).toBe(true)
		expect(hatch.glow.ringTransparency > 0.5 and hatch.glow.ringTransparency < 1).toBe(true)
	end,

	["the rays behind the egg are wide and narrow in turns, faint and slowly turning"] = function(expect)
		local rays = Ui.hatch.rays
		-- Every strip makes two rays; wide and narrow lines take turns all the way around.
		expect(rays.count >= 4 and rays.count % 4 == 0).toBe(true)
		expect(rays.strips.narrow >= 1 and rays.strips.narrow % 1 == 0).toBe(true)
		expect(rays.strips.wide > rays.strips.narrow and rays.strips.wide % 1 == 0).toBe(true)
		-- Sparing for weak phones: every strip is one element that turns every frame.
		expect(rays.count / 4 * (rays.strips.wide + rays.strips.narrow) <= 40).toBe(true)
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
