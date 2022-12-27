---disconnects the player from the server
local function disconnect_from_server()
    if gamecoordinator.GetMatchAbandonStatus() ~= MATCHABANDON_PENTALTY then
        gamecoordinator.AbandonMatch()
        client.Command("disconnect", true)
    end
end

--- Programmatically queue for matchmaking with the same game mode once the current game ends.
--- Can only queue up casual / competitive due to api limitations.
local matchGroups = party.GetAllMatchGroups()
local currentMatchGroup = matchGroups["Casual"]

local function find_next_match()
    -- gamecoordinator is offline
    if not gamecoordinator.ConnectedToGC() then
        return
    end
    -- recieved match invite
    if gamecoordinator.GetNumMatchInvites() ~= 0 then
        -- gamecoordinator.AcceptMatchInvites()
        return
    end
    -- there's no matchmade game assigned
    if gamecoordinator.HasLiveMatch() == false then
        if currentMatchGroup then
            local reasons = party.CanQueueForMatchGroup(currentMatchGroup)
            if reasons == true then
                -- queue once
                party.QueueUp(currentMatchGroup)
                currentMatchGroup = nil
            else
                -- for id, msg in pairs(reasons) do print(id, msg) end
            end
        end
        return
    end
    local signOnState = clientstate.GetClientSignonState()
    if signOnState == 6 and gamerules.GetRoundState() == ROUND_GAMEOVER then
        disconnect_from_server()
        return
    end
    if signOnState ~= 0 then
        if gamerules.IsMatchTypeCasual() then
            currentMatchGroup = matchGroups["Casual"]
        else if gamerules.IsMatchTypeCompetitive() then
                currentMatchGroup = matchGroups["Competitive6v6"]
            end
        end
    end
end

callbacks.Register("Draw", find_next_match)
