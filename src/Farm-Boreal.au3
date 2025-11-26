#CS ===========================================================================
; Author: JackLinesMatthews
; Contributor: Kronos
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
Global Const $BorealChestRunnerSkillbar = 'OwZjgwf84Q3l0kTQAAAAAAAAAAA'
Global Const $BorealChestRunInformations = 'For best results, have :' & @CRLF _
	& '- dwarves rank 5 minimum' & @CRLF _
	& '- norn rank 5 minimum'
; Average duration ~ 1m30s
Global Const $BOREAL_FARM_DURATION = (1 * 60 + 30) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Boreal_DwarvenStability) is better than UseSkillEx(1))
Global Const $Boreal_DwarvenStability = 1
Global Const $Boreal_IAmUnstoppable = 2
Global Const $Boreal_Dash = 3

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
	If GetMapID() <> $ID_Boreal_Station Then DistrictTravel($ID_Boreal_Station, $DISTRICT_NAME)
	LeaveParty()
	;LoadSkillTemplate($BorealChestRunnerSkillbar)
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf

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


;~ Boreal Chest farm loop
Func BorealChestFarmLoop($STATUS)
	Info('Starting chest farm run')
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf

	Moveto(3986, -27642)
	RandomSleep(1500)
	WaitMapLoading($ID_Ice_Cliff_Chasms, 10000, 2000)

	Local $openedChests = 0

	Info('Running to Spot #1')
	BorealAssassinRun(2728, -25294)
	BorealAssassinRun(2900, -22272)
	BorealAssassinRun(-1000, -19801)
	BorealAssassinRun(-2570, -17208)
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Running to Spot #2')
	BorealAssassinRun(-4218, -15219)
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Running to Spot #3')
	BorealAssassinRun(-4218, -15219)
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Running to Spot #4')
	BorealAssassinRun(-4218, -15219)
	$openedChests += FindAndOpenChests($RANGE_COMPASS,BorealSpeedRun) ? 1 : 0
	Info('Opened ' & $openedChests & ' chests.')
	; Result can't be considered a failure if no chests were found
	Local $result = IsPlayerAlive() ? $SUCCESS : $FAIL
	BackToBorealStation()
	Return $result
EndFunc


;~ Returning to Boreal Station
Func BackToBorealStation()
	Info('Porting to Boreal Station')
	Resign()
	RandomSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Boreal_Station, 10000, 1000)
EndFunc


;~ Function to speed it up
Func BorealSpeedRun()
	Local $me = GetMyAgent()
	If IsPlayerDead() Then Return $FAIL
	If DllStructGetData(GetEffect($ID_Crippled), 'SkillID') <> 0 And IsRecharged($Boreal_IAmUnstoppable) And GetEnergy() >= 5 Then UseSkillEx($Boreal_IAmUnstoppable)
	If IsRecharged($Boreal_DwarvenStability) And GetEnergy() >= 5 Then
		UseSkillEx($Boreal_DwarvenStability)
	EndIf
	If IsRecharged($Boreal_Dash) And GetEnergy() >= 5 Then
		UseSkillEx($Boreal_Dash)
	EndIf
	Return $SUCCESS
EndFunc


;~ Main function to run as an Assassin
Func BorealAssassinRun($X, $Y)
	Move($X, $Y, 0)
	Local $me = GetMyAgent()
	While IsPlayerAlive() And GetDistanceToPoint($me, $X, $Y) > 100
		If BorealSpeedRun() == $FAIL Then Return $FAIL
		Sleep(250)
		$me = GetMyAgent()
		Move($X, $Y, 0)
	WEnd
	Return $SUCCESS
EndFunc