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
Global Const $BOREAL_DERVISH_CHEST_RUNNER_SKILLBAR = 'Ogej4NfMLTbXHYHQ3l0kTQ4OIQA'


Global Const $BOREAL_CHESTRUN_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- dwarves rank 5 minimum' & @CRLF _
	& '- norn rank 5 minimum' & @CRLF _
	& 'Must have skills: Dash, Dwarven Stability, I am Unstoppable' & @CRLF _
	& 'Optional skills (for more survivability and unblocking): Shroud of Distress, Heart of Shadow, Deaths Charge'
; Average duration ~ 1m30s
Global Const $BOREAL_FARM_DURATION = (1 * 60 + 30) * 1000
Global Const $BOREAL_CHEST_RUN_TIMEOUT_MS = 2 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($BOREAL_DWARVEN_STABILITY) is better than UseSkillEx(1))
Global Const $BOREAL_PIOUS_RENEWAL		= 1
Global Const $BOREAL_PIOUS_HASTE		= 2
Global Const $BOREAL_SHROUD_OF_DISTRESS	= 3
Global Const $BOREAL_DWARVEN_STABILITY	= 4
Global Const $BOREAL_I_AM_UNSTOPPABLE	= 5
Global Const $BOREAL_DASH				= 6
Global Const $BOREAL_DEATHS_CHARGE		= 7
Global Const $BOREAL_HEART_OF_SHADOW	= 8

; Model IDs of enemy NPCs that we might encounter
Global Const $BOREAL_MOUNTAIN_PINESOUL_MODEL_ID = 6539
Global Const $BOREAL_MOUNTAIN_ALOE_MODEL_ID = 6540

; global variable to remember player's profession in setup
Global $boreal_player_profession = $ID_ASSASSIN
Global $boreal_farm_setup = False

; variables whether certain optional skills are equipped
Global $boreal_has_shroud_of_distress = False
Global $boreal_has_heart_of_shadow = False
Global $boreal_has_deaths_charge = False
Global $boreal_has_pious_renewal = False
Global $boreal_has_pious_haste = False

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

	MoveTo(5600, -27900)
	MoveTo(5200, -27900, $RANGE_ADJACENT, 0)
	If GetDistanceToPoint(GetMyAgent(), 5200, -27900) > $RANGE_ADJACENT Then
		MoveTo(5350, -27500)
		MoveTo(5500, -27750)
		MoveTo(5200, -27900)
	EndIf
	Move(3986, -27642)
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
	$boreal_has_shroud_of_distress = GetSkillbarSkillID($BOREAL_SHROUD_OF_DISTRESS) == $ID_SHROUD_OF_DISTRESS
	$boreal_has_heart_of_shadow = GetSkillbarSkillID($BOREAL_HEART_OF_SHADOW) == $ID_HEART_OF_SHADOW
	$boreal_has_deaths_charge = GetSkillbarSkillID($BOREAL_DEATHS_CHARGE) == $ID_DEATHS_CHARGE
	$boreal_has_pious_renewal = GetSkillbarSkillID($BOREAL_PIOUS_RENEWAL) == $ID_PIOUS_RENEWAL
	$boreal_has_pious_haste = GetSkillbarSkillID($BOREAL_PIOUS_HASTE) == $ID_PIOUS_HASTE
EndFunc


;~ Boreal Chest farm loop
Func BorealChestFarmLoop()
	TravelToOutpost($ID_BOREAL_STATION, $district_name)
	If FindInInventory($ID_LOCKPICK)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	Info('Starting chest farm run')

	MoveTo(5200,-27900, $RANGE_ADJACENT, 0)
	Move(3986, -27642)
	RandomSleep(1500)
	WaitMapLoading($ID_ICE_CLIFF_CHASMS, 10000, 2000)

	Local $openedChests = 0
	Local $totalChestsCount = 0

	; Run to the first spot and open chests there
	Info('Running to Spot #1')
	If BorealChestRun(2728, -25294) == $FAIL Then Return $FAIL
	If BorealChestRun(2900, -22272) == $FAIL Then Return $FAIL
	If BorealChestRun(-1000, -19801) == $FAIL Then Return $FAIL
	If BorealChestRun(-2570, -17208) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS, BorealSpeedRun, BorealUnblock) ? 1 : 0

	; Run to the second spot and count all chests in compass range
	Info('Running to Spot #2 and counting chests')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$totalChestsCount = CountChestsInCompassRange()
	Info('Total amount of chests here: ' & $totalChestsCount)

	; For all remaining chests, run to them, and return to the original spot inbetween
	For $i = 1 To $totalChestsCount - $openedChests
		Info('Running to Spot #' & (2+$i))
		$openedChests += FindAndOpenChests($RANGE_COMPASS, BorealSpeedRun, BorealUnblock) ? 1 : 0
		If $openedChests == $totalChestsCount Then ExitLoop
		If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	Next

	Info('Opened ' & $openedChests & '/' & $totalChestsCount & ' chests.')
	; Result cannot be considered a failure if no chests were found
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Count the amount of Chests in compass range
Func CountChestsInCompassRange()
	Local $me = GetMyAgent()
	Local $X = DllStructGetData($me, 'X')
	Local $Y = DllStructGetData($me, 'Y')
	Local $count = 0
	Local $agents = GetAgentArray($ID_AGENT_TYPE_STATIC)
	For $agent In $agents
		Local $gadgetID = DllStructGetData($agent, 'GadgetID')
		If $MAP_CHESTS_IDS[$gadgetID] == Null Then ContinueLoop
		If GetDistanceToPoint($agent, $X, $Y) > $RANGE_COMPASS Then ContinueLoop
		$count += 1
	Next
	Return $count
