#CS ===========================================================================
=====================================
|	Stygian Gemstones Farm bot		|
|				TonReuf				|
=====================================
;
; Run this farm bot as Assassin or Mesmer or Ranger
;
; Rewritten for BotsHub: Gahais
; Stygian gemstone farm in the Stygian Veil based on below articles:
https://gwpvx.fandom.com/wiki/Build:Me/A_Stygian_Farmer
https://gwpvx.fandom.com/wiki/Build:R/N_HM_Stygian_Veil_Trapper
; For Mesmer and Assassin this bot works by exploitation of AI pathing bug of Guild Wars
;
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

Opt('MustDeclareVars', True)

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

#Region Configuration
; === Build ===
;Global Const $AME_STYGIAN_SKILLBAR = 'OwVTI4h9X6mSGYFct0E4uM0ZCCA'
Global Const $AME_STYGIAN_SKILLBAR = 'OwVT8ZBPGiHRn5mat0E4uM0ZCC'
;Global Const $MEA_STYGIAN_SKILLBAR = 'OQdUASBPmfS3UyArgrlmA3lhOTQA'
Global Const $MEA_STYGIAN_SKILLBAR = 'OQdTI4x8ZiHRn5mat0E4uM0ZCC'
Global Const $RN_STYGIAN_SKILLBAR = 'OgQTcybiZK5o5Y5wSIXc465o7AA'
Global Const $STYGIAN_RANGER_HERO_SKILLBAR = 'OgMSY5LHQnh0EAAAAAAAA'

; You can select which ranger hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
Global Const $STYGIAN_HERO_PARTY_ID = $ID_ACOLYTE_JIN
;Global Const $STYGIAN_HERO_PARTY_ID = $ID_MARGRID_THE_SLY
;Global Const $STYGIAN_HERO_PARTY_ID = $ID_PYRE_FIERCESHOT
Global Const $STYGIAN_HERO_INDEX = 1

Global Const $STYGIAN_DEADLY_PARADOX			= 1
Global Const $STYGIAN_SHADOWFORM				= 2
Global Const $STYGIAN_WASTRELS_DEMISE			= 3
Global Const $STYGIAN_MINDBENDER				= 4
Global Const $STYGIAN_CHANNELING				= 5
Global Const $STYGIAN_DWARVEN_STABILITY			= 6
Global Const $STYGIAN_SHADOW_OF_HASTE			= 7
Global Const $STYGIAN_DASH						= 8

Global Const $STYGIAN_RANGER_DUST_TRAP			= 1
Global Const $STYGIAN_RANGER_SPIKE_TRAP			= 2
Global Const $STYGIAN_RANGER_FLAME_TRAP			= 3
Global Const $STYGIAN_RANGER_MARK_OF_PAIN		= 4
Global Const $STYGIAN_RANGER_EBON_STANDARD		= 5
Global Const $STYGIAN_RANGER_TRAPPERS_SPEED		= 6
Global Const $STYGIAN_RANGER_WINNOWING			= 7
Global Const $STYGIAN_RANGER_MUDDY_TERRAIN		= 8

; ranger hero
Global Const $STYGIAN_HERO_EDGE_OF_EXTINCTION	= 1
Global Const $STYGIAN_HERO_UNYIELDING_AURA		= 2
Global Const $STYGIAN_HERO_SUCCOR				= 3
#EndRegion Configuration

; ==== Constants ====
Global Const $GEMSTONE_STYGIAN_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- Armor with Skills/HP/Energy runes and 5 blessed insignias (+50 armor when enchanted)' & @CRLF _
	& '- Weapon of Enchanting (20% longer enchantments duration) to make Shadow Form permanent' & @CRLF _
	& ' ' & @CRLF _
	& 'You can run this farm as Assassin or Mesmer or Ranger. Bot will set up build automatically for these professions' & @CRLF _
	& 'This bot farms stygian gemstones (1 of 4 types) in Stygian Veil location' & @CRLF _
	& 'Player needs to have access to Gate of Anguish outpost which has exit to Stygian Veil location' & @CRLF _
	& 'Recommended to have maxed out Lightbringer title. If not maxed out then this farm is good for raising lightbringer rank' & @CRLF _
	& 'Can switch to normal mode in case of low success rate but hard mode has better loots' & @CRLF _
	& 'Gemstones can be exchanged into armbrace of truth (15 of each type) or coffer of whisper (1 of each type)' & @CRLF _
	& 'This farm is based on below articles:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:Me/A_Stygian_Farmer' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:R/N_HM_Stygian_Veil_Trapper' & @CRLF _
	& 'For Mesmer and Assassin this bot works by exploitation of Guild Wars bug in pathing AI, which causes mobs to not attack player' & @CRLF
