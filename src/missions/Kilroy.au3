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
	& 'Consumables: pumpkin pie, cupcakes can be used' & @CRLF _
	& 'IMPORTANT: this bot has not been proven survival safe yet'
; Average duration ~TBD
Global Const $KILROY_FARM_DURATION = (6 * 60 + 40) * 1000
Global Const $KILROY_MAX_FARM_DURATION = 8 * 60 * 1000
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
	Local $kilroy = GetNearestNPCToCoords(-16730, -13230)
	$kilroy_id = DllStructGetData($kilroy, 'ID')

	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)
	Info('Move and wait for Kilroy')
	MoveTo(-15800, -14250)
	RandomSleep(7500)
	KilroyMove(-15000, -15500, 'Group 1')
	KilroyMove(-11500, -16250, 'Group 2')
	KilroyMove(-7500, -16250, 'Group 3')
	KilroyMove(-4000, -16000, 'Group 4')
	KilroyMove(-2100, -15000, 'Group 5')
	KilroyMove(800, -14000, 'Group 6')

	; Skipping foes in the corridor - too much death, loss of time
	;KilroyMove(1050, -14250, 'Group 7')
	;KilroyMove(2850, -16200, 'Group 8')
	;KilroyMove(3650, -16600, 'Group 9')
	;KilroyMove(4670, -16170, 'Group 10')
	; Skipping foes in the arena too
	;KilroyMove(7000, -15500, 'Group 11')

	Local $kilroy_move_options = CloneMap($default_move_defend_options)
	$kilroy_move_options['defendFunction']	= KilroySpamBlockSkill
	$kilroy_move_options['moveTimeOut']		= 15 * 1000
	$kilroy_move_options['randomFactor']	= 0

	; Instead, running straight through the corridor
	MoveAvoidingBodyBlock(1050, -14250, $kilroy_move_options)
	MoveAvoidingBodyBlock(2850, -16200, $kilroy_move_options)
	MoveAvoidingBodyBlock(3650, -16600, $kilroy_move_options)
	; Between the doors
	MoveAvoidingBodyBlock(4670, -16170, $kilroy_move_options)
	; Following the right wall
	MoveAvoidingBodyBlock(6200, -15850, $kilroy_move_options)
	; Passage through the guards
	MoveTo(6998, -16020, 0, 0, KilroySpamBlockSkill)
	; This spot is the bodyblock spot: (7114, -16028)
	MoveTo(7300, -16050, 0, 0, KilroySpamBlockSkill)
	; Safe spot before boss
	MoveTo(10550, -16100, 0, 0, KilroySpamBlockSkill)
	MoveTo(11900, -16000, 0, 0, KilroySpamBlockSkill)
	; Boss and Ettin at (13000, -15700)
	Info('Boss and his pal')
	Local $me = GetMyAgent()
	Local $ettin = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsNormalFoe)
	ChangeTarget($ettin)
	If BrawlFight($ettin) == $FAIL Then Return $FAIL
	Local $boss = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_COMPASS, IsBossFoe)
	ChangeTarget($boss)
	If BrawlFight($boss) == $FAIL Then Return $FAIL
	PickUpItems()

	Info('Looting chest')
	MoveTo(13270, -15950)
	ClearTarget()
	Sleep(2000)
	; Doubled to secure bot
	For $i = 1 To 2
		MoveTo(13270, -15950)
		TargetNearestItem()
		RandomSleep(500)
		ActionInteract()
		RandomSleep(500)
		PickUpItems()
	Next
EndFunc


