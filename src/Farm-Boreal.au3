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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
; Universal run build for every profession
Global Const $BorealWarriorChestRunnerSkillbar = 'OQcT8ZPHHiHRn5A6ukmcCC3BBC'
Global Const $BorealRangerChestRunnerSkillbar = 'OgcT8ZPfHiHRn5A6ukmcCC3BBC'
Global Const $BorealMonkChestRunnerSkillbar = 'OwcT8ZPDHiHRn5A6ukmcCC3BBC'
Global Const $BorealNecromancerChestRunnerSkillbar = 'OAdTY4P7HiHRn5A6ukmcCC3BBC'
Global Const $BorealMesmerChestRunnerSkillbar = 'OQdT8ZPDGiHRn5A6ukmcCC3BBC'
Global Const $BorealElementalistChestRunnerSkillbar = 'OgdT8Z/wYiHRn5A6ukmcCC3BBC'
Global Const $BorealAssassinChestRunnerSkillbar = 'OwBj8xe84Q8I6MHQ3l0kTQ4OIQ'
Global Const $BorealRitualistChestRunnerSkillbar = 'OAej8xeM5Q8I6MHQ3l0kTQ4OIQ'
Global Const $BorealParagonChestRunnerSkillbar = 'OQej8xeM6Q8I6MHQ3l0kTQ4OIQ'
Global Const $BorealDervishChestRunnerSkillbar = 'Ogej8xeDLT8I6MHQ3l0kTQ4OIQ'
Global $BorealPlayerProfession = $ID_Assassin ; global variable to remember player's profession in setup

Global Const $BorealChestRunInformations = 'For best results, have :' & @CRLF _
	& '- dwarves rank 5 minimum' & @CRLF _
	& '- norn rank 5 minimum'
; Average duration ~ 1m30s
Global Const $BOREAL_FARM_DURATION = (1 * 60 + 30) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Boreal_DwarvenStability) is better than UseSkillEx(1))
Global Const $Boreal_DeadlyParadox		= 1
Global Const $Boreal_ShadowForm			= 2
Global Const $Boreal_ShroudOfDistress	= 3
Global Const $Boreal_DwarvenStability	= 4
Global Const $Boreal_IAmUnstoppable		= 5
Global Const $Boreal_Dash				= 6
Global Const $Boreal_DeathsCharge		= 7
Global Const $Boreal_HeartOfShadow		= 8

Global $BOREAL_FARM_SETUP = False

;~ Main method to chest farm Boreal
Func BorealChestFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $BOREAL_FARM_SETUP Then SetupBorealFarm()
	Local $result = BorealChestFarmLoop($STATUS)
	ReturnBackToOutpost($ID_Boreal_Station)
	Return $result
EndFunc


;~ Boreal chest farm setup
Func SetupBorealFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Boreal_Station, $DISTRICT_NAME)

	SetupPlayerBorealChestFarm()
	LeaveParty() ; solo farmer
	SwitchToHardModeIfEnabled()

	MoveTo(5584, -27924)
	Move(5232, -27891)
	Moveto(3986, -27642)
	RandomSleep(1500)
	WaitMapLoading($ID_Ice_Cliff_Chasms, 10000, 2000)

	Move(5232, -27891)
	RandomSleep(1500)
	WaitMapLoading($ID_Boreal_Station, 10000, 2000)
	$BOREAL_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func SetupPlayerBorealChestFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_Warrior
			$BorealPlayerProfession = $ID_Warrior
			LoadSkillTemplate($BorealWarriorChestRunnerSkillbar)
		Case $ID_Ranger
			$BorealPlayerProfession = $ID_Ranger
			LoadSkillTemplate($BorealRangerChestRunnerSkillbar)
		Case $ID_Monk
			$BorealPlayerProfession = $ID_Monk
			LoadSkillTemplate($BorealMonkChestRunnerSkillbar)
		Case $ID_Necromancer
			$BorealPlayerProfession = $ID_Necromancer
			LoadSkillTemplate($BorealNecromancerChestRunnerSkillbar)
		Case $ID_Mesmer
			$BorealPlayerProfession = $ID_Mesmer
			LoadSkillTemplate($BorealMesmerChestRunnerSkillbar)
		Case $ID_Elementalist
			$BorealPlayerProfession = $ID_Elementalist
			LoadSkillTemplate($BorealElementalistChestRunnerSkillbar)
		Case $ID_Assassin
			$BorealPlayerProfession = $ID_Assassin
			LoadSkillTemplate($BorealAssassinChestRunnerSkillbar)
		Case $ID_Ritualist
			$BorealPlayerProfession = $ID_Ritualist
			LoadSkillTemplate($BorealRitualistChestRunnerSkillbar)
		Case $ID_Paragon
			$BorealPlayerProfession = $ID_Paragon
			LoadSkillTemplate($BorealParagonChestRunnerSkillbar)
		Case $ID_Dervish
			$BorealPlayerProfession = $ID_Dervish
			LoadSkillTemplate($BorealDervishChestRunnerSkillbar)
	EndSwitch
	Sleep(250 + GetPing())
	TrySetupWeaponSlotUsingGUISettings()
EndFunc


;~ Boreal Chest farm loop
Func BorealChestFarmLoop($STATUS)
	TravelToOutpost($ID_Boreal_Station, $DISTRICT_NAME)
	If FindInInventory($ID_Lockpick)[0] == 0 Then
		Error('No lockpicks available to open chests')
		Return $PAUSE
	EndIf

	Info('Starting chest farm run')

	Moveto(3986, -27642)
	RandomSleep(1500)
	WaitMapLoading($ID_Ice_Cliff_Chasms, 10000, 2000)

	Local $openedChests = 0

	Info('Running to Spot #1')
	If BorealChestRun(2728, -25294) == $FAIL Then Return $FAIL
	If BorealChestRun(2900, -22272) == $FAIL Then Return $FAIL
	If BorealChestRun(-1000, -19801) == $FAIL Then Return $FAIL
	If BorealChestRun(-2570, -17208) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Running to Spot #2')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Running to Spot #3')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Running to Spot #4')
	If BorealChestRun(-4218, -15219) == $FAIL Then Return $FAIL
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Opened ' & $openedChests & ' chests.')
	; Result can't be considered a failure if no chests were found
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Function to speed run up
Func BorealSpeedRun()
	If IsPlayerDead() Then Return $FAIL
	Local $me = GetMyAgent()
	If IsRecharged($Boreal_IAmUnstoppable) And GetEffect($ID_Crippled) <> Null And GetEnergy() >= 5 Then
		UseSkillEx($Boreal_IAmUnstoppable)
	EndIf
	If IsRecharged($Boreal_DwarvenStability) And GetEnergy() >= 5 Then
		UseSkillEx($Boreal_DwarvenStability)
	EndIf
	If IsRecharged($Boreal_Dash) And GetEnergy() >= 5 Then
		UseSkillEx($Boreal_Dash)
	EndIf
	Return $SUCCESS
EndFunc


;~ Main function for chest run
Func BorealChestRun($X, $Y)
	Move($X, $Y, 0)
	Local $me = GetMyAgent()
	While IsPlayerAlive() And GetDistanceToPoint($me, $X, $Y) > $RANGE_ADJACENT
		BorealSpeedRun()
		Sleep(250)
		$me = GetMyAgent()
		Move($X, $Y, 0)
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc