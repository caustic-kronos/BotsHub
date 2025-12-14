#CS ===========================================================================
======================================
|  	  Stygian Gemstones Farm bot	 |
|			  	TonReuf   			 |
======================================
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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

#Region Configuration
; === Build ===
;Global Const $AMeStygianSkillBar = 'OwVTI4h9X6mSGYFct0E4uM0ZCCA'
Global Const $AMeStygianSkillBar = 'OwVT8ZBPGiHRn5mat0E4uM0ZCC'
;Global Const $MeAStygianSkillBar = 'OQdUASBPmfS3UyArgrlmA3lhOTQA'
Global Const $MeAStygianSkillBar = 'OQdTI4x8ZiHRn5mat0E4uM0ZCC'
Global Const $RNStygianSkillBar = 'OgQTcybiZK5o5Y5wSIXc465o7AA'
Global $StygianPlayerProfession = $ID_Mesmer ; global variable to remember player's profession in setup to avoid creating Dll structs over and over
Global Const $StygianRangerHeroSkillBar = 'OgMSY5LHQnh0EAAAAAAAA'

; You can select which ranger hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
Global Const $StygianHeroPartyID = $ID_Acolyte_Jin
;Global Const $StygianHeroPartyID = $ID_Margrid_The_Sly
;Global Const $StygianHeroPartyID = $ID_Pyre_Fierceshot
Global Const $StygianHeroIndex = 1 ; index of first hero party member in team, player index is 0
Global $StygianHeroAgentID = Null ; agent ID that is randomly assigned to hero in exploration areas


Global Const $Stygian_DeadlyParadox			= 1
Global Const $Stygian_ShadowForm			= 2
Global Const $Stygian_WastrelsDemise		= 3
Global Const $Stygian_Mindbender			= 4
Global Const $Stygian_Channeling			= 5
Global Const $Stygian_DwarvenStability		= 6
Global Const $Stygian_ShadowOfHaste			= 7
Global Const $Stygian_Dash					= 8

Global Const $Stygian_Ranger_DustTrap		= 1
Global Const $Stygian_Ranger_SpikeTrap		= 2
Global Const $Stygian_Ranger_FlameTrap		= 3
Global Const $Stygian_Ranger_MarkOfPain		= 4
Global Const $Stygian_Ranger_EbonStandard	= 5
Global Const $Stygian_Ranger_TrappersSpeed	= 6
Global Const $Stygian_Ranger_Winnowing		= 7
Global Const $Stygian_Ranger_MuddyTerrain	= 8

; ranger hero
Global Const $Stygian_Hero_EdgeOfExtinction	= 1
Global Const $Stygian_Hero_UnyieldingAura	= 2
Global Const $Stygian_Hero_Succor			= 3
#EndRegion Configuration

; ==== Constants ====
Global Const $GemstoneStygianFarmInformations = 'For best results, have :' & @CRLF _
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
Global $GemstoneStygianFarmTimer = Null
Global $GEMSTONE_STYGIAN_FARM_SETUP = False
Global Const $Stygians_Range_Short = 800
Global Const $Stygians_Range_Long = 1200

Global $StygianRunOptions = CloneDictMap($Default_MoveDefend_Options)
$StygianRunOptions.Item('defendFunction')		= StygianCheckRunBuffs
$StygianRunOptions.Item('moveTimeOut')			= 3 * 60 * 1000
$StygianRunOptions.Item('randomFactor')			= 20
$StygianRunOptions.Item('hosSkillSlot')			= 0
$StygianRunOptions.Item('deathChargeSkillSlot')	= 0
$StygianRunOptions.Item('openChests')			= False


;~ Main loop function for farming stygian gemstones
Func GemstoneStygianFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $GEMSTONE_STYGIAN_FARM_SETUP And SetupGemstoneStygianFarm() == $FAIL Then Return $PAUSE
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	If GoToStygianVeil() == $FAIL Then Return $FAIL
	Local $result = GemstoneStygianFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared stygian mobs')
	If $result == $FAIL Then Info('Player died. Could not clear stygian mobs')
	Info('Returning back to the outpost') ; in this case outpost has the same map ID as farm location
	ResignAndReturnToOutpost()
	Return $result
EndFunc


