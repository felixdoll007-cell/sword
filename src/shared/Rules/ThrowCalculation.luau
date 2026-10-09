--!strict
-- Pure function for the main throw: throw power in, broken walls and reward out.
-- Every broken wall uses up its hardness from the throw power. The first wall
-- that needs more than what is left stops the throw (the sword bounces off it).

local Walls = require("./Walls")

export type StrengthConfig = {
	strengthPerBrokenWall: number,
}

export type ThrowResult = {
	brokenWalls: { Walls.Wall },
	-- The wall the sword bounces off. nil if every wall was broken.
	bounceWall: Walls.Wall?,
	completedZones: { number },
	currency: number,
	strength: number,
}

local ThrowCalculation = {}

function ThrowCalculation.calculate(
	wallConfig: Walls.WallConfig,
	strengthConfig: StrengthConfig,
	throwPower: number
): ThrowResult
	local result: ThrowResult = {
		brokenWalls = {},
		bounceWall = nil,
		completedZones = {},
		currency = 0,
		strength = 0,
	}

	-- NaN or negative power breaks nothing.
	if throwPower ~= throwPower or throwPower < 0 then
		result.bounceWall = Walls.get(wallConfig, 1)
		return result
	end

	-- Adding up the used power (instead of subtracting from what is left) means a throw
	-- with exactly the sum of the hardnesses breaks all those walls, without rounding errors.
	local usedPower = 0
	for index = 1, Walls.count(wallConfig) do
		local wall = Walls.get(wallConfig, index) :: Walls.Wall
		if usedPower + wall.hardness > throwPower then
			result.bounceWall = wall
			break
		end

		usedPower += wall.hardness
		table.insert(result.brokenWalls, wall)
		result.currency += wall.reward

		if wall.positionInZone == wallConfig.wallsPerZone then
			table.insert(result.completedZones, wall.zone)
			result.currency += wall.reward * wallConfig.zoneBonusFactor
		end
	end

	result.strength = #result.brokenWalls * strengthConfig.strengthPerBrokenWall
	return result
end

return ThrowCalculation
