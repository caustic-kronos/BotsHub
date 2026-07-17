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
Global Const $RA_KAPPA_FARMER_SKILLBAR = 'OgcUY3rhlPT3l8I6MEQHHHQCHQHA'
Global Const $KAPPA_P1_HERO_SKILLBAR = 'OQqjYyojKP3Xa8O2EfjBAAgyLA'
Global Const $KAPPA_P2_HERO_SKILLBAR = 'OQqjYyojKP3Xa8OmFTirxAgyLA'
Global Const $KAPPA_BIP_HERO_SKILLBAR = 'OApjQoGoKP3XAAAAAAAAA3hyLA'
Global Const $KAPPA_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- the quest The Challenge' & @CRLF _
	& '- 10 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 13 in Beast Mastery' & @CRLF _
	& '- A shield with the inscription +10 armor against Cold damage' & @CRLF _
	& '- A one hand weapon with +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
Global Const $KAPPA_FARM_DURATION = 2 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($KAPPA_DWARVEN_STABILITY) is better than UseSkillEx(1))
Global Const $KAPPA_DWARVEN_STABILITY		= 1
Global Const $KAPPA_DEADLY_PARADOX			= 2
Global Const $KAPPA_SHADOWFORM				= 3
;~ Global Const $KAPPA_WAY_OF_PERFECTION		= 4
Global Const $KAPPA_STORM_CHASER			= 4
Global Const $KAPPA_SHROUD_OF_DISTRESS		= 5
;~ Global Const $KAPPA_SHADOW_SANCTUARY		= 6
Global Const $KAPPA_DRYDERS_DEFENSE			= 6
Global Const $KAPPA_WHIRLING_DEFENSE		= 7
Global Const $KAPPA_EDGE_OF_EXTINCTION		= 8

; Common to all 3 Hero builds
Global Const $KAPPA_MYSTIC_HEALING			= 1
Global Const $KAPPA_FAITHFUL_INTERVENTION	= 8

; Common to paragon paragon hero builds
Global Const $KAPPA_CAUTERY_SIGNET			= 2
Global Const $KAPPA_FALLBACK				= 3

; P1
Global Const $KAPPA_ENDURING_HARMONY		= 4
Global Const $KAPPA_MAKE_HASTE				= 5

; P2
Global Const $KAPPA_BLADETURN_REFRAIN		= 4
Global Const $KAPPA_BRACE_YOURSELVES		= 5
Global Const $KAPPA_STAND_YOUR_GROUND		= 6

; Necro only
Global Const $KAPPA_BLOOD_IS_POWER			= 7


Global $kappa_farm_setup = False


;~ Main method to farm Kappas
Func KappaFarm()
	If Not $kappa_farm_setup And SetupKappaFarm() == $FAIL Then Return $PAUSE

	GoToTheUndercity()
	Local $result = KappaFarmLoop()
	ResignAndReturnToOutpost($ID_VIZUNAH_SQUARE_LOCAL_QUARTER)
	Return $result
EndFunc


