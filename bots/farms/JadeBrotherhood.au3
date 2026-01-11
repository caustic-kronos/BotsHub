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

Opt('MustDeclareVars', True)


; ==== Constants ====
Global Const $JB_SKILLBAR = 'OgejkirMrSqimXfXfbrXaXNX4OA'
Global Const $JB_HERO_SKILLBAR = 'OQijEqmMKODbe8O2Efjrx0bWMA'
Global Const $JB_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 in earth prayers' & @CRLF _
	& '- 11+ in mysticism' & @CRLF _
	& '- 9+ in scythe mastery (enough to use your scythe)'& @CRLF _
	& '- A scythe Guided by Fate, enchantements last 20% longer' & @CRLF _
	& '- Windwalker insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- General Morgahn with 16 in Command, 10 in restoration and the rest in Leadership' & @CRLF _
	& '- The Missing Daughter quest not completed'
; Average duration ~ 3m ~ First run is 3m20s with setup
Global Const $JADEBROTHERHOOD_FARM_DURATION = (3 * 60 + 10) * 1000

; You can select which paragon hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
Global Const $JB_HERO_PARTY_ID = $ID_GENERAL_MORGAHN
;Global Const $JB_HERO_PARTY_ID = $ID_KEIRAN_THACKERAY
;Global Const $JB_HERO_PARTY_ID = $ID_HAYDA
Global Const $JB_HERO_INDEX = 1

; Skill numbers declared to make the code WAY more readable (UseSkillEx($MarkOfPain) is better than UseSkillEx(1))
Global Const $JB_DRUNKENMASTER				= 1
Global Const $JB_SAND_SHARDS				= 2
Global Const $JB_MYSTIC_VIGOR				= 3
Global Const $JB_VOW_OF_STRENGTH			= 4
Global Const $JB_ARMOR_OF_SANCTITY			= 5
Global Const $JB_STAGGERING_FORCE			= 6
Global Const $JB_EREMITES_ATTACK			= 7
Global Const $JB_DEATHS_CHARGE				= 8

; Hero Build
Global Const $BROTHERHOOD_VOCAL_WAS_SOGOLON	= 1
Global Const $BROTHERHOOD_INCOMING			= 2
Global Const $BROTHERHOOD_FALLBACK			= 3
Global Const $BROTHERHOOD_ENDURING_HARMONY	= 4
Global Const $BROTHERHOOD_MAKE_HASTE		= 5
Global Const $BROTHERHOOD_STAND_YOUR_GROUND	= 6
Global Const $BROTHERHOOD_BLADETURN_REFRAIN	= 8

Global Const $JB_TIMEOUT = 120000

Global $jade_brotherhood_farm_setup = False
Global $deadlock_timer


;~ Main method to farm Jade Brotherhood for q8
Func JadeBrotherhoodFarm()
	If Not $jade_brotherhood_farm_setup And SetupJadeBrotherhoodFarm() == $FAIL Then Return $PAUSE

	Local $result = JadeBrotherhoodFarmLoop()
	ReturnBackToOutpost($ID_THE_MARKETPLACE)
	Return $result
EndFunc


;~ Setup for the jade brotherhood farm
Func SetupJadeBrotherhoodFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_THE_MARKETPLACE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerJadeBrotherhoodFarm() == $FAIL Then Return $FAIL
	If SetupTeamJadeBrotherhoodFarm() == $FAIL Then Return $FAIL

	GoToBukdekByway()
	RandomSleep(50)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_INCOMING)
	MoveTo(-14000, -11000)
	Move(-14000, -11700)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_MARKETPLACE)
	$jade_brotherhood_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerJadeBrotherhoodFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_DERVISH Then
		LoadSkillTemplate($JB_SKILLBAR)
	Else
		Warn('Should run this farm as dervish')
		Return $FAIL
	EndIf
	Sleep(250 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamJadeBrotherhoodFarm()
	Info('Setting up team')
	LeaveParty()
	Sleep(500 + GetPing())
	AddHero($JB_HERO_PARTY_ID)
	Sleep(250 + GetPing())
	LoadSkillTemplate($JB_HERO_SKILLBAR, $JB_HERO_INDEX)
	Sleep(250 + GetPing())
	DisableAllHeroSkills($JB_HERO_INDEX)
	Sleep(500 + GetPing())
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Jade Brotherhood farm loop
Func JadeBrotherhoodFarmLoop()
	GoToBukdekByway()
	MoveToSeparationWithHero()
	$deadlock_timer = TimerInit()
	TalkToAiko()
	If IsPlayerDead() Then Return $FAIL
	WaitForBall()
	If IsPlayerDead() Then Return $FAIL
	KillJadeBrotherhood()
	RandomSleep(1000)

	If IsPlayerAlive() Then
		Info('Looting')
		PickUpItems()
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc


;~ Move out of outpost into Bukdek Byway
Func GoToBukdekByway()
	TravelToOutpost($ID_THE_MARKETPLACE, $district_name)
	If GetQuestByID(0x1C9) <> Null Then
		Info('Abandoning quest')
		AbandonQuest(0x1C9)
	EndIf
	While GetMapID() <> $ID_BUKDEK_BYWAY
		Info('Moving to Bukdek Byway')
		MoveTo(16106, 18497)
		MoveTo(16500, 19400)
		Move(16551, 19860)
		RandomSleep(1000)
		WaitMapLoading($ID_BUKDEK_BYWAY)
	WEnd
EndFunc


;~ Separate from paragon hero - you'll be missed Morgahn
Func MoveToSeparationWithHero()
	Info('Moving to crossing')
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_VOCAL_WAS_SOGOLON)
	RandomSleep(1250)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_INCOMING)
	RandomSleep(50)
	MoveTo(-10475, -9685)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_FALLBACK)
	MoveTo(-11303, -6545)
	CommandAll(-11303, -6545)
	MoveTo(-11983, -6261)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_MAKE_HASTE, GetMyAgent())
EndFunc

#CS
	CommandAll(-10475, -9685)
	RandomSleep(7500)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_ENDURING_HARMONY, GetMyAgent())
	RandomSleep(1500)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_MAKE_HASTE, GetMyAgent())
	RandomSleep(50)
	Info('Moving Hero away')
	CommandAll(-8447, -10099)
#CE

;~ Talk to Aiko and take her quest
Func TalkToAiko()
	Info('Talking to Aiko')
	GoNearestNPCToCoords(-13923, -5098)
	RandomSleep(1000)
	Info('Taking quest')
	; QuestID 0x1C9 = 457
	AcceptQuest(0x1C9)
	Move(-11303, -6545, 40)
	RandomSleep(4500)
EndFunc


;~ Wait for mobs to be properly balled
Func WaitForBall()
	Info('Waiting for ball')
	RandomSleep(4500)
	Local $foesBalled = 0, $peasantsAlive = 100, $countsDidNotChange = 0
	Local $prevFoesBalled = 0, $prevPeasantsAlive = 100
	; Aiko counts
	While ($foesBalled <> 8 Or $peasantsAlive > 1)
		If IsPlayerDead() Or TimerDiff($deadlock_timer) > $JB_TIMEOUT Then Return
		Debug('Foes balled : ' & $foesBalled)
		Debug('Peasants alive : ' & $peasantsAlive)
		RandomSleep(4500)
		$prevFoesBalled = $foesBalled
		$prevPeasantsAlive = $peasantsAlive
		$foesBalled = CountFoesInRangeOfCoords(-13262, -5486, 500)
		$peasantsAlive = CountAlliesInRangeOfCoords(-13262, -5486, 1200)
		If ($foesBalled = $prevFoesBalled And $peasantsAlive = $prevPeasantsAlive) Then
			$countsDidNotChange += 1
			If $countsDidNotChange > 2 Then Return
		Else
			$countsDidNotChange = 0
		EndIf
	WEnd
EndFunc


;~ Kill the jade brotherhood group
Func KillJadeBrotherhood()
	Local $enchantmentsTimer
	Local $target

	Info('Clearing Jade Brotherhood')
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_INCOMING)
	UseSkillEx($JB_DRUNKENMASTER)
	RandomSleep(50)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_STAND_YOUR_GROUND)
	RandomSleep(50)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_ENDURING_HARMONY, GetMyAgent())
	UseSkillEx($JB_SAND_SHARDS)
	RandomSleep(50)
	UseHeroSkill($JB_HERO_INDEX, $BROTHERHOOD_BLADETURN_REFRAIN, GetMyAgent())

	$target = GetNearestEnemyToCoords(-13262, -5486)
	Local $center = FindMiddleOfFoes(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'), 2 * $RANGE_EARSHOT)
	$target = GetNearestEnemyToCoords($center[0], $center[1])
	GetAlmostInRangeOfAgent($target)
	Info('Moving Hero away')
	CommandAll(-8447, -10099)
	UseSkillEx($JB_MYSTIC_VIGOR)
	RandomSleep(300)
	UseSkillEx($JB_ARMOR_OF_SANCTITY)
	RandomSleep(300)
	UseSkillEx($JB_VOW_OF_STRENGTH)
	$enchantmentsTimer = TimerInit()
	; Waiting for mana to be completely back
	RandomSleep(3500)
	While IsRecharged($JB_DEATHS_CHARGE)
		If IsPlayerDead() Or TimerDiff($deadlock_timer) > $JB_TIMEOUT Then Return
		UseSkillEx($JB_DEATHS_CHARGE, $target)
		RandomSleep(50)
	WEnd
	While IsRecharged($JB_STAGGERING_FORCE)
		If IsPlayerDead() Or TimerDiff($deadlock_timer) > $JB_TIMEOUT Then Return
		UseSkillEx($JB_STAGGERING_FORCE)
		RandomSleep(50)
	WEnd
	UseSkillEx($JB_EREMITES_ATTACK, $target)
	While IsRecharged($JB_EREMITES_ATTACK)
		If IsPlayerDead() Or TimerDiff($deadlock_timer) > $JB_TIMEOUT Then Return
		UseSkillEx($JB_EREMITES_ATTACK, $target)
		RandomSleep(50)
	WEnd

	Local $foesCount = 8
	Local $energy = 0
	While $foesCount > 0
		If IsPlayerDead() Or TimerDiff($deadlock_timer) > $JB_TIMEOUT Then Return
		$energy = GetEnergy()
		If $foesCount > 1 And $energy >= 6 And IsRecharged($JB_SAND_SHARDS) Then
			UseSkillEx($JB_SAND_SHARDS)
			RandomSleep(50)
			$energy -= 5
		EndIf
		If $energy >= 6 And TimerDiff($enchantmentsTimer) > 20500 Then
			UseSkillEx($JB_VOW_OF_STRENGTH)
			RandomSleep(300)
			UseSkillEx($JB_MYSTIC_VIGOR)
			RandomSleep(300)
			$enchantmentsTimer = TimerInit()
			$energy -= 10
		EndIf
		If $energy >= 3 And IsRecharged($JB_ARMOR_OF_SANCTITY) Then
			UseSkillEx($JB_ARMOR_OF_SANCTITY)
			RandomSleep(300)
		EndIf
		$target = GetNearestEnemyToAgent(GetMyAgent())
		RandomSleep(250)
		ChangeTarget($target)
		Attack($target)
		RandomSleep(250)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 1250)
	WEnd
EndFunc