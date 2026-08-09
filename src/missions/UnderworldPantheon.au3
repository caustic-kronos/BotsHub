#CS ===========================================================================
; Author: kneemant (underworld farm structure of Akiro/The Great Gree was used)
; Copyright 2026 caustic-kronos
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
Global Const $UW_PANTHEON_A_SKILLBAR					= 'OwhjAyi84QlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_E_SKILLBAR					= 'OghjwMgsITlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_D_SKILLBAR					= 'OgijAyiM7QlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_ME_SKILLBAR					= 'OQhjAyiMwQlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_MO_SKILLBAR					= 'OwgjAyiM0QlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_N_SKILLBAR					= 'OAhjAyisxQlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_P_SKILLBAR					= 'OQijAyiM6QlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_RA_SKILLBAR					= 'OggjAyi81QlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_RT_SKILLBAR					= 'OACjAyiM5QlTfT+gXTRbnNVTQT'
Global Const $UW_PANTHEON_W_SKILLBAR					= 'OQgjAyic0QlTfT+gXTRbnNVTQT'

Global Const $UNDERWORLD_FARM_PANTHEON_INFORMATIONS = 'Only use this during the pantheon week !' & @CRLF _
	& 'For best results run the bot in NM' & @CRLF _
	& 'HM can workout but it depends where the aatxe spawn,' & @CRLF _
	& 'it also depends on the aggro of the spirits/aatxe.' & @CRLF _
	& 'Any class should work. Do not use melee weapons.' & @CRLF _
	& 'Make sure you have a staff and minimum 35 energy' & @CRLF _

Global Const $UW_FARM_PANTHEON_DURATION = 2 * 60 * 1000
Global Const $MAX_UW_FARM_PANTHEON_DURATION = 2 * 60 * 1000

Global Const $UW_FARM_BLOODSONG				= 1
Global Const $UW_FARM_PAIN					= 2
Global Const $UW_FARM_VAMPIRISM				= 3
Global Const $UW_FARM_SIGNET_OF_SPIRITS		= 4
Global Const $UW_FARM_ANGUISH				= 5
Global Const $UW_FARM_SHADOWSONG			= 6
Global Const $UW_FARM_PAINFUL_BOND			= 7
Global Const $UW_FARM_ARMOR_OF_UNFEELING	= 8

; Waiting time between 2 Aatxe checks
Global Const $UW_AATXE_CHECK_INTERVAL = 1000
; Interval, skill 7 and 8 cast time during fight
Global Const $UW_AATXE_SKILL_RECAST_INTERVAL = 5000

Global $uw_pantheon_farm_setup = False

;~ Main loop function
Func UnderworldFarmPantheon()
	If Not $uw_pantheon_farm_setup Then SetupUnderworldFarmPantheon()
	Local $result = EnterUnderworld()
	If $result <> $SUCCESS Then Return $result
	$result = ClearTheChamberUnderworldPantheon()
	TravelToUWOutpost($district_name)
	Return $result
EndFunc


Func SetupUnderworldFarmPantheon()
	Info('Setting up farm')
	TravelToUWOutpost($district_name)
	LeaveParty()
	SetupPlayerUnderworldPantheonFarm()
	SwitchToHardModeIfEnabled()
	$uw_pantheon_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerUnderworldPantheonFarm()
	Info('Setting up player build skill bar')
	Switch DllStructGetData(GetMyAgent(), 'Primary')
		Case $ID_WARRIOR
			LoadSkillTemplate($UW_PANTHEON_W_SKILLBAR)
		Case $ID_RANGER
			LoadSkillTemplate($UW_PANTHEON_RA_SKILLBAR)
		Case $ID_MONK
			LoadSkillTemplate($UW_PANTHEON_MO_SKILLBAR)
		Case $ID_NECROMANCER
			LoadSkillTemplate($UW_PANTHEON_N_SKILLBAR)
		Case $ID_MESMER
			LoadSkillTemplate($UW_PANTHEON_ME_SKILLBAR)
		Case $ID_ELEMENTALIST
			LoadSkillTemplate($UW_PANTHEON_E_SKILLBAR)
		Case $ID_ASSASSIN
			LoadSkillTemplate($UW_PANTHEON_A_SKILLBAR)
		Case $ID_RITUALIST
			LoadSkillTemplate($UW_PANTHEON_RT_SKILLBAR)
		Case $ID_PARAGON
			LoadSkillTemplate($UW_PANTHEON_P_SKILLBAR)
		Case $ID_DERVISH
			LoadSkillTemplate($UW_PANTHEON_D_SKILLBAR)
	EndSwitch
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Single-pass: Spawn spirits, wair for exactly 2 aatxe, pull, kill, loot
Func ClearTheChamberUnderworldPantheon()
	Info('Place Spirits for block')
	MoveTo(1376, 7418)
	UseSkillEx($UW_FARM_BLOODSONG)
	Sleep(500)
	UseSkillEx($UW_FARM_PAIN)
	Sleep(500)
	UseSkillEx($UW_FARM_VAMPIRISM)
	Sleep(500)
	; First 3 spirits have very long duration, so we can wait for energy to be maxxed again
	While GetEnergy() < 30
		If CheckStuck('UW Pantheon - Waiting for max energy', $MAX_UW_FARM_PANTHEON_DURATION) == $FAIL Then Return $FAIL
		Sleep(1000)
	WEnd
	UseSkillEx($UW_FARM_SIGNET_OF_SPIRITS)
	Sleep(250)
	UseSkillEx($UW_FARM_ANGUISH)
	Sleep(250)
	UseSkillEx($UW_FARM_SHADOWSONG)
	Sleep(250)
	MoveTo(1000, 7500)
	Sleep(1000)
	If WaitForExactlyTwoAatxe() == $FAIL Then Return $FAIL
	; Wait for enough energy to cast painful bond
	While GetEnergy() < 15
		If CheckStuck('UW Pantheon - Waiting for energy', $MAX_UW_FARM_PANTHEON_DURATION) == $FAIL Then Return $FAIL
		Sleep(1000)
	WEnd
	Info('Pull started')
	; walk nearby to pull
	MoveTo(1000, 8000)
	Sleep(250)
	If IsPlayerDead() Then Return $FAIL
	Local $bondTargetAgent = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_LONGBOW + 250)
	UseSkillEx($UW_FARM_PAINFUL_BOND, $bondTargetAgent)
	Sleep(250)
	; hide behind spirits
	MoveTo(1487, 7632)
	GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
	Local $bondTargetAgent = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
	UseSkillEx($UW_FARM_ARMOR_OF_UNFEELING)
	MoveAggroAndKill(1458, 7491)
	If WaitUntilAatxeDead() == $FAIL Then Return $FAIL

	Info('Aatxes killed - Item pickup')
	PickUpItems()
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Wait until at most 2 Aatxe are nearby.
;~ - more than 2: wait until one leaves (spirits cannot handle 3)
;~ - exactly 2: proceed normally
;~ - 0 or 1: Aatxe are too far away to be counted in range - target the nearest enemy and pull anyway
Func WaitForExactlyTwoAatxe()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 2000)
	While $foesCount > 2
		Info('More than 2 Aatxes nearby - wait until 1 leaves')

		If CheckStuck('UW Pantheon - Waiting for 2 Aaxtes or less', $MAX_UW_FARM_PANTHEON_DURATION) == $FAIL Then Return $FAIL
		Sleep($UW_AATXE_CHECK_INTERVAL)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 2000)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	If $foesCount <= 1 Then Info('Only ' & $foesCount & ' Aatxe in range - targeting nearest enemy and pulling anyway')

	Return $SUCCESS
EndFunc


;~ Wait until Aatxe are dead. Recasts skill 7 and 8
Func WaitUntilAatxeDead()
	Local $lastSkillCast = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	While $foesCount > 0
		If CheckStuck('UW Pantheon - Waiting for Aaxtes to be dead', $MAX_UW_FARM_PANTHEON_DURATION) == $FAIL Then Return $FAIL

		If TimerDiff($lastSkillCast) >= $UW_AATXE_SKILL_RECAST_INTERVAL Then
			UseSkillEx($UW_FARM_ARMOR_OF_UNFEELING)
			Local $bondTargetAgent = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
			UseSkillEx($UW_FARM_PAINFUL_BOND, $bondTargetAgent)
			$lastSkillCast = TimerInit()
		EndIf

		Attack(GetNearestEnemyToAgent(GetMyAgent()))
		Sleep(500)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc
