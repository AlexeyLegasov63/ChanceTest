-- Lua lang utils by AlexKarma
local RunService = game:GetService("RunService")

local LangUtils = {}

export type Predicate<T> = (T) -> boolean

export type Consumer<T> = (T) -> ()

export type Throttled = (newTimeout: (number | () -> number)?) -> boolean

--[[
    Safe call a function with given args
    @param function callback 
    @param string message
    @param ... varargs 
    @return boolean *(was the call success)*, ... *(function return result)*
]]
function LangUtils.try<T, R>(callback: (T) -> R, message: string, ...: T): (boolean, R)
	return xpcall(callback, function(report: string)
		warn(`An error occurred!\n\tMessage: {message} \n\tTraceback: {debug.traceback(report)}`)
	end, ...)
end

--[[
    Safe call a function with given args without a success check
    @param function callback 
    @param ... varargs 
    @return ... *(function return result)*
]]
function LangUtils.trySoft<T, R>(callback: (T) -> R, ...: T): R
	return select(2, LangUtils.try(callback, ...))
end

--[[
    Get a safe function
    @param function callback 
    @return Wrapped function with **try** statement
]]
function LangUtils.safeCallWrap<T, R>(callback: (T) -> R): (T) -> R
	return function(...: T): R
		return LangUtils.trySoft(callback, ...)
	end
end

--[[
    Use time throttle
    </br> Also it can be called with a new timeout to change
    @param number | function timeout in seconds
    @return Function that returns true if enough time has passed since the last call
]]
function LangUtils.setThrottle(timeout: number? | (() -> number)?): Throttled
	timeout = timeout or 0

	local lastCall = 0
	return function(newTimeout: number? | (() -> number)?)
		if newTimeout then
			timeout = newTimeout
			lastCall = os.clock()
			return true
		end

		local currentTimeout = typeof(timeout) == "function" and timeout() or timeout
		local currentTime = os.clock()

		if currentTime - lastCall >= currentTimeout then
			lastCall = currentTime
			return true
		end

		return false
	end
end

--[[
    Get a debounced function with a primitive lock
    </br> Return nil if debounced 
    @param function callback
    @param number Debounce time
    @return Wrapped debounced function
]]
function LangUtils.debounce(callback, debounceTime)
	local lastDebounceTime = 0
	return function(...)
		local currentTime = os.clock()

		if currentTime - lastDebounceTime < debounceTime then
			return
		end
		lastDebounceTime = currentTime

		return LangUtils.trySoft(callback, ...)
	end
end

--[[
    Get a once-callable function
    @param function callback 
    @return Wrapped function with **try** statement and **once** locker
]]
function LangUtils.once(callback)
	local called = false
	return function(...)
		if called then
			return
		end
		called = true
		return LangUtils.trySoft(callback, ...)
	end
end

--[[
    Yield until a callback returns a value

    </br> Wait until the callback starts returning not nil or not false value otherwise throw an error
    </br> Notice: Don't return any tuples

    @param callback with some value
    @param timeout (Optional, default 10)
    @param error message (Optional)
    @param soft (Optional, default false)
    
    @return A returned callback value
]]
function LangUtils.await(callback, timeout, message, soft)
	timeout = timeout or 10

	local start = os.clock()
	local value = callback()

	while not value and os.clock() - start < timeout do
		value = callback()
		task.wait() -- wait a ms
	end

	if value then
		return value -- We got something, muahaha
	elseif soft then
		return nil -- We got nothing but it's ok
	end

	error(message or "The callback hasn't returned anything within timeout")
end

--[[
    Makes an immutable enum
    @param table enum (key to number value)
    @return Immutable enum with {values, valueOf, toString}
]]
function LangUtils.newEnum<T>(enum: T)
	local enumName = debug.info(2, "s") or "Anonymous"
	local inversed = {}

	for key, value in enum do
		if inversed[value] then
			error(
				`Enum {enumName} has duplicate value {key} with value {value}!\nPlease ensure that all enum values are unique`
			)
		end
		inversed[value] = key
	end

	local enumClass = {
		-- For iteration
		values = table.clone(enum :: { [any]: number }),

		valueOf = function(key)
			if not enum[key] then
				error(`Enum {enumName} has no key {key}`)
			end
			return enum[key]
		end,

		isValid = function(value)
			return inversed[value] ~= nil
		end,

		toString = function(value)
			if not inversed[value] then
				error(`Enum {enumName} has no value {value}`)
			end
			return inversed[value]
		end,
	}

	return setmetatable({}, {
		__index = function(_, key)
			return enumClass[key] or enum[key] -- fallback
		end,
		__newindex = function()
			error(`Enum {enumName} is immutable`)
		end,
	}) :: typeof(enumClass) & typeof(enum)
end

--[[
    Make a new weak map
    @return Weak map
]]
function LangUtils.newWeakMap()
	return setmetatable({}, {
		__mode = "k",
	})
end

--[[
    Current UNIX timestamp
    @return Current UNIX timestamp
]]
function LangUtils.systemMillis()
	return DateTime.now().UnixTimestampMillis
end

--[[
    Run a callback every heartbeat
    @param function callback
    @param number timeout
    @param ... varargs
    @return RBXScriptConnection
]]
function LangUtils.runHeartbeatLoop(callback, timeout, ...)
	local lastCall = os.clock()
	local args = table.pack(...)

	return RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - lastCall >= timeout then
			return
		end

		lastCall = now

		callback(table.unpack(args))
	end)
end

--[[
    Run a callback in a loop inside a new task
    @param function callback
    @param number timeout
    @param ... varargs
    @return thread
]]
function LangUtils.runLoop(callback, timeout, ...)
	local args = { ... }

	return task.defer(function()
		while true do
			LangUtils.try(callback, "Empty message", unpack(args))
			task.wait(timeout)
		end
	end)
end

return LangUtils
