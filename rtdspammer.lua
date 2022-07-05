local make_clean_string = function( original )
    -- filter control characters
    original = string.gsub( original, '%c', '' )
    -- escape magic characters
    original = string.gsub( original, '%%', '%%%%' )
    return original -- modified
end

local UserMessage = { 'Train', 'HudText', 'SayText', 'SayText2', 'TextMsg', 'ResetHUD', 'GameTitle', 'ItemPickup', 'ShowMenu', 'Shake',
                      'Fade', 'VGUIMenu', 'Rumble', 'CloseCaption', 'SendAudio', 'VoiceMask', 'RequestState', 'Damage', 'HintText',
                      'KeyHintText', 'HudMsg', 'AmmoDenied', 'AchievementEvent', 'UpdateRadar', 'VoiceSubtitle', 'HudNotify',
                      'HudNotifyCustom', 'PlayerStatsUpdate', 'MapStatsUpdate', 'PlayerIgnited', 'PlayerIgnitedInv', 'HudArenaNotify',
                      'UpdateAchievement', 'TrainingMsg', 'TrainingObjective', 'DamageDodged', 'PlayerJarated', 'PlayerExtinguished',
                      'PlayerJaratedFade', 'PlayerShieldBlocked', 'BreakModel', 'CheapBreakModel', 'BreakModel_Pumpkin',
                      'BreakModelRocketDud', 'CallVoteFailed', 'VoteStart', 'VotePass', 'VoteFailed', 'VoteSetup', 'PlayerBonusPoints',
                      'RDTeamPointsChanged', 'SpawnFlyingBird', 'PlayerGodRayEffect', 'PlayerTeleportHomeEffect', 'MVMStatsReset',
                      'MVMPlayerEvent', 'MVMResetPlayerStats', 'MVMWaveFailed', 'MVMAnnouncement', 'MVMPlayerUpgradedEvent', 'MVMVictory',
                      'MVMWaveChange', 'MVMLocalPlayerUpgradesClear', 'MVMLocalPlayerUpgradesValue', 'MVMResetPlayerWaveSpendingStats',
                      'MVMLocalPlayerWaveSpendingValue', 'MVMResetPlayerUpgradeSpending', 'MVMServerKickTimeUpdate', 'PlayerLoadoutUpdated',
                      'PlayerTauntSoundLoopStart', 'PlayerTauntSoundLoopEnd', 'ForcePlayerViewAngles', 'BonusDucks', 'EOTLDuckEvent',
                      'PlayerPickupWeapon', 'QuestObjectiveCompleted', 'SPHapWeapEvent', 'HapDmg', 'HapPunch', 'HapSetDrag', 'HapSetConst',
                      'HapMeleeContact' }
UserMessage[0] = 'Geiger'

local dumpBytes = function( msg )
    msg:Reset()
    local buf = {}
    for i = 1, msg:GetDataBytes() do
        buf[i] = msg:ReadByte()
    end
    msg:Reset()
    local dumpstr = table.concat( buf, ' ' )
    return dumpstr
end
--[[
//   byte:   message direction  ( HUD_PRINTCONSOLE, HUD_PRINTNOTIFY, HUD_PRINTCENTER, HUD_PRINTTALK )
//   string: message 
// optional parameters:
//   string: message parameter 1
//   string: message parameter 2
//   string: message parameter 3
//   string: message parameter 4
]]

--[[
    // Position command $position x y 
// x & y are from 0 to 1 to be screen resolution independent
// -1 means center in each dimension
// Effect command $effect <effect number>
// effect 0 is fade in/fade out
// effect 1 is flickery credits
// effect 2 is write out (training room)
// Text color r g b command $color
// Text color r g b command $color2
// fadein time fadeout time / hold time
// $fadein (message fade in time - per character in effect 2)
// $fadeout (message fade out time)
// $holdtime (stay on the screen for this long)
]]

-- Ham TF2 (7,316) got 2 points for killing ok kiki (1,178) [48/50] is saytext2

