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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'

; ==== Constants ====
Local Const $RA_ZODIAC_FARMER_SKILLBAR	= 'OgcTcZ88Z6ukHRn5Aim84Q445AA'
Local Const $ZODIAC_HERO_SKILLBAR		= 'OQijEqmMKOD7dMAwEfjBAAAaMA'
Local Const $ZODIAC_FARM_INFORMATIONS	= 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 3 in Wilderness Survival' & @CRLF _
	& '- A shield with the inscription Sleep Now in the Fire (+10 armor against fire damage)' & @CRLF _
	& '- A one hand weapon with +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- Cupcakes' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 3m ~ First run is 3m20s with setup
Global Const $ZODIAC_FARM_DURATION = (4 * 60) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($ZODIAC_DEADLY_PARADOX) is better than UseSkillEx(1))
Local Const $ZODIAC_DWARVEN_STABILITY	= 1
Local Const $ZODIAC_DEADLY_PARADOX		= 2
Local Const $ZODIAC_SHADOWFORM			= 3
Local Const $ZODIAC_SHROUD_OF_DISTRESS	= 4
Local Const $ZODIAC_I_AM_UNSTOPPABLE	= 5
Local Const $ZODIAC_STORMCHASER			= 6
Local Const $ZODIAC_WHIRLING_DEFENSE	= 7
Local Const $ZODIAC_WINNOWING			= 8

Local Const $ZODIAC_VOCAL_WAS_SOGOLON	= 1
Local Const $ZODIAC_FALLBACK			= 2
Local Const $ZODIAC_ENDURING_HARMONY	= 4
Local Const $ZODIAC_MAKE_HASTE			= 5
Local Const $ZODIAC_CAUTERY_SIGNET		= 8

Local $zodiac_farm_setup = False

Local $zodiac_shadow_form_timer			= Null
Local $zodiac_shroud_of_distress_timer	= Null
Local $zodiac_dwarven_stability_timer	= Null


;~ Main method to farm Zodiac
Func ZodiacFarm()
	If Not $zodiac_farm_setup Then
		SetupZodiacFarm()
		$zodiac_farm_setup = True
	EndIf

	If $runtime_status <> 'RUNNING' Then Return 2

	Local $result = ZodiacFarmLoop()
	BackToUrgozWarrenOutpost()
	Return $result
EndFunc


;~ Zodiac farm setup
Func SetupZodiacFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_URGOZS_WARREN Then
		; Setup must happen before getting into Urgoz_Warren
		LeaveParty()
		AddHero($ID_GENERAL_MORGAHN)
		LoadSkillTemplate($RA_ZODIAC_FARMER_SKILLBAR)
		LoadSkillTemplate($ZODIAC_HERO_SKILLBAR, 1)
		SwitchMode($ID_HARD_MODE)
		RandomSleep(250)
		DisableAllHeroSkills(1)
		RandomSleep(250)
		If EnterUrgozsWarren(True) == $FAIL Then Return $FAIL
		Info('Preparations complete')
	Else
		Warn('Already in Urgoz Warren - Farm must be already set up')
	EndIf
EndFunc


;~ Zodiac farm loop
Func ZodiacFarmLoop()
	Info('Entering Urgoz Warren explorable')
	Sleep(1000)
	EnterChallenge()
	Sleep(3000)
	While Not WaitMapLoading()
		If CheckStuck('Loading Urgoz Warren map', $ZODIAC_FARM_DURATION * 1.5) == $FAIL Then Return $FAIL
		Sleep(50)
	WEnd

	;################ Pre aggro phase ################
	UseHeroSkill(1, $ZODIAC_FALLBACK)
	UseHeroSkill(1, $ZODIAC_VOCAL_WAS_SOGOLON)
	UseSkillEx($ZODIAC_DWARVEN_STABILITY)
	MoveTo(12450, 8900, 0)
	CommandHero(1, 12475, 9950)
	RandomSleep(500)
	Local $me = GetMyAgent()
	UseHeroSkillEx(1, $ZODIAC_ENDURING_HARMONY, $me)
	UseHeroSkill(1, $ZODIAC_MAKE_HASTE, $me)
	RandomSleep(100)
	CommandHero(1, 15400, 9300)

	;################ Running phase ################
	; Cupcake is mandatory - otherwise we do not lose aggro of dredges and we do not pack foes properly
	UseConsumable($ID_BIRTHDAY_CUPCAKE, True)
	; Run past the mobs
	; Second speed boost causes enemies to lose aggro
	UseSkillEx($ZODIAC_STORMCHASER)
	UseSkillEx($ZODIAC_I_AM_UNSTOPPABLE)
	MoveTo(11700,	7450, $RANGE_NEARBY)
	MoveTo(9500,	6500, $RANGE_NEARBY)
	MoveTo(8000,	4500, $RANGE_NEARBY)
	If IsPlayerDead() Then Return $FAIL
	If GetHasCondition(GetMyAgent()) Then UseHeroSkill(1, $ZODIAC_CAUTERY_SIGNET)

	;################ First Drinker group ################
	Info('First group')
	MoveTo(5760, 3168)
	ZodiacWaitForBall(6500, 3250)
	ZodiacKillGroup(6500, 3250)
	If IsPlayerDead() Then Return $FAIL
	
	;################ Running to second group ################
	ZodiacWaitForShadowForm()
	ZodiacMoveToAndStayAlive(7000, 2700)
	UseSkillEx($ZODIAC_I_AM_UNSTOPPABLE)
	ZodiacMoveToAndStayAlive(8000, 1500)
	ZodiacMoveToAndStayAlive(9000, 250)
	If GetHasCondition(GetMyAgent()) Then UseHeroSkill(1, $ZODIAC_CAUTERY_SIGNET)
	ZodiacMoveToAndStayAlive(10390, -1015)

	;################ Second Drinker group ################
	Info('Second group')
	ZodiacWaitForBall(9750, -550)
	ZodiacKillGroup(9750, -550)
	If IsPlayerDead() Then Return $FAIL

	;################ Running to third group ################
	ZodiacWaitForShadowForm()
	ZodiacMoveToAndStayAlive(12000, -500)
	UseSkillEx($ZODIAC_I_AM_UNSTOPPABLE)
	ZodiacMoveToAndStayAlive(14000, -700)
	ZodiacMoveToAndStayAlive(14700, -200)
	ZodiacMoveToAndStayAlive(16200, 900)
	If GetHasCondition(GetMyAgent()) Then UseHeroSkill(1, $ZODIAC_CAUTERY_SIGNET)
	ZodiacMoveToAndStayAlive(17300, 1800)
	ZodiacMoveToAndStayAlive(19100, 3100)
	If IsPlayerDead() Then Return $FAIL

	;################ Third Drinker group ################
	Info('Third group')
	ZodiacWaitForBall(18300, 3000)
	ZodiacKillGroup(18300, 3000)
	If IsPlayerDead() Then Return $FAIL

	;################ Last Drinker group ################
	Info('Last group')
	ZodiacMoveToAndStayAlive(17300, 1800, False)
	FindAndOpenChests($RANGE_AREA)
	ZodiacMoveToAndStayAlive(16600, 1100, False)
	FindAndOpenChests($RANGE_AREA)
	ZodiacMoveToAndStayAlive(16200, 800, False)
	FindAndOpenChests($RANGE_AREA)
	ZodiacMoveToAndStayAlive(15300, 250, False)
	Local $foe = GetNearestAgentToAgent(GetMyAgent(), $ID_AGENT_TYPE_NPC, $RANGE_SPIRIT, IsGreaterBloodDrinker)
	GetAlmostInRangeOfAgent($foe, $RANGE_EARSHOT - 200)
	Sleep(2000)
	ZodiacMoveToAndStayAlive(15615, 480, False)
	ZodiacWaitForBall(14800, -100)
	ZodiacKillGroup(14800, -100)
	If IsPlayerDead() Then Return $FAIL

	Return $SUCCESS
EndFunc


