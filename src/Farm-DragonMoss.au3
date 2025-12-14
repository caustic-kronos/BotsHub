#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Contributor: Gahais
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

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $RADragonMossFarmerSkillbar = 'OgcTcZ88Z6u844AiHRnJuE3R4AA'
Global Const $DragonMossFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Wilderness Survival' & @CRLF _
	& '- A shield with the inscription Riders on the storm (+10 armor against Lightning damage)' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
Global Const $DRAGONMOSS_FARM_DURATION = 2 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($DM_DwarvenStability) is better than UseSkillEx(1))
Global Const $DM_DwarvenStability	= 1
Global Const $DM_StormChaser		= 2
Global Const $DM_ShroudOfDistress	= 3
Global Const $DM_DeadlyParadox		= 4
Global Const $DM_ShadowForm			= 5
Global Const $DM_MentalBlock		= 6
Global Const $DM_DeathsCharge		= 7
Global Const $DM_WhirlingDefense	= 8

Global $DM_FARM_SETUP = False

;~ Main method to farm Dragon Moss
Func DragonMossFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $DM_FARM_SETUP And SetupDragonMossFarm() == $FAIL Then Return $PAUSE

	GoToDrazachThicket()
	Local $result = DragonMossFarmLoop()
	ReturnBackToOutpost($ID_Saint_Anjekas_Shrine)
	Return $result
EndFunc


;~ Dragon moss farm setup
Func SetupDragonMossFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_Saint_Anjekas_Shrine, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerDragonMossFarm() Then Return $FAIL
	LeaveParty() ; solo farmer
	GoToDrazachThicket()
	MoveTo(-11100, 19700)
	Move(-11300, 19900)
	RandomSleep(1000)
	WaitMapLoading($ID_Saint_Anjekas_Shrine, 10000, 1000)
	$DM_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerDragonMossFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Ranger Then
		LoadSkillTemplate($RADragonMossFarmerSkillbar)
    Else
    	Warn('Should run this farm as ranger')
    	Return $FAIL
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Drazach Thicket
Func GoToDrazachThicket()
	TravelToOutpost($ID_Saint_Anjekas_Shrine, $DISTRICT_NAME)
	While GetMapID() <> $ID_Drazach_Thicket
		Info('Moving to Drazach Thicket')
		MoveTo(-11400, -22650)
		Move(-11000, -24000)
		RandomSleep(1000)
		WaitMapLoading($ID_Drazach_Thicket, 10000, 1000)
	WEnd
EndFunc


;~ Farm loop
Func DragonMossFarmLoop()
	If GetMapID() <> $ID_Drazach_Thicket Then Return $FAIL

	UseSkillEx($DM_DwarvenStability)
	RandomSleep(50)
	UseSkillEx($DM_StormChaser)
	RandomSleep(50)
	MoveTo(-8400, 18450)
	; Can talk to get benediction here

	; Move to spot before aggro
	MoveTo(-6350, 16750)
	UseSkillEx($DM_ShroudOfDistress)
	RandomSleep(50)
	UseSkillEx($DM_DeadlyParadox)
	RandomSleep(50)
	UseSkillEx($DM_ShadowForm)
	RandomSleep(50)
	; Aggro
	MoveTo(-5400, 15675, UseIMSWhenAvailable)
	MoveTo(-6150, 18000, 0, UseIMSWhenAvailable)
	RandomSleep(2000)
	; Safety
	MoveTo(-6575, 18575, 0)
	UseSkillEx($DM_DwarvenStability)
	While IsPlayerAlive() And Not IsRecharged($DM_ShadowForm)
		RandomSleep(500)
	WEnd
	UseSkillEx($DM_DeadlyParadox)
	RandomSleep(50)
	UseSkillEx($DM_ShadowForm)
	RandomSleep(50)
	If IsPlayerDead() Then Return $FAIL
	RandomSleep(1000)
	; Killing
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_ADJACENT)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	While IsRecharged($DM_DeathsCharge) And IsPlayerAlive()
		UseSkillEx($DM_DeathsCharge, $target)
		RandomSleep(200)
	WEnd
	While IsRecharged($DM_WhirlingDefense) And IsPlayerAlive()
		UseSkillEx($DM_WhirlingDefense)
		RandomSleep(200)
	WEnd

	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $counter = 0
	While IsPlayerAlive() And $foesCount > 0 And $counter < 16
		If IsRecharged($DM_ShadowForm) Then UseSkillEx($DM_ShadowForm)
		RandomSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	WEnd
	If IsPlayerDead() Then Return $FAIL

	RandomSleep(1000)

	If IsPlayerAlive() Then
		Info('Looting')
		PickUpItems()
	EndIf

	Return $SUCCESS
EndFunc


;~ If storm chaser is available, use it
Func UseIMSWhenAvailable()
	If IsRecharged($DM_StormChaser) Then UseSkillEx($DM_StormChaser)
EndFunc