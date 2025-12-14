#CS ===========================================================================
======================================
|  	  Torment Gemstones Farm bot	 |
|			  	TonReuf   			 |
======================================
;
; Run this farm bot as Elementalist
;
; Rewritten for BotsHub: Gahais
; Torment gemstone farm in the Ravenheart Gloom based on below article:
https://gwpvx.fandom.com/wiki/Build:E/A_Obsidian_Flesh_Gloom_Farmer
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
Global Const $EATormentSkillBar = 'OgdTkSFzSC3xF0YQbAYYYgXoXA'

Global Const $Torment_DeathsCharge			= 1
Global Const $Torment_ElementalLord			= 2
Global Const $Torment_GlyphOfElementalPower	= 3
Global Const $Torment_ObsidianFlesh			= 4
Global Const $Torment_MeteorShower			= 5
Global Const $Torment_LavaFont				= 6
Global Const $Torment_FlameBurst			= 7
Global Const $Torment_RodgortsInvocation	= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $GemstoneTormentFarmInformations = 'For best results, have :' & @CRLF _
	& '- At least 100 energy to be able to cast all the spells' & @CRLF _
	& '- Full Radiant Armor with Attunement Runes to max out energy' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- A focus with a "Live for Today" inscription (+15 energy, -1 energy degeneration) to max out energy' & @CRLF _
	& ' ' & @CRLF _
	& 'You can run this farm as Elementalist. Bot will set up build automatically' & @CRLF _
	& 'This bot farms torment gemstones (1 of 4 types) in Ravenheart Gloom location' & @CRLF _
	& 'Player needs to have access to Gate of Anguish outpost which has exit to RavenHeart Gloom location' & @CRLF _
	& 'Recommended to have maxed out Lightbringer title. If not maxed out then this farm is good for raising lightbringer rank' & @CRLF _
	& 'It is recommended to run this farm in normal mode' & @CRLF _
	& 'Gemstones can be exchanged into armbrace of truth (15 of each type) or coffer of whisper (1 of each type)' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:E/A_Obsidian_Flesh_Gloom_Farmer' & @CRLF
; Average duration ~ 10 minutes
Global Const $GEMSTONE_TORMENT_FARM_DURATION = 10 * 60 * 1000
Global Const $MAX_GEMSTONE_TORMENT_FARM_DURATION = 20 * 60 * 1000
Global $GemstoneTormentFarmTimer = Null
Global $GEMSTONE_TORMENT_FARM_SETUP = False

Global Const $Torment_Weapon_Slot_Staff = 3 ; Staff of enchanting 20% for the run and faster energy regeneration
Global Const $Torment_Weapon_Slot_Focus = 4 ; Weapon of enchanting 20% and +5 Energy and a focus +15Energy/-1Regeneration for more energy

Global $TormentRunOptions = CloneDictMap($Default_MoveDefend_Options)
$TormentRunOptions.Item('defendFunction')		= DefendTormentFarm
$TormentRunOptions.Item('moveTimeOut')			= 3 * 60 * 1000
$TormentRunOptions.Item('randomFactor')			= 200
$TormentRunOptions.Item('hosSkillSlot')			= 0
$TormentRunOptions.Item('deathChargeSkillSlot')	= $Torment_DeathsCharge
$TormentRunOptions.Item('openChests')			= True ; chests in Ravenheart Gloom should have good loot


;~ Main loop function for farming torment gemstones
Func GemstoneTormentFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $GEMSTONE_TORMENT_FARM_SETUP And SetupGemstoneTormentFarm() == $FAIL Then Return $PAUSE

	If GoToRavenHeartGloom() == $FAIL Then Return $FAIL
	Local $result = GemstoneTormentFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared torment mobs')
	If $result == $FAIL Then Info('Player died. Could not clear torment mobs')
	Info('Returning back to the outpost') ; in this case outpost has the same map ID as farm location
	ResignAndReturnToOutpost()
	Return $result
EndFunc


Func SetupGemstoneTormentFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Gate_Of_Anguish Then
		If TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	Else ; resigning to return to outpost in case when player is in one of 4 DoA farm areas that have the same map ID as Gate of Anguish outpost (474)
		ResignAndReturnToOutpost()
	EndIf
	SwitchToHardModeIfEnabled()
	If SetupPlayerTormentFarm() == $FAIL Then Return $FAIL
	LeaveParty() ; solo farmer
	Sleep(500 + GetPing())
	SetDisplayedTitle($ID_Lightbringer_Title)
	Sleep(500 + GetPing())
	$GEMSTONE_TORMENT_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerTormentFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Elementalist Then
		LoadSkillTemplate($EATormentSkillBar)
	Else
		Warn('You need to run this farm bot as Elementalist')
		Return $FAIL
	EndIf
	Sleep(250 + GetPing())
	If GUICtrlRead($GUI_Checkbox_WeaponSlot) == $GUI_CHECKED Then
		Info('Setting player weapon slot to ' & $WEAPON_SLOT & ' according to GUI settings')
		ChangeWeaponSet($WEAPON_SLOT)
	Else
		Info('Automatic player weapon slot setting is disabled. Assuming that player sets weapon slot manually')
	EndIf
	Sleep(250 + GetPing())
	Return $SUCCESS
EndFunc


