#CS ===========================================================================
; Author: Ian
; Contributor: ----
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

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Agents.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $KILROY_FARM_INFORMATIONS = 'This bot loops the Kilroy Stonekins' & @CRLF _
	& 'Punch Out Extravanganza Quest' & @CRLF _
	& 'Check the Maintain Survivor under Options to keep Survivor going.' & @CRLF _
	& 'Ensure your Brass Knuckcles are in Weapon Slot 1 and you have 9 in Dagger Mastery' & @CRLF _
	& 'Complete all of Kilroys other quests first to get the best Daggers.'
Global Const $KILROY_FARM_DURATION = 10000 ;sample time for now
Global Const $KILROY_ACCEPT_REWARD = 0x835807
Global Const $KILROY_START_QUEST = 0x835803 
Global Const $KILRAY_ACCEPT_QUEST = 0x835801

;Skill Bar Variables
Global Const $SKILL_BRAWLING_BLOCK    = 1
Global Const $SKILL_BRAWLING_JAB      = 2
Global Const $SKILL_STRAIGHT_RIGHT    = 3
Global Const $SKILL_BRAWLING_HOOK     = 4
Global Const $SKILL_BRAWLING_UPPERCUT = 5
Global Const $SKILL_BRAWLING_HEADBUTT = 6
Global Const $SKILL_COMBO_PUNCH       = 7
Global Const $SKILL_STAND_UP          = 8

; Variables used for Survivor async checking (Low Health Monitor)
Global Const $LOW_ENERGY_THRESHOLD_KILROY = 0
Global Const $LOW_ENERGY_CHECK_INTERVAL_KILROY = 100

Global $g_StandMode = False
Global $g_StandStart = 0
Global Const $STAND_TIMEOUT_MS = 10000

Global $kilroy_farm_setup = False

Func KilroyFarm()
	If Not $kilroy_farm_setup And SetupKilroyFarm() == $FAIL Then
		Info('Kilroy farm setup failed, stopping farm.')
		Return $PAUSE
	EndIf
	MoveToPunchOut()
	AdlibRegister('LowEnergyMonitor', $LOW_ENERGY_CHECK_INTERVAL_KILROY)
	AdlibRegister("KilroyCombatRotation", 150)
	Local $result =FarmPunchOut()
	AdlibUnRegister('LowEnergyMonitor')
	AdlibUnRegister("KilroyCombatRotation")
	DistrictTravel($ID_GUNNARS_HOLD, $district_name)
	Return $result
EndFunc

