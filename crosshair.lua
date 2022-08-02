local myfont = draw.CreateFont( "Verdana", 16, 800 )

local trace, entity
callbacks.Register( 'CreateMove', function()
    local me = entities.GetLocalPlayer()

    if not me then
        return
    end

    local source = me:GetAbsOrigin() + engine.GetViewAngles():Forward() * 10
    local destination = me:GetAbsOrigin() + engine.GetViewAngles():Forward() * MAX_TRACE_LENGTH

    trace = engine.TraceLine( source, destination, MASK_SOLID | CONTENTS_DEBRIS )

    --[[
    trace_t tr;
	Vector vecStart, vecEnd;
	VectorMA( MainViewOrigin(), MAX_TRACE_LENGTH, MainViewForward(), vecEnd );
	VectorMA( MainViewOrigin(), 10,   MainViewForward(), vecStart );
    ]]

    -- g_vecRenderOrigin
    -- g_vecVForward
end )

callbacks.Register( 'Draw', function()
    if trace then
        draw.SetFont( myfont )
        draw.Color( 0, 255, 0, 120 )
        local x, y = table.unpack( client.WorldToScreen( trace.startpos ) )
        local x1, y1 =  table.unpack( client.WorldToScreen( trace.endpos ) )
        draw.Line( x, y, x1, y1 )
        if trace.entity:IsPlayer() then
            local w, h = draw.GetScreenSize()
            draw.Text( w // 2, h // 2,
                string.format( 'I am looking at %s - dist : %s', trace.entity:GetName(), trace.fraction * 1000 ) )
            ---print( "I am looking at " .. trace.entity:GetClass() )
            ---print( "Distance to entity: " .. trace.fraction * 1000 )
        end
    end
end )

--[[
void C_TFPlayer::UpdateIDTarget()
{
	C_TFPlayer *pLocalPlayer = C_TFPlayer::GetLocalTFPlayer();
	if ( !pLocalPlayer || !IsLocalPlayer() )
		return;

	// don't show IDs if mp_fadetoblack is on
	if ( GetTeamNumber() > TEAM_SPECTATOR && mp_fadetoblack.GetBool() && !IsAlive() )
	{
		m_iIDEntIndex = 0;
		return;
	}

	if ( m_iForcedIDTarget )
	{
		m_iIDEntIndex = m_iForcedIDTarget;
		return;
	}

	// If we're in deathcam, ID our killer
	if ( (GetObserverMode() == OBS_MODE_DEATHCAM || GetObserverMode() == OBS_MODE_CHASE) && GetObserverTarget() && GetObserverTarget() != GetLocalTFPlayer() )
	{
		m_iIDEntIndex = GetObserverTarget()->entindex();
		return;
	}

	// Clear old target and find a new one
	m_iIDEntIndex = 0;

	trace_t tr;
	Vector vecStart, vecEnd;
	VectorMA( MainViewOrigin(), MAX_TRACE_LENGTH, MainViewForward(), vecEnd );
	VectorMA( MainViewOrigin(), 10,   MainViewForward(), vecStart );

	// If we're in observer mode, ignore our observer target. Otherwise, ignore ourselves.
	if ( IsObserver() )
	{
		UTIL_TraceLine( vecStart, vecEnd, MASK_SOLID, GetObserverTarget(), COLLISION_GROUP_NONE, &tr );
	}
	else
	{
		// Add DEBRIS when a medic has revive (for tracing against revive markers)
		int iReviveMedic = 0;
		CALL_ATTRIB_HOOK_INT( iReviveMedic, revive );
		if ( TFGameRules() && TFGameRules()->GameModeUsesUpgrades() && pLocalPlayer->IsPlayerClass( TF_CLASS_MEDIC ) )
		{
			iReviveMedic = 1;
		}

		int nMask = MASK_SOLID | CONTENTS_DEBRIS;
		UTIL_TraceLine( vecStart, vecEnd, nMask, this, COLLISION_GROUP_NONE, &tr );
	}

	bool bIsEnemyPlayer = false;

	if ( tr.m_pEnt && tr.m_pEnt->IsPlayer() )
	{
		// It's okay to start solid against enemies because we sometimes press right against them
		bIsEnemyPlayer = GetTeamNumber() != tr.m_pEnt->GetTeamNumber();
	}

	if ( ( !tr.startsolid || bIsEnemyPlayer ) && tr.DidHitNonWorldEntity() )
	{
		C_BaseEntity *pEntity = tr.m_pEnt;

		if ( pEntity && ( pEntity != this ) )
		{
			m_iIDEntIndex = pEntity->entindex();
		}
	}
}
]]
