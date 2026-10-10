local HoldPose = require("../src/shared/Rules/HoldPose")
local HoldConfig = require("../src/shared/Config/HoldPose")
local AnimationConfig = require("../src/shared/Config/Animations")

return {
	["the pose comes back in the return time"] = function(expect)
		local quarter = HoldConfig.returnSeconds / 4
		expect(HoldPose.nextShare(HoldConfig, 0, true, quarter)).toBeNear(0.25)
		local share = 0
		for _ = 1, 4 do
			share = HoldPose.nextShare(HoldConfig, share, true, quarter)
		end
		expect(share).toBeNear(1)
	end,

	["the pose lets go in the let-go time"] = function(expect)
		local quarter = HoldConfig.letGoSeconds / 4
		expect(HoldPose.nextShare(HoldConfig, 1, false, quarter)).toBeNear(0.75)
		local share = 1
		for _ = 1, 4 do
			share = HoldPose.nextShare(HoldConfig, share, false, quarter)
		end
		expect(share).toBeNear(0)
	end,

	["the share never goes past its ends"] = function(expect)
		expect(HoldPose.nextShare(HoldConfig, 0.9, true, 10)).toBe(1)
		expect(HoldPose.nextShare(HoldConfig, 0.1, false, 10)).toBe(0)
		expect(HoldPose.nextShare(HoldConfig, 1, true, 10)).toBe(1)
		expect(HoldPose.nextShare(HoldConfig, 0, false, 10)).toBe(0)
	end,

	["without a blend time the share jumps"] = function(expect)
		local config = table.clone(HoldConfig)
		config.returnSeconds = 0
		config.letGoSeconds = -1
		expect(HoldPose.nextShare(config, 0, true, 0.016)).toBe(1)
		expect(HoldPose.nextShare(config, 1, false, 0.016)).toBe(0)
	end,

	["broken frame times change nothing, broken shares are repaired"] = function(expect)
		expect(HoldPose.nextShare(HoldConfig, 0.4, true, 0 / 0)).toBeNear(0.4)
		expect(HoldPose.nextShare(HoldConfig, 0.4, true, -1)).toBeNear(0.4)
		expect(HoldPose.nextShare(HoldConfig, 0 / 0, true, 0.016)).toBe(1)
		expect(HoldPose.nextShare(HoldConfig, 0 / 0, false, 0.016)).toBe(0)
		expect(HoldPose.nextShare(HoldConfig, 7, false, 0)).toBe(1)
		expect(HoldPose.nextShare(HoldConfig, -7, true, 0)).toBe(0)
	end,

	["easing keeps the ends and the middle"] = function(expect)
		expect(HoldPose.ease(0)).toBe(0)
		expect(HoldPose.ease(1)).toBe(1)
		expect(HoldPose.ease(0.5)).toBeNear(0.5)
		expect(HoldPose.ease(0.25) < 0.25).toBe(true)
		expect(HoldPose.ease(-2)).toBe(0)
		expect(HoldPose.ease(7)).toBe(1)
		expect(HoldPose.ease(0 / 0)).toBe(0)
	end,

	["the pose lets go of the arm well before the weapon leaves the hand"] = function(expect)
		expect(HoldConfig.letGoSeconds < AnimationConfig.trainingThrow.releaseSeconds).toBe(true)
		expect(HoldConfig.letGoSeconds < AnimationConfig.mainThrow.releaseSeconds).toBe(true)
	end,

	["the pose only names the three joints of the right arm"] = function(expect)
		local count = 0
		for name in HoldConfig.arm do
			count += 1
			expect(name == "shoulder" or name == "elbow" or name == "wrist").toBe(true)
		end
		expect(count).toBe(3)
	end,
}
