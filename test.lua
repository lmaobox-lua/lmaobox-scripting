callbacks.Unregister( 'CreateMove', 'think' )
callbacks.Register( 'CreateMove', 'think', function( cmd )
    local me = entities.GetLocalPlayer()
    local wpn = me:GetPropEntity( 'm_hActiveWeapon' )
    local iReloadMode = wpn:GetPropInt("m_iReloadMode")

    local pitch, yaw, roll = cmd:GetViewAngles()
    cmd:SetViewAngles( pitch, yaw + 90, roll )
    -- print(cmd:GetSendPacket())
    -- cmd:SetSendPacket( true )
    local buttons = cmd:GetButtons()
    local is_in_reload = (buttons & IN_RELOAD) ~= 0 or iReloadMode == 1
    if is_in_reload then
        print( string.format( 'button: %d, tick: %d', buttons, cmd.tick_count ) )
        cmd:SetButtons( buttons & ~IN_RELOAD )
        engine.SendKeyValues( [[
            "+inspect_server" {

            }
        ]] )

        --wpn:SetPropInt( 0, 'm_iReloadMode' )
    end


end )

--[[
    bool CTFWeaponBase::IsReloading()
{
    // m_bInReload in CBaseCombatWeapon, 12 bytes from flNextPrimaryAttack offset)
    bool& bInReload = GetMember<bool>(gd.BaseCombatWeapon__flNextPrimaryAttack+12);
    // m_iReloadMode deals with reloading rocket launchers etc
    return bInReload || iReloadMode()!=0;
}

if ( pOwner->m_nButtons & (IN_ATTACK | IN_ATTACK2) && m_iClip1 > 0 )
			{
				m_bInReload = false;
				return;
			}
]]