;~ Move to the coordinates provided, staying close to Kilroy, killing foes and opening chests
Func KilroyMove($x, $y, $log = '', $openChests = True)
	If $log <> '' Then Info($log)
	IsPlayerStuck(Default, Default, True) ; init internal state

	Move($x, $y)

	Local $target
	Local $me = GetMyAgent()
	Local $kilroy = GetAgentByID($kilroy_id)
	Local $timer = TimerInit()
	; Completion of move should be smaller than aggro range
	While GetDistanceToPoint($me, $x, $y) > (2 * $RANGE_AREA)
		$target = GetNearestEnemyToAgent($kilroy)
		; Fight should be larger than move completion
		If DllStructGetData($target, 'ID') <> 0 And GetDistance($kilroy, $target) < $RANGE_EARSHOT Then
			If KilroyFightGroup() == $FAIL Then Return $FAIL
			$me = GetMyAgent()
			$kilroy = GetAgentByID($kilroy_id)
		EndIf

		; Moving toward destination, but staying close to Kilroy - with timer to complete move
		If TimerDiff($timer) > 120000 Then
			MoveTo($x, $y, 0, 0, KilroySpamBlockSkill)
		ElseIf GetDistance($me, $kilroy) > 2 * $RANGE_AREA Then
			Move(DllStructGetData($kilroy, 'X'), DllStructGetData($kilroy, 'Y'))
		Else
			Move($x, $y)
		EndIf
		RandomSleep(250)

		If IsPlayerStuck() Then
			If TryToGetUnstuck($x, $y) == $SUCCESS Then
				IsPlayerStuck(Default, Default, True) ; reset stuck detection
			Else
				Error('Player detected as stuck and could not get unstuck')
				Return $FAIL
			EndIf
		EndIf

		If $openChests Then
			Local $chest = FindChest($RANGE_EARSHOT)
			If $chest <> Null Then
				KilroyMove(DllStructGetData($chest, 'X'), DllStructGetData($chest, 'Y'), 'Found a chest', False)
				FindAndOpenChests($RANGE_EARSHOT)
			EndIf
		EndIf
		$me = GetMyAgent()
		$kilroy = GetAgentByID($kilroy_id)
		If IsCharacterPassedOut() And Not GetBackUp() Then Return $FAIL
	WEnd
	$timer = TimerInit()
	While GetIsDead($kilroy) And TimerDiff($timer) < 20000
		Move(DllStructGetData($kilroy, 'X'), DllStructGetData($kilroy, 'Y'))
		RandomSleep(250)
		$kilroy = GetAgentByID($kilroy_id)
	WEnd
	Return $SUCCESS
EndFunc


;~ Kilroy function to fight a group of foes
Func KilroyFightGroup()
	Local $me = GetMyAgent()
	Local $kilroy = GetAgentByID($kilroy_id)
	Local $foesCount = CountFoesInRangeOfAgent($kilroy, $RANGE_EARSHOT)
	Local $target = Null

	While $foesCount > 0
		If CheckStuck('Kilroy fight', $KILROY_MAX_FARM_DURATION) == $FAIL Then Return $FAIL
		$target = GetNearestEnemyToAgent($kilroy)
		If $target <> Null And DllStructGetData($target, 'ID') <> 0 And Not GetIsDead($target) And GetDistance($kilroy, $target) < $RANGE_EARSHOT Then
			If GetDistance($me, $target) < $RANGE_NEARBY Then
				ChangeTarget($target)
				PingSleep(50)
				If BrawlFight($target) == $FAIL Then Return $FAIL
			Else
				Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
				RandomSleep(250)
			EndIf
		EndIf

		$me = GetMyAgent()
		$kilroy = GetAgentByID($kilroy_id)
		$foesCount = CountFoesInRangeOfAgent($kilroy, $RANGE_EARSHOT)
		If IsCharacterPassedOut() And Not GetBackUp() Then Return $FAIL
	WEnd
	RandomSleep(500)
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Kilroy function to kill a single mob
Func BrawlFight($target)
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0 And DllStructGetData($target, 'Allegiance') == $ID_ALLEGIANCE_FOE
		If CheckStuck('Kilroy fight', $KILROY_MAX_FARM_DURATION) == $FAIL Then Return $FAIL

		;	Position	Skill									usage							priority
		;	1			$SKILLBAR_BRAWLING_BLOCK				off cooldown					0
		;	2			$SKILLBAR_BRAWLING_JAB					if everything else is on cd		5
		;	3			$SKILLBAR_BRAWLING_STRAIGHT_RIGHT		off cooldown					3
		;	4			$SKILLBAR_BRAWLING_BRAWLING_HOOK		when enough adrenaline (4)		4
		;	5			$SKILLBAR_BRAWLING_BRAWLING_UPPERCUT	when enough adrenaline (10)		1
		;	6			$SKILLBAR_BRAWLING_HEADBUTT				when enough adrenaline (7)		0
		;	7			$SKILLBAR_BRAWLING_COMBO_PUNCH			off cooldown					2
		;	8			$SKILLBAR_STAND_UP						just used when knocked down

		; Here we are doing an intense usage of skillbar informations - it's better to avoid using IsRecharged and such
		Local $skillbar = GetSkillbar(0)
		; Skill 7 is unavailable in NM
		Local $recharge1 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_BLOCK)
		Local $recharge2 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_JAB)
		Local $recharge3 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_STRAIGHT_RIGHT)
		Local $recharge7 = DllStructGetData($skillbar, 'Recharge' & $SKILLBAR_BRAWLING_COMBO_PUNCH)
		Local $useSkill7 = DllStructGetData($skillbar, 'SkillID7') <> 0
		Local $skillTimer = GetSkillTimer()

		; Block is used as soon as available
		If $recharge1 == 0 Or ($recharge1 - $skillTimer) == 0 Then
			UseSkill($SKILLBAR_BRAWLING_BLOCK)
		EndIf
		; Other skills are used in order of priority
		If DllStructGetData($skillbar, 'AdrenalineA' & $SKILLBAR_BRAWLING_HEADBUTT) == 175 Then
			UseSkillEx($SKILLBAR_BRAWLING_HEADBUTT, $target)
		ElseIf DllStructGetData($skillbar, 'AdrenalineA' & $SKILLBAR_BRAWLING_BRAWLING_UPPERCUT) == 250 Then
			UseSkillEx($SKILLBAR_BRAWLING_BRAWLING_UPPERCUT, $target)
		ElseIf $useSkill7 And ($recharge7 == 0 Or ($recharge7 - $skillTimer) == 0) Then
			UseSkillEx($SKILLBAR_BRAWLING_COMBO_PUNCH, $target)
		ElseIf $recharge3 == 0 Or ($recharge3 - $skillTimer) == 0 Then
			UseSkillEx($SKILLBAR_BRAWLING_STRAIGHT_RIGHT, $target)
		ElseIf DllStructGetData($skillbar, 'AdrenalineA' & $SKILLBAR_BRAWLING_BRAWLING_HOOK) == 100 Then
			UseSkillEx($SKILLBAR_BRAWLING_BRAWLING_HOOK, $target)
		Else
			UseSkillEx($SKILLBAR_BRAWLING_JAB, $target)
		EndIf
		$target = GetCurrentTarget()
		If IsCharacterPassedOut() And Not GetBackUp() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


