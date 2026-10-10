local HoldPose = require("../src/shared/Rules/HoldPose")
local HoldConfig = require("../src/shared/Config/HoldPose")
local AnimationConfig = require("../src/shared/Config/Animations")

return {
	["standing still is not walking, normal walking speed is"] = function(expect)
		expect(HoldPose.isWalking(HoldConfig, 0)).toBe(false)
		expect(HoldPose.isWalking(HoldConfig, 16)).toBe(true)
	end,

	["exactly the minimum speed counts as walking, just below does not"] = function(expect)
		expect(HoldPose.isWalking(HoldConfig, HoldConfig.walkingMinSpeed)).toBe(true)
		expect(HoldPose.isWalking(HoldConfig, HoldConfig.walkingMinSpeed - 0.01)).toBe(false)
	end,

	["broken speeds are not walking"] = function(expect)
		expect(HoldPose.isWalking(HoldConfig, 0 / 0)).toBe(false)
		expect(HoldPose.isWalking(HoldConfig, -5)).toBe(false)
	end,

	["a share moves toward its target and takes the given time"] = function(expect)
		expect(HoldPose.approach(0, 1, 0.05, 0.2)).toBeNear(0.25)
		expect(HoldPose.approach(1, 0, 0.05, 0.2)).toBeNear(0.75)
		local share = 0
		for _ = 1, 4 do
			share = HoldPose.approach(share, 1, 0.05, 0.2)
		end
		expect(share).toBeNear(1)
	end,

	["a share never goes past its target"] = function(expect)
		expect(HoldPose.approach(0.9, 1, 10, 0.2)).toBe(1)
		expect(HoldPose.approach(0.1, 0, 10, 0.2)).toBe(0)
		expect(HoldPose.approach(0, 5, 10, 0.2)).toBe(1)
		expect(HoldPose.approach(1, -3, 10, 0.2)).toBe(0)
	end,

	["without a blend time the share jumps to its target"] = function(expect)
		expect(HoldPose.approach(0, 1, 0.016, 0)).toBe(1)
		expect(HoldPose.approach(1, 0, 0.016, -1)).toBe(0)
	end,

	["broken frame times change nothing, broken shares are repaired"] = function(expect)
		expect(HoldPose.approach(0.4, 1, 0 / 0, 0.2)).toBeNear(0.4)
		expect(HoldPose.approach(0.4, 1, -1, 0.2)).toBeNear(0.4)
		expect(HoldPose.approach(0 / 0, 1, 0.016, 0.2)).toBe(1)
		expect(HoldPose.approach(0.4, 0 / 0, 10, 0.2)).toBe(0)
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

	["mixing gives the first pose at 0, the second at 1 and the middle between"] = function(expect)
		local from = { x = 10, y = 0, z = -20 }
		local to = { x = 30, y = 180, z = 20 }
		local x, y, z = HoldPose.mix(from, to, 0)
		expect(x).toBe(10)
		expect(y).toBe(0)
		expect(z).toBe(-20)
		x, y, z = HoldPose.mix(from, to, 1)
		expect(x).toBe(30)
		expect(y).toBe(180)
		expect(z).toBe(20)
		x, y, z = HoldPose.mix(from, to, 0.5)
		expect(x).toBeNear(20)
		expect(y).toBeNear(90)
		expect(z).toBeNear(0)
	end,

	["mixing stays between the two poses for shares out of range"] = function(expect)
		local from = { x = 10, y = 0, z = -20 }
		local to = { x = 30, y = 180, z = 20 }
		local x = HoldPose.mix(from, to, 5)
		expect(x).toBe(30)
		x = HoldPose.mix(from, to, -5)
		expect(x).toBe(10)
		x = HoldPose.mix(from, to, 0 / 0)
		expect(x).toBe(10)
	end,

	["the arm swings out to the side only while the pose changes"] = function(expect)
		expect(HoldPose.sideSwing(HoldConfig, 0)).toBe(0)
		expect(HoldPose.sideSwing(HoldConfig, 1)).toBe(0)
		expect(HoldPose.sideSwing(HoldConfig, 0.5)).toBeNear(HoldConfig.blendSideDegrees)
		expect(HoldPose.sideSwing(HoldConfig, 0.25) < HoldConfig.blendSideDegrees).toBe(true)
		expect(HoldPose.sideSwing(HoldConfig, 0.25) > 0).toBe(true)
		expect(HoldPose.sideSwing(HoldConfig, -3)).toBe(0)
		expect(HoldPose.sideSwing(HoldConfig, 9)).toBe(0)
		expect(HoldPose.sideSwing(HoldConfig, 0 / 0)).toBe(0)
	end,

	["the pose lets go of the arm well before the weapon leaves the hand"] = function(expect)
		expect(HoldConfig.throwBlendSeconds < AnimationConfig.trainingThrow.releaseSeconds).toBe(true)
		expect(HoldConfig.throwBlendSeconds < AnimationConfig.mainThrow.releaseSeconds).toBe(true)
	end,
}
