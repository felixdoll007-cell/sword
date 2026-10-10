--!strict
local LaneBuilder = require(script.LaneBuilder)
local PlayerStats = require(script.PlayerStats)
local RebirthService = require(script.RebirthService)
local ThrowService = require(script.ThrowService)
local TrainingService = require(script.TrainingService)

LaneBuilder.build()
PlayerStats.start()
ThrowService.start()
TrainingService.start()
RebirthService.start()