;~ Function checking if we are down in the Kilroy sense (0 energy)
Func IsCharacterPassedOut()
	Local $energyPercent = DllStructGetData(GetMyAgent(), 'EnergyPercent')
	Return IsNearlyEqual($energyPercent, 0)
EndFunc


;~ Function to spam skill 8 to get back on your feet and keep on fighting
Func GetBackUp()
	; For some reason we are not in instance anymore
	If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return False

	Local $me = GetMyAgent()
	Local $maxEnergy = DllStructGetData($me, 'MaxEnergy')
	If $maxEnergy > 120 Then
		Info('Energy too High. Run Failed')
		DistrictTravel($ID_GUNNARS_HOLD, $district_name)
		Return False
	EndIf

	Local $timer = TimerInit()
	Local $energyPercent = DllStructGetData($me, 'EnergyPercent')
	; 10 seconds maximum to get back up
	While Not IsNearlyEqual($energyPercent, 1) And TimerDiff($timer) < 10000
		; Respect skill 8 recharge
		Local $skillbar = GetSkillbar()
		If DllStructGetData($skillbar, "Recharge8") == 0 Then UseSkill($SKILLBAR_STAND_UP)
		RandomSleep(50)
		$me = GetMyAgent()
		$energyPercent = DllStructGetData($me, 'EnergyPercent')
	WEnd
	Return IsNearlyEqual($energyPercent, 1)
EndFunc


;~ While running spamm block skill to survive
Func KilroySpamBlockSkill()
	If IsRecharged($SKILLBAR_BRAWLING_BLOCK) Then UseSkill($SKILLBAR_BRAWLING_BLOCK)
EndFunc


;~ Return True if agent is a foe and a boss
Func IsBossFoe($agent)
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then Return False
	Return GetIsBoss($agent)
EndFunc


;~ Return True if agent is a foe and not a boss
Func IsNormalFoe($agent)
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If DllStructGetData($agent, 'HealthPercent') <= 0 Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then Return False
	Return Not GetIsBoss($agent)
EndFunc