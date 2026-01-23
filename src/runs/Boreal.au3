#CS ===========================================================================
; Author: JackLinesMatthews
; Contributors: Kronos, Gahais
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
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
; Universal run build for every profession
Global Const $BOREAL_WARRIOR_CHESTRUNNER_SKILLBAR = 'OQcT8ZPHHiHRn5A6ukmcCC3BBC'
Global Const $BOREAL_RANGER_CHESTRUNNER_SKILLBAR = 'OgcT8ZPfHiHRn5A6ukmcCC3BBC'
Global Const $BOREAL_MONK_CHESTRUNNER_SKILLBAR = 'OwcT8ZPDHiHRn5A6ukmcCC3BBC'
Global Const $BOREAL_NECROMANCER_CHESTRUNNER_SKILLBAR = 'OAdTY4P7HiHRn5A6ukmcCC3BBC'
Global Const $BOREAL_MESMER_CHESTRUNNER_SKILLBAR = 'OQdT8ZPDGiHRn5A6ukmcCC3BBC'
Global Const $BOREAL_ELEMENTALIST_CHESTRUNNER_SKILLBAR = 'OgdT8Z/wYiHRn5A6ukmcCC3BBC'
Global Const $BOREAL_ASSASSIN_CHESTRUNNER_SKILLBAR = 'OwBj8xe84Q8I6MHQ3l0kTQ4OIQ'
Global Const $BOREAL_RITUALIST_CHESTRUNNER_SKILLBAR = 'OAej8xeM5Q8I6MHQ3l0kTQ4OIQ'
Global Const $BOREAL_PARAGON_CHESTRUNNER_SKILLBAR = 'OQej8xeM6Q8I6MHQ3l0kTQ4OIQ'
Global Const $BOREAL_DERVISH_CHEST_RUNNER_SKILLBAR = 'Ogej8xeDLT8I6MHQ3l0kTQ4OIQ'


Global Const $BOREAL_CHESTRUN_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- dwarves rank 5 minimum' & @CRLF _
	& '- norn rank 5 minimum'
; Average duration ~ 1m30s
Global Const $BOREAL_FARM_DURATION = (1 * 60 + 30) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($BOREAL_DWARVENSTABILITY) is better than UseSkillEx(1))
Global Const $BOREAL_DEADLYPARADOX		= 1
Global Const $BOREAL_SHADOWFORM			= 2
Global Const $BOREAL_SHROUDOFDISTRESS	= 3
Global Const $BOREAL_DWARVENSTABILITY	= 4
Global Const $BOREAL_IAMUNSTOPPABLE		= 5
Global Const $BOREAL_DASH				= 6
Global Const $BOREAL_DEATHSCHARGE		= 7
Global Const $BOREAL_HEARTOFSHADOW		= 8

; Model IDs of enemy NPCs that we might encounter
Global Const $BOREAL_MOUNTAIN_PINESOUL_MODEL_ID = 6539
Global Const $BOREAL_MOUNTAIN_ALOE_MODEL_ID = 6540

; global variable to remember player's profession in setup
Global $boreal_player_profession = $ID_ASSASSIN
Global $boreal_farm_setup = False

;~ Main method to chest farm Boreal
Func BorealChestFarm()
	If Not $boreal_farm_setup Then SetupBorealFarm()
	Local $result = BorealChestFarmLoop()
	ResignAndReturnToOutpost($ID_BOREAL_STATION)
	Return $result
EndFunc


;~ Boreal chest farm setup
Func SetupBorealFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_BOREAL_STATION, $district_name)

	SetupPlayerBorealChestFarm()
	LeaveParty()
	SwitchToHardModeIfEnabled()

	MoveTo(5799, -27957)
	MoveTo(6035, -27977)
	;~ MoveTo(5584, -27924)
	Move(5232, -27891)
	Moveto(3986, -27642)
	RandomSleep(1500)
	WaitMapLoading($ID_ICE_CLIFF_CHASMS, 10000, 2000)

	Move(5232, -27891)
	RandomSleep(1500)
	WaitMapLoading($ID_BOREAL_STATION, 10000, 2000)
	$boreal_farm_setup = True
	Info('Preparations complete')
EndFunc


Func SetupPlayerBorealChestFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_WARRIOR
			$boreal_player_profession = $ID_WARRIOR
			LoadSkillTemplate($BOREAL_WARRIOR_CHESTRUNNER_SKILLBAR)
		Case $ID_RANGER
			$boreal_player_profession = $ID_RANGER
			LoadSkillTemplate($BOREAL_RANGER_CHESTRUNNER_SKILLBAR)
		Case $ID_MONK
			$boreal_player_profession = $ID_MONK
			LoadSkillTemplate($BOREAL_MONK_CHESTRUNNER_SKILLBAR)
		Case $ID_NECROMANCER
			$boreal_player_profession = $ID_NECROMANCER
			LoadSkillTemplate($BOREAL_NECROMANCER_CHESTRUNNER_SKILLBAR)
		Case $ID_MESMER
			$boreal_player_profession = $ID_MESMER
			LoadSkillTemplate($BOREAL_MESMER_CHESTRUNNER_SKILLBAR)
		Case $ID_ELEMENTALIST
			$boreal_player_profession = $ID_ELEMENTALIST
			LoadSkillTemplate($BOREAL_ELEMENTALIST_CHESTRUNNER_SKILLBAR)
		Case $ID_ASSASSIN
			$boreal_player_profession = $ID_ASSASSIN
			LoadSkillTemplate($BOREAL_ASSASSIN_CHESTRUNNER_SKILLBAR)
		Case $ID_RITUALIST
			$boreal_player_profession = $ID_RITUALIST
			LoadSkillTemplate($BOREAL_RITUALIST_CHESTRUNNER_SKILLBAR)
		Case $ID_PARAGON
			$boreal_player_profession = $ID_PARAGON
			LoadSkillTemplate($BOREAL_PARAGON_CHESTRUNNER_SKILLBAR)
		Case $ID_DERVISH
			$boreal_player_profession = $ID_DERVISH
			LoadSkillTemplate($BOREAL_DERVISH_CHEST_RUNNER_SKILLBAR)
	EndSwitch
	RandomSleep(250)
