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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $RA_DRAGON_MOSS_FARMER_SKILLBAR = 'OgcTcZ88Z6u844AiHRnJuE3R4AA'
Global Const $DRAGON_MOSS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- the quest A New Escort that makes the dragon moss show up (without it you cant farm)' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Wilderness Survival' & @CRLF _
	& '- A shield with the inscription Riders on the storm (+10 armor against Lightning damage)' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
Global Const $DRAGONMOSS_FARM_DURATION = 2 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($DM_DWARVEN_STABILITY) is better than UseSkillEx(1))
Global Const $DM_DWARVEN_STABILITY	= 1
Global Const $DM_STORM_CHASER		= 2
Global Const $DM_SHROUD_OF_DISTRESS	= 3
Global Const $DM_DEADLY_PARADOX		= 4
Global Const $DM_SHADOWFORM			= 5
Global Const $DM_MENTAL_BLOCK		= 6
Global Const $DM_DEATHS_CHARGE		= 7
Global Const $DM_WHIRLING_DEFENSE	= 8

Global $dm_farm_setup = False

;~ Main method to farm Dragon Moss
Func DragonMossFarm()
	If Not $dm_farm_setup And SetupDragonMossFarm() == $FAIL Then Return $PAUSE

	GoToDrazachThicket()
	Local $result = DragonMossFarmLoop()
	ResignAndReturnToOutpost($ID_SAINT_ANJEKAS_SHRINE)
	Return $result
EndFunc


;~ Dragon moss farm setup
Func SetupDragonMossFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_SAINT_ANJEKAS_SHRINE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerDragonMossFarm() Then Return $FAIL
	LeaveParty()
	GoToDrazachThicket()
	MoveTo(-11100, 19700)
	Move(-11300, 19900)
	RandomSleep(1000)
	WaitMapLoading($ID_SAINT_ANJEKAS_SHRINE, 10000, 1000)
	$dm_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerDragonMossFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($RA_DRAGON_MOSS_FARMER_SKILLBAR)
	Else
		Warn('Should run this farm as ranger')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Drazach Thicket
Func GoToDrazachThicket()
	TravelToOutpost($ID_SAINT_ANJEKAS_SHRINE, $district_name)
	While GetMapID() <> $ID_DRAZACH_THICKET
		Info('Moving to Drazach Thicket')
		MoveTo(-11400, -22650)
		Move(-11000, -24000)
		RandomSleep(1000)
		WaitMapLoading($ID_DRAZACH_THICKET, 10000, 1000)
	WEnd
EndFunc


;~ Farm loop
Func DragonMossFarmLoop()
	If GetMapID() <> $ID_DRAZACH_THICKET Then Return $FAIL

	UseSkillEx($DM_DWARVEN_STABILITY)
	RandomSleep(50)
	UseSkillEx($DM_STORM_CHASER)
	RandomSleep(50)
	MoveTo(-8400, 18450)
	; Can talk to get benediction here

	; Move to spot before aggro
	MoveTo(-6350, 16750)
	UseSkillEx($DM_SHROUD_OF_DISTRESS)
	RandomSleep(50)
	UseSkillEx($DM_DEADLY_PARADOX)
	RandomSleep(50)
	UseSkillEx($DM_SHADOWFORM)
	RandomSleep(50)
	; Aggro
	MoveTo(-5400, 15675, 25, 0, UseIMSWhenAvailable)
	MoveTo(-6150, 18000, 25, 0, UseIMSWhenAvailable)
	RandomSleep(2000)
	; Safety
	MoveTo(-6575, 18575, 25, 0)
	UseSkillEx($DM_DWARVEN_STABILITY)
	While IsPlayerAlive() And Not IsRecharged($DM_SHADOWFORM)
		RandomSleep(500)
	WEnd
	UseSkillEx($DM_DEADLY_PARADOX)
	RandomSleep(50)
	UseSkillEx($DM_SHADOWFORM)
	RandomSleep(50)
	If IsPlayerDead() Then Return $FAIL
	RandomSleep(1000)
	; Killing
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_ADJACENT)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	While IsRecharged($DM_DEATHS_CHARGE) And IsPlayerAlive()
		UseSkillEx($DM_DEATHS_CHARGE, $target)
		RandomSleep(200)
	WEnd
	While IsRecharged($DM_WHIRLING_DEFENSE) And IsPlayerAlive()
		UseSkillEx($DM_WHIRLING_DEFENSE)
		RandomSleep(200)
	WEnd

	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $counter = 0
	While $foesCount > 0 And $counter < 16
		If IsRecharged($DM_SHADOWFORM) Then UseSkillEx($DM_SHADOWFORM)
		RandomSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_NEARBY)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	RandomSleep(1000)
	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ If storm chaser is available, use it
Func UseIMSWhenAvailable()
	If IsRecharged($DM_STORM_CHASER) Then UseSkillEx($DM_STORM_CHASER)
EndFunc