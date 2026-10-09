--!strict
local DebugTools = require(script.DebugTools)
local LaneView = require(script.LaneView)
local StrengthView = require(script.StrengthView)
local ThrowController = require(script.ThrowController)
local TrainingView = require(script.TrainingView)

LaneView.build()
TrainingView.start()
StrengthView.start()
ThrowController.start()
DebugTools.start()
