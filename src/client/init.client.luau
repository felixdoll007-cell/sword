--!strict
local DebugTools = require(script.DebugTools)
local LaneView = require(script.LaneView)
local StrengthView = require(script.StrengthView)
local ThrowController = require(script.ThrowController)
local TrainingSnap = require(script.TrainingSnap)
local TrainingView = require(script.TrainingView)

LaneView.build()
TrainingView.start()
TrainingSnap.start()
StrengthView.start()
ThrowController.start()
DebugTools.start()
