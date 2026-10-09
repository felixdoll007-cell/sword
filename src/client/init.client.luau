--!strict
local DebugTools = require(script.DebugTools)
local LaneView = require(script.LaneView)
local StatsView = require(script.StatsView)
local ThrowController = require(script.ThrowController)
local TrainingSnap = require(script.TrainingSnap)
local TrainingView = require(script.TrainingView)

LaneView.build()
TrainingView.start()
TrainingSnap.start()
StatsView.start()
ThrowController.start()
DebugTools.start()