; Average duration ~ 8 minutes
Global Const $GEMSTONE_STYGIAN_FARM_DURATION = 8 * 60 * 1000
Global Const $MAX_GEMSTONE_STYGIAN_FARM_DURATION = 16 * 60 * 1000
Global Const $STYGIANS_RANGE_SHORT = 800
Global Const $STYGIANS_RANGE_LONG = 1200

Global $stygian_run_options = CloneDictMap($Default_MoveDefend_Options)
$stygian_run_options.Item('defendFunction')		= StygianCheckRunBuffs
$stygian_run_options.Item('moveTimeOut')			= 3 * 60 * 1000
$stygian_run_options.Item('randomFactor')			= 20
$stygian_run_options.Item('hosSkillSlot')			= 0
$stygian_run_options.Item('deathChargeSkillSlot')	= 0
$stygian_run_options.Item('openChests')			= False

Global $stygian_player_profession = $ID_MESMER
Global $gemstone_stygian_farm_setup = False

;~ Main loop function for farming stygian gemstones
Func GemstoneStygianFarm()
	If Not $gemstone_stygian_farm_setup And SetupGemstoneStygianFarm() == $FAIL Then Return $PAUSE

	If GoToStygianVeil() == $FAIL Then Return $FAIL
	Local $result = GemstoneStygianFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared stygian mobs')
	If $result == $FAIL Then Info('Player died. Could not clear stygian mobs')
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost()
	Return $result
EndFunc


