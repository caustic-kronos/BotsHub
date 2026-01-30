#CS ===========================================================================
==================================================
|	Fissure Of Woe Tower of Courage farm Bot	|
|	Authors: Zaishen/RiflemanX/Monk Reborn		|
|	Rewrite Author for BotsHub: Gahais			|
==================================================
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the 'License');
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an 'AS IS' BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.
;
; Fissure of Woe farm of Obsidian Shards in Tower of Courage location based on below article:
https://gwpvx.fandom.com/wiki/Build:R/A_Whirling_Defense_Farmer
; Run this farm bot as Ranger
;
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)


#Region Configuration
; === Build ===
Global Const $RA_FOW_TOC_FARMER_SKILLBAR = 'OgcTc5+8ZSn5AimsBC35uU4IuEA'

Global Const $FOW_TOC_SHADOWFORM			= 1
Global Const $FOW_TOC_SHROUD_OF_DISTRESS	= 2
Global Const $FOW_TOC_I_AM_UNSTOPPABLE		= 3
Global Const $FOW_TOC_DARK_ESCAPE			= 4
;Global Const $FOW_TOC_HEART_OF_SHADOW		= 5
Global Const $FOW_TOC_DEATH_CHARGE			= 5
Global Const $FOW_TOC_DWARVEN_STABILITY		= 6
Global Const $FOW_TOC_WHIRLING_DEFENSE		= 7
Global Const $FOW_TOC_MENTAL_BLOCK			= 8
#EndRegion Configuration

; ==== Constants ====
Global Const $FOW_TOC_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- Armor with HP/Energy runes and 5 blessed insignias (+50 armor when enchanted)' & @CRLF _
	& '- Spear/Sword/Axe +5 energy of Enchanting (20% longer enchantments duration)' & @CRLF _
	& '- A shield with the inscription Through Thick and Thin (+10 armor against piercing damage) and +45 health while enchanted or in stance' & @CRLF _
	& '- At least 5th level in Deldrimor, Asura and Norn reputation ranks' & @CRLF _
	& ' ' & @CRLF _
	& 'This bot farms obsidian shards in Tower of Courage in Fissure of Woe location in normal mode.' & @CRLF _
	& 'Solo farm using Ranger based on below article' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:R/A_Whirling_Defense_Farmer' & @CRLF _
	& 'If you have FoW scrolls then can set in GUI to enter FoW only through FoW scrolls and stop the bot when FoW scrolls run out' & @CRLF _
	& 'It is recommended to run this farm mostly during weeks with Pantheon bonus active which gives free entry to FoW and UW' & @CRLF _
	& 'Otherwise this farm bot can flush gold storage to 0. However income from obsidian shards and other loot should outweight the platinum cost' & @CRLF
Global Const $FOW_TOC_FARM_DURATION = 3 * 60 * 1000
Global Const $MAX_FOW_TOC_FARM_DURATION = 6 * 60 * 1000

Global $fow_toc_move_options = CloneDictMap($default_movedefend_options)
$fow_toc_move_options.Item('defendFunction')		= CastFowToCBuffs
$fow_toc_move_options.Item('moveTimeOut')			= 5 * 60 * 1000
$fow_toc_move_options.Item('randomFactor')			= 25
$fow_toc_move_options.Item('hosSkillSlot')			= 0
$fow_toc_move_options.Item('deathChargeSkillSlot')	= $FOW_TOC_DEATH_CHARGE
$fow_toc_move_options.Item('openChests')			= False

;Global Const $FOW_TOC_MODELID_SHADOW_MESMER	= 2855
;Global Const $FOW_TOC_MODELID_SHADOW_ELEMENTAL	= 2856
;Global Const $FOW_TOC_MODELID_SHADOW_MONK		= 2857
;Global Const $FOW_TOC_MODELID_SHADOW_WARRIOR	= 2858
;Global Const $FOW_TOC_MODELID_SHADOW_BEAST		= 2860
;Global Const $FOW_TOC_MODELID_SHADOW_RANGER	= 2859
Global Const $FOW_TOC_MODELID_ABYSSAL			= 2861

Global $fow_toc_farm_setup = False
Global $fow_toc_30s_timer

;~ Main method to farm Fissure of Woe - Tower of Courage
Func FoWToCFarm()
	If Not $fow_toc_farm_setup And SetupFoWToCFarm() == $FAIL Then Return $PAUSE

	Local $result = EnterFissureOfWoe()
	If $result <> $SUCCESS Then Return $result
	$result = FoWToCFarmLoop()
	If $result == $SUCCESS Then Info('Successfully cleared FoW Tower of Courage mobs')
	If $result == $FAIL Then Info('Player died. Could not clear FoW Tower of Courage mobs')
	TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name)
	Return $result
EndFunc


;~ Fissure of Woe - Tower of Courage farm setup
Func SetupFoWToCFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_TEMPLE_OF_THE_AGES, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFowToCFarm() == $FAIL Then Return $FAIL
	LeaveParty()
	RandomSleep(500)
	$fow_toc_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFowToCFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($RA_FOW_TOC_FARMER_SKILLBAR)
	Else
		Warn('You need to run this farm bot as Ranger')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Farm loop
