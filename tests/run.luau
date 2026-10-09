-- Minimal test runner for Lune: runs every *.spec.luau file in this folder.
-- Each spec returns a table of { [testName] = function(expect) ... end }.
local fs = require("@lune/fs")
local process = require("@lune/process")

local function expect(actual)
	return {
		toBe = function(expected)
			if actual ~= expected then
				error(`expected {tostring(expected)}, got {tostring(actual)}`, 2)
			end
		end,
		-- For decimal numbers: allows a tiny relative difference from rounding.
		toBeNear = function(expected)
			local tolerance = math.abs(expected) * 1e-9
			if typeof(actual) ~= "number" or math.abs(actual - expected) > tolerance then
				error(`expected about {tostring(expected)}, got {tostring(actual)}`, 2)
			end
		end,
	}
end

local passed, failed = 0, 0

local files = fs.readDir("tests")
table.sort(files)

for _, file in files do
	if not file:match("%.spec%.luau$") then
		continue
	end

	local spec = require(`./{file:gsub("%.luau$", "")}`)
	for name, test in spec do
		local ok, err = pcall(test, expect)
		if ok then
			passed += 1
			print(`  PASS  {file} > {name}`)
		else
			failed += 1
			print(`  FAIL  {file} > {name}\n        {err}`)
		end
	end
end

print(`\n{passed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