Func SetupGemstoneStygianFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		If TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name) == $FAIL Then Return $FAIL
	Else
		ResignAndReturnToOutpost()
	EndIf
	SwitchToHardModeIfEnabled()
	If SetupPlayerStygianFarm() == $FAIL Then Return $FAIL
	If SetupTeamStygianFarm() == $FAIL Then Return $FAIL
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	Sleep(500 + GetPing())
	$gemstone_stygian_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerStygianFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_ASSASSIN
			$stygian_player_profession = $ID_ASSASSIN
			LoadSkillTemplate($AME_STYGIAN_SKILLBAR)
		Case $ID_MESMER
			$stygian_player_profession = $ID_MESMER
			LoadSkillTemplate($MEA_STYGIAN_SKILLBAR)
		Case $ID_RANGER
			$stygian_player_profession = $ID_RANGER
			LoadSkillTemplate($RN_STYGIAN_SKILLBAR)
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Ranger')
			Return $FAIL
	EndSwitch
	Sleep(250 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamStygianFarm()
	Info('Setting up team')
	LeaveParty()
	Sleep(500 + GetPing())
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		AddHero($STYGIAN_HERO_PARTY_ID)
		Sleep(500 + GetPing())
		LoadSkillTemplate($STYGIAN_RANGER_HERO_SKILLBAR, $STYGIAN_HERO_INDEX)
		Sleep(500 + GetPing())
		DisableAllHeroSkills($STYGIAN_HERO_INDEX)
		If GetPartySize() <> 2 Then
			Warn('Could not add ranger hero to team. Team size different than 2')
			Return $FAIL
		EndIf
	EndIf
	Return $SUCCESS
EndFunc


;~ exit gate of Anguish outpost by moving into portal that leads into farming location - Stygian Veil
Func GoToStygianVeil()
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Info('Moving to Stygian Veil')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Stygian Veil
	Local Static $StartX = -364
	Local Static $StartY = -10445
	Local $TimerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		If TimerDiff($TimerZoning) > 120000 Then
			Info('Could not zone to Stygian Veil')
			Return $FAIL
		EndIf
		MoveTo(6798, -15867)
		MoveTo(1315, -17924)
		MoveTo(-785, -18969)
		Move(-1100, -20000, 0)
		Sleep(8000)
	WEnd
EndFunc


Func GemstoneStygianFarmLoop()
	Info('Starting Farm')

	RunStygianFarm(2415, -10451)
	RandomSleep(15000)
	RunStygianFarm(7010, -9050)
	RandomSleep(250)
	If IsPlayerDead() Then Return $FAIL
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoNearestNPCToCoords(7309, -8902)
		Sleep(1000)
		Dialog(0x85)
		Sleep(500)
	EndIf
	Info('Taking Quest')
	Local $TimerQuest = TimerInit()
	While GetQuestByID(0x2E6) == Null And TimerDiff($TimerQuest) < 10000
		GoNearestNPCToCoords(7188, -9108)
		Sleep(1000)
		Dialog(0x82E601)
		Sleep(1000)
	WEnd
	If GetQuestByID(0x2E6) == Null Then Return $FAIL

	Switch $stygian_player_profession
		Case $ID_ASSASSIN, $ID_MESMER
			Return StygianFarmMesmerAssassin()
		Case $ID_RANGER
			Return StygianFarmRanger()
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Ranger')
			Return $FAIL
	EndSwitch
EndFunc


Func StygianFarmMesmerAssassin()
	If IsPlayerDead() Then Return $FAIL
	If StygianJobMesmerAssassin() == $FAIL Then Return $FAIL
	RunStygianFarm(13240, -10006)
	If StygianJobMesmerAssassin() == $FAIL Then Return $FAIL
	MoveTo(13240, -10006)
	; Too hard to aggro the 2 groups after that, so hide in spot then go back to pick up loot
	GoToHidingSpot()
	If IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(StygianCheckSFBuffs, DefaultShouldPickItem, $STYGIANS_RANGE_LONG)
			Sleep(GetPing())
		Next
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


Func StygianFarmRanger()
	If IsPlayerDead() Then Return $FAIL
	UseHeroSkill($STYGIAN_HERO_INDEX, $STYGIAN_HERO_SUCCOR, GetMyAgent())
	GoToHidingSpot()
	If StygianJobRanger() == $FAIL Then Return $FAIL
	MoveTo(7337, -9709)
	MoveTo(9071, -7330)
	If IsPlayerAlive() Then RandomSleep(10000)
	If StygianJobRanger() == $FAIL Then Return $FAIL
	;MoveTo(7337, -9709)
	;MoveTo(9071, -7330)
	;If IsPlayerAlive() Then RandomSleep(10000)
	;If StygianJobRanger() == $FAIL Then Return $FAIL
	;MoveTo(7337, -9709)
	;MoveTo(9071, -7330)
	;If IsPlayerAlive() Then RandomSleep(10000)
	;If StygianJobRanger() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


Func StygianJobMesmerAssassin()
	Local Static $pickItemsAfterFirstWave = False
	If IsPlayerDead() Then Return $FAIL
	GoToHidingSpot()
	If $pickItemsAfterFirstWave And IsPlayerAlive() Then
		Info('Picking up loot')
		; Tripled to secure the looting of items
		For $i = 1 To 3
			PickUpItems(StygianCheckSFBuffs, DefaultShouldPickItem, $STYGIANS_RANGE_LONG)
			Sleep(GetPing())
		Next
	EndIf
	MoveTo(13128, -10084)
	; 0 to get player into the exact location without randomness, spot for cleaning stygian mobs
	MoveTo(13082, -9788, 0)
	RandomSleep(500)
	If IsRecharged($STYGIAN_DWARVEN_STABILITY) Then
		UseSkillEx($STYGIAN_DWARVEN_STABILITY)
		RandomSleep(100)
	EndIf
	UseSkillEx($STYGIAN_SHADOW_OF_HASTE)
	MoveTo(13240, -10006)
	MoveTo(9437, -9283)
	UseSkillEx($STYGIAN_MINDBENDER)
	; spot to aggro mobs
	MoveTo(8567, -9050)
	RandomSleep(200)
	MoveTo(12376, -9557)
	RandomSleep(1500)
	; this ends shadow of haste and transfers player into spot
	UseSkillEx($STYGIAN_DASH)
	; waiting for all mobs to come
	Sleep(12500)
	KillStygianMobsUsingWastrelSkills()
	$pickItemsAfterFirstWave = True
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func StygianJobRanger()
	If IsPlayerDead() Then Return $FAIL
	MoveTo(10844, -10205)
	MoveTo(10313, -11156)
	MoveTo(8269, -11160, 10)
	CommandHero($STYGIAN_HERO_INDEX, 9492, -11484)
	If IsRecharged($STYGIAN_RANGER_WINNOWING) Then UseSkillEx($STYGIAN_RANGER_WINNOWING)
	RandomSleep(2000)
	MoveTo(8177, -11171, 10)
	If IsRecharged($STYGIAN_RANGER_TRAPPERS_SPEED) Then UseSkillEx($STYGIAN_RANGER_TRAPPERS_SPEED)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_DUST_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_DUST_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_SPIKE_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_SPIKE_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_FLAME_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_FLAME_TRAP)
	If IsRecharged($STYGIAN_RANGER_TRAPPERS_SPEED) Then UseSkillEx($STYGIAN_RANGER_TRAPPERS_SPEED)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_SPIKE_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_SPIKE_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_FLAME_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_FLAME_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_DUST_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_DUST_TRAP)
	If IsRecharged($STYGIAN_RANGER_MUDDY_TERRAIN) Then UseSkillEx($STYGIAN_RANGER_MUDDY_TERRAIN)
	RandomSleep(2000)
	If IsRecharged($STYGIAN_RANGER_TRAPPERS_SPEED) Then UseSkillEx($STYGIAN_RANGER_TRAPPERS_SPEED)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_SPIKE_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_SPIKE_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_FLAME_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_FLAME_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_DUST_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_DUST_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_SPIKE_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_SPIKE_TRAP)
	While IsPlayerAlive() And Not IsRecharged($STYGIAN_RANGER_FLAME_TRAP)
		RandomSleep(100)
	WEnd
	UseSkillEx($STYGIAN_RANGER_FLAME_TRAP)
	UseHeroSkill($STYGIAN_HERO_INDEX, $STYGIAN_HERO_EDGE_OF_EXTINCTION)
	;TargetNearestEnemy()
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeTarget($target)
	UseSkill($STYGIAN_RANGER_MARK_OF_PAIN, $target)
	While IsPlayerAlive() And Not GetHasHex($target)
		RandomSleep(100)
	WEnd
	MoveTo(8368, -11244)
	If IsRecharged($STYGIAN_RANGER_EBON_STANDARD) Then UseSkillEx($STYGIAN_RANGER_EBON_STANDARD)
	While CountFoesInRangeOfAgent(GetMyAgent(), $STYGIANS_RANGE_LONG) > 0 And IsPlayerAlive()
		If CheckStuck('Stygian job ranger', $MAX_GEMSTONE_STYGIAN_FARM_DURATION) == $FAIL Then Return $FAIL
		RandomSleep(100)
	WEnd
	CancelAll()
	RandomSleep(500)
	If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $STYGIANS_RANGE_LONG)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KillStygianMobsUsingWastrelSkills()
	Local $me, $target, $distance

	While CountFoesInRangeOfAgent(GetMyAgent(), $STYGIANS_RANGE_LONG) > 0 And IsPlayerAlive()
		If CheckStuck('Stygian fight mesmer/assassin', $MAX_GEMSTONE_STYGIAN_FARM_DURATION) == $FAIL Then Return $FAIL
		StygianCheckSFBuffs()
		$me = GetMyAgent()
		$target = GetNearestEnemyToAgent(GetMyAgent())
		ChangeTarget($target)
		If IsRecharged($STYGIAN_CHANNELING) And Not IsRecharged($STYGIAN_SHADOWFORM) And GetEnergy() > 5 Then
			UseSkillEx($STYGIAN_CHANNELING)
			RandomSleep(100)
		EndIf
		$distance = GetDistance($me, $target)
		If Not GetHasHex($target) And IsRecharged($STYGIAN_WASTRELS_DEMISE) And Not IsRecharged($STYGIAN_SHADOWFORM) And GetEnergy() > 5 And $distance < $STYGIANS_RANGE_SHORT Then
			UseSkillEx($STYGIAN_WASTRELS_DEMISE, $target)
			RandomSleep(100)
		EndIf
		RandomSleep(100)
	WEnd
	RandomSleep(500)
	;If IsPlayerAlive() Then PickUpItems(StygianCheckSFBuffs, DefaultShouldPickItem, $STYGIANS_RANGE_LONG)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func RunStygianFarm($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $stygian_run_options)