;~ Kappa farm setup
Func SetupKappaFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_VIZUNAH_SQUARE_LOCAL_QUARTER, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	;If SetupPlayerKappaFarm() == $FAIL Then Return $FAIL
	;If SetupTeamKappaFarm() == $FAIL Then Return $FAIL

	GoToTheUndercity()
	MoveTo(19750, 17050)
	Move(19900, 17200)
	RandomSleep(1000)
	WaitMapLoading($ID_VIZUNAH_SQUARE_LOCAL_QUARTER, 10000, 2000)
	$kappa_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerKappaFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($RA_KAPPA_FARMER_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as ranger')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


Func SetupTeamKappaFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	If AddHeroByProfession($ID_PARAGON, $ID_GENERAL_MORGAHN) == $FAIL Then Return $FAIL
	If AddHeroByProfession($ID_PARAGON, $ID_HAYDA) == $FAIL Then Return $FAIL
	If AddHeroByProfession($ID_NECROMANCER, $ID_OLIAS) == $FAIL Then Return $FAIL
	LoadSkillTemplate($KAPPA_P1_HERO_SKILLBAR, 1)
	LoadSkillTemplate($KAPPA_P2_HERO_SKILLBAR, 2)
	LoadSkillTemplate($KAPPA_BIP_HERO_SKILLBAR, 3)
	RandomSleep(250)
	DisableAllHeroSkills(1)
	DisableAllHeroSkills(2)
	DisableAllHeroSkills(3)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into the Undercity
Func GoToTheUndercity()
	TravelToOutpost($ID_VIZUNAH_SQUARE_LOCAL_QUARTER, $district_name)
	While GetMapID() <> $ID_THE_UNDERCITY
		Info('Moving to The Undercity')
		MoveTo(-4700, -19700)
		Move(-4800, -19900)
		RandomSleep(1000)
		WaitMapLoading($ID_THE_UNDERCITY, 10000, 2000)
	WEnd
EndFunc


;~ Kappa farm loop
Func KappaFarmLoop()
	If GetMapID() <> $ID_THE_UNDERCITY Then Return $FAIL

	; Move to spot before aggro
	UseHeroSkill(1, $KAPPA_FALLBACK)
	MoveTo(18000, 15500)
	MoveTo(18000, 14000)
	UseHeroSkill(2, $KAPPA_FALLBACK)
	MoveTo(18000, 12000)
	MoveTo(17750, 10200)
	UseHeroSkill(1, $KAPPA_FALLBACK)
	MoveTo(15500, 10200)
	MoveTo(14500, 8500)
	UseHeroSkill(2, $KAPPA_FALLBACK)
	MoveTo(12000, 6800)

	; Cast defensive and speed skills
	Local $me = GetMyAgent()
	; Done early so it refreshes BladeTurn Refrain later on
	UseHeroSkillEx(2, $KAPPA_STAND_YOUR_GROUND)
	UseHeroSkill(3, $KAPPA_BLOOD_IS_POWER, $me)
	UseHeroSkill(1, $KAPPA_ENDURING_HARMONY, $me)
	UseHeroSkill(2, $KAPPA_BLADETURN_REFRAIN, $me)
	KappaCastDefensiveSkills()
	UseHeroSkill(2, $KAPPA_BRACE_YOURSELVES, $me)
	UseHeroSkill(1, $KAPPA_MAKE_HASTE, $me)
	UseHeroSkillEx(3, $KAPPA_BLOOD_IS_POWER, $me)

	CommandAll(13000, 6800)

	Info('Avoiding afflicted and Am Fah')
	MoveTo(10750,	6000, $RANGE_NEARBY, KappaCastDefensiveSkills)
	MoveTo(10750,	1500, $RANGE_NEARBY, KappaCastDefensiveSkills)
	MoveTo(10000,	1000, $RANGE_NEARBY, KappaCastDefensiveSkills)
	If IsPlayerDead() Then Return $FAIL

	; Aggro and kill, North Side way
	Info('Reached Kappas - killing, North-side way')
	MoveTo(9000,	600, $RANGE_NEARBY, KappaCastDefensiveSkills)
	RandomSleep(500)
	MoveTo(7500,	1050, $RANGE_NEARBY, KappaCastDefensiveSkills)
	RandomSleep(500)
	MoveTo(7600,	-750, $RANGE_NEARBY, KappaCastDefensiveSkills)
	RandomSleep(2000)
	MoveTo(6550,	1050, $RANGE_NEARBY, KappaCastDefensiveSkills)
	RandomSleep(500)
	If IsPlayerDead() Then Return $FAIL

	; Balling spot
	MoveTo(5775, 850, 100, KappaCastDefensiveSkills)
	KappaWaitForFoesBall(6350, 850)
	If IsPlayerDead() Then Return $FAIL
	MoveTo(6400, 1200, 100, KappaCastDefensiveSkills)
	KillKappas(6350, 850)

	; Aggro and kill, South Side way - TODO
	Info('Picking up loot')
	PickUpItems(KappaCastDefensiveSkills)
	FindAndOpenChests($RANGE_SPIRIT, KappaCastDefensiveSkills)
	Return $SUCCESS
EndFunc


;~ Cast defensive skills if needed
Func KappaCastDefensiveSkills($useStormChaser = True)
	Local Static $shadow_form_timer = Null
	Local Static $dwarven_stability_timer = Null
	Local Static $shroud_of_distress_timer = Null
	KappaHealPlayer()
	If $shadow_form_timer == Null Or TimerDiff($shadow_form_timer) > 20000 Then
		If GetEnergy() >= 20 Then AdlibRegister('UseKappaDeadlyParadox', 750)
		UseSkillEx($KAPPA_SHADOWFORM)
		$shadow_form_timer = TimerInit()
		;~ If GetEnergy() >= 5 Then
		;~ 	PingSleep(50)
		;~ 	UseSkillEx($KAPPA_WAY_OF_PERFECTION)
		;~ EndIf
		If $useStormChaser Then
			If IsRecharged($KAPPA_DWARVEN_STABILITY) Then UseSkillEx($KAPPA_DWARVEN_STABILITY)
			PingSleep(50)
			UseSkillEx($KAPPA_STORM_CHASER)
		Else
			If IsRecharged($KAPPA_DWARVEN_STABILITY) Then UseSkillEx($KAPPA_DWARVEN_STABILITY)
			PingSleep(50)
			UseSkillEx($KAPPA_DRYDERS_DEFENSE)
		EndIf
		PingSleep(50)
	EndIf
	If $shroud_of_distress_timer == Null Or TimerDiff($shroud_of_distress_timer) > 62000 And GetEnergy() >= 10 Then
		UseSkillEx($KAPPA_SHROUD_OF_DISTRESS)
		PingSleep(50)
		$shroud_of_distress_timer = TimerInit()
	EndIf
EndFunc


;~ Use Deadly Paradox while using ShadowForm
Func UseKappaDeadlyParadox()
	UseSkillEx($KAPPA_DEADLY_PARADOX)
	AdlibUnRegister(UseKappaDeadlyParadox)
EndFunc


;~ Wait for all ennemies to be balled
Func KappaWaitForFoesBall($x, $y)
	Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, $x, $y, $RANGE_SPELLCAST)
	While GetDistanceToPoint($target, $x, $y) > $RANGE_AREA
		KappaCastDefensiveSkills(False)
		; We casted SF not long ago (Deadly paradox in CD) yet we did not cast Dryder's Defense
		If Not IsRecharged($KAPPA_DEADLY_PARADOX) And IsRecharged($KAPPA_DRYDERS_DEFENSE) Then
			UseSkillEx($KAPPA_DRYDERS_DEFENSE)
		EndIf
		Sleep(500)
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, $x, $y, $RANGE_SPELLCAST)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Sleep(500)
	Return $SUCCESS
