SIGNONSTATE_NONE = 0 -- no state yet, about to connect
SIGNONSTATE_CHALLENGE = 1 -- client challenging server, all OOB packets
SIGNONSTATE_CONNECTED = 2 -- client is connected to server, netchans ready
SIGNONSTATE_NEW = 3 -- just got serverinfo and string tables
SIGNONSTATE_PRESPAWN = 4 -- received signon buffers
SIGNONSTATE_SPAWN = 5 -- ready to receive entity packets
SIGNONSTATE_FULL = 6 -- we are fully connected, first non-delta packet received
SIGNONSTATE_CHANGELEVEL = 7 -- server is changing level, please wait

local CAT_IDENTIFY = 0xCA7
local CAT_REPLY = 0xCA8

-- more like sendVacIdentify()
local function sendCatIdentify( reply )
    local status = engine.SendKeyValues( string.format( [[
        "AchievementEarned" 
        {
            "achievementID" "%d"
        }
    ]], reply and CAT_REPLY or CAT_IDENTIFY ) )
    --printc( 0, 255, 0, 255, status)
end

local timer, reply = 0, false

callbacks.Register( 'CreateMove', function( cmd )
    if clientstate.GetClientSignonState() == SIGNONSTATE_FULL then
        if timer < globals.RealTime() then
            sendCatIdentify( reply )
            timer = globals.RealTime() + 15
            reply = false
        end
        return
    end
    timer = 0
end )

callbacks.Register( 'FireGameEvent', function( event )

    if event:GetName() == 'achievement_earned' then
        local entidx, achievement
        entidx = event:GetInt( 'player' )
        achievement = event:GetInt( 'achievement' )
        if achievement == CAT_IDENTIFY or achievement == CAT_REPLY then
            local playerinfo = client.GetPlayerInfo( entidx )
            client.ChatPrintf( '\x01[\x07e05938CAT\x01] %s identified themself as catsexual.', playerinfo.Name )

            if entidx == client.GetLocalPlayerIndex() then
                return
            end

            if achievement == CAT_REPLY then
                timer = 0
                reply = true
            end
        end
    end

end )
