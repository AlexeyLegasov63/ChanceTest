--!strict

-- Creates random TODOs every 0.5 seconds
-- And destroys the scope after 10 seconds

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chance = require(ReplicatedStorage.Packages.Chance)
local Charm = require(ReplicatedStorage.Packages.Charm)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChanceTest"
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

type Todo = {
	text: string,
	completed: boolean,
}

local todos = Charm.atom({}) :: Charm.Atom<{ Todo }>

local factory = function(todo: Todo, index: number)
	local element = Instance.new("TextLabel")
	element.Name = "Todo" .. index
	element.Text = todo.text
	element.TextScaled = true
	element.AnchorPoint = Vector2.one / 2
	element.Size = UDim2.fromScale(0.15, 0.05)
	element.Position = UDim2.fromScale(1 * math.random(), 1 * math.random())

	return element
end

local scope = Chance.createScope(function(cleanup)
	Chance.hydrate(cleanup, screenGui, {
		Children = Chance.setChildren(todos :: () -> { Todo }, factory),
	})

	cleanup(screenGui) -- Remove it at the end
end)

for _ = 0, 10 do
	todos(function(todos)
		todos = table.clone(todos)
		table.insert(todos, {
			text = "Todo at " .. os.date(),
			completed = math.random() > 0.5,
		})
		return todos
	end)
	task.wait(0.5)
end

task.delay(3, scope) -- Destroy the scope after 10 seconds