local function removeColorCode( message )
    local tbl = { message:byte( 1, #message ) }
    for i, val in ipairs( tbl ) do
        if val > 0 and val <= 8 then
            table.remove( tbl, i )
        end
        if val == 7 or val == 8 then
            for i1 = 2, val, 1 do
                table.remove( tbl, i )
            end
        end
    end
    return string.char( table.unpack( tbl ) )
end

local function PartySay( message ) client.Command( string.format( 'tf_party_chat %q', message ), true ) end

local cooldown, timer = 0, 0

--[[
    Color g_ColorBlue( 153, 204, 255, 255 );
Color g_ColorRed( 255, 63, 63, 255 );
Color g_ColorGreen( 153, 255, 153, 255 );
Color g_ColorDarkGreen( 64, 255, 64, 255 );
Color g_ColorYellow( 255, 178, 0, 255 );
Color g_ColorGrey( 204, 204, 204, 255 );
]]

callbacks.Register( 'DispatchUserMessage', function( msg )

    if msg:GetID() == Shake or msg:GetID() == Fade then -- remove effect
        msg:WriteInt( 0, msg:GetDataBytes() )
    end

    if msg:GetID() == SayText2 then
        local entidx, is_text_chat, chat_type, player_name, chat_text
        entidx = msg:ReadByte()
        is_text_chat = msg:ReadByte() -- if set to 1, GetFilterForString gets called
        chat_type = msg:ReadString( 64 ) -- used in ReadLocalizedString
        player_name = msg:ReadString( 64 )
        chat_text = msg:ReadString( 64 )
    end

    -- cl_showtextmsg
    if msg:GetID() == TextMsg then
        local dest, omessage, message, pos
        dest, pos = msg:ReadByte()

        omessage = msg:ReadString( 64 )
        message = removeColorCode( omessage )

        if message:find( '[RTD]' ) then
            if message:match( '%d+' ) then
                cooldown = tonumber( message:match( '%d+' ) )
                timer = cooldown + globals.RealTime()
            end

            if message:find( 'Rolled' ) then
                -- PartySay( message )
            end

            -- [RTD] Your perk has worn off.
            if message:find( 'worn off' ) then
                client.ChatSay( '/rtd' )
            end

            client.ChatPrintf( omessage )
        end

        if pos then
            msg:SetCurBit( pos )
            msg:WriteString( '' )
        end

        -- PartySay( string.format( 'rtd Cooldown: %d', timer ) )
    end

    if msg:GetID() == HudMsg then
        local x, y, r1, g1, b1, a1, r2, g2, b2, a2
        local effect, fadein, fadeout, holdtime, fxtime
        local message

        msg:SetCurBit( 272 )
        message = msg:ReadString( 64 )

        if message:match( '%d+' ) then
            cooldown = tonumber( message:match( '%d+' ) )
            timer = cooldown + globals.RealTime()
        end
    end

end )

callbacks.Register("FireGameEvent", function( event )
    
    if event:GetName() == "player_death" then
        local userid, attacker 
        if entities.GetByUserID(event:GetInt('attacker')) == entities.GetLocalPlayer() then
        end
    end
    
end)

local font_calibri = draw.CreateFont( 'Tahoma', 14, 700, FONTFLAG_OUTLINE | FONTFLAG_DROPSHADOW )
draw.SetFont( font_calibri )
callbacks.Register( 'Draw', function()
    local connected = clientstate.GetClientSignonState() == 6

    if not connected then
        return
    end
    if timer < globals.RealTime() then
        cooldown = 60
        timer = cooldown + globals.RealTime()
        client.ChatSay( '/rtd' )
    end

    if engine.Con_IsVisible() or engine.IsGameUIVisible() then
        return
    end

    draw.Color( 255, 255, 255, 255 )

    local w, h = draw.GetScreenSize()
    w = w // 2
    h = h // 2

    draw.Text( w, h, string.format( 'Next RTD in %ds', math.abs(globals.RealTime() - timer) // 1 ) )
end )
