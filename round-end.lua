local function on_game_over()

end

local switch = {

}
callbacks.Unregister("FireGameEvent", "FireGameEvent")
callbacks.Register("FireGameEvent", "FireGameEvent", function(event) ---@param event GameEvent
    local switch = switch
end)

callbacks.Unregister("CreateMove", "level_init")
callbacks.Register("CreateMove", "level_init", function()
    callbacks.Unregister("CreateMove", "level_init")
    print("Hello world")
end)
