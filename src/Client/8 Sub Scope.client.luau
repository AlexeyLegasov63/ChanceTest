local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Chance = require(ReplicatedStorage.Packages.Chance)

Chance.createScope(function()
	print("Hi 1 Scope")

	local destroy = Chance.subScope(function()
		print("Hi 2 Scope ")

		Chance.cleanup(function()
			print("Goodbye 2 Scope")
		end)
	end)

	Chance.cleanup(function()
		print("Goodbye 1 Scope")
	end)

	destroy()
end)()
