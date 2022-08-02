-- helix you owe me one copy of project zomboid on steam.
-- https://steamcommunity.com/id/darklancer/
-- requestify patcher 
-- ONLY USE THIS SCRIPT IF YOU INTEND TO USE WITH https://github.com/weespin/RequestifyTF2
local version = 1.1

--[[local interaction, filename = {}, engine.GetGameDir() .. '\\console.log'
function interaction:write( contents )
    if self.handle then
        self.handle:write( contents .. '\n' )
        self.handle:flush()
    else
        client.Command( string.format( 'echo %q', contents ), true )
    end
    return true
end

local ok, ret = pcall( function()
    local fh = io.open( filename, 'w' ) -- do not sure w+ (reason disclosed)
    interaction.handle = fh
end )
if not ok then
    print( string.format( '[print method] filename: %s,\nhandle: %s,\nret: %s', interaction.handle, ret ) )
else
    print( '[direct write method]' )
end

callbacks.Register( 'FireGameEvent', function( event )
    if event:GetName() == 'party_chat' then
        local text, steamid64
        text = event:GetString( 'text' )
        steamid64 = tonumber( event:GetString( 'steamid' ) )
        if text:find( '!' ) == 1 then
            interaction:write( string.format( '%s : %s', steam.GetPlayerName( steamid64 ), text ) )
        end
    end
end )

local UserMessage = { 'Train', 'HudText', 'SayText', 'SayText2', 'TextMsg', 'ResetHUD', 'GameTitle', 'ItemPickup',
                      'ShowMenu', 'Shake', 'Fade', 'VGUIMenu', 'Rumble', 'CloseCaption', 'SendAudio', 'VoiceMask',
                      'RequestState', 'Damage', 'HintText', 'KeyHintText', 'HudMsg', 'AmmoDenied', 'AchievementEvent',
                      'UpdateRadar', 'VoiceSubtitle', 'HudNotify', 'HudNotifyCustom', 'PlayerStatsUpdate',
                      'MapStatsUpdate', 'PlayerIgnited', 'PlayerIgnitedInv', 'HudArenaNotify', 'UpdateAchievement',
                      'TrainingMsg', 'TrainingObjective', 'DamageDodged', 'PlayerJarated', 'PlayerExtinguished',
                      'PlayerJaratedFade', 'PlayerShieldBlocked', 'BreakModel', 'CheapBreakModel', 'BreakModel_Pumpkin',
                      'BreakModelRocketDud', 'CallVoteFailed', 'VoteStart', 'VotePass', 'VoteFailed', 'VoteSetup',
                      'PlayerBonusPoints', 'RDTeamPointsChanged', 'SpawnFlyingBird', 'PlayerGodRayEffect',
                      'PlayerTeleportHomeEffect', 'MVMStatsReset', 'MVMPlayerEvent', 'MVMResetPlayerStats',
                      'MVMWaveFailed', 'MVMAnnouncement', 'MVMPlayerUpgradedEvent', 'MVMVictory', 'MVMWaveChange',
                      'MVMLocalPlayerUpgradesClear', 'MVMLocalPlayerUpgradesValue', 'MVMResetPlayerWaveSpendingStats',
                      'MVMLocalPlayerWaveSpendingValue', 'MVMResetPlayerUpgradeSpending', 'MVMServerKickTimeUpdate',
                      'PlayerLoadoutUpdated', 'PlayerTauntSoundLoopStart', 'PlayerTauntSoundLoopEnd',
                      'ForcePlayerViewAngles', 'BonusDucks', 'EOTLDuckEvent', 'PlayerPickupWeapon',
                      'QuestObjectiveCompleted', 'SPHapWeapEvent', 'HapDmg', 'HapPunch', 'HapSetDrag', 'HapSetConst',
                      'HapMeleeContact' }
UserMessage[0] = 'Geiger'

callbacks.Register( 'DispatchUserMessage', function( msg )
    if msg:GetID() == SayText2 then
        local ent_idx, is_text_chat, chat_type, player_name, chat_text
        ent_idx = msg:ReadByte()
        is_text_chat = msg:ReadByte() -- if set to 1, GetFilterForString gets called
        chat_type = msg:ReadString( 256 ):lower() -- used in ReadLocalizedString
        player_name = msg:ReadString( 256 )
        chat_text = msg:ReadString( 256 )

        -- print( chat_type )
        -- don't use localize to avoid stupid localization updates.
        if chat_text:find( '!' ) == 1 then -- ! is requestify prefix
            if chat_type:find( 'tf_chat_all' ) then
                interaction:write( string.format( '%s : %s', player_name, chat_text ) )
            elseif chat_type:find( 'tf_chat_team' ) then
                interaction:write( string.format( '(TEAM) %s : %s', player_name, chat_text ) )
            end
        end
    end
end )

client.Command( 'con_logfile \"\"', true )
callbacks.Register( 'SendStringCmd', function( cmd )
    local userinput = cmd:Get()
    if userinput:find( 'con_logfile' ) then
        printc( 255, 0, 0, 255, 'blocked con_logfile (from requesifycom)' )
        -- cmd:Set( '' )
        return
    end

    if userinput:find( 'echo' ) == 1 then
        if interaction.handle then
            local tbl = {}
            for w in userinput:gmatch( '%S+' ) do
                tbl[#tbl + 1] = w
            end
            if tbl[1] == 'echo' then
                table.remove( tbl, 1 )
                interaction:write( table.concat( tbl, ' ' ) )
            end
            -- interaction:write( contents )
        end
        return
    end
end )]]

local filename = engine.GetGameDir() .. '\\console.log'
local file = io.open( filename, 'w' ) -- we could use a+, but i remembered it bugged out or smth, test it again for me thanks
file:setvbuf( 'no' )
callbacks.Register( 'FireGameEvent', function( event )
    if event:GetName() == 'party_chat' then
        local text, steamid64
        text = event:GetString( 'text' )
        steamid64 = tonumber( event:GetString( 'steamid' ) )
        if text:find( '!' ) == 1 then
            file:write( string.format( '%s : %s', steam.GetPlayerName( steamid64 ), text ) )
            file:flush()
        end
    end
end )

