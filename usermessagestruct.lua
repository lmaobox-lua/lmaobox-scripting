local UserMessage, UserMessageStruct

UserMessage = { 'Train', 'HudText', 'SayText', 'SayText2', 'TextMsg', 'ResetHUD', 'GameTitle', 'ItemPickup', 'ShowMenu', 'Shake', 'Fade',
                'VGUIMenu', 'Rumble', 'CloseCaption', 'SendAudio', 'VoiceMask', 'RequestState', 'Damage', 'HintText', 'KeyHintText',
                'HudMsg', 'AmmoDenied', 'AchievementEvent', 'UpdateRadar', 'VoiceSubtitle', 'HudNotify', 'HudNotifyCustom',
                'PlayerStatsUpdate', 'MapStatsUpdate', 'PlayerIgnited', 'PlayerIgnitedInv', 'HudArenaNotify', 'UpdateAchievement',
                'TrainingMsg', 'TrainingObjective', 'DamageDodged', 'PlayerJarated', 'PlayerExtinguished', 'PlayerJaratedFade',
                'PlayerShieldBlocked', 'BreakModel', 'CheapBreakModel', 'BreakModel_Pumpkin', 'BreakModelRocketDud', 'CallVoteFailed',
                'VoteStart', 'VotePass', 'VoteFailed', 'VoteSetup', 'PlayerBonusPoints', 'RDTeamPointsChanged', 'SpawnFlyingBird',
                'PlayerGodRayEffect', 'PlayerTeleportHomeEffect', 'MVMStatsReset', 'MVMPlayerEvent', 'MVMResetPlayerStats', 'MVMWaveFailed',
                'MVMAnnouncement', 'MVMPlayerUpgradedEvent', 'MVMVictory', 'MVMWaveChange', 'MVMLocalPlayerUpgradesClear',
                'MVMLocalPlayerUpgradesValue', 'MVMResetPlayerWaveSpendingStats', 'MVMLocalPlayerWaveSpendingValue',
                'MVMResetPlayerUpgradeSpending', 'MVMServerKickTimeUpdate', 'PlayerLoadoutUpdated', 'PlayerTauntSoundLoopStart',
                'PlayerTauntSoundLoopEnd', 'ForcePlayerViewAngles', 'BonusDucks', 'EOTLDuckEvent', 'PlayerPickupWeapon',
                'QuestObjectiveCompleted', 'SPHapWeapEvent', 'HapDmg', 'HapPunch', 'HapSetDrag', 'HapSetConst', 'HapMeleeContact' }
UserMessage[0] = 'Geiger'

UserMessageStruct = [[
    SayText {
        bytes  index          = 1,
        bool   is_text_chat   = 2,
    },
    SayText2 {
        bytes  index          = 1,
        bool   is_text_chat   = 2,
        string chat_type      = 3,
        string player_name    = 4,
        string chat_text      = 5,
    },
    Fade {
        duration = 1,
        holdTime = 2,
        fadeFlags = 3,
        red = 4,
        green = 5,
        blue = 6,
        alpha = 7,
    },
    ...
]]

local DispatchUserMessageStruct = function( msg, name )
    local iStart, iEnd = UserMessageStruct:find( name )

    if not iEnd then
        return
    end

    local constructor = UserMessageStruct:match( '%{(.-)%}', iEnd ):gsub( '[=,]', '' )
    local struct, type, key, keyindex = {}, nil, nil, nil
    if constructor then
        for any in constructor:gmatch( '%S+' ) do
            if type == nil then
                type = any
                goto continue
            end

            if key == nil then
                key = any
                goto continue
            end

            if keyindex == nil then
                keyindex = tonumber( any )
                struct[key] = type:gsub( '%S+', {
                    ['bytes'] = 'ReadByte',
                    ['bool'] = 'ReadByte',
                    ['string'] = 'ReadString'
                 } )
                table.insert( struct, keyindex, key )
                type, key, keyindex = nil, nil, nil
            end

            ::continue::
        end
    end

    local structext = {}

    for i = 1, #struct do
        local k, databits, pdatabits = struct[i], nil, 0
        struct[k], databits = msg[struct[k]]( msg, 256 )
        structext[k] = {
            databits = databits,
            length = databits - pdatabits
         }

        function structext:set( data, over_original_bits ) end
        pdatabits = databits
        struct[i] = undef
    end

    msg:Reset()

    return struct
end

callbacks.Register( 'DispatchUserMessage', 'IOI', function( msg )
    local id, databits, databytes
    id = msg:GetID()
    databits = msg:GetDataBits()
    databytes = msg:GetDataBytes()
    --local data = DispatchUserMessageStruct( msg, UserMessage[id] )
    print( UserMessage[id] )
    local playerindex = msg:ReadByte()
    print(playerindex)
end)