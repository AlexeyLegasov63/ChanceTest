--!strict

-- Expects an error

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chance = require(ReplicatedStorage.Packages.Chance)

Chance.fastHydrate(workspace, {
	[Chance.attribute("Test")] = Chance.setInterval(function(steps)
		return steps
	end, {
		interval = 0.1,
	}),
})
