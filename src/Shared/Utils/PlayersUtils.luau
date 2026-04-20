-- This module is responsible for player utils
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local LangUtils = require(script.Parent.LangUtils)

local PlayerUtils = {}

--[[
    Use join event for every player
    @param function callback for every join and cleanup
    @return **Players.PlayerAdded** signal connection
]]
function PlayerUtils.onJoinEvent(callback: (plr: Player, cleanup: <T>(t: T) -> T) -> any): RBXScriptConnection
	local handler = function(player: Player)
		local cleaner = Trove.new()
		player:GetPropertyChangedSignal("Parent"):Connect(function()
			cleaner:Destroy()
		end)
		callback(player, function(t)
			return cleaner:Add(t :: any)
		end)
	end

	-- Iterate already present players
	for _, player in pairs(Players:GetPlayers()) do
		task.spawn(handler, player)
	end

	return Players.PlayerAdded:Connect(handler)
end

--[[
    Use quit event for every player
    @param function callback for every quit
    @return **Players.PlayerRemoving** signal connection
]]
function PlayerUtils.onQuitEvent(callback: (player: Player, reason: Enum.PlayerExitReason) -> ()): RBXScriptConnection
	return Players.PlayerRemoving:Connect(callback)
end

--[[
    Use quit event for the player
    @param Player player
    @param function callback for their quit
    @return **Players.PlayerRemoving** signal connection (With auto disconnect)
]]
function PlayerUtils.onPlayerQuitEvent(player: Player, callback: () -> any): RBXScriptConnection
	local connection: RBXScriptConnection

	connection = Players.PlayerRemoving:Connect(function(somePlayer)
		if somePlayer ~= player then
			return
		end

		connection:Disconnect()
		callback()
	end)

	return connection
end

--[[
    Check if the player has a tool
    @param Player player
    @param function predicate
    @param boolean includeStarterGear
    @return boolean True if the player has a tool
]]
function PlayerUtils.hasTool(
	player: Player,
	predicate: LangUtils.Predicate<Tool>,
	includeStarterGear: boolean?
): boolean
	for _, tool in player.Backpack:GetChildren() do
		if tool:IsA("Tool") and predicate(tool) then
			return true
		end
	end

	if includeStarterGear then
		for _, tool in player.StarterGear:GetChildren() do
			if tool:IsA("Tool") and predicate(tool) then
				return true
			end
		end
	end

	if not player.Character then
		return false
	end

	local toolInCharacter = player.Character:FindFirstChildOfClass("Tool")
	if toolInCharacter and predicate(toolInCharacter) then
		return true
	end

	return false
end

-- Remove player tools
function PlayerUtils.removeTools(player: Player, predicate: LangUtils.Predicate<Tool>, includeStarterGear: boolean?)
	for _, tool in player.Backpack:GetChildren() do
		if not tool:IsA("Tool") or not predicate(tool) then
			continue
		end
		tool:Destroy()
	end

	if includeStarterGear then
		for _, tool in player.StarterGear:GetChildren() do
			if not tool:IsA("Tool") or not predicate(tool) then
				continue
			end
			tool:Destroy()
		end
	end

	if not player.Character then
		return
	end

	local tool = player.Character:FindFirstChildOfClass("Tool")

	if tool and predicate(tool) then
		tool:Destroy()
	end
end

--[[
    Get player from character descendant
    @param Instance instance
    @return Player?
]]
function PlayerUtils.findByCharacterDescendant(instance: Instance): Player?
	for _, player in Players:GetPlayers() do
		if player.Character and instance:IsDescendantOf(player.Character) then
			return player
		end
	end
	return nil
end

--[[
    Use player character once
    </br> Garrant that the callback will be called only once with the character
    @param Player player
    @param function callback
    @return boolean True if the player has a character and is alive
]]
function PlayerUtils.garanteeCharacter(player: Player, callback: (character: Model) -> ()): boolean
	local function handler()
		local character = player.Character
		if not character then
			return false
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			return false
		end
		LangUtils.try(callback, "Error in PlayerUtils.garanteeCharacterOnce", character :: Model)
		return true
	end
	if player.Character and handler() then
		return true
	end
	-- Watch for every character change
	local connection
	connection = player:GetPropertyChangedSignal("Character"):Connect(function()
		if player.Character and handler() then
			connection:Disconnect()
		end
	end)
	return false
end

--[[
    Use player character once, 
    </br> Garrant that the callback will be called only once with the character
    </br> It will be loaded if dead or not exists
    @param Player player
    @param function callback
]]
function PlayerUtils.garanteeCharacterNow(player: Player, callback: (character: Model) -> ())
	if PlayerUtils.garanteeCharacter(player, callback) then
		return
	end
	task.spawn(function()
		player:LoadCharacterAsync()
	end)
end

--[[
    Check if the player is dead
    @param Player player
    @return boolean True if the player is dead
]]
function PlayerUtils.isDead(player: Player): boolean
	local character = player.Character
	if not character then
		return false
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return not humanoid or humanoid.Health <= 0
end

--[[
    Check if the player is alive
    @param Player player
    @return boolean True if the player is alive
]]
function PlayerUtils.isAlive(player: Player): boolean
	return not PlayerUtils.isDead(player)
end

--[[
    Use player character
    @param Player player
    @param function callback
    @return RBXScriptConnection
]]
function PlayerUtils.onCharacter(player: Player, callback: (character: Model, cleanup: <T>(t: T) -> T) -> ())
	local cleaner = Trove.new()

	local handler = function(character: Model?)
		cleaner:Destroy()

		if not character then
			return
		end

		callback(character, function(t)
			return cleaner:Add(t)
		end)
	end

	if player.Character then
		task.defer(handler, player.Character)
	end

	-- Watch for every character change
	return player:GetPropertyChangedSignal("Character"):Connect(function()
		handler(player.Character)
	end)
end

--[[
    Use local player character
    @param Player player
    @param function callback
    @return RBXScriptConnection
]]
function PlayerUtils.onLocalCharacter(callback: (character: Model, cleanup: (t: any) -> ()) -> ())
	return PlayerUtils.onCharacter(Players.LocalPlayer, callback)
end

--[[
    Get characters of all players
    @param boolean excludeDead
    @return { [Model]: Player } Map of character to player
]]
function PlayerUtils.getCharactersToPlayers(excludeDead: boolean?): { [Model]: Player }
	local characters = {}

	for _, player in Players:GetPlayers() do
		if player.Character and (not excludeDead or not PlayerUtils.isDead(player)) then
			characters[player.Character] = player
		end
	end

	return characters
end

--[[
    Use every player character
    @param function callback
    @return RBXScriptConnection
]]
function PlayerUtils.onEveryCharacter(callback: (character: Model, cleanup: (t: any) -> ()) -> ())
	return PlayerUtils.onJoinEvent(function(player)
		PlayerUtils.onCharacter(player, callback)
	end)
end

return PlayerUtils
