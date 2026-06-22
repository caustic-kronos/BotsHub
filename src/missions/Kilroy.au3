#CS ===========================================================================
; Author: Ian
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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Agents.au3'

Opt('MustDeclareVars', True)


; ==== Constants ====
Global Const $KILROY_FARM_INFORMATIONS = 'This bot runs the Kilroy Stonekins Punch Out Extravaganza quest' & @CRLF _
	& 'Ideal setup: sup vigor, insignias (stalwart or better), rune of Clarity and Recovery,' & @CRLF _
	& 'Thunderfists Brass Knuckles +15^-5e, vampiric, of Shelter (customized)' & @CRLF _
	& 'As much in Dagger Mastery and your primary attribute as possible' & @CRLF _
	& 'Consumables: pumpkin pie, cupcakes can be used'
; Average duration ~TBD
Global Const $KILROY_FARM_DURATION = 10 * 60 * 1000
Global Const $KILROY_ACCEPT_REWARD = 0x835807
Global Const $KILROY_START_QUEST = 0x835803
Global Const $KILRAY_ACCEPT_QUEST = 0x835801

; Skill Bar Variables
Global Const $SKILLBAR_BRAWLING_BLOCK = 1
Global Const $SKILLBAR_BRAWLING_JAB = 2
Global Const $SKILLBAR_BRAWLING_STRAIGHT_RIGHT = 3
Global Const $SKILLBAR_BRAWLING_BRAWLING_HOOK = 4
Global Const $SKILLBAR_BRAWLING_BRAWLING_UPPERCUT = 5
Global Const $SKILLBAR_BRAWLING_HEADBUTT = 6
Global Const $SKILLBAR_BRAWLING_COMBO_PUNCH = 7
Global Const $SKILLBAR_STAND_UP = 8

Global $kilroy_id

;~ Global function called to run Kilroy dungeon farm
Func KilroyFarm()
	; No setup required
	If ManageKilroyQuest() == $FAIL Then Return $FAIL
	MoveToPunchOut()
	Return FarmPunchOut()
EndFunc