;~ Move and stay alive function of the Zodiac farm
Func ZodiacMoveToAndStayAlive($X, $Y, $useStormChaser = True)
	Local $me = GetMyAgent()
	While GetDistanceToPoint($me, $X, $Y) > $RANGE_NEARBY
		If CheckStuck('Trying to move', $ZODIAC_FARM_DURATION * 1.5) == $FAIL Then Return $FAIL
		ZodiacStayAlive($useStormChaser)
		Move($X, $Y)
		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd
EndFunc


;~ Waiting for Drinkers to be a ball
Func ZodiacWaitForBall($X, $Y)
	Info('Waiting for foes to appear')
	Local $foesCount = 0
	Local $deadlockTimer = TimerInit()
	While $foesCount < 1 And TimerDiff($deadlockTimer) < 4000
		ZodiacStayAlive(True)
		RandomSleep(200)
		$foesCount = CountFoesInRangeOfCoords($X, $Y, $RANGE_SPELLCAST, IsGreaterBloodDrinker)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	Info('Waiting for foes to ball up')
	Local $centerX = $X
	Local $centerY = $Y
	$foesCount = 0
	While $foesCount < 7 And TimerDiff($deadlockTimer) < 12000
		ZodiacStayAlive(True)
		Local $newCenter = FindMiddleOfBloodDrinkers($centerX, $centerY)
		If $newCenter[0] <> 0 And $newCenter[1] <> 0 Then
			$centerX = $newCenter[0]
			$centerY = $newCenter[1]
		EndIf
		$foesCount = CountFoesInRangeOfCoords($centerX, $centerY, $RANGE_NEARBY, IsGreaterBloodDrinker)
		RandomSleep(200)
		If IsPlayerDead() Then Return $FAIL
	WEnd
EndFunc


Func ZodiacWaitForShadowForm()
	If TimerDiff($zodiac_shadow_form_timer) > 10000 Or GetEnergy() < 14 Then
		; Wait for Shadow Form to be just recasted
		While TimerDiff($zodiac_shadow_form_timer) < 20000
			TryUseZodiacShroudOfDistress()
			RandomSleep(200)
			If IsPlayerDead() Then Return $FAIL
		WEnd
		TryUseZodiacShadowForm(True)
	EndIf
EndFunc

;~ Killing function of the Zodiac farm
Func ZodiacKillGroup($X, $Y)
	Local $center = FindMiddleOfBloodDrinkers($X, $Y)
	MoveTo($center[0], $center[1], $RANGE_ADJACENT, ZodiacStayAlive)

	; Wait for Shadow Form to be just recasted
	While TimerDiff($zodiac_shadow_form_timer) < 20000
		TryUseZodiacShroudOfDistress()
		$center = FindMiddleOfBloodDrinkers($X, $Y)
		MoveTo($center[0], $center[1], $RANGE_ADJACENT, ZodiacStayAlive)
		RandomSleep(500)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	TryUseZodiacShadowForm(False)

	; Cast whirling defense
	UseWhirlingDefense()
	; Wait for most mobs to be dead
	Local $me = GetMyAgent()
	Local $foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY, IsGreaterBloodDrinker)
	Local $counter = 0
	While $foesCount > 2 And $counter < 36
		ZodiacStayAlive(True)
		RandomSleep(500)
		$counter = $counter + 1
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY, IsGreaterBloodDrinker)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	; Finish off enemies only if 1 or 2 enemies and low life
	If $foesCount < 3 Then
		Local $target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_EARSHOT)
		While $target <> Null And DllStructGetData($target, 'HealthPercent') < 0.15
			If CheckStuck('Finishings mobs off', $ZODIAC_FARM_DURATION * 1.5) == $FAIL Then Return $FAIL
			While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0
				If CheckStuck('Finishings one mob off', $ZODIAC_FARM_DURATION * 1.5) == $FAIL Then Return $FAIL
				ZodiacStayAlive(True)
				Attack($target)
				RandomSleep(500)
				$target = GetAgentByID(DllStructGetData($target, 'ID'))
				If IsPlayerDead() Then Return $FAIL
			WEnd
			$target = GetNearestEnemyToAgent(GetMyAgent(), $RANGE_EARSHOT)
		WEnd
	EndIf
	PickUpItems()
EndFunc


;~ Resign and return to Urgoz Warren outpost
Func BackToUrgozWarrenOutpost()
	Info('Porting to Urgoz Warren')
	Resign()
	RandomSleep(3500)
	ReturnToOutpost()
	; The explorable map has the same ID as the outpost
	While Not WaitMapLoading()
		If CheckStuck('Returning to the outpost', $ZODIAC_FARM_DURATION * 1.5) == $FAIL Then Return $FAIL
		Sleep(50)
	WEnd
EndFunc


Func ZodiacStayAlive($useStormChaser = False)
	TryUseZodiacShadowForm($useStormChaser)
	TryUseZodiacShroudOfDistress()
EndFunc


;~ Uses Shadow Form if its recharged
Func TryUseZodiacShadowForm($useStormChaser)
	If $zodiac_shadow_form_timer == Null Or TimerDiff($zodiac_shadow_form_timer) > 20000 And GetEnergy() >= 20 Then
		AdlibRegister('UseZodiacDeadlyParadox', 750)
		UseSkillEx($ZODIAC_SHADOWFORM)
		$zodiac_shadow_form_timer = TimerInit()
		If $useStormChaser Then
			Local $energy = GetEnergy()
			If $zodiac_dwarven_stability_timer == Null Or TimerDiff($zodiac_dwarven_stability_timer) > 32000 And $energy >= 9 Then
				PingSleep(50)
				UseSkillEx($ZODIAC_DWARVEN_STABILITY)
				$zodiac_dwarven_stability_timer = TimerInit()
				PingSleep(50)
				UseSkillEx($ZODIAC_STORMCHASER)
				PingSleep(50)
			Else
				UseSkillEx($ZODIAC_STORMCHASER)
				PingSleep(50)
			EndIf
		EndIf
	EndIf
EndFunc


;~ Uses Shroud of distress if its recharged
Func TryUseZodiacShroudOfDistress()
	If $zodiac_shroud_of_distress_timer == Null Or TimerDiff($zodiac_shroud_of_distress_timer) > 62000 And TimerDiff($zodiac_shadow_form_timer) < 18000 And GetEnergy() >= 10 Then
		UseSkillEx($ZODIAC_SHROUD_OF_DISTRESS)
		$zodiac_shroud_of_distress_timer = TimerInit()
	EndIf
EndFunc


;~ Use Deadly Paradox while using ShadowForm
Func UseZodiacDeadlyParadox()
	UseSkillEx($ZODIAC_DEADLY_PARADOX)
	AdlibUnRegister(UseZodiacDeadlyParadox)
EndFunc


;~ Use Whirling Defense
Func UseWhirlingDefense()
	; Cast whirling defense
	While IsRecharged($ZODIAC_WHIRLING_DEFENSE) And Not IsPlayerDead()
		If CheckStuck('Waiting for Whirling defense to be used', $ZODIAC_FARM_DURATION * 1.5) == $FAIL Then Return $FAIL
		UseSkillEx($ZODIAC_WHIRLING_DEFENSE)
		PingSleep(50)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	; Can't do winnowing in advance as it might get killed by foes
	UseSkillEx($ZODIAC_WINNOWING)
EndFunc


;~ Specialized version - Blood Drinkers are idle minions when they spawn, making all functions have issues with them
Func FindMiddleOfBloodDrinkers($posX, $posY)
	Local $position[] = [0, 0]
	Local $nearestFoe = GetNearestAgentToCoords($posX, $posY, $ID_AGENT_TYPE_NPC, IsGreaterBloodDrinker)
	Local $foes = GetFoesInRangeOfAgent($nearestFoe, $RANGE_AREA, IsGreaterBloodDrinker)
	Local $count = 0
	For $foe In $foes
		$position[0] += DllStructGetData($foe, 'X')
		$position[1] += DllStructGetData($foe, 'Y')
		$count += 1
	Next
	If $count == 0 Then
		Warn('No foes to find middle of.')
		Return $position
	EndIf
	$position[0] = $position[0] / $count
	$position[1] = $position[1] / $count
	Return $position
EndFunc


;~ Filter for Greater Blood Drinkers
Func IsGreaterBloodDrinker($target)
	Return DllStructGetData($target, 'ModelID') == 3794
EndFunc