Func FoWToCFarmLoop()
	$run_timer = TimerInit()

	Info('Moving to initial spot')
	CastFowToCBuffs()
	; Dark escape can be replaced by other skills like great dwarf armor to increase survivability at the cost of farm speed
	UseSkillEx($FOW_TOC_DARK_ESCAPE)
	If MoveDefendingFoWToC(-21100, -2400) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-17500, -2800) == $FAIL Then Return $FAIL
	UseSkillEx($FOW_TOC_MENTAL_BLOCK)
	If MoveDefendingFoWToC(-16500, -3100) == $FAIL Then Return $FAIL
	; Waiting for Dark Escape to finish anf for buffs to be all fresh
	While TimerDiff($fow_toc_30s_timer) < 27000
		Sleep(500)
	WEnd

	Info('Balling abyssals')
	If MoveDefendingFoWToC(-15250, -3600) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-14450, -3500) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-14150, -2950) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-13600, -1800) == $FAIL Then Return $FAIL
	UseSkillEx($FOW_TOC_WHIRLING_DEFENSE)
	If MoveDefendingFoWToC(-14200, -700) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-14650, -200) == $FAIL Then Return $FAIL

	Info('Killing abyssals')
	Local $killTimer = TimerInit()
	Local $foesCount = 999
	While $foesCount > 0
		CastFowToCBuffs()
		Sleep(500)
		; If only 2 abyssal left we can finish them by hand
		If $foesCount > 0 And $foesCount < 3 Then 
			Local $foe = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
			If DllStructGetData($foe, 'HealthPercent') < 0.3 Then Attack($foe)
		EndIf
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($killTimer) > 30000 Then ExitLoop
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT, IsAbyssal)
	WEnd
	Sleep(500 + GetPing())
	Info('Abyssals cleared. Picking up loot')
	If IsPlayerAlive() Then PickUpItems(CastFowToCBuffs)
	RandomSleep(500)

	Info('Balling rangers')
	If MoveDefendingFoWToC(-14200, -700) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-13600, -1800) == $FAIL Then Return $FAIL
	If MoveDefendingFoWToC(-14750, -2800) == $FAIL Then Return $FAIL
	RandomSleep(2000)
	If MoveDefendingFoWToC(-15150, -2950) == $FAIL Then Return $FAIL
	RandomSleep(2000)

	Info('Killing rangers')
	; Longest bow range is around 1500
	Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST + 500)
	;Local $target = GetNearestEnemyToAgent(GetMyAgent())
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_EARSHOT)
	;$target = GetNearestEnemyToCoords($center[0], $center[1])
	CastFowToCBuffs()
	GetAlmostInRangeOfAgent($target)
	CastFowToCBuffs()
	While IsRecharged($FOW_TOC_DEATH_CHARGE)
		UseSkillEx($FOW_TOC_DEATH_CHARGE, $target)
		RandomSleep(100)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	While Not IsRecharged($FOW_TOC_WHIRLING_DEFENSE)
		CastFowToCBuffs()
		Move($center[0], $center[1])
		RandomSleep(500)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	UseSkillEx($FOW_TOC_WHIRLING_DEFENSE)
	$killTimer = TimerInit()
	$foesCount = 999
	While $foesCount > 0
		CastFowToCBuffs()
		Sleep(500)
		; If only 2 rangers left we can finish them by hand
		If $foesCount > 0 And $foesCount < 3 Then 
			Local $foe = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
			If DllStructGetData($foe, 'HealthPercent') < 0.3 Then Attack($foe)
		EndIf
		If IsPlayerDead() Then Return $FAIL
		If TimerDiff($killTimer) > 30000 Then ExitLoop
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	WEnd
	Info('Rangers cleared. Picking up loot')
	Sleep(500 + GetPing())
	PickUpItems(CastFowToCBuffs)
	Return $SUCCESS
EndFunc


Func MoveDefendingFoWToC($destinationX, $destinationY)
	CastFowToCBuffs()
	If CheckStuck('FoW', $MAX_FOW_TOC_FARM_DURATION) == $FAIL Then Return $FAIL
	Return MoveAvoidingBodyBlock($destinationX, $destinationY, $fow_toc_move_options)
EndFunc


Func CastFowToCBuffs()
	If $fow_toc_30s_timer == Null Or TimerDiff($fow_toc_30s_timer) > 28000 Then
		; Since everything is casted together, no risk of interrupts
		$fow_toc_30s_timer = TimerInit()
		UseSkillEx($FOW_TOC_I_AM_UNSTOPPABLE)
		Sleep(250)
		UseSkillEx($FOW_TOC_SHADOWFORM)
		Sleep(250)
		UseSkillEx($FOW_TOC_DWARVEN_STABILITY)
		If (TimerDiff($run_timer) > 20000) And (GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0) And (IsRecharged($FOW_TOC_MENTAL_BLOCK)) Then UseSkillEx($FOW_TOC_MENTAL_BLOCK)
		$fow_toc_30s_timer = TimerInit()
	EndIf
	If IsRecharged($FOW_TOC_SHROUD_OF_DISTRESS) Then
		Sleep(250)
		UseSkillEx($FOW_TOC_SHROUD_OF_DISTRESS)
	EndIf
EndFunc


Func IsAbyssal($agent)
	Return DllStructGetData($agent, 'ModelID') == $FOW_TOC_MODELID_ABYSSAL
EndFunc