;~ Deal with the quest shenanigans: take quest, take reward ...
Func ManageKilroyQuest()
	DistrictTravel($ID_GUNNARS_HOLD, $district_name)
	SwitchToHardModeIfEnabled()
	If IsQuestReward($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Quest Reward Found! Gathering Quest Reward')
		MoveTo(17280, -4850)
		Local $questNPC = GetNearestNPCToCoords(17280, -4850)
		TakeQuestReward($questNPC, $ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA, $KILROY_ACCEPT_REWARD)
		Info('Zoning to Olafsted to Refresh Quest')
		DistrictTravel($ID_OLAFSTEAD, $district_name)
		RandomSleep(500)
		Info('Zoning back to Gunnars')
		DistrictTravel($ID_GUNNARS_HOLD, $district_name)
		RandomSleep(500)
	EndIf

	If IsQuestNotFound($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Setting up Kilroy Quest')
		MoveTo(17280, -4850)
		Local $questNPC = GetNearestNPCToCoords(17280, -4850)
		TakeQuest($questNPC, $ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA, $KILRAY_ACCEPT_QUEST, $KILROY_START_QUEST)
	EndIf

	If IsQuestActive($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Error('Could not get Kilroy quest')
		Return $FAIL
	EndIf
EndFunc


;~ Move into dungeon
Func MoveToPunchOut()
	Info('Moving to Punchout')
	GoToNPC(GetNearestNPCToCoords(17280, -4850))
	RandomSleep(250)
	Dialog(0x85)
	WaitMapLoading($ID_FRONIS_IRONTOES_LAIR, 10000, 2000)
	If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return $FAIL
EndFunc


;~ Do the dungeon
Func FarmPunchOut()
	; Done here in order to pick latest version of default_move_aggro_kill_options
	Local $kilroyOptions = CloneDictMap($default_move_aggro_kill_options)
	$kilroyOptions.Item('fightFunction') = KilroyFighting
	$kilroyOptions.Item('fightRange') = $RANGE_EARSHOT
	$kilroyOptions.Item('callTarget') = False
	$kilroyOptions.Item('lootInFights') = False
	$kilroyOptions.Item('openChests') = True
	$kilroyOptions.Item('chestOpenRange') = $RANGE_EARSHOT
	; No practical limit to fight duration other than the duration of the dungeon
	$kilroyOptions.Item('fightDuration') = $KILROY_FARM_DURATION

	Local $kilroy = GetNearestNPCToCoords(-16730, -13230)
	$kilroy_id = DllStructGetData($kilroy, 'ID')

	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)
	Info('Move and wait for Kilroy') 
	MoveTo(-15820, -14240)
	RandomSleep(8000)
	MoveAggroAndKill(-15160, -15200, 'Group 1', $kilroyOptions)
	MoveAggroAndKill(-11940, -16200, 'Group 2', $kilroyOptions)
	MoveAggroAndKill(-7425, -16290, 'Group 3', $kilroyOptions)
	MoveAggroAndKill(-4450, -16180, 'Group 4', $kilroyOptions)
	Info('Move and wait for Kilroy') 
	MoveTo(-2500, -15725) 
	Sleep(2000)
	MoveAggroAndKill(-2050, -14725, 'Group 5', $kilroyOptions)
	MoveAggroAndKill(530, -13925, 'Group 6', $kilroyOptions)
	MoveAggroAndKill(3330, -16210, 'Group 7', $kilroyOptions)
	MoveAggroAndKill(6930, -15400, 'Group 8', $kilroyOptions)
	Info('Moving to Boss and Sleeping for Kilroy')
	MoveTo(10500, -16130)
	Sleep(10000)
	MoveAggroAndKill(12575,-15934, 'Boss', $kilroyOptions)

	Info('Looting chest')
	MoveTo(13270,-15950)
	ClearTarget()
	Sleep(2000)
	; Doubled to secure bot
	For $i = 1 To 2
		MoveTo(13270,-15950)
		TargetNearestItem()
		RandomSleep(500)
		ActionInteract()
		RandomSleep(500)
	Next
EndFunc


;~ Kilroy group fight function - no need to give a default $options, it will always be the kilroyOptions of the previous function
Func KilroyFighting($options = Null)
	Local $me = GetMyAgent()
	Local $kilroy = GetAgentByID($kilroy_id)
	Local $foesCount = CountFoesInRangeOfAgent($kilroy, $RANGE_EARSHOT)
	Local $target = Null

	While $foesCount > 0
		;If $priorityMobs Then $target = GetHighestPriorityFoe($me, $RANGE_EARSHOT)
		;If Not $priorityMobs Or $target == Null Then
		$target = GetNearestEnemyToAgent($kilroy)
		If $target <> Null And DllStructGetData($target, 'ID') <> 0 And Not GetIsDead($target) And GetDistance($kilroy, $target) < $RANGE_EARSHOT Then
			ChangeTarget($target)
			PingSleep(50)
			If BrawlFight($target) == $FAIL Then Return $FAIL
		EndIf

		$me = GetMyAgent()
		$kilroy = GetAgentByID($kilroy_id)
		$foesCount = CountFoesInRangeOfAgent($kilroy, $RANGE_EARSHOT)
		If IsKilroyDown() And Not GetBackUp() Then Return $FAIL
	WEnd
	RandomSleep(500)
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Kilroy mob killing function
Func BrawlFight($target)
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		;	Skill										usage						priority
		;	$SKILLBAR_BRAWLING_BLOCK				->	off cooldown				0
		;	$SKILLBAR_BRAWLING_JAB					->	off cooldown				5	
		;	$SKILLBAR_BRAWLING_STRAIGHT_RIGHT		->	off cooldown				4
		;	$SKILLBAR_BRAWLING_BRAWLING_HOOK		->	when enough adrenaline (4)	2
		;	$SKILLBAR_BRAWLING_BRAWLING_UPPERCUT	->	when enough adrenaline (10) 0
		;	$SKILLBAR_BRAWLING_HEADBUTT				->	when enough adrenaline (7)	1
		;	$SKILLBAR_BRAWLING_COMBO_PUNCH			->	off cooldown				3
		;	$SKILLBAR_STAND_UP						->	just used when knocked down

		; Here we are doing an intense usage of skillbar informations - it's better to avoid using IsRecharged and such
		Local $skillbar = GetSkillbar(0)
		Local $recharge1 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_BLOCK)
		Local $recharge2 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_JAB)
		Local $recharge3 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_STRAIGHT_RIGHT)
		Local $recharge7 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_COMBO_PUNCH)
		Local $skillTimer = GetSkillTimer()

		; Block is used as soon as available
		If $recharge1 == 0 Or ($recharge1 - $skillTimer) == 0 Then
			UseSkillEx($SKILLBAR_BRAWLING_BLOCK)
		EndIf
		; Other skills are used in order of priority
		If DllStructGetData($skillbar, 'AdrenalineA' & $SKILLBAR_BRAWLING_BRAWLING_UPPERCUT) == 250 Then
			UseSkillEx($SKILLBAR_BRAWLING_BRAWLING_UPPERCUT, $target)
		ElseIf DllStructGetData($skillbar, 'AdrenalineA' & $SKILLBAR_BRAWLING_HEADBUTT) == 175 Then
			UseSkillEx($SKILLBAR_BRAWLING_HEADBUTT, $target)
		ElseIf DllStructGetData($skillbar, 'AdrenalineA' & $SKILLBAR_BRAWLING_BRAWLING_HOOK) == 100 Then
			UseSkillEx($SKILLBAR_BRAWLING_BRAWLING_HOOK, $target)
		ElseIf $recharge7 == 0 Or ($recharge7 - $skillTimer) == 0 Then
			UseSkillEx($SKILLBAR_BRAWLING_COMBO_PUNCH, $target)
		ElseIf $recharge3 == 0 Or ($recharge3 - $skillTimer) == 0 Then
			UseSkillEx($SKILLBAR_BRAWLING_STRAIGHT_RIGHT, $target)
		ElseIf $recharge2 == 0 Or ($recharge2 - $skillTimer) == 0 Then
			UseSkillEx($SKILLBAR_BRAWLING_JAB, $target)
		Else
			Attack($target)
		EndIf
		PingSleep(50)
		$target = GetCurrentTarget()
		If IsKilroyDown() And Not GetBackUp() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


