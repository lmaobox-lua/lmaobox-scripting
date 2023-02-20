--- very situational, and not recommended for other developers to use

local callbacks_register, callbacks_unregister = callbacks.Register, callbacks.Unregister
local nanoids = require("nanoids").generate
local modname, where

if ... then
    modname, where = ...
end

local function new_instance()
    local event_sets = {
        Draw = true,
        CreateMove = true,
        Unload = false,
        DrawModel = true,
        FireGameEvent = true,
        DispatchUserMessage = true,
        SendStringCmd = true,
        PostPropUpdate = true,
        ServerCmdKeyValues = true
    }

    local callbacks, callbacks_mt, calbacks_instance

    local function deconstructor()
        for unique, id in pairs(calbacks_instance) do
            callbacks_unregister(id, unique)
        end
    end

    callbacks_mt = {}
    callbacks = {}
    calbacks_instance = {}

    callbacks.deconstructor = deconstructor

    function callbacks.reference(id, callback)
        local unique    = nanoids(33)
        local reference = {}

        if id == "Unload" then print("Unload is not supported (The library can never know when the script is unloaded)") end

        if event_sets[id] then
            reference.unregister = function()
                callbacks_unregister(id, unique)
            end
        else

        end

        callbacks_register(id, unique, callback)
        calbacks_instance[unique] = id

        return reference
    end

    function callbacks.unique()
        return nanoids(33)
    end

    return callbacks
end

return setmetatable({
    new_instance = new_instance
}, {
    __close = function(self, error)
        UnloadScript(where)
    end
})
