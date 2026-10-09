--!strict
local DebugTools = require(script.DebugTools)
local LaneView = require(script.LaneView)
local ThrowController = require(script.ThrowController)

LaneView.build()
ThrowController.start()
DebugTools.start()
