--!strict

-- Creates a part and changes its color every second

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chance = require(ReplicatedStorage.Packages.Chance)

local part = Instance.new("Part")
part.Name = "Part"
part.Parent = workspace
part.Color = Color3.fromRGB(0, 0, 0)
part.Position = Vector3.new(0, 50, 0)
part.Anchored = true
part.Size = Vector3.one * 15

local scope = Chance.createScope(function(cleanup)
	Chance.hydrate(cleanup, part, {
		Material = Enum.Material.Neon,
		Color = Chance.setInterval(function()
			print("Interval test")
			return BrickColor.random().Color
		end, 1),
	})

	cleanup(function()
		print("Goodbye, world!")
	end)
end)

task.wait(5)

print("Destroying scope...")

scope()
