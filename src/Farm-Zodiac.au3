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
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

Local Const $ZodiacBotVersion = '0.1'

; ==== Constants ====
Local Const $RAZodiacFarmerSkillbar = 'OgcTcXs9Z6ukHRn5Aim84Q445AA'
Local Const $ZodiacHeroSkillbar = 'OQijEqmMKODbe8OGAYi7x3YWMA'
Local Const $ZodiacFarmInformations = 'For best results, have :' & @CRLF _
	& '- 15 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 6 in Wilderness Survival' & @CRLF _
	& '- A shield with the inscription Sleep Now in the Fire (+10 armor against fire damage)' & @CRLF _
	& '- A one hand weapon with +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 3m ~ First run is 3m20s with setup
Global Const $ZODIAC_FARM_DURATION = (4 * 60) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Zodiac_DeadlyParadox) is better than UseSkillEx(1))
Local Const $Zodiac_DwarvenStability = 1
Local Const $Zodiac_DeadlyParadox = 2
Local Const $Zodiac_ShadowForm = 3
Local Const $Zodiac_ShroudOfDistress = 4
Local Const $Zodiac_IAmUnstoppable = 5
Local Const $Zodiac_StormChaser = 6
Local Const $Zodiac_WhirlingDefense = 7
Local Const $Zodiac_Winnowing = 8

Local $ZODIAC_FARM_SETUP = False

Local $zodiacShadowFormTimer = Null
Local $zodiacShroudOfDistressTimer = Null
Local $zodiacDwarvenStabilityTimer = Null


;~ Main method to farm Zodiac
Func ZodiacFarm($STATUS)
	If Not $ZODIAC_FARM_SETUP Then
		SetupZodiacFarm()
		$ZODIAC_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Local $result = ZodiacFarmLoop()
	BackToUrgozWarrenOutpost()
	Return $result
EndFunc


;~ Zodiac farm setup
Func SetupZodiacFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Urgoz_Warren And GetMapID() <> $ID_HouseZuHeltzer Then
		;Talk to Vash in Kaineng Center - only 1 week out of 9
		; TODO
		;Or move to House Zu Heltzer and use a scroll
		If GetMapID() <> $ID_HouseZuHeltzer Then
			Info('Travelling to House Zu Heltzer')
			DistrictTravel($ID_HouseZuHeltzer, $DISTRICT_NAME)
		EndIf
		UseConsumable($ID_Urgoz_Scroll)
	EndIf
	SwitchMode($ID_HARD_MODE)
	;~ LeaveGroup()
	;~ AddHero($ID_General_Morgahn)

	;~ LoadSkillTemplate($RAZodiacFarmerSkillbar)
	;~ LoadSkillTemplate($ZodiacHeroSkillbar, 1)
	;~ DisableAllHeroSkills(1)

	Info('Preparations complete')
EndFunc


;~ Zodiac farm loop
Func ZodiacFarmLoop()
	Info('Entering Urgoz Warren explorable')
	Sleep(1000)
	EnterChallenge()
	Sleep(3000)
	While Not WaitMapLoading()
		Sleep(50)
	WEnd

	; Move to spot before aggro
	MoveTo(12450, 8900, 0)
	UseHeroSkill(1, $Zodiac_VocalWasSogolon)
	RndSleep(1500)
	UseHeroSkill(1, $Zodiac_EnduringHarmony, GetMyAgent())
	RndSleep(1500)
	UseHeroSkill(1, $Zodiac_MakeHaste, GetMyAgent())
	UseHeroSkill(1, $Zodiac_Incoming)
	CommandAll(14000, 12000)

	; Run past the mobs
	MoveTo(11900, 7600)
	MoveTo(10000, 7000)
	MoveTo(8500, 5000)
	UseConsumable($ID_Birthday_Cupcake, True)

	; First Drinker group spawns
	MoveTo(5850, 3200)
	TryUseZodiacShadowForm(True)
	TryUseZodiacShroudOfDistress()
	If GetIsDead() Then Return 1

	Out('First group')
	ZodiacWaitForBall(6350, 3500)
	ZodiacKillGroup(6350, 3500)
	If GetIsDead() Then Return 1

	ZodiacMoveToAndStayAlive(7000, 2700)
	ZodiacMoveToAndStayAlive(8000, 1500)
	UseSkillEx($Zodiac_IAmUnstoppable)
	ZodiacMoveToAndStayAlive(10400, -900)

	Out('Second group')
	ZodiacWaitForBall(10400, -900)
	ZodiacKillGroup(10400, -900)
	If GetIsDead() Then Return 1

	ZodiacMoveToAndStayAlive(12000, -500)
	UseSkillEx($Zodiac_IAmUnstoppable)
	ZodiacMoveToAndStayAlive(14000, -700)
	ZodiacMoveToAndStayAlive(14800, -125)
	ZodiacMoveToAndStayAlive(15750, 565)

	ZodiacMoveToAndStayAlive(16800, 1350)
	ZodiacMoveToAndStayAlive(17700, 2150)

	ZodiacMoveToAndStayAlive(18300, 2950)
	ZodiacMoveToAndStayAlive(19100, 3100)
	If GetIsDead() Then Return 1

	Out('Third group')
	ZodiacWaitForBall(18300, 2950)
	ZodiacKillGroup(18300, 2950)
	If GetIsDead() Then Return 1

	ZodiacMoveToAndStayAlive(13900, -700)
	If GetIsDead() Then Return 1

	Out('Last group')
	ZodiacWaitForBall(18300, 2950)
	ZodiacKillGroup(18300, 2950)
	If GetIsDead() Then Return 1

	; Bonus : add opening of chest
	Return 0
