local Rebirth = require("../src/shared/Rules/Rebirth")
local RebirthConfig = require("../src/shared/Config/Rebirth")

local listLength = #RebirthConfig.thresholds

return {
	["multiplier is 1x without rebirths, then +1x per rebirth"] = function(expect)
		expect(Rebirth.multiplier(RebirthConfig, 0)).toBe(1)
		expect(Rebirth.multiplier(RebirthConfig, 1)).toBe(2)
		expect(Rebirth.multiplier(RebirthConfig, 6)).toBe(7)
		expect(Rebirth.multiplier(RebirthConfig, -3)).toBe(1)
	end,

	["thresholds come from the list"] = function(expect)
		expect(Rebirth.threshold(RebirthConfig, 0)).toBe(200)
		expect(Rebirth.threshold(RebirthConfig, 1)).toBe(400)
		expect(Rebirth.threshold(RebirthConfig, listLength - 1)).toBe(RebirthConfig.thresholds[listLength])
	end,

	["thresholds rise with every rebirth, also far beyond the list"] = function(expect)
		for rebirths = 0, 200 do
			expect(Rebirth.threshold(RebirthConfig, rebirths + 1) > Rebirth.threshold(RebirthConfig, rebirths)).toBe(
				true
			)
		end
	end,

	["after the list each run takes 20 percent longer"] = function(expect)
		-- Training time of a run is proportional to threshold / multiplier (same lane).
		local function runTime(rebirths: number): number
			return Rebirth.threshold(RebirthConfig, rebirths) / Rebirth.multiplier(RebirthConfig, rebirths)
		end
		for rebirths = listLength - 1, listLength + 20 do
			expect(runTime(rebirths + 1) / runTime(rebirths)).toBeNear(RebirthConfig.runTimeGrowthAfterList)
		end
	end,

	["very many rebirths still give a finite threshold"] = function(expect)
		local threshold = Rebirth.threshold(RebirthConfig, 1000)
		expect(threshold > 0 and threshold < math.huge).toBe(true)
	end,

	["rebirth is possible exactly at the threshold, not just below"] = function(expect)
		expect(Rebirth.canRebirth(RebirthConfig, 200, 0)).toBe(true)
		expect(Rebirth.canRebirth(RebirthConfig, 199.99, 0)).toBe(false)
		expect(Rebirth.canRebirth(RebirthConfig, 200, 1)).toBe(false)
		expect(Rebirth.canRebirth(RebirthConfig, 1e300, 5)).toBe(true)
	end,

	["broken strength values never allow a rebirth"] = function(expect)
		expect(Rebirth.canRebirth(RebirthConfig, 0 / 0, 0)).toBe(false)
		expect(Rebirth.canRebirth(RebirthConfig, -500, 0)).toBe(false)
	end,

	["progress goes from 0 to 1 and never beyond"] = function(expect)
		expect(Rebirth.progress(RebirthConfig, 0, 0)).toBe(0)
		expect(Rebirth.progress(RebirthConfig, 100, 0)).toBe(0.5)
		expect(Rebirth.progress(RebirthConfig, 200, 0)).toBe(1)
		expect(Rebirth.progress(RebirthConfig, 1e30, 0)).toBe(1)
		expect(Rebirth.progress(RebirthConfig, -5, 0)).toBe(0)
		expect(Rebirth.progress(RebirthConfig, 0 / 0, 0)).toBe(0)
	end,

	["a rebirth resets strength to the start and counts one up"] = function(expect)
		local after = Rebirth.apply(RebirthConfig, { strength = 250, rebirths = 0 }, 10) :: Rebirth.Values
		expect(after.strength).toBe(10)
		expect(after.rebirths).toBe(1)
	end,

	["a rebirth without enough strength changes nothing"] = function(expect)
		expect(Rebirth.apply(RebirthConfig, { strength = 150, rebirths = 0 }, 10)).toBe(nil)
		expect(Rebirth.apply(RebirthConfig, { strength = 250, rebirths = 1 }, 10)).toBe(nil)
	end,

	["apply does not change the input"] = function(expect)
		local values = { strength = 250, rebirths = 0 }
		Rebirth.apply(RebirthConfig, values, 10)
		expect(values.strength).toBe(250)
		expect(values.rebirths).toBe(0)
	end,
}