EndFunc


;~ Boreal Chest farm loop
Func BorealChestFarmLoop()
	TravelToOutpost($ID_BOREAL_STATION, $district_name)
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	Info('Starting chest farm run')

	MoveTo(5799, -27957)
	Moveto(3986, -27642)
	RandomSleep(1500)
	WaitMapLoading($ID_ICE_CLIFF_CHASMS, 10000, 2000)

	Local $openedChests = 0

	Info('Running to Spot #1')
	If BorealChestRun(2728, -25294) == $FAIL Then Return $FAIL
	If BorealChestRun(2900, -22272) == $FAIL Then Return $FAIL
	If BorealChestRun(-1000, -19801) == $FAIL Then Return $FAIL
	If BorealChestRun(-2570, -17208) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS, BorealSpeedRun, BorealUnblock) ? 1 : 0
	Info('Running to Spot #2')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS, BorealSpeedRun, BorealUnblock) ? 1 : 0
	Info('Running to Spot #3')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS, BorealSpeedRun, BorealUnblock) ? 1 : 0
	Info('Running to Spot #4')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS, BorealSpeedRun, BorealUnblock) ? 1 : 0
	Info('Opened ' & $openedChests & ' chests.')
	; Result can't be considered a failure if no chests were found
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Function to unblocked when opening chests
Func BorealUnblock()
	If IsRecharged($BOREAL_HEARTOFSHADOW) And GetEnergy() >= 5 Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then $target = GetMyAgent()
		UseSkillEx($BOREAL_HEARTOFSHADOW, $target)
	ElseIf IsRecharged($BOREAL_DEATHSCHARGE) And GetEnergy() >= 5 Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($BOREAL_DEATHSCHARGE, $target)
	EndIf
EndFunc


;~ Function to speed run up
Func BorealSpeedRun()
	If IsPlayerDead() Then Return $FAIL
	Local $me = GetMyAgent()
	Local $my_health_percent = DllStructGetData($me, 'HealthPercent')
	;~ If health is low, cast Shroud of Distress
	If $my_health_percent < 0.6 And GetEnergy() >= 10 And IsRecharged($BOREAL_SHROUDOFDISTRESS) Then
		UseSkillEx($BOREAL_SHROUDOFDISTRESS)
	EndIf
	;~ If health is very low, attempt to shadow step away from nearest target
	If $my_health_percent < 0.2 And GetEnergy() >= 5 And IsRecharged($BOREAL_HEARTOFSHADOW) Then
		Local $target = GetNearestEnemyToAgent($me)
		If $target == Null Then $target = $me
		UseSkillEx($BOREAL_HEARTOFSHADOW, $target)
	EndIf
	;~ If Crippled or Mountain Aloe near, cast I am unstoppable
	If IsRecharged($BOREAL_IAMUNSTOPPABLE) And GetEnergy() >= 5 Then
		If GetEffect($ID_CRIPPLED) <> Null Or IsEnemyNPCInCastingRange($BOREAL_MOUNTAIN_ALOE_MODEL_ID) Then
			UseSkillEx($BOREAL_IAMUNSTOPPABLE)
		EndIf
	EndIf
	;~ If Mountain Pinesouls are near, cast Shadow Form
	If IsRecharged($BOREAL_SHADOWFORM) And GetEnergy() >= 5 Then
		If GetEffect($ID_CRIPPLED) <> Null Or IsEnemyNPCInCastingRange($BOREAL_MOUNTAIN_PINESOUL_MODEL_ID) Then
			UseSkillEx($BOREAL_SHADOWFORM)
		EndIf
	EndIf
	;~ Cast Dwarven Stability and Dash when ready
	If IsRecharged($BOREAL_DWARVENSTABILITY) And GetEnergy() >= 5 Then
		UseSkillEx($BOREAL_DWARVENSTABILITY)
	EndIf
	If IsRecharged($BOREAL_DASH) And GetEnergy() >= 5 Then
		UseSkillEx($BOREAL_DASH)
	EndIf
	Return $SUCCESS
EndFunc


Func IsEnemyNPCInCastingRange($model_id)
	Local $me = GetMyAgent()
	For $agent In GetNPCsInRangeOfAgent($me, $ID_ALLEGIANCE_FOE, $RANGE_SPELLCAST)
		If DllStructGetData($agent, 'ModelID') == $model_id Then
			Return True
		EndIf
	Next
	Return False
EndFunc


;~ Main function for chest run
Func BorealChestRun($X, $Y)
	Move($X, $Y, 0)
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $X, $Y) > $RANGE_ADJACENT
		BorealSpeedRun()
		Sleep(250)
		$me = GetMyAgent()
		Move($X, $Y, 0)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc
