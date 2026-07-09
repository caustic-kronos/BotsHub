#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $SKREES_FARMER_SKILLBAR = 'OgcTcZ88Z6AiV8uMuE4Q4A3BBCA'
Global Const $SKREES_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- the quest Desperate Measures that makes the skrees show up (without it you cant farm)' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- A shield +30 health with +10 armor against piercing damage' & @CRLF _
	& '- A sword +5 energy +7 armor against physical damage or +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all armor pieces' & @CRLF _
	& '- A superior vigor rune'
Global Const $SKREES_FARM_DURATION = 2 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SKREE_SHROUD_OF_DISTRESS) is better than UseSkillEx(1))
Global Const $SKREES_SHROUD_OF_DISTRESS				= 1
Global Const $SKREES_GREAT_DWARF_ARMOR				= 2
Global Const $SKREES_DWARVEN_STABILITY				= 3
Global Const $SKREES_MENTAL_BLOCK					= 4
Global Const $SKREES_ESCAPE							= 5
Global Const $SKREES_WHIRLING_DEFENSE				= 6
Global Const $SKREES_DEATHS_CHARGE					= 7
Global Const $SKREES_HEART_OF_SHADOW				= 8

; Ranger Hero Build
Global Const $SKREES_RANGER_HERO_SKILLBAR			= 'OggjYxYDIPQnnz1ReCAAAAAAAA'
Global Const $SKREES_RANGER_HERO_WINNOWING			= 1
Global Const $SKREES_RANGER_HERO_FROZEN_SOIL		= 2
Global Const $SKREES_RANGER_HERO_EDGE_OF_EXTINCTION	= 3
Global Const $SKREES_RANGER_HERO_SOOTHING			= 4

; Ritualist skills that could be used (but require additional hero)
;~ Global Const $SKREES_RITUALIST_HERO_SOOTHING		= 1
;~ Global Const $SKREES_RITUALIST_HERO_UNION		= 2
;~ Global Const $SKREES_RITUALIST_HERO_DISPLACEMENT	= 3
;~ Global Const $SKREES_RITUALIST_HERO_RECUPERATION	= 4
;~ Global Const $SKREES_RITUALIST_HERO_RECOVERY		= 5

Global Const $SKREES_PARAGON_HERO_SKILLBAR			= 'OQijEqmMKOD7dsJuHziJx1YaMA'
Global Const $SKREES_PARAGON_HERO_VOCAL_WAS_SOGOLON	= 1
Global Const $SKREES_PARAGON_HERO_FALLBACK			= 2
Global Const $SKREES_PARAGON_HERO_ENDURING_HARMONY	= 3
Global Const $SKREES_PARAGON_HERO_THEYRE_ON_FIRE	= 4
Global Const $SKREES_PARAGON_HERO_BLADETURN_REFRAIN	= 5
Global Const $SKREES_PARAGON_HERO_HELP				= 6
Global Const $SKREES_PARAGON_HERO_STAND_YOUR_GROUND	= 7
Global Const $SKREES_PARAGON_HERO_CAUTERY_SIGNET	= 8

; Necro skills that could be used (but require additional hero)
;~ Global Const $SKREES_NECRO_HERO_MASOCHISM		= 1
;~ Global Const $SKREES_NECRO_HERO_TAINTED_FLESH	= 2

Global $skrees_farm_setup = False

;~ Main method to farm Skrees
Func SkreesFarm()
	If Not $skrees_farm_setup And SetupSkreesFarm() == $FAIL Then Return $PAUSE

	LeaveToForumHighlands()
	Local $result = SkreesFarmLoop()
	ResignAndReturnToOutpost($ID_TIHARK_ORCHARD)
	Return $result
EndFunc


;~ Skrees farm setup
Func SetupSkreesFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_TIHARK_ORCHARD, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerSkreesFarm() == $FAIL Then Return $FAIL
	If SetupTeamSkreesFarm() == $FAIL Then Return $FAIL
	LeaveToForumHighlands()

	MoveTo(-2150, 14500)
	Move(-2000, 14500)
	RandomSleep(1000)
	WaitMapLoading($ID_TIHARK_ORCHARD, 10000, 1000)
	$skrees_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Setting up character with proper attributes and skills
Func SetupPlayerSkreesFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($SKREES_FARMER_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as ranger')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Setting up the team with a ranger and a paragon
Func SetupTeamSkreesFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	If AddHeroByProfession($ID_RANGER, $ID_PYRE_FIERCESHOT) <> $SUCCESS Then Return $FAIL
	If AddHeroByProfession($ID_PARAGON, $ID_GENERAL_MORGAHN) <> $SUCCESS Then Return $FAIL
	RandomSleep(150)
	LoadSkillTemplate($SKREES_RANGER_HERO_SKILLBAR, 1)
	LoadSkillTemplate($SKREES_PARAGON_HERO_SKILLBAR, 2)
	RandomSleep(150)
	DisableAllHeroSkills(1)
	DisableAllHeroSkills(2)
	SetHeroBehaviour(1, $ID_HERO_AVOIDING)
	SetHeroBehaviour(2, $ID_HERO_AVOIDING)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Forum Highlands
Func LeaveToForumHighlands()
	TravelToOutpost($ID_TIHARK_ORCHARD, $district_name)
	While GetMapID() <> $ID_FORUM_HIGHLANDS
		Info('Moving to Forum Highlands')
		MoveTo(-2000, 14450)
		Move(-2200, 14550)
		RandomSleep(1000)
		WaitMapLoading($ID_FORUM_HIGHLANDS, 10000, 1000)
	WEnd
EndFunc


;~ Farm loop
Func SkreesFarmLoop()
	If GetMapID() <> $ID_FORUM_HIGHLANDS Then Return $FAIL

	; Running to hero spot
	UseHeroSkillEx(2, $SKREES_PARAGON_HERO_VOCAL_WAS_SOGOLON)
	PingSleep(50)
	UseHeroSkillEx(2, $SKREES_PARAGON_HERO_FALLBACK)
	PingSleep(50)

	CommandHero(1, -4600, 8000)
	CommandHero(2, -4600, 8000)
	MoveTo(-4600, 8000)
	Sleep(1000)
	UseHeroSkillEx(2, $SKREES_PARAGON_HERO_FALLBACK)

	CommandHero(1, -6000, 6200)
	CommandHero(2, -6000, 6200)
	MoveTo(-6000, 6200)
	Sleep(1000)

	CommandHero(1, -7400, 5400)
	CommandHero(2, -7400, 5400)
	MoveTo(-6750, 6150)
	Sleep(1000)

	; Casting buffs
	Local $me = GetMyAgent()
	UseHeroSkill(2, $SKREES_PARAGON_HERO_ENDURING_HARMONY, $me)
	UseSkillEx($SKREES_SHROUD_OF_DISTRESS)
	PingSleep(50)

	UseHeroSkill(2, $SKREES_PARAGON_HERO_THEYRE_ON_FIRE)
	UseSkillEx($SKREES_GREAT_DWARF_ARMOR)
	PingSleep(50)

	UseSkill($SKREES_DWARVEN_STABILITY)
	UseHeroSkillEx(2, $SKREES_PARAGON_HERO_BLADETURN_REFRAIN, $me)
	PingSleep(50)

	UseHeroSkill(2, $SKREES_PARAGON_HERO_HELP, $me)
	UseSkillEx($SKREES_MENTAL_BLOCK)
	PingSleep(50)

	UseHeroSkill(1, $SKREES_RANGER_HERO_SOOTHING)
	UseHeroSkill(2, $SKREES_PARAGON_HERO_STAND_YOUR_GROUND)
	UseSkillEx($SKREES_ESCAPE)

	; Aggroing Skrees
	Local $path[][] = [ _
		[-6900,		6300], _
		[-7350,		6700], _
		[-7800,		7000], _
		[-8350,		7200], _
		[-8900,		7300], _
		[-9500,		7200], _
		[-10050,	7150], _
		[-10600,	7000], _
		[-11050,	6600], _
		[-11500,	6200], _
		[-11900,	5800], _
		[-12000,	5250], _
		[-11700,	4850], _
		[-11100,	5000], _
		[-10600,	5200], _
		[-10100,	5500], _
		[-9500,		5700], _
		[-9050,		5450] _
	]
	; There should be about 2s of walking between these spots, less with an IMS
	For $i = 0 To UBound($path) - 1
		; Casting spirits towards the end of the aggro
		If $i == UBound($path) - 10 Then UseHeroSkill(1, $SKREES_RANGER_HERO_EDGE_OF_EXTINCTION)
		If $i == UBound($path) - 8 Then UseHeroSkill(1, $SKREES_RANGER_HERO_WINNOWING)
		If $i == UBound($path) - 6 Then UseHeroSkill(1, $SKREES_RANGER_HERO_FROZEN_SOIL)
		If $i == UBound($path) - 4 Then
			CommandHero(1, -2450, -1050)
			CommandHero(2, -2450, -1050)
		EndIf
		$me = GetMyAgent()
		Local $tries = 0
		While GetDistanceToPoint($me, $path[$i][0], $path[$i][1]) > $RANGE_NEARBY And $tries < 16
			$tries += 1
			If (GetHasCondition(GetMyAgent()) And GetEffect($ID_CRIPPLED) <> Null) Then UseHeroSkill(2, $SKREES_PARAGON_HERO_CAUTERY_SIGNET)
			UpkeepSkreesBoons(True)
			Move($path[$i][0], $path[$i][1])
			Sleep(250)
			If DllStructGetData($me, 'HealthPercent') < 0.4 Then CheckAndSendStuckCommand()
			$me = GetMyAgent()
			If $tries == 12 Then UseSkillEx($SKREES_HEART_OF_SHADOW)
			If IsPlayerDead() Then Return $FAIL
		WEnd
	Next

	For $i = 0 To 8
		UpkeepSkreesBoons(True)
		Sleep(500)
	Next
	If IsPlayerDead() Then Return $FAIL

	UseSkillEx($SKREES_WHIRLING_DEFENSE)

	; Target the boss
	Local $target = GetBossFoe($RANGE_SPELLCAST)
	If $target == Null Then $target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_SPELLCAST)
	While IsRecharged($SKREES_DEATHS_CHARGE)
		UseSkillEx($SKREES_DEATHS_CHARGE, $target)
		RandomSleep(200)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	$me = GetMyAgent()
	Local $foesCount = CountFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
	Local $killTimer = TimerInit()
	While $foesCount > 0
		If TimerDiff($killTimer) > 24000 Then ExitLoop
		UpkeepSkreesBoons(False)
		PickUpItems(UpkeepSkreesBoons)
		Attack($target)
		Sleep(500)
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_SPELLCAST)
		$target = GetNearestEnemyToAgent($me)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Sleep(1000)

	; Loooooooooot
	Info('Picking up loot')
	RandomSleep(1000)
	PickUpItems(UpkeepSkreesBoons)
	FindAndOpenChests($RANGE_COMPASS, UpkeepSkreesBoons)
	Return $SUCCESS