EndFunc


Func StygianCheckSFBuffs()
	If IsPlayerDead() Then Return $FAIL
	If $stygian_player_profession == $ID_RANGER Then Return $FAIL
	If IsRecharged($STYGIAN_DEADLY_PARADOX) And IsRecharged($STYGIAN_SHADOWFORM) And GetEnergy() >= 20 Then
		UseSkillEx($STYGIAN_DEADLY_PARADOX)
		UseSkillEx($STYGIAN_SHADOWFORM)
	EndIf
	Return $SUCCESS
EndFunc


Func StygianCheckRunBuffs()
	If IsPlayerDead() Then Return $FAIL
	If $stygian_player_profession == $ID_RANGER Then Return $FAIL
	If IsRecharged($STYGIAN_DWARVEN_STABILITY) And GetEnergy() > 5 Then UseSkillEx($STYGIAN_DWARVEN_STABILITY)
	If IsRecharged($STYGIAN_DASH) And GetEnergy() > 5 Then UseSkillEx($STYGIAN_DASH)
	Return $SUCCESS
EndFunc


Func GoToHidingSpot()
	If IsPlayerDead() Then Return $FAIL
	RunStygianFarm(10575, -8170)
	; 0 to get player into the exact location without randomness, spot to hide from running mobs
	MoveTo(10871, -7842, 0)
	; waiting for mobs to run by
	RandomSleep(15000)
	RunStygianFarm(10575, -8170)
	RunStygianFarm(12853, -9936)
EndFunc