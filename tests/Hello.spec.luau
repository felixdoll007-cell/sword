local Hello = require("../src/shared/Hello")

return {
	["greet returns a greeting with the name"] = function(expect)
		expect(Hello.greet("Felix")).toBe("Hello, Felix!")
	end,

	["greet works with an empty name"] = function(expect)
		expect(Hello.greet("")).toBe("Hello, !")
	end,
}