;~ exit gate of Anguish outpost by moving into portal that leads into farming location - RavenHeart Gloom
Func GoToRavenHeartGloom()
	TravelToOutpost($ID_Gate_Of_Anguish, $DISTRICT_NAME)
	Info('Moving to RavenHeart Gloom')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is hard to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in RavenHeart Gloom
	Local Static $StartX = -364 ; TODO
	Local Static $StartY = -10445 ; TODO
	Local $TimerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		If TimerDiff($TimerZoning) > 120000 Then ; 120 seconds max time for leaving outpost in case of bot getting stuck
			Info('Could not zone to RavenHeart Gloom')
			Return $FAIL
		EndIf
		MoveTo(6798, -15867)
		MoveTo(5487, -17983)
		MoveTo(6489, -20099)
		Move(6700, -21250, 0)
		Sleep(8000) ; wait 8 seconds to ensure that player exited outpost
	WEnd
EndFunc


Func GemstoneTormentFarmLoop()
	Info('Starting Farm')
	$GemstoneTormentFarmTimer = TimerInit() ; starting run timer, if run lasts longer than max time then bot must have gotten stuck and fail is returned to restart run

	ChangeWeaponSet($Torment_Weapon_Slot_Staff)
	RandomSleep(250)
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoToNearestNPCToCoords(15784, 2466)
		Sleep(1000)
		Dialog(0x85)
		Sleep(500)
	EndIf

	If RunTormentFarm(15125, 2794) == $STUCK Then Return $FAIL
	If RunTormentFarm(15561, 5241) == $STUCK Then Return $FAIL
	$TimerWait = TimerInit()
	While TimerDiff($TimerWait) < 5000 And IsPlayerAlive()
		RandomSleep(100)
	WEnd
	$TimerWait = TimerInit()
	UseSkillEx($Torment_ObsidianFlesh)
	While TimerDiff($TimerWait) < 2000 And IsPlayerAlive()
		RandomSleep(100)
	WEnd

	If RunTormentFarm(12304, 9022) == $STUCK Then Return $FAIL
	If RunTormentFarm(11444, 9370) == $STUCK Then Return $FAIL
	If RunTormentFarm(10828, 10583) == $STUCK Then Return $FAIL
	$TimerWait = TimerInit()
	While IsPlayerAlive() And (TimerDiff($TimerWait) < 15000 Or Not IsRecharged($Torment_ObsidianFlesh) Or GetEnergy() < 100)
		RandomSleep(100)
	WEnd
	If IsPlayerAlive() Then Info('First group')
	If RunTormentFarm(10779, 9898) == $STUCK Then Return $FAIL
	CastBuffsTormentFarm()
	If RunTormentFarm(11125, 9198) == $STUCK Then Return $FAIL
	ChangeWeaponSet($Torment_Weapon_Slot_Focus)
	RandomSleep(500 + GetPing())
	If KillTormentMobs() == $FAIL Then Return $FAIL
	If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)

	ChangeWeaponSet($Torment_Weapon_Slot_Staff)
	RandomSleep(250)
	If RunTormentFarm(11130, 10910) == $STUCK Then Return $FAIL
	If RunTormentFarm(12140, 12103) == $STUCK Then Return $FAIL
	If RunTormentFarm(13915, 13415) == $STUCK Then Return $FAIL
	If RunTormentFarm(16250, 14073) == $STUCK Then Return $FAIL
	$TimerWait = TimerInit()
	While IsPlayerAlive() And (TimerDiff($TimerWait) < 42000 Or Not IsRecharged($Torment_ElementalLord) Or _
			Not IsRecharged($Torment_ObsidianFlesh) Or Not IsRecharged($Torment_MeteorShower) Or GetEnergy() < 100)
		RandomSleep(100)
	WEnd
	If IsPlayerAlive() Then Info('Second group')
	CastBuffsTormentFarm()
	RandomSleep(250)
	ChangeWeaponSet($Torment_Weapon_Slot_Focus)
	RandomSleep(500 + GetPing())
	If KillTormentMobs() == $FAIL Then Return $FAIL
	If IsPlayerAlive() Then PickUpItems(Null, DefaultShouldPickItem, $RANGE_SPIRIT)

	Return $SUCCESS
EndFunc


Func RunTormentFarm($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $TormentRunOptions)
EndFunc


Func CastBuffsTormentFarm()
	If IsPlayerDead() Then Return $FAIL
	RandomSleep(GetPing() + 150)
	UseSkillEx($Torment_ElementalLord)
	UseSkillEx($Torment_GlyphOfElementalPower)
	UseSkillEx($Torment_ObsidianFlesh)
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


Func DefendTormentFarm()
	Local $me = GetMyAgent()

	If (DllStructGetData($me, 'HealthPercent') < 0.3 Or _
			(DllStructGetData($me, 'HealthPercent') < 0.4 And GetHasCondition($me))) And _
			CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 And _
			IsRecharged($deathChargeSkillSlot) And GetEnergy() > 5 Then
		$target = GetFurthestNPCInRangeOfCoords($ID_Allegiance_Foe, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
		ChangeTarget($target)
		UseSkillEx($Torment_DeathsCharge, $target)
	EndIf
EndFunc


Func KillTormentMobs()
	If IsPlayerDead() Then Return $FAIL
	Local $target = Null

	$target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeTarget($target)
	UseSkillEx($Torment_MeteorShower, $target)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeTarget($target)
	UseSkillEx($Torment_DeathsCharge, $target)
	UseSkillEx($Torment_LavaFont)
	UseSkillEx($Torment_FlameBurst)
	UseSkillEx($Torment_RodgortsInvocation, $target)

	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc