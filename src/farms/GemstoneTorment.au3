#CS ===========================================================================
=========================================
|		Torment Gemstones Farm bot		|
|				TonReuf					|
=========================================
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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'


#Region Configuration
; === Build ===
Global Const $EA_TORMENT_SKILLBAR = 'OgdTkSFzSC3xF0YQbAYYYgXoXA'

Global Const $TORMENT_DEATHS_CHARGE				= 1
Global Const $TORMENT_ELEMENTAL_LORD			= 2
Global Const $TORMENT_GLYPH_OF_ELEMENTAL_POWER	= 3
Global Const $TORMENT_OBSIDIAN_FLESH				= 4
Global Const $TORMENT_METEOR_SHOWER				= 5
Global Const $TORMENT_LAVA_FONT					= 6
Global Const $TORMENT_FLAME_BURST				= 7
Global Const $TORMENT_RODGORTS_INVOCATION		= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $GEMSTONE_TORMENT_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- At least 100 energy to be able to cast all the spells' & @CRLF _
	& '- Full Radiant Armor with Attunement Runes to max out energy' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- A focus with a Live for Today inscription (+15 energy, -1 energy degeneration) to max out energy' & @CRLF _
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

; Staff of enchanting 20% for the run and faster energy regeneration
Global Const $TORMENT_WEAPON_SLOT_STAFF = 2
; Weapon of enchanting 20% and +5 Energy and a focus +15Energy/-1Regeneration for more energy
Global Const $TORMENT_WEAPON_SLOT_FOCUS = 3

Global $torment_run_options = CloneDictMap($default_movedefend_options)
$torment_run_options.Item('defendFunction')		= DefendTormentFarm
$torment_run_options.Item('moveTimeOut')			= 3 * 60 * 1000
$torment_run_options.Item('randomFactor')			= 200
$torment_run_options.Item('hosSkillSlot')			= 0
$torment_run_options.Item('deathChargeSkillSlot')	= $TORMENT_DEATHS_CHARGE
; chests in Ravenheart Gloom should have good loot
$torment_run_options.Item('openChests')			= True

Global $gemstone_torment_farm_setup = False

;~ Main loop function for farming torment gemstones
Func GemstoneTormentFarm()
	If Not $gemstone_torment_farm_setup And SetupGemstoneTormentFarm() == $FAIL Then Return $PAUSE

	If GoToRavenHeartGloom() == $FAIL Then Return $FAIL
	Local $result = GemstoneTormentFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared torment mobs')
	If $result == $FAIL Then Info('Player died. Could not clear torment mobs')
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	Return $result
EndFunc


Func SetupGemstoneTormentFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_GATE_OF_ANGUISH Then
		If TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name) == $FAIL Then Return $FAIL
	Else
		ResignAndReturnToOutpost($ID_GATE_OF_ANGUISH, true)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerTormentFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	RandomSleep(500)
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	RandomSleep(500)
	$gemstone_torment_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerTormentFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ELEMENTALIST Then
		LoadSkillTemplate($EA_TORMENT_SKILLBAR)
	Else
		Warn('You need to run this farm bot as Elementalist')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ exit gate of Anguish outpost by moving into portal that leads into farming location - RavenHeart Gloom
Func GoToRavenHeartGloom()
	TravelToOutpost($ID_GATE_OF_ANGUISH, $district_name)
	Info('Moving to RavenHeart Gloom')
	; Unfortunately all 4 gemstone farm explorable locations have the same map ID as Gate of Anguish outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in RavenHeart Gloom
	Local Static $StartX = 16034
	Local Static $StartY = 1244
	Local $timerZoning = TimerInit()
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		If TimerDiff($timerZoning) > 120000 Then
			Info('Could not zone to RavenHeart Gloom')
			Return $FAIL
		EndIf
		MoveTo(6798, -15867)
		MoveTo(5487, -17983)
		MoveTo(6489, -20099)
		Move(6700, -21250, 0)
		Sleep(8000)
	WEnd
EndFunc


Func GemstoneTormentFarmLoop()
	Info('Starting Farm')
	Local $timerWait

	ChangeWeaponSet($TORMENT_WEAPON_SLOT_STAFF)
	RandomSleep(250)
	If GetLightbringerTitle() < 50000 Then
		Info('Taking Blessing')
		GoNearestNPCToCoords(16457, 1801)
		Sleep(1000)
		Dialog(0x85)
		Sleep(500)
	EndIf

	If RunTormentFarm(15125, 2794) == $FAIL Then Return $FAIL
	If RunTormentFarm(15561, 5241) == $FAIL Then Return $FAIL
	$timerWait = TimerInit()
	While TimerDiff($timerWait) < 5000 And IsPlayerAlive()
		RandomSleep(100)
	WEnd
	$timerWait = TimerInit()
	UseSkillTimed($TORMENT_OBSIDIAN_FLESH)
	While TimerDiff($timerWait) < 2000 And IsPlayerAlive()
		RandomSleep(100)
	WEnd

	If RunTormentFarm(12304, 9022) == $FAIL Then Return $FAIL
	If RunTormentFarm(11444, 9370) == $FAIL Then Return $FAIL
	If RunTormentFarm(10828, 10583) == $FAIL Then Return $FAIL
	$timerWait = TimerInit()
	While IsPlayerAlive() And (TimerDiff($timerWait) < 15000 Or Not IsRecharged($TORMENT_OBSIDIAN_FLESH) Or GetEnergy() < 80)
		RandomSleep(100)
	WEnd
	Info('First group')
	CastBuffsTormentFarm()
	If RunTormentFarm(10779, 9898) == $FAIL Then Return $FAIL
	;If RunTormentFarm(11125, 9198) == $FAIL Then Return $FAIL
	ChangeWeaponSet($TORMENT_WEAPON_SLOT_FOCUS)
	RandomSleep(500)
	If KillTormentMobs() == $FAIL Then Return $FAIL
	Info('Picking up loot')
	PickUpItems()

	ChangeWeaponSet($TORMENT_WEAPON_SLOT_STAFF)
	RandomSleep(250)
	If RunTormentFarm(11130, 10910) == $FAIL Then Return $FAIL
	If RunTormentFarm(12140, 12103) == $FAIL Then Return $FAIL
	If RunTormentFarm(13915, 13415) == $FAIL Then Return $FAIL
	If RunTormentFarm(16250, 14073) == $FAIL Then Return $FAIL
	$timerWait = TimerInit()
	While IsPlayerAlive() And (TimerDiff($timerWait) < 42000 Or Not IsRecharged($TORMENT_ELEMENTAL_LORD) Or _
			Not IsRecharged($TORMENT_OBSIDIAN_FLESH) Or Not IsRecharged($TORMENT_METEOR_SHOWER) Or GetEnergy() < 80)
		RandomSleep(100)
	WEnd
	Info('Second group')
	CastBuffsTormentFarm()
	RandomSleep(250)
	ChangeWeaponSet($TORMENT_WEAPON_SLOT_FOCUS)
	RandomSleep(500)
	If KillTormentMobs() == $FAIL Then Return $FAIL

	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


Func RunTormentFarm($destinationX, $destinationY)
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $torment_run_options)
EndFunc


Func CastBuffsTormentFarm()
	If IsPlayerDead() Then Return $FAIL
	RandomSleep(150)
	UseSkillTimed($TORMENT_ELEMENTAL_LORD)
	UseSkillTimed($TORMENT_GLYPH_OF_ELEMENTAL_POWER)
	UseSkillTimed($TORMENT_OBSIDIAN_FLESH)
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


Func DefendTormentFarm()
	Local $me = GetMyAgent(), $target = Null

	If (DllStructGetData($me, 'HealthPercent') < 0.3 Or _
			(DllStructGetData($me, 'HealthPercent') < 0.4 And GetHasCondition($me))) And _
			CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT) > 0 And _
			IsRecharged($TORMENT_DEATHS_CHARGE) And GetEnergy() > 5 Then
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
		UseSkillTimed($TORMENT_DEATHS_CHARGE, $target)
	EndIf
EndFunc


Func KillTormentMobs()
	If IsPlayerDead() Then Return $FAIL
	Local $target = Null

	$target = GetNearestEnemyToAgent(GetMyAgent())
	UseSkillTimed($TORMENT_METEOR_SHOWER, $target)
	$target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeTarget($target)
	UseSkillTimed($TORMENT_DEATHS_CHARGE, $target)
	UseSkillTimed($TORMENT_LAVA_FONT)
	UseSkillTimed($TORMENT_FLAME_BURST)
	UseSkillTimed($TORMENT_RODGORTS_INVOCATION, $target)
	; waiting for mobs to be cleaned by meteor shower
	RandomSleep(1500)

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc