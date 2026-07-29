#CS ===========================================================================
=====================================================
|	Underworld melandru farm bot					|
|	Authors: kneemant (underworld farm structure of Akiro/The Great Gree was used|
| Rewrite Authors for BotsHub: no one yet	|
=====================================================
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
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Quests.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $UNDERWORLD_FARMPantheon_INFORMATIONS = 'Only use this during the pantheon week!' & @CRLF _
	& 'For best results run the bot in NM' & @CRLF _
	& 'HM can workout but it depends where the aatxe spawn,' & @CRLF _
	& 'it also depends on the aggro of the spirits/aatxe.' & @CRLF _
	& 'Use this template OghjwMgsITlTfTXT+gRbnNQTVTA. Any class should work.' & @CRLF _
	& 'Make sure you have a staff and minimum 35 energy' & @CRLF _

 Const $UW_FARMPantheon_DURATION = 2 * 60 * 1000 ; Runs take about 1min 20s
 Global Const $MAX_UW_FARMPantheon_DURATION = 2 * 60 * 1000 ; Runs take about 1 minute 20s 


Global Const $UW_BLOODSONG				= 1
Global Const $UW_PAIN					= 2
Global Const $UW_SIGNET_OF_SPIRITS		= 3
Global Const $UW_VAMPIRISM				= 4
Global Const $UW_ANGUISH				= 5
Global Const $UW_SHADOWSONG				= 6
Global Const $UW_ARMOR_OF_UNFEELING		= 7
Global Const $UW_PAINFUL_BOND			= 8

; Waiting time between 2 Aatxe checks
Global Const $UW_AATXE_CHECK_INTERVAL = 1000
; Interval, skill 7 and 8 cast time during fight
Global Const $UW_AATXE_SKILL_RECAST_INTERVAL = 5000

Global $uw_farm_setup = False

;~ Main loop function - startet nach jedem erfolgreichen Durchlauf komplett neu (EnterUnderworld + FarmLoop)
Func UnderworldFarmPantheon()
	If Not $uw_farm_setup Then SetupUnderworldFarmPantheon()
	While True
		Local $result = EnterUnderworld()
		If $result <> $SUCCESS Then Return $result
		$result = UnderworldFarmPantheonLoop()
		If $result == $SUCCESS Then Info('Successfully cleared Underworld')
		If $result == $FAIL Then
			Info('Could not clear Underworld')
			TravelToUWOutpost($district_name)
			Return $result
		EndIf
		; IF successfull, restart
	WEnd
EndFunc


Func SetupUnderworldFarmPantheon()
	Info('Setting up farm')
	TravelToUWOutpost($district_name)
;~	SwitchToHardModeIfEnabled()
	Info('Preparations complete')
	Return $SUCCESS
EndFunc



Func UnderworldFarmPantheonLoop()
	Info('Starting Farm')
	If ClearTheChamberUnderworldPantheon() == $FAIL Then Return $FAIL

	Return IsPlayerOrPartyAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Single-pass: Spawn spirits, wair for exactly 2 aatxe, pull, kill, loot
Func ClearTheChamberUnderworldPantheon()
	Info('Place Spirits for block')
	MoveTo(1376, 7418)
	UseSkillEx($UW_BLOODSONG)
	Sleep(1000)
	UseSkillEx($UW_PAIN)
	Sleep(1000)
	UseSkillEx($UW_SIGNET_OF_SPIRITS)
	Sleep(1000)
	UseSkillEx($UW_VAMPIRISM)
	Sleep(1000)
	UseSkillEx($UW_ANGUISH)
	Sleep(1000)
	UseSkillEx($UW_SHADOWSONG)
	MoveTo(1008, 7411)
	Sleep(1000)

	If WaitForExactlyTwoAatxe() == $FAIL Then Return $FAIL

	Info('Found exactly 2 Aatxe - Pull started')
	MoveTo(1000, 8005) ; walk nearby to pull
	Sleep(100)
	If IsPlayerDead() Then Return $FAIL
	Local $bondTargetAgent = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_LONGBOW + 250)
	UseSkillEx($UW_PAINFUL_BOND, $bondTargetAgent)
	Sleep(300)
	MoveTo(1458, 7491) ; hide behind spirits
	GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
	Local $bondTargetAgent = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
	UseSkillEx($UW_PAINFUL_BOND, $bondTargetAgent)
	UseSkillEx($UW_ARMOR_OF_UNFEELING)
	MoveAggroAndKill(1458, 7491)

	If WaitUntilAatxeDead() == $FAIL Then Return $FAIL

	Info('Aatxe killed - Item pickup')
	If IsPlayerAlive() Then PickUpItems()
	RandomSleep(500)

	Return $SUCCESS
EndFunc

;~ Wait until exactly 2 Aatxe are nearby
;~ If it is 3 Aatxe, wait until one walked away. spirits cannot handle 3
Func WaitForExactlyTwoAatxe()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 2000)
	While True
		If IsPlayerDead() Then Return $FAIL

		If $foesCount == 2 Then
			Return $SUCCESS
		ElseIf $foesCount >= 3 Then
			Info('3 Aatxe nearby - wait until 1 leaves')
		EndIf

		Sleep($UW_AATXE_CHECK_INTERVAL)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 2000)
	WEnd
EndFunc

;~ Wait until Aatxe are dead. Recasts skill 7 and 8

Func WaitUntilAatxeDead()
	Local $lastSkillCast = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	While $foesCount > 0
		If IsPlayerDead() Then Return $FAIL

		If TimerDiff($lastSkillCast) >= $UW_AATXE_SKILL_RECAST_INTERVAL Then
			UseSkillEx($UW_ARMOR_OF_UNFEELING)
			Local $bondTargetAgent = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
			UseSkillEx($UW_PAINFUL_BOND, $bondTargetAgent)
			$lastSkillCast = TimerInit()
		EndIf

		Sleep(500)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	WEnd
	Return $SUCCESS
EndFunc
