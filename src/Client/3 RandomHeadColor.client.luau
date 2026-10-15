--!strict

-- Changes local player head color every 0.5 seconds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chance = require(ReplicatedStorage.Packages.Chance)
local PlayersUtils = require(ReplicatedStorage.Shared.Utils.PlayersUtils)

PlayersUtils.onLocalCharacter(function(character, cleanup)
	local head = character:WaitForChild("Head") :: Part

	cleanup(Chance.fastHydrate(head, {
		BrickColor = Chance.setInterval(function()
			return BrickColor.random()
		end, {
			interval = 0.5,
		}),
	}))
end)
