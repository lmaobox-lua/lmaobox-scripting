local kv = [[
    "upgrades" {
        "itemslot" ""
        "upgrade" ""
        "count" ""
    }
]]

--region: idc
local umsg_name = {
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
    'HapMeleeContact'
 }
--endregion

callbacks.Register( 'DispatchUserMessage', function( u )
print(umsg_name[u:GetID()])
end )

callbacks.Register( 'Draw', function()
    if globals.FrameCount() % (1 // globals.TickInterval()) == 0 then
        client.Command( 'bot_command all addcond 0', '' )
        client.Command( 'bot_command all addcond 71', '' )
        client.Command( 'tf_mvm_tank_kill', '' )
    end
end )
