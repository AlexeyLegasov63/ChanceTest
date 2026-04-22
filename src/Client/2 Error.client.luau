--!strict

-- Expects an error

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chance = require(ReplicatedStorage.Packages.Chance)

Chance.fastHydrate(game, {
	EwwwProperty = "Ewww",
})
