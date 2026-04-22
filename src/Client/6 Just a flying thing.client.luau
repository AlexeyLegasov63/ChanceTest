--!strict

-- Creates a part and changes its position every frame

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chance = require(ReplicatedStorage.Packages.Chance)

local destroy = Chance.createScope(function(cleanup)
	local part = Instance.new("Part")
	part.Anchored = true
	part.Parent = workspace

	cleanup(Chance.fastHydrate(part, {
		Position = Chance.setRendered(function()
			return Vector3.new(0, 20 + math.sin(os.clock()) * 5, 0)
		end),
	}))

	cleanup(function()
		part:Destroy()
	end)

	print("Hello world!")

	cleanup(function()
		print("Bye world!")
	end)
end)

-- When the scope is no longer needed:
task.delay(10, destroy)
