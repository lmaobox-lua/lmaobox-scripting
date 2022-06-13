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
local MsgFunc_HudText = function( m )
    local proto, i = {}, {}
    proto.index, i[#i + 1] = m:ReadByte()
    proto.chat_text, i[#i + 1] = m:ReadString( 256 )
    return proto, i
end

local MsgFunc_SayText = function( m )
    local proto, i = {}, {}
    proto.index, i[#i + 1] = m:ReadByte()
    proto.chat_text, i[#i + 1] = m:ReadString( 256 )
    return proto, i
end

local MsgFunc_SayText2 = function( m )
    local proto, i = {}, {}
    proto.index, i[#i + 1] = m:ReadByte()
    proto.is_text_chat, i[#i + 1] = m:ReadByte()
    proto.chat_type, i[#i + 1] = m:ReadString( 256 )
    proto.player_name, i[#i + 1] = m:ReadString( 256 )
    proto.chat_text, i[#i + 1] = m:ReadString( 256 )
    return proto, i
end

local MsgFunc_TextMsg = function( m )
    local proto, i = {}, {}
    proto.msg_dest, i[#i + 1] = m:ReadByte()
    proto.chat_text, i[#i + 1] = m:ReadByte()
    return proto, i
end

local MsgFunc_Shake = function( m ) end

local MsgFunc_Fade = function( m ) end

local MsgFunc_Rumble = function( m ) end

local MsgFunc_CallVoteFailed = function( m )
    local proto, i = {}, {}
    proto.reason, i[#i + 1] = msg:ReadByte()
    proto.time, i[#i + 1] = msg:ReadInt( 16 )
    return proto, i
end

local MsgFunc_VoteStart = function( m )
    local proto, i = {}, {}
    proto.team, i[#i + 1] = msg:ReadByte()
    proto.index, i[#i + 1] = msg:ReadByte()
    proto.disp_str, i[#i + 1] = msg:ReadString( 256 )
    proto.details_str, i[#i + 1] = msg:ReadString( 256 )
    proto.is_yes_no_vote, i[#i + 1] = msg:ReadByte()
    return proto, i
end

local MsgFunc_VotePass = function( m )
    local proto, i = {}, {}
    proto.team, i[#i + 1] = msg:ReadByte()
    proto.disp_str, i[#i + 1] = msg:ReadString( 256 )
    proto.details_str, i[#i + 1] = msg:ReadString( 256 )
    return proto, i
end

local MsgFunc_VoteFailed = function( m )
    local proto, i = {}, {}
    proto.team, i[#i + 1] = msg:ReadByte()
    proto.reason, i[#i + 1] = msg:ReadByte()
    return proto, i
end

local MsgFunc_VoteSetup = function( m )
    local proto, i = {}, {}
    --
end

-- LuaFormatter on

local o = {
    [Geiger] = nil,
    [Train] = nil,
    [HudText] = nil,
    [SayText] = MsgFunc_SayText,
    [SayText2] = MsgFunc_SayText2,
    [TextMsg] = MsgFunc_TextMsg,
    [ResetHUD] = nil,
    [GameTitle] = nil,
    [ItemPickup] = nil,
    [ShowMenu] = nil,
    [Shake] = nil,
    [Fade] = nil,
    [VGUIMenu] = nil,
    [Rumble] = nil,
    [CloseCaption] = nil,
    [SendAudio] = nil,
    [VoiceMask] = nil,
    [RequestState] = nil,
    [Damage] = nil,
    [HintText] = nil,
    [KeyHintText] = nil,
    [HudMsg] = nil,
    [AmmoDenied] = nil,
    [AchievementEvent] = nil,
    [UpdateRadar] = nil,
    [VoiceSubtitle] = nil,
    [HudNotify] = nil,
    [HudNotifyCustom] = nil,
    [PlayerStatsUpdate] = nil,
    [MapStatsUpdate] = nil,
    [PlayerIgnited] = nil,
    [PlayerIgnitedInv] = nil,
    [HudArenaNotify] = nil,
    [UpdateAchievement] = nil,
    [TrainingMsg] = nil,
    [TrainingObjective] = nil,
    [DamageDodged] = nil,
    [PlayerJarated] = nil,
    [PlayerExtinguished] = nil,
    [PlayerJaratedFade] = nil,
    [PlayerShieldBlocked] = nil,
    [BreakModel] = nil,
    [CheapBreakModel] = nil,
    [BreakModel_Pumpkin] = nil,
    [BreakModelRocketDud] = nil,
    [CallVoteFailed] = MsgFunc_CallVoteFailed,
    [VoteStart] = MsgFunc_VoteStart,
    [VotePass] = MsgFunc_VotePass,
    [VoteFailed] = MsgFunc_VoteFailed,
    [VoteSetup] = MsgFunc_VoteSetup,
    [PlayerBonusPoints] = nil,
    [RDTeamPointsChanged] = nil,
    [SpawnFlyingBird] = nil,
    [PlayerGodRayEffect] = nil,
    [PlayerTeleportHomeEffect] = nil,
    [MVMStatsReset] = nil,
    [MVMPlayerEvent] = nil,
    [MVMResetPlayerStats] = nil,
    [MVMWaveFailed] = nil,
    [MVMAnnouncement] = nil,
    [MVMPlayerUpgradedEvent] = nil,
    [MVMVictory] = nil,
    [MVMWaveChange] = nil,
    [MVMLocalPlayerUpgradesClear] = nil,
    [MVMLocalPlayerUpgradesValue] = nil,
    [MVMResetPlayerWaveSpendingStats] = nil,
    [MVMLocalPlayerWaveSpendingValue] = nil,
    [MVMResetPlayerUpgradeSpending] = nil,
    [MVMServerKickTimeUpdate] = nil,
    [PlayerLoadoutUpdated] = nil,
    [PlayerTauntSoundLoopStart] = nil,
    [PlayerTauntSoundLoopEnd] = nil,
    [ForcePlayerViewAngles] = nil,
    [BonusDucks] = nil,
    [EOTLDuckEvent] = nil,
    [PlayerPickupWeapon] = nil,
    [QuestObjectiveCompleted] = nil,
    [SPHapWeapEvent] = nil,
    [HapDmg] = nil,
    [HapPunch] = nil,
    [HapSetDrag] = nil,
    [HapSetConst] = nil,
    [HapMeleeContact] = nil,
 }

local deserialize_user_message = function( id, data )
    local deserialized, location = o[id]( data )
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
            UnloadScript( GetScriptName() )
        end
    end
end)

local make_unique_string = function( prefix ) return table.concat( { prefix or '', engine.RandomFloat( 0, 1 ), GetScriptName() }, '_' ) end

local uml = {
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
        printc( 255 // (id * 0.01), 255, 255 // (id * 0.03), 255, string.format( 'msg->id(): %s (%s)', uml[id], id ) )
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
