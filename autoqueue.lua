--[[
    TODO: Look at this shit later
    Queue up

    Main Queue Mode 
    + Queue time > delay -> Queue additional game mode

    In Game
    - queue up for the same game mode once the current game ends.

    Joining Server
    - Stop all queue , except main queue
    - Will not queue up

    Main Menu
    - queue up for the same game mode once the player enters the main menu.

    + Set Map if there's no map selected
]]

local config = {
    delay_in_second     = 5,
    requeue_on_failure  = true,
    stop_when_connected = false,
    primary_game_mode   = "Casual",
    extra_game_mode     = {},
    queue_up_standby    = false -- casual only
}

local all_match_groups = party.GetAllMatchGroups()
local match_group      = all_match_groups[config.primary_game_mode]
local find_game        = false

local function disconnect()
    if gamecoordinator.GetMatchAbandonStatus() ~= MATCHABANDON_PENTALTY then
        gamecoordinator.AbandonMatch()
        client.Command("disconnect", not nil)
    end
end

callbacks.Register("Draw", function()
    if gamecoordinator.ConnectedToGC() then

        if gamecoordinator.GetNumMatchInvites() ~= 0 then
            gamecoordinator.AcceptMatchInvites()
            return
        end

        if clientstate.GetClientSignonState() == 6 then
            if gamerules.GetRoundState() == 8 then
                if config.stop_when_connected then
                    return
                end
                disconnect()
                find_game = true
            end

            match_group = all_match_groups["Bootcamp"]
            if gamerules.IsMatchTypeCasual() then
                match_group = all_match_groups["Casual"]
            end
            if gamerules.IsMatchTypeCompetitive() then
                match_group = all_match_groups["Competitive6v6"]
            end
        end

        if not find_game then
            return
        end

        -- in community server or main menu
        if not gamecoordinator.HasLiveMatch() then
            local reasons = party.CanQueueForMatchGroup(match_group)
            if reasons == true then
                party.QueueUp(match_group)
                return
            end
            for id, msg in pairs(reasons) do
                print(id, msg)
            end
        end
    end

    find_game = false
end)