Func SetupKilroyFarm()
	Info('Setting Up Farm')
	Info('Traveling to Gunnars')
	DistrictTravel($ID_GUNNARS_HOLD, $district_name)
	SwitchToHardModeIfEnabled()
	If IsQuestReward($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Quest Reward Found! Gathering Quest Reward')
		MoveTo(17281.19, -4850.08)
		Local $questNPC = GetNearestNPCToCoords(17281.19, -4850.08)
		RandomSleep(750)
		TakeQuestReward($questNPC, $ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA, $KILROY_ACCEPT_REWARD)
		RandomSleep(750)
		Info('Zoning to Olafsted to Refresh Quest')
		DistrictTravel($ID_OLAFSTEAD, $district_name)
		Sleep(750)
		Info('Zoning back to Gunnars')
		DistrictTravel($ID_GUNNARS_HOLD, $district_name)
		RandomSleep(1000)
	EndIf
	
	If IsQuestNotFound($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Setting up Kilroy Quest')
		RandomSleep(750)
		MoveTo(17281.19, -4850.08)
		Local $questNPC = GetNearestNPCToCoords(17281.19, -4850.08)
		TakeQuest($questNPC, $ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA, $KILRAY_ACCEPT_QUEST, $KILROY_START_QUEST)
	EndIf
	
	If IsQuestActive($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		$kilroy_farm_setup = True
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc

Func MoveToPunchOut()
	Info('Moving to Punchout')
	GoToNPC(GetNearestNPCToCoords(17281.19, -4850.08))
	RandomSleep(250)
	Dialog(0x85)
	WaitMapLoading($ID_FRONIS_IRONTOES_LAIR, 10000, 2000)
	If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return $FAIL
EndFunc

Func FarmPunchOut()
	Info('Move and wait for Kilroy')
	MoveTo(-16161.00, -15209.14)
	Sleep(1000)
	Info('Moving to Group 1')
	MoveAggroAndKillInRange(-15161.00, -15209.14)
	Info('Moving to Group 2')
	MoveAggroAndKillInRange(-11940.47, -16210.85)
	Info('Moving to Group 3')
	MoveAggroAndKillInRange(-7430.37, -16290.83)
	Info('Moving to Group 4')
	MoveAggroAndKillInRange(-4460.11, -16184.76)
	Info('Moving to Group 5')
	MoveAggroAndKillInRange(-2047.64, -14724.66)
	Info('Moving to Group 6')
	MoveAggroAndKillInRange(531.69, -13925.98)
	Info('Moving to Group 7')
	MoveAggroAndKillInRange(3334.65, -16213.76)
	Info('Moving to Group 8')
	MoveAggroAndKillInRange(6933.14, -15406.12)
	Info('Moving to Boss and Sleeping for Kilroy')
	MoveTo(10500.60, -16134.18)
	Sleep(10000)
	Info('Moving to Boss')
	MoveAggroAndKillInRange(12575.02,-15934.02)
	
	Info('Moving to Chest')
	MoveTo(13270.85,-15948.80)
	
	ClearTarget()
	Sleep(2000)
	; Doubled to secure bot
	For $i = 1 To 2
		MoveTo(13270.85,-15948.80)
		TargetNearestItem()
		RandomSleep(500)
		ActionInteract()
		ActionInteract()
		RandomSleep(500)
	Next
	$kilroy_farm_setup = false
	$SUCCESS
EndFunc

; Stand up when energy is 0, keep using skill 8 until energy == max energy,
Func LowEnergyMonitor()
    If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return $SUCCESS

    Local $me = GetMyAgent()
    Local $maxEnergy = DllStructGetData($me, "MaxEnergy")
    Local $energy = GetEnergy()

    ; Detect knocked down (your current rule)
    Local $low = (DllStructGetData($me, 'EnergyPercent') = 0)

    ; Enter stand mode
    If $low And Not $g_StandMode Then
        $g_StandMode = True
        $g_StandStart = TimerInit()
        Out("Energy is 0 - entering stand-up mode...")
    EndIf

    ; If not in stand mode, do nothing
    If Not $g_StandMode Then Return $SUCCESS

    ; Timeout safety
    If TimerDiff($g_StandStart) > $STAND_TIMEOUT_MS Then
        Out("Stand-up timeout: aborting stand mode.")
        $g_StandMode = False
        Return $FAIL
    EndIf

    ; Exit condition: energy restored
    If $energy = $maxEnergy Then
        Out("Standing complete: energy restored.")
        $g_StandMode = False
        Return $SUCCESS
    EndIf

    ; Try to stand up again when skill 8 is ready
    Local $skillbar = GetSkillbar()
    Local $recharge8 = DllStructGetData($skillbar, "Recharge8")

    If $recharge8 = 0 Then
        UseSkill($SKILL_STAND_UP, $me)
        ; no sleeping/looping here—just one use per tick
    EndIf

    Return $SUCCESS
EndFunc

Func isLowEnergy()
	Local $me = GetMyAgent()
	Local $energyPercent = DllStructGetData($me, 'EnergyPercent')
	If $energyPercent = 0 Then Return True
	Return False
EndFunc

Func KilroyCombatRotation()
    ; Never run outside the instance
    If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return

    ; If you implemented stand-mode, don't fight while standing up
    If IsDeclared("g_StandMode") And $g_StandMode Then Return

    ; Prevent re-entrancy (Adlib can re-fire)
    Static $busy = False
    If $busy Then Return
    $busy = True

    ; Throttle (important): don't spam packets every 150ms
    Static $tLast = 0
    If TimerDiff($tLast) < 220 Then
        $busy = False
        Return
    EndIf
    $tLast = TimerInit()

    Local $me = GetMyAgent()
    Local $target = GetNearestEnemyToAgent($me)
    If $target = 0 Then
        $busy = False
        Return
    EndIf

    ; Keep auto-attack going (no sleeps!)
    Attack($target)
	
	    ; Optional: block if nothing else is up (or remove if it slows DPS)
    If IsRecharged($SKILL_BRAWLING_BLOCK) Then
        UseSkillEx($SKILL_BRAWLING_BLOCK, $target)
    EndIf

    ; Decide priority (same logic you had, but without Nulls)
    Local $hook = 0, $upper = 0, $headbutt = 0
    If GetSkillbarSkillAdrenaline($SKILL_BRAWLING_HOOK) >= 100 Then $hook = $SKILL_BRAWLING_HOOK
    If GetSkillbarSkillAdrenaline($SKILL_BRAWLING_UPPERCUT) >= 250 Then $upper = $SKILL_BRAWLING_UPPERCUT
    If GetSkillbarSkillAdrenaline($SKILL_BRAWLING_HEADBUTT) >= 175 Then $headbutt = $SKILL_BRAWLING_HEADBUTT

    ; Use ONE skill per tick, in priority order (no sleeps!)
    If $upper <> 0 And IsRecharged($upper) Then
        UseSkillEx($upper, $target)
        $busy = False
        Return
    EndIf

    If $headbutt <> 0 And IsRecharged($headbutt) Then
        UseSkillEx($headbutt, $target)
        $busy = False
        Return
    EndIf

    If $hook <> 0 And IsRecharged($hook) Then
        UseSkillEx($hook, $target)
        $busy = False
        Return
    EndIf

    ; Fallback chain (tune order how you like)
    If IsRecharged($SKILL_COMBO_PUNCH) Then
        UseSkillEx($SKILL_COMBO_PUNCH, $target)
        $busy = False
        Return
    EndIf

    If IsRecharged($SKILL_STRAIGHT_RIGHT) Then
        UseSkillEx($SKILL_STRAIGHT_RIGHT, $target)
        $busy = False
        Return
    EndIf

    If IsRecharged($SKILL_BRAWLING_JAB) Then
        UseSkillEx($SKILL_BRAWLING_JAB, $target)
        $busy = False
        Return
    EndIf

    $busy = False
EndFunc