EndFunc


Func KillKappas($x, $y)
	Local $center = FindMiddleOfFoes($x, $y, $RANGE_AREA)
	MoveTo($center[0], $center[1], $RANGE_ADJACENT, KappaCastDefensiveSkills)
	While IsRecharged($KAPPA_WHIRLING_DEFENSE) And IsPlayerAlive()
		UseSkillEx($KAPPA_WHIRLING_DEFENSE)
		RandomSleep(50)
		KappaCastDefensiveSkills(False)
	WEnd
	If IsPlayerDead() Then Return $FAIL
	For $i = 0 To 5
		KappaCastDefensiveSkills(False)
		Sleep(500)
	Next
	UseSkillEx($KAPPA_EDGE_OF_EXTINCTION)
	If IsPlayerDead() Then Return $FAIL

	; Wait for all mobs to be registered dead or wait 3s
	Local $me = GetMyAgent()
	Local $foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY)
	Local $counter = 0
	While $foesCount > 0 And $counter < 6
		KappaCastDefensiveSkills(False)
		RandomSleep(500)
		$counter = $counter + 1
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Local $foe = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_NEARBY)
	Local $killTimer = TimerInit()
	While $foe <> Null And DllStructGetData($foe, 'HealthPercent') < 0.2 And TimerDiff($killTimer) < 15000
		KappaCastDefensiveSkills(False)
		Attack($foe)
		RandomSleep(500)
		$foe = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_NEARBY)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	RandomSleep(1000)
EndFunc


;~ Use Cautery Signet and Mystic Healing to heal player
Func KappaHealPlayer()
	Local Static $healerPosition = 1
	Local Static $cauteryPosition = 1
	Local Static $healTimer = Null
	Local Static $cauteryTimer = Null

	; Both skills have a 1s cast time - it makes no sense checking things again while skills are being casted
	Local $me = GetMyAgent()
	; Only removing conditions if we are past halfway of the farm (should be closing in on the Kappa at that point)
	If TimerDiff($run_timer) > 75000 And GetHasCondition($me) Then
		; This timer should roughly ensure unicity
		; 3s is long enough for any command to go through and for queue to be empty of other commands
		If $cauteryTimer <> Null And TimerDiff($cauteryTimer) < 3000 Then Return
		If IsRecharged($KAPPA_CAUTERY_SIGNET, $cauteryPosition) Then
			UseHeroSkill($cauteryPosition, $KAPPA_CAUTERY_SIGNET)
			$cauteryPosition = Mod($cauteryPosition, 2) + 1
			$cauteryTimer = TimerInit()
			Return
		EndIf
	EndIf
	If DllStructGetData($me, 'HealthPercent') < 0.5 Then
		; This timer condition doesn't ensure unicity of mystic healing usage
		; Command queue could make it several heroes cast it - but it doesn't matter
		If $healTimer <> Null And TimerDiff($healTimer) < 1000 Then Return
		If IsRecharged($KAPPA_MYSTIC_HEALING, $healerPosition) Then
			UseHeroSkill($healerPosition, $KAPPA_MYSTIC_HEALING)
			$healerPosition = Mod($healerPosition, 3) + 1
			$healTimer = TimerInit()
			Return
		EndIf
	EndIf
EndFunc