callbacks.Register( 'FireGameEvent', function( event )
    local eventname = event:GetName()
    if eventname == 'player_disconnect' then
        local userid, reason, name, networkid, bot
        userid = event:GetInt( 'userid' )
        reason = event:GetString( 'reason' )
        name = event:GetString( 'name' )
        networkid = event:GetString( 'name' )
        bot = event:GetInt( 'bot' )

        if bot == 0 then
            local priority = playerlist.GetPriority( userid )
            if priority > 0 then
                client.ChatPrintf( string.format( '\3(%d) %s left for milk (%s)', priority, name, reason ) )
            end
            -- client.ChatSay(string.format('%s left for milk (%s)', name, reason)) 

        end
        return
    end

    if eventname == 'player_connect_client' then
        local name, index, userid, networkid, bot
        name = event:GetString( 'name' )
        index = event:GetInt( 'index' )
        userid = event:GetInt( 'userid' )
        networkid = event:GetInt( 'networkid' )
        bot = event:GetInt( 'bot' )

        local priority = playerlist.GetPriority( userid )
        if priority > 0 then
            client.ChatPrintf( '\3(%d) \5%s\1 joined', priority, name )
        end
        return
    end
end )

local next_map_vote = {
    [0] = 'USER_NEXT_MAP_VOTE_MAP_0',
    'USER_NEXT_MAP_VOTE_MAP_1',
    'USER_NEXT_MAP_VOTE_MAP_2',
    'USER_NEXT_MAP_VOTE_UNDECIDED'
 }

local state = {
    [0] = 'NEXT_MAP_VOTE_STATE_NONE',
    'NEXT_MAP_VOTE_STATE_WAITING_FOR_USERS_TO_VOTE',
    'NEXT_MAP_VOTE_STATE_MAP_CHOSEN_PAUSE'
 }

timer = timer or globals.RealTime()

callbacks.Register( 'Draw', function()

    if gamerules.GetRoundState() == ROUND_GAMEOVER then
        for i = 1, 1000 do
            local ent = entities.GetByIndex( i )
            if ent then
                local class = ent:GetClass()
                if class == 'CTFGameRulesProxy' then
                    local m_eRematchState = ent:GetPropInt( 'm_eRematchState' )
                    local m_nNextMapVoteOptions = ent:GetPropDataTableInt( 'm_ePlayerWantsRematch' )
                    print( string.format( '%d - %s ', m_eRematchState, state[m_eRematchState] ) )
                    for i, v in ipairs( m_nNextMapVoteOptions ) do
                        local name = client.GetPlayerNameByIndex( i )
                        if #name > 0 then
                            printc( 238, 210, 2, 255,
                                string.format( '(%d) %s: (%d) %s', i, name, v, next_map_vote[v] or 'undefined' ) )
                        end
                    end
                end
            end
        end
    end
end )

for i = 1, 1000 do
    local ent = entities.GetByIndex( i )
    if ent then
        local class = ent:GetClass()
        if class == 'CTFGameRulesProxy' then
            local m_eRematchState = ent:GetPropInt( 'm_eRematchState' )
            local m_nNextMapVoteOptions = ent:GetPropDataTableInt( 'm_ePlayerWantsRematch' )
            print( string.format( '%d - %s ', m_eRematchState, state[m_eRematchState] ) )
            for i, v in ipairs( m_nNextMapVoteOptions ) do
                local name = client.GetPlayerNameByIndex( i )
                if #name > 0 then
                    printc( 238, 210, 2, 255,
                        string.format( '(%d) %s: (%d) %s', i, name, v, next_map_vote[v] or 'undefined' ) )
                end
            end
        end
    end
end

--[[
for i = 1, 1000 do
    local ent = entities.GetByIndex( i )
    if ent then
        local class = ent:GetClass()
        if class == 'CTFGameRulesProxy' then
            local m_nNextMapVoteOptions = ent:GetPropDataTableInt( 'm_ePlayerWantsRematch' )
            return printLuaTable( m_nNextMapVoteOptions )
        end
        if class == 'CVoteController' then
            -- return printLuaTable(ent:GetPropDataTableInt('m_nVoteOptionCount'))
        end
    end
end

enum EUserNextMapVote
	{
		USER_NEXT_MAP_VOTE_MAP_0 = 0,
		USER_NEXT_MAP_VOTE_MAP_1,
		USER_NEXT_MAP_VOTE_MAP_2,
		USER_NEXT_MAP_VOTE_UNDECIDED,

		NUM_VOTE_STATES
	};

]]