EndFunc


Func UpkeepSkreesBoons($keepEscape = True)
	Local $shroud = False
	Local $armor = False
	Local $stability = False
	Local $block = False
	Local $escape = False
	Local $defense = False
	Local $effectsArray = GetEffect(0)
	For $effect In $effectsArray
		Local $effectID = DllStructGetData($effect, 'SkillID')
		If $effectID == $ID_SHROUD_OF_DISTRESS Then
			$shroud = True
		ElseIf $effectID == $ID_GREAT_DWARF_ARMOR Then
			$armor = True
		ElseIf $effectID == $ID_DWARVEN_STABILITY Then
			$stability = True
		ElseIf $effectID == $ID_MENTAL_BLOCK Then
			$block = True
		ElseIf $effectID == $ID_ESCAPE Then
			$escape = True
		ElseIf $effectID == $ID_WHIRLING_DEFENSE Then
			$defense = True
		EndIf
	Next
	If Not $shroud Then UseSkillEx($SKREES_SHROUD_OF_DISTRESS)
	If Not $armor Then UseSkillEx($SKREES_GREAT_DWARF_ARMOR)
	If Not $stability Then UseSkillEx($SKREES_DWARVEN_STABILITY)
	If Not $block Then UseSkillEx($SKREES_MENTAL_BLOCK)
	If Not $escape And $keepEscape Then UseSkillEx($SKREES_ESCAPE)
	If Not $defense And Not $keepEscape Then UseSkillEx($SKREES_WHIRLING_DEFENSE)
EndFunc