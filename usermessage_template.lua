--[[ 
SayText2
xref:
| Name         | Type   | Detail                                                       |
| ------------ | ------ | ------------------------------------------------------------ |
| ent_idx      | number | Client index of person who send message, or 0 for the server |
| is_text_chat | number |                                                              |
| chat_type    | string |                                                              |
| player_name  | string |                                                              |
| chat_text    | string |                                                              |
ent_idx, is_text_chat, chat_type, player_name, chat_text
]] --
--[[ 
SayText
xref: 
| Name      | Type   | Detail |
| --------- | ------ | ------ |
| ent_idx   | number |        |
| chat_text | string |        |
ent_idx, chat_text
]] --
--[[ 
Fade
xref: __MsgFunc_Fade
| Name      | Type   | Detail |
| --------- | ------ | ------ |
| duration  | number |        |
| holdTime  | number |        |
| fadeFlags | number |        |
| red       | number |        |
| green     |        |        |
| blue      |        |        |
| alpha     |        |        |
]] --
--[[
VGUIMenu
xref: __MsgFunc_VGUIMenu
| Name      | Type   | Detail |
| --------- | ------ | ------ |
| panelname | string |        |
| bShow     | number |        |
| count     | number |        |
| name      | string |        |
| data      | string |        |
]] --
--[[
Rumble
xref: __MsgFunc_Rumble
| Name          | Type   | Detail |
| ------------- | ------ | ------ |
| waveformIndex | number |        |
| rumbleData    | number |        |
| rumbleFlags   | number |        |
]] --
local umsg_lookup = {
    [Geiger] = function( m ) end,
    [Train] = function( m ) end,
    [HudText] = function( m ) end,
    [SayText] = function( m )
        local a, b = {}, {
            [1] = 0,
         }
        a[#a + 1], b[#b + 1] = m:ReadByte()
        a[#a + 1], b[#b + 1] = m:ReadString( 256 )
    end,
    [SayText2] = function( m )
        local a, b = {}, {
            [1] = 0,
         }
        a[#a + 1], b[#b + 1] = m:ReadByte()
        a[#a + 1], b[#b + 1] = m:ReadByte()
        a[#a + 1], b[#b + 1] = m:ReadString( 256 )
        a[#a + 1], b[#b + 1] = m:ReadString( 256 )
        a[#a + 1], b[#b + 1] = m:ReadString( 256 )
        return a, b
    end,
    [TextMsg] = function( m ) end,
    [ResetHUD] = function( m ) end,
    [GameTitle] = function( m ) end,
    [ItemPickup] = function( m ) end,
    [ShowMenu] = function( m ) end,
    [Shake] = function( m ) end,
    [Fade] = function( m ) end,
    [VGUIMenu] = function( m ) end,
    [Rumble] = function( m ) end,
    [CloseCaption] = function( m ) end,
    [SendAudio] = function( m ) end,
    [VoiceMask] = function( m ) end,
    [RequestState] = function( m ) end,
    [Damage] = function( m ) end,
    [HintText] = function( m ) end,
    [KeyHintText] = function( m ) end,
    [HudMsg] = function( m ) end,
    [AmmoDenied] = function( m ) end,
    [AchievementEvent] = function( m ) end,
    [UpdateRadar] = function( m ) end,
    [VoiceSubtitle] = function( m ) end,
    [HudNotify] = function( m ) end,
    [HudNotifyCustom] = function( m ) end,
    [PlayerStatsUpdate] = function( m ) end,
    [MapStatsUpdate] = function( m ) end,
    [PlayerIgnited] = function( m ) end,
    [PlayerIgnitedInv] = function( m ) end,
    [HudArenaNotify] = function( m ) end,
    [UpdateAchievement] = function( m ) end,
    [TrainingMsg] = function( m ) end,
    [TrainingObjective] = function( m ) end,
    [DamageDodged] = function( m ) end,
    [PlayerJarated] = function( m ) end,
    [PlayerExtinguished] = function( m ) end,
    [PlayerJaratedFade] = function( m ) end,
    [PlayerShieldBlocked] = function( m ) end,
    [BreakModel] = function( m ) end,
    [CheapBreakModel] = function( m ) end,
    [BreakModel_Pumpkin] = function( m ) end,
    [BreakModelRocketDud] = function( m ) end,
    [CallVoteFailed] = function( m ) end,
    [VoteStart] = function( m ) end,
    [VotePass] = function( m ) end,
    [VoteFailed] = function( m ) end,
    [VoteSetup] = function( m ) end,
    [PlayerBonusPoints] = function( m ) end,
    [RDTeamPointsChanged] = function( m ) end,
    [SpawnFlyingBird] = function( m ) end,
    [PlayerGodRayEffect] = function( m ) end,
    [PlayerTeleportHomeEffect] = function( m ) end,
    [MVMStatsReset] = function( m ) end,
    [MVMPlayerEvent] = function( m ) end,
    [MVMResetPlayerStats] = function( m ) end,
    [MVMWaveFailed] = function( m ) end,
    [MVMAnnouncement] = function( m ) end,
    [MVMPlayerUpgradedEvent] = function( m ) end,
    [MVMVictory] = function( m ) end,
    [MVMWaveChange] = function( m ) end,
    [MVMLocalPlayerUpgradesClear] = function( m ) end,
    [MVMLocalPlayerUpgradesValue] = function( m ) end,
    [MVMResetPlayerWaveSpendingStats] = function( m ) end,
    [MVMLocalPlayerWaveSpendingValue] = function( m ) end,
    [MVMResetPlayerUpgradeSpending] = function( m ) end,
    [MVMServerKickTimeUpdate] = function( m ) end,
    [PlayerLoadoutUpdated] = function( m ) end,
    [PlayerTauntSoundLoopStart] = function( m ) end,
    [PlayerTauntSoundLoopEnd] = function( m ) end,
    [ForcePlayerViewAngles] = function( m ) end,
    [BonusDucks] = function( m ) end,
    [EOTLDuckEvent] = function( m ) end,
    [PlayerPickupWeapon] = function( m ) end,
    [QuestObjectiveCompleted] = function( m ) end,
    [SPHapWeapEvent] = function( m ) end,
    [HapDmg] = function( m ) end,
    [HapPunch] = function( m ) end,
    [HapSetDrag] = function( m ) end,
    [HapSetConst] = function( m ) end,
    [HapMeleeContact] = function( m ) end,
 }

local deserialize_user_message = function( id, data )
    local deserialized, location = umsg_lookup[id]( data )
    if next( deserialized ) == nil then
        printc( 255, 255, 255, 255, string.format( '[usermessage][deserializer] msg->id: %s isn\'t supported, sorry.', id ) )
        return
    end
    function deserialized:Unpack( filter ) return table.unpack( deserialized, 1, #deserialized ) end
    function deserialized:SetBitPos( pos )
        data:SetCurBit( pos )
        return data
    end
    return deserialized
end

local self_unload_module = (function()
    local _, __, filepath = pcall( debug.getlocal, 4, 1 )
    for id, lib in pairs( package.loaded ) do
            local matched = string.match( GetScriptName(), id, 1, true )
            if matched then
                printc( 0, 255, 0, 255, string.format( '[packages.loaded]| found: %q', matched ) )
                package.loaded[matched] = undef
                printc( 0, 255, 255, 255, string.format( '[packages.loaded]| %q is unloaded (method called on : %q)', matched, filepath ) )
            end
    end
end)

local make_unique_string = function( prefix ) return table.concat( { prefix or '', engine.RandomFloat( 0, 1 ), GetScriptName() }, '_' ) end

local main = function()
    UnloadScript( GetScriptName() )
    local a = 'DispatchUserMessage'
    callbacks.Register( a, make_unique_string( a ), function( msg )
        if msg:GetID() == SayText2 then
            local t = deserialize_user_message( SayText2, msg )
            local ent_idx, is_text_chat, chat_type, player_name, player_text = t:Unpack()
        end
    end )
    callbacks.Register( a, make_unique_string( a ), function( msg ) end )
    callbacks.Register( a, make_unique_string( a ), function( msg )
        local id = msg:GetID()
        local a = {
            [0] = 'Geiger',
            'Train',
            'HudText',
            'SayText',
            'SayText2',
            'TextMsg',
            'ResetHUD',
            'GameTitle',
            'ItemPickup',
            'ShowMenu',
            'Shake',
            'Fade',
            'VGUIMenu',
            'Rumble',
            'CloseCaption',
            'SendAudio',
            'VoiceMask',
            'RequestState',
            'Damage',
            'HintText',
            'KeyHintText',
            'HudMsg',
            'AmmoDenied',
            'AchievementEvent',
            'UpdateRadar',
            'VoiceSubtitle',
            'HudNotify',
            'HudNotifyCustom',
            'PlayerStatsUpdate',
            'MapStatsUpdate',
            'PlayerIgnited',
            'PlayerIgnitedInv',
            'HudArenaNotify',
            'UpdateAchievement',
            'TrainingMsg',
            'TrainingObjective',
            'DamageDodged',
            'PlayerJarated',
            'PlayerExtinguished',
            'PlayerJaratedFade',
            'PlayerShieldBlocked',
            'BreakModel',
            'CheapBreakModel',
            'BreakModel_Pumpkin',
            'BreakModelRocketDud',
            'CallVoteFailed',
            'VoteStart',
            'VotePass',
            'VoteFailed',
            'VoteSetup',
            'PlayerBonusPoints',
            'RDTeamPointsChanged',
            'SpawnFlyingBird',
            'PlayerGodRayEffect',
            'PlayerTeleportHomeEffect',
            'MVMStatsReset',
            'MVMPlayerEvent',
            'MVMResetPlayerStats',
            'MVMWaveFailed',
            'MVMAnnouncement',
            'MVMPlayerUpgradedEvent',
            'MVMVictory',
            'MVMWaveChange',
            'MVMLocalPlayerUpgradesClear',
            'MVMLocalPlayerUpgradesValue',
            'MVMResetPlayerWaveSpendingStats',
            'MVMLocalPlayerWaveSpendingValue',
            'MVMResetPlayerUpgradeSpending',
            'MVMServerKickTimeUpdate',
            'PlayerLoadoutUpdated',
            'PlayerTauntSoundLoopStart',
            'PlayerTauntSoundLoopEnd',
            'ForcePlayerViewAngles',
            'BonusDucks',
            'EOTLDuckEvent',
            'PlayerPickupWeapon',
            'QuestObjectiveCompleted',
            'SPHapWeapEvent',
            'HapDmg',
            'HapPunch',
            'HapSetDrag',
            'HapSetConst',
            'HapMeleeContact',
         }
        printc( 255 // (id * 0.01), 255, 255 // (id * 0.03), 255, string.format( 'msg->id(): %s (%s)', a[id], id ) )
    end )
    -- id 16 can be used to check if voicebanned or not xref HandleVoiceMaskMsg
    -- __MsgFunc_PlayerJaratedFade
end

if pcall( debug.getlocal, 4, 1 ) then
    -- executed as module
    print( 'this message appears when module entries packages.loaded' )
    return {
        deserialize_user_message = deserialize_user_message,
        self_unload_module = self_unload_module,
        make_unique_string = make_unique_string,
     }
else
    -- executed as main script
    self_unload_module()
    main()
end

-- region: input / output
--[[
local list = {
    ['parse'] = function( cmd )
        local buf = string.format( 'parse: %s, number: %s, vector: %s, boolean: %s', cmd:string(), cmd:number(),
                                   table.concat( cmd:vec(), '; ' ), cmd:boolean() )
        print( buf )
    end,
    ['lua_unload'] = function( cmd )
        local base_dir, buf = os.getenv( 'LOCALAPPDATA' ), cmd:string()
        local final = table.concat( { base_dir, (buf:gsub( '/', '/' )) }, '//' )
        local status = UnloadScript( final )
        print( final, status )
    end,
 }]]