Func SetupGemstoneStygianFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Gate_Of_Anguish Then
		If TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	Else ; resigning to return to outpost in case when player is in one of 4 DoA farm areas that have the same map ID as Gate of Anguish outpost (474)
		ResignAndReturnToOutpost()
	EndIf
	SwitchToHardModeIfEnabled()
	If SetupPlayerStygianFarm() == $FAIL Then Return $FAIL
	If SetupTeamStygianFarm() == $FAIL Then Return $FAIL
	SetDisplayedTitle($ID_Lightbringer_Title)
	Sleep(500 + GetPing())
	$GEMSTONE_STYGIAN_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerStygianFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_Assassin
			$StygianPlayerProfession = $ID_Assassin
			LoadSkillTemplate($AMeStygianSkillBar)
		Case $ID_Mesmer
			$StygianPlayerProfession = $ID_Mesmer
			LoadSkillTemplate($MeAStygianSkillBar)
		Case $ID_Ranger
			$StygianPlayerProfession = $ID_Ranger
			LoadSkillTemplate($RNStygianSkillBar)
		Case Else
			Warn('You need to run this farm bot as Assassin or Mesmer or Ranger')
			Return $FAIL
	EndSwitch
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamStygianFarm()
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	Sleep(500 + GetPing())
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Ranger Then
		AddHero($StygianHeroPartyID)
		Sleep(500 + GetPing())
		LoadSkillTemplate($StygianRangerHeroSkillBar, $StygianHeroIndex)
		Sleep(500 + GetPing())
		DisableAllHeroSkills($StygianHeroIndex)
		If GetPartySize() <> 2 Then
			Warn("Could not add ranger hero to team. Team size different than 2")
			Return $FAIL
		EndIf
	EndIf
	Return $SUCCESS
EndFunc


;~ exit gate of Anguish outpost by moving into portal that leads into farming location - Stygian Veil
Func GoToStygianVeil()
	TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	Info('Moving to Stygian Veil')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is hard to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Stygian Veil
	Local Static $StartX = -364
	Local Static $StartY = -10445
	Local $TimerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		If TimerDiff($TimerZoning) > 120000 Then ; 120 seconds max time for leaving outpost in case of bot getting stuck
			Info('Could not zone to Stygian Veil')
			Return $FAIL
		EndIf
		MoveTo(6798, -15867)
		MoveTo(1315, -17924)
		MoveTo(-785, -18969)
		Move(-1100, -20000, 0)
		Sleep(12000) ; wait 12 seconds to ensure that player exited outpost
	WEnd
EndFunc


Func GemstoneStygianFarmLoop()
	Sleep(2000)
	Info('Starting Farm')
	$GemstoneStygianFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run

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
	GoNearestNPCToCoords(7188, -9108)
	Sleep(1000)
	Dialog(0x82E601)
	Sleep(1000)
	If GetQuestByID(0x2E6) == Null Then Return $FAIL

	Switch $StygianPlayerProfession
		Case $ID_Assassin, $ID_Mesmer
			Return StygianFarmMesmerAssassin()
		Case $ID_Ranger
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
		PickUpItems(StygianCheckSFBuffs, DefaultShouldPickItem, $Stygians_Range_Long)
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