EndFunc


;~ Move and stay alive function of the Zodiac farm
Func ZodiacMoveToAndStayAlive($X, $Y)
	Local $me = GetMyAgent()
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $X, $Y) > $RANGE_NEARBY
		TryUseZodiacShadowForm(True)
		TryUseZodiacShroudOfDistress()
		Move($X, $Y)
		RndSleep(100)
	WEnd
EndFunc


;~ Waiting for Drinkers to be a ball
Func ZodiacWaitForBall($X, $Y)
	Info('Waiting for ball')
	Local $foesBalled = 0
	Local $centerX = $X, $centerY = $Y
	Local $deadlockTimer = TimerInit()
	While Not GetIsDead() And $foesBalled < 8 And TimerDiff($deadlockTimer) < 10000
		$foesBalled = CountFoesInRangeOfCoords($centerX, $centerY, $RANGE_ADJACENT)
		Local $newCenter = FindMiddleOfFoes($centerX, $centerY, $RANGE_SPELLCAST)
		$centerX = $newCenter[0]
		$centerY = $newCenter[1]
		Debug('Foes balled : ' & $foesBalled)
		TryUseZodiacShadowForm(True)
		TryUseZodiacShroudOfDistress()
		RndSleep(200)
	WEnd
EndFunc


;~ Killing function of the Zodiac farm
Func ZodiacKillGroup($X, $Y)
	Local $center = FindMiddleOfFoes($X, $Y, $RANGE_SPELLCAST)
	MoveTo($center[0], $center[1])
	AdlibRegister('UseZodiacWhirlingDefense', 500)
	UseSkillEx($Zodiac_Winnowing)

	; Wait for all mobs to be registered dead or wait 20s ?
	Local $me = GetMyAgent()
	Local $foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY)
	Local $counter = 0
	While Not GetIsDead() And $foesCount > 0 And $counter < 20
		RndSleep(1000)
		TryUseZodiacShadowForm(False)
		TryUseZodiacShroudOfDistress()
		$counter = $counter + 1
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY)
	WEnd
	RndSleep(1000)
	PickUpItems()
EndFunc


;~ Resign and return to Urgoz Warren outpost
Func BackToUrgozWarrenOutpost()
	Info('Porting to Urgoz Warren')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	; The explorable map has the same ID as the outpost
	While Not WaitMapLoading()
		Sleep(50)
	WEnd
EndFunc


;~ Uses Shadow Form if its recharged
Func TryUseZodiacShadowForm($useStormChaser)
	If $zodiacShadowFormTimer == Null Or TimerDiff($zodiacShadowFormTimer) > 20000 Then
		UseSkillEx($Zodiac_DeadlyParadox)
		UseSkillEx($Zodiac_ShadowForm)
		$shadowFormTimer = TimerInit()

		If $useStormChaser Then
			TryUseZodiacDwarvenStability()
			UseSkillEx($Zodiac_StormChaser)
		EndIf
	EndIf
EndFunc


;~ Uses Shroud of distress if its recharged
Func TryUseZodiacShroudOfDistress()
	If $zodiacShroudOfDistressTimer == Null Or TimerDiff($zodiacShroudOfDistressTimer) > 65000 And TimerDiff($zodiacShadowFormTimer) < 18000 Then
		UseSkillEx($Zodiac_ShroudOfDistress)
		$zodiacShroudOfDistressTimer = TimerInit()
	EndIf
EndFunc


;~ Uses Dwarven Stability if its recharged
Func TryUseZodiacDwarvenStability()
	If $zodiacDwarvenStabilityTimer == Null Or TimerDiff($zodiacDwarvenStabilityTimer) > 32000 Then
		UseSkillEx($Zodiac_ShroudOfDistress)
		$zodiacDwarvenStabilityTimer = TimerInit()
	EndIf
EndFunc


;~ Use Whirling Defense skill
Func UseZodiacWhirlingDefense()
	While IsRecharged($Zodiac_WhirlingDefense) And Not GetIsDead()
		UseSkillEx($Zodiac_WhirlingDefense)
		RndSleep(50)
	WEnd
	AdlibUnRegister()
EndFunc