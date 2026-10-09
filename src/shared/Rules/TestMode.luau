--!strict
-- Pure function: a test switch only counts when it is on AND the game runs in Studio.
-- That way a switch accidentally left on does nothing in the published game.

local TestMode = {}

function TestMode.isOn(switch: boolean, isStudio: boolean): boolean
	return switch and isStudio
end

return TestMode
