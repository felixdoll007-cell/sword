local Walls = require("../src/shared/Rules/Walls")
local WallConfig = require("../src/shared/Config/Walls")

return {
	["the real config has 6 zones with 5 walls"] = function(expect)
		expect(Walls.count(WallConfig)).toBe(30)
	end,

	["wall 1 is paper with the first hardness"] = function(expect)
		local wall = Walls.get(WallConfig, 1) :: Walls.Wall
		expect(wall.material).toBe("Paper")
		expect(wall.zone).toBe(1)
		expect(wall.positionInZone).toBe(1)
		expect(wall.hardness).toBe(5)
		expect(wall.reward).toBeNear(1)
	end,

	["hardness grows by 1.3 inside a zone"] = function(expect)
		for index = 1, 4 do
			local current = Walls.get(WallConfig, index) :: Walls.Wall
			local nextWall = Walls.get(WallConfig, index + 1) :: Walls.Wall
			expect(nextWall.hardness / current.hardness).toBeNear(1.3)
		end
	end,

	["first wall of a new zone is 2.5 times the last wall of the previous zone"] = function(expect)
		for zone = 1, 5 do
			local last = Walls.get(WallConfig, zone * 5) :: Walls.Wall
			local first = Walls.get(WallConfig, zone * 5 + 1) :: Walls.Wall
			expect(first.zone).toBe(zone + 1)
			expect(first.hardness / last.hardness).toBeNear(2.5)
		end
	end,

	["materials follow the config order"] = function(expect)
		expect((Walls.get(WallConfig, 5) :: Walls.Wall).material).toBe("Paper")
		expect((Walls.get(WallConfig, 6) :: Walls.Wall).material).toBe("Wood")
		expect((Walls.get(WallConfig, 30) :: Walls.Wall).material).toBe("Bedrock")
	end,

	["reward is a fifth of the hardness"] = function(expect)
		local wall = Walls.get(WallConfig, 17) :: Walls.Wall
		expect(wall.reward).toBeNear(wall.hardness / 5)
	end,

	["wall numbers outside the lane return nil"] = function(expect)
		expect(Walls.get(WallConfig, 0)).toBe(nil)
		expect(Walls.get(WallConfig, -3)).toBe(nil)
		expect(Walls.get(WallConfig, 31)).toBe(nil)
		expect(Walls.get(WallConfig, 2.5)).toBe(nil)
		expect(Walls.get(WallConfig, 0 / 0)).toBe(nil)
		expect(Walls.get(WallConfig, math.huge)).toBe(nil)
	end,

	["a longer config keeps growing without breaking"] = function(expect)
		local materials = {}
		for i = 1, 60 do
			materials[i] = `Material{i}`
		end
		local config = table.clone(WallConfig)
		config.materials = materials

		local last = Walls.get(config, Walls.count(config)) :: Walls.Wall
		expect(last.zone).toBe(60)
		expect(last.hardness > 1e30).toBe(true)
		expect(last.hardness < math.huge).toBe(true)
	end,
}