EndFunc


;~ Function to unblocked when opening chests
Func BorealUnblock()
	If $boreal_has_heart_of_shadow And IsRecharged($BOREAL_HEART_OF_SHADOW) And GetEnergy() >= 5 Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent())
		If $target == Null Then $target = GetMyAgent()
		UseSkillEx($BOREAL_HEART_OF_SHADOW, $target)
	ElseIf $boreal_has_deaths_charge And IsRecharged($BOREAL_DEATHS_CHARGE) And GetEnergy() >= 5 Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($BOREAL_DEATHS_CHARGE, $target)
	EndIf
EndFunc


;~ Function to speed run up
Func BorealSpeedRun()
	If IsPlayerDead() Then Return $FAIL
	Local $me = GetMyAgent()
	Local $myHealthPercent = DllStructGetData($me, 'HealthPercent')
	Local $areEnemiesInCastingRange = GetAreBorealEnemiesInCastingRange()
	Local $amCrippled = GetEffect($ID_CRIPPLED) <> Null
	;~ If health is very low, attempt to shadow step away from nearest target
	If $boreal_has_heart_of_shadow And $myHealthPercent < 0.2 And GetEnergy() >= 5 And IsRecharged($BOREAL_HEART_OF_SHADOW) Then
		Local $target = GetNearestEnemyToAgent($me)
		If $target == Null Then $target = $me
		UseSkillEx($BOREAL_HEART_OF_SHADOW, $target)
	EndIf
	;~ If health is low, cast Shroud of Distress
	If $boreal_has_shroud_of_distress And $myHealthPercent < 0.6 And GetEnergy() >= 10 And IsRecharged($BOREAL_SHROUD_OF_DISTRESS) Then
		UseSkillEx($BOREAL_SHROUD_OF_DISTRESS)
	EndIf
	;~ If Crippled or Mountain Aloe/Pinesoul near, cast I am unstoppable
	If $areEnemiesInCastingRange Or $amCrippled Then
		If IsRecharged($BOREAL_I_AM_UNSTOPPABLE) And GetEnergy() >= 5 Then
			UseSkillEx($BOREAL_I_AM_UNSTOPPABLE)
		EndIf
	EndIf
	;~ Cast Dwarven Stability and Dash when ready
	If IsRecharged($BOREAL_DWARVEN_STABILITY) And GetEnergy() >= 5 Then
		UseSkillEx($BOREAL_DWARVEN_STABILITY)
		Sleep(GetPing() + 100)
	EndIf
	If $boreal_player_profession == $ID_DERVISH And $boreal_has_pious_haste And $boreal_has_pious_renewal Then
		If IsRecharged($BOREAL_PIOUS_HASTE) And GetEnergy() >= 10 Then
			UseSkillEx($BOREAL_PIOUS_RENEWAL)
			Sleep(GetPing() + 100)
			UseSkillEx($BOREAL_PIOUS_HASTE)
		EndIf
	ElseIf IsRecharged($BOREAL_DASH) And GetEnergy() >= 5 Then
		UseSkillEx($BOREAL_DASH)
	EndIf
	Return $SUCCESS
EndFunc


Func GetAreBorealEnemiesInCastingRange()
	Local $me = GetMyAgent()
	For $agent In GetNPCsInRangeOfAgent($me, $ID_ALLEGIANCE_FOE, $RANGE_SPELLCAST)
		Switch DllStructGetData($agent, 'ModelID')
			Case $BOREAL_MOUNTAIN_ALOE_MODEL_ID, $BOREAL_MOUNTAIN_PINESOUL_MODEL_ID
				return True
		EndSwitch
	Next
	Return False
EndFunc


;~ Main function for chest run
Func BorealChestRun($X, $Y)
	Local $runTimer = TimerInit()
	Move($X, $Y, 0)
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $X, $Y) > $RANGE_ADJACENT
		If TimerDiff($runTimer) > $BOREAL_CHEST_RUN_TIMEOUT_MS Then Return $FAIL
		BorealSpeedRun()
		Sleep(250)
		$me = GetMyAgent()
		Move($X, $Y, 0)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc
