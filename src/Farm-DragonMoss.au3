; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Global Const $DragonMossBotVersion = '0.1'

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
Global Const $DM_DwarvenStability = 1
Global Const $DM_StormChaser = 2
Global Const $DM_ShroudOfDistress = 3
Global Const $DM_DeadlyParadox = 4
Global Const $DM_ShadowForm = 5
Global Const $DM_MentalBlock = 6
Global Const $DM_DeathsCharge = 7
Global Const $DM_WhirlingDefense = 8

Global $DM_FARM_SETUP = False

;~ Main method to farm Dragon Moss
Func DragonMossFarm($STATUS)
	If Not $DM_FARM_SETUP Then
		SetupDragonMossFarm()
		$DM_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return DragonMossFarmLoop()
EndFunc


;~ Dragon moss farm setup
Func SetupDragonMossFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Saint_Anjekas_Shrine Then DistrictTravel($ID_Saint_Anjekas_Shrine, $DISTRICT_NAME)
	SwitchMode($ID_HARD_MODE)
	LeaveGroup()
	LoadSkillTemplate($RADragonMossFarmerSkillbar)
	Info('Entering Drazach Thicket')
	MoveTo(-11400, -22650)
	Move(-11000, -24000)
	RndSleep(1000)
	WaitMapLoading($ID_Drazach_Thicket, 10000, 1000)
	MoveTo(-11100, 19700)
	Move(-11300, 19900)
	RndSleep(1000)
	WaitMapLoading($ID_Saint_Anjekas_Shrine, 10000, 1000)
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func DragonMossFarmLoop()
	Info('Entering Drazach Thicket')
	MoveTo(-11400, -22650)
	Move(-11000, -24000)
	RndSleep(1000)
	WaitMapLoading($ID_Drazach_Thicket, 10000, 1000)
	UseSkillEx($DM_DwarvenStability)
	RndSleep(50)
	UseSkillEx($DM_StormChaser)
	RndSleep(50)
	MoveTo(-8400, 18450)
	; Can talk to get benediction here

	; Move to spot before aggro
	MoveTo(-6350, 16750)
	UseSkillEx($DM_ShroudOfDistress)
	RndSleep(50)
	UseSkillEx($DM_DeadlyParadox)
	RndSleep(50)
	UseSkillEx($DM_ShadowForm)
	RndSleep(50)
	; Aggro
	MoveTo(-5400, 15675, UseIMSWhenAvailable)
	MoveTo(-6150, 18000, 0, UseIMSWhenAvailable)
	RndSleep(2000)
	; Safety
	MoveTo(-6575, 18575, 0)
	UseSkillEx($DM_DwarvenStability)
	While Not GetIsDead() And Not IsRecharged($DM_ShadowForm)
		RndSleep(500)
	WEnd
	UseSkillEx($DM_DeadlyParadox)
	RndSleep(50)
	UseSkillEx($DM_ShadowForm)
	RndSleep(50)
	If GetIsDead() Then
		BackToSaintAnjekaOutpost()
		Return 1
	EndIf
	RndSleep(1000)
	; Killing
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_ADJACENT)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	While IsRecharged($DM_DeathsCharge) And Not GetIsDead()
		UseSkillEx($DM_DeathsCharge, $target)
		RndSleep(200)
	WEnd
	While IsRecharged($DM_WhirlingDefense) And Not GetIsDead()
		UseSkillEx($DM_WhirlingDefense)
		RndSleep(200)
	WEnd

	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $counter = 0
	While Not GetIsDead() And $foesCount > 0 And $counter < 16
		If IsRecharged($DM_ShadowForm) Then UseSkillEx($DM_ShadowForm)
		RndSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	WEnd

	If GetIsDead() Then
		BackToSaintAnjekaOutpost()
		Return 1
	EndIf

	RndSleep(1000)

	Info('Looting')
	PickUpItems()

	BackToSaintAnjekaOutpost()
	Return 0
EndFunc


;~ If storm chaser is available, uses it
Func UseIMSWhenAvailable()
	If IsRecharged($DM_StormChaser) Then UseSkillEx($DM_StormChaser)
EndFunc


;~ Return to Saint Anjeka outpost
Func BackToSaintAnjekaOutpost()
	Info('Porting to Saint Anjekas Shrine')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Saint_Anjekas_Shrine, 10000, 1000)
EndFunc