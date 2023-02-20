local sets = {
    ["Game.YourTeamWon"] = true,
    ["Game.YourTeamLost"] = true,
    ["Game.Stalemate"] = false,
    ["Game.SuddenDeath"] = false,
}

callbacks.Register("FireGameEvent", function(event) ---@param event GameEvent
    if event:GetName() == "teamplay_broadcast_audio" then
        if sets[event:GetString("sound")] then
            event:SetString("sound", "")
            engine.PlaySound('sound/ui/notification_alert.wav')
        end
    end
end)