Func StygianFarmRanger()
	If IsPlayerDead() Then Return $FAIL
	UseHeroSkill($StygianHeroIndex, $Stygian_Hero_Succor, GetMyAgent())
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
	If $pickItemsAfterFirstWave And IsPlayerAlive() Then PickUpItems(StygianCheckSFBuffs, DefaultShouldPickItem, $Stygians_Range_Long)
	MoveTo(13128, -10084)
	MoveTo(13082, -9788, 0) ; 0 to get player into the exact location without randomness, spot for cleaning stygian mobs
	RandomSleep(500)
	If IsRecharged($Stygian_DwarvenStability) Then
		UseSkillEx($Stygian_DwarvenStability)
		RandomSleep(100)
	EndIf
	UseSkillEx($Stygian_ShadowOfHaste)
	MoveTo(13240, -10006)
	MoveTo(9437, -9283)
	UseSkillEx($Stygian_Mindbender)
	MoveTo(8567, -9050) ; spot to aggro mobs
	RandomSleep(200)
	MoveTo(12376, -9557)
	RandomSleep(1500)
	UseSkillEx($Stygian_Dash) ; this ends shadow of haste and transfers player into spot
	Sleep(12500) ; waiting for all mobs to come
	KillStygianMobsUsingWastrelSkills()
	$pickItemsAfterFirstWave = True
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func StygianJobRanger()
	If IsPlayerDead() Then Return $FAIL
	MoveTo(10844, -10205)
	MoveTo(10313, -11156)
	MoveTo(8269, -11160, 10)
	CommandHero($StygianHeroIndex, 9492, -11484)
	If IsRecharged($Stygian_Ranger_Winnowing) Then UseSkillEx($Stygian_Ranger_Winnowing)
	RandomSleep(2000)
	MoveTo(8177, -11171, 10)
	If IsRecharged($Stygian_Ranger_TrappersSpeed) Then UseSkillEx($Stygian_Ranger_TrappersSpeed)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_DustTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_DustTrap) Then UseSkillEx($Stygian_Ranger_DustTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_SpikeTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_SpikeTrap) Then UseSkillEx($Stygian_Ranger_SpikeTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_FlameTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_FlameTrap) Then UseSkillEx($Stygian_Ranger_FlameTrap)
	If IsRecharged($Stygian_Ranger_TrappersSpeed) Then UseSkillEx($Stygian_Ranger_TrappersSpeed)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_SpikeTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_SpikeTrap) Then UseSkillEx($Stygian_Ranger_SpikeTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_FlameTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_FlameTrap) Then UseSkillEx($Stygian_Ranger_FlameTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_DustTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_DustTrap) Then UseSkillEx($Stygian_Ranger_DustTrap)
	If IsRecharged($Stygian_Ranger_MuddyTerrain) Then UseSkillEx($Stygian_Ranger_MuddyTerrain)
	RandomSleep(2000)
	If IsRecharged($Stygian_Ranger_TrappersSpeed) Then UseSkillEx($Stygian_Ranger_TrappersSpeed)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_SpikeTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_SpikeTrap) Then UseSkillEx($Stygian_Ranger_SpikeTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_FlameTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_FlameTrap) Then UseSkillEx($Stygian_Ranger_FlameTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_DustTrap) Or IsPlayerDead()
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_SpikeTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_SpikeTrap) Then UseSkillEx($Stygian_Ranger_SpikeTrap)
	Do
		RandomSleep(100)
	Until IsRecharged($Stygian_Ranger_FlameTrap) Or IsPlayerDead()
	If IsRecharged($Stygian_Ranger_FlameTrap) Then UseSkillEx($Stygian_Ranger_FlameTrap)
	UseHeroSkill($StygianHeroIndex, $Stygian_Hero_EdgeOfExtinction)
	;TargetNearestEnemy()
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeTarget($target)
	UseSkill($Stygian_Ranger_MarkOfPain, $target)
	Do
		RandomSleep(50)
	Until GetHasHex($target) Or IsPlayerDead()
	MoveTo(8368, -11244)
	If IsRecharged($Stygian_Ranger_EbonStandard) Then UseSkillEx($Stygian_Ranger_EbonStandard)
	While CountFoesInRangeOfAgent(GetMyAgent(), $Stygians_Range_Long) > 0 And IsPlayerAlive()
		If TimerDiff($GemstoneStygianFarmTimer) > $MAX_GEMSTONE_STYGIAN_FARM_DURATION Then Return $FAIL
		RandomSleep(100)
	WEnd
	CancelAll()
	RandomSleep(500)
	If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $Stygians_Range_Long)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func KillStygianMobsUsingWastrelSkills()
	Local $me, $target, $distance

	While CountFoesInRangeOfAgent(GetMyAgent(), $Stygians_Range_Long) > 0 And IsPlayerAlive()
		If TimerDiff($GemstoneStygianFarmTimer) > $MAX_GEMSTONE_STYGIAN_FARM_DURATION Then Return $FAIL
		StygianCheckSFBuffs()
		$me = GetMyAgent()
		$target = GetNearestEnemyToAgent(GetMyAgent())
		ChangeTarget($target)
		If IsRecharged($Stygian_Channeling) And Not IsRecharged($Stygian_ShadowForm) And GetEnergy() > 5 Then
			UseSkillEx($Stygian_Channeling)
			RandomSleep(100)
		EndIf
		$distance = GetDistance($me, $target)
		If Not GetHasHex($target) And IsRecharged($Stygian_WastrelsDemise) And Not IsRecharged($Stygian_ShadowForm) And GetEnergy() > 5 And $distance < $Stygians_Range_Short Then
			UseSkillEx($Stygian_WastrelsDemise, $target)
			RandomSleep(100)
		EndIf
		RandomSleep(100)
	WEnd
	RandomSleep(500)
	;If IsPlayerAlive() Then PickUpItems(StygianCheckSFBuffs, DefaultShouldPickItem, $Stygians_Range_Long)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func RunStygianFarm($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $StygianRunOptions)
EndFunc


Func StygianCheckSFBuffs()
	If IsPlayerDead() Then Return $FAIL
	If $StygianPlayerProfession == $ID_Ranger Then Return $FAIL
	If IsRecharged($Stygian_DeadlyParadox) And IsRecharged($Stygian_ShadowForm) And GetEnergy() >= 20 Then
		UseSkillEx($Stygian_DeadlyParadox)
		UseSkillEx($Stygian_ShadowForm)
	EndIf
	Return $SUCCESS
EndFunc


Func StygianCheckRunBuffs()
	If IsPlayerDead() Then Return $FAIL
	If $StygianPlayerProfession == $ID_Ranger Then Return $FAIL
	If IsRecharged($Stygian_DwarvenStability) And GetEnergy() > 5 Then UseSkillEx($Stygian_DwarvenStability)
	If IsRecharged($Stygian_Dash) And GetEnergy() > 5 Then UseSkillEx($Stygian_Dash)
	Return $SUCCESS
EndFunc


Func GoToHidingSpot()
	If IsPlayerDead() Then Return $FAIL
	RunStygianFarm(10575, -8170)
	MoveTo(10871, -7842, 0) ; 0 to get player into the exact location without randomness, spot to hide from running mobs
	RandomSleep(15000) ; waiting for mobs to run by
	RunStygianFarm(10575, -8170)
	RunStygianFarm(12853, -9936)
EndFunc