;~ Function checking if we are down in the Kilroy sense (0 energy)
Func IsKilroyDown()
	Local $energyPercent = DllStructGetData(GetMyAgent(), 'EnergyPercent')
	Return $energyPercent == 0
EndFunc


;~ Function to spam skill 8 to get back on your feet and keep on fighting
Func GetBackUp()
	; For some reason we are not in instance anymore
	If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return $FAIL

	Local $me = GetMyAgent()
	Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
	If $maxEnergy > 120 Then
		Info('Energy too High. Run Failed')
		DistrictTravel($ID_GUNNARS_HOLD, $district_name)
		Return $FAIL
	EndIf

	Local $timer = TimerInit()
	Local $energyPercent = DllStructGetData($me, 'EnergyPercent')
	; 10 seconds maximum to get back up
    While $energyPercent <> 1 And TimerDiff($timer) < 10000
        ; Respect skill 8 recharge
        Local $skillbar = GetSkillbar()
        If DllStructGetData($skillbar, "Recharge8") == 0 Then UseSkill($SKILLBAR_STAND_UP)
        RandomSleep(50)
		$me = GetMyAgent()
		$energyPercent = DllStructGetData($me, 'EnergyPercent')
    WEnd
    Return $energyPercent == 1 ? $SUCCESS : $FAIL
EndFunc