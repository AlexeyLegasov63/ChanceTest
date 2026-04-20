--!strict

-- Changes local player head color every 0.3 seconds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Chance = require(ReplicatedStorage.Packages.Chance)
local Charm = require(ReplicatedStorage.Packages.Charm)
local PlayersUtils = require(ReplicatedStorage.Shared.Utils.PlayersUtils)

local isShifting = Charm.atom(false)

-------- INPUT --------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isShifting(true)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		isShifting(false)
	end
end)

-------- CHARACTER SPEED --------

PlayersUtils.onLocalCharacter(function(character, characterCleanup)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	characterCleanup(Chance.fastHydrate(humanoid, {
		-- Computed values are just Charm subscriptions
		WalkSpeed = function()
			return isShifting() and 50 or 16
		end,
	}))
end)
