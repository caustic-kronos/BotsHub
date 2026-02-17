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

; Possible improvements : add second hero, use winnowing - get further away from Bunkoro/Bohseda
; Using third hero for more speed is a bad idea - you'd lose aggro

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $RA_CORSAIRS_FARMER_SKILLBAR = 'OgcSc5PT3lCHIQHQj1xlpZ4O'
Global Const $MOP_CORSAIRS_HERO_SKILLBAR = 'OwkjAlNpJP3Ya8HRmAAAAAAAA'
Global Const $DR_CORSAIRS_HERO_SKILLBAR = 'OgKjwOqMGPPn7LAAAAAAA+mhD'
Global Const $CORSAIRS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- A shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A spear +5 energy +5 armor or +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- Required hero for mission Dunkoro' & @CRLF _
	& '' & @CRLF _
	& 'This farm bot is based on below article:' & @CRLF _
	& 'https://gwpvx.fandom.com/wiki/Build:R/A_Moddok_Crevice_Corsair_Farmer'
Global Const $CORSAIRS_FARM_DURATION = 3 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($RAPTORS_MARK_OF_PAIN) is better than UseSkillEx(1))
Global Const $CORSAIRS_DWARVEN_STABILITY	= 1
Global Const $CORSAIRS_WHIRLING_DEFENSE		= 2
Global Const $CORSAIRS_HEART_OF_SHADOW		= 3
Global Const $CORSAIRS_SHROUD_OF_DISTRESS	= 4
Global Const $CORSAIRS_TOGETHER_AS_ONE		= 5
Global Const $CORSAIRS_MENTAL_BLOCK			= 6
Global Const $CORSAIRS_FEIGNED_NEUTRALITY	= 7
Global Const $CORSAIRS_DEATHS_CHARGE		= 8

; Hero Build
Global Const $CORSAIRS_MAKE_HASTE		= 1
Global Const $CORSAIRS_CAUTERY_SIGNET	= 2
Global Const $CORSAIRS_WINNOWING		= 1
Global Const $CORSAIRS_MYSTIC_HEALING	= 2

Global $corsairs_farm_setup = False
Global $bohseda_timer = Null

;~ Main method to farm Corsairs
Func CorsairsFarm()
	If Not $corsairs_farm_setup And SetupCorsairsFarm() == $FAIL Then Return $PAUSE

	EnterCorsairsModdokCreviceMission()
	Local $result = CorsairsFarmLoop()
	; in this case outpost has the same map ID as farm location
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost($ID_MODDOK_CREVICE, true)
	Return $result
EndFunc


;~ Corsairs farm setup
Func SetupCorsairsFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_MODDOK_CREVICE Then
		If TravelToOutpost($ID_MODDOK_CREVICE, $district_name) == $FAIL Then Return $FAIL
	Else
		ResignAndReturnToOutpost($ID_MODDOK_CREVICE, true)
	EndIf
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerCorsairsFarm() == $FAIL Then Return $FAIL
	If SetupTeamCorsairsFarm() == $FAIL Then Return $FAIL
	$corsairs_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerCorsairsFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($RA_CORSAIRS_FARMER_SKILLBAR)
	Else
		Warn('Should run this farm as ranger')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamCorsairsFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	RandomSleep(250)
	AddHero($ID_DUNKORO)
	AddHero($ID_MELONNI)
	RandomSleep(500)
	If GetPartySize() <> 3 Then
		Warn('Could not set up party correctly. Team size different than 3')
		Return $FAIL
	EndIf
	LoadSkillTemplate($MOP_CORSAIRS_HERO_SKILLBAR, 1)
	LoadSkillTemplate($DR_CORSAIRS_HERO_SKILLBAR, 2)
	RandomSleep(500)
	DisableHeroSkillSlot(1, $CORSAIRS_MAKE_HASTE)
	DisableHeroSkillSlot(2, $CORSAIRS_WINNOWING)
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func EnterCorsairsModdokCreviceMission()
	TravelToOutpost($ID_MODDOK_CREVICE, $district_name)
	; Unfortunately Moddok Crevice mission map has the same map ID as Moddok Crevice outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Moddok Crevice mission map
	Local Static $StartX = -11468
	Local Static $StartY = -7267
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		Info('Entering Moddok Crevice mission')
		GoToNPC(GetNearestNPCToCoords(-13875, -12800))
		RandomSleep(250)
		Dialog(0x84)
		; wait 8 seconds to ensure that player exited outpost and entered mission
		Sleep(8000)
	WEnd
EndFunc


;~ Farm loop
Func CorsairsFarmLoop()
	If GetMapID() <> $ID_MODDOK_CREVICE Then Return $FAIL

	UseSkillEx($CORSAIRS_DWARVEN_STABILITY)
	RandomSleep(100)
	UseSkillEx($CORSAIRS_WHIRLING_DEFENSE)
	RandomSleep(100)
	UseHeroSkill(1, $CORSAIRS_MAKE_HASTE, GetMyAgent())
	RandomSleep(100)
	$bohseda_timer = TimerInit()
	; Furthest point from Bohseda
	CommandHero(1, -13778, -10156)
	CommandHero(2, -10850, -7025)
	MoveTo(-9050, -7000)
	Local $captainBohseda = GetNearestNPCToCoords(-9850, -7250)
	UseSkillEx($CORSAIRS_HEART_OF_SHADOW, $captainBohseda)
	RandomSleep(100)
	MoveTo(-8020, -6500)
	MoveTo(-7400, -4750)
	CastAllDefensiveSkills()
	MoveTo(-7300, -4500)
	If IsPlayerDead() Then Return $FAIL

	MoveTo(-8100, -6550)
	DefendAgainstCorsairs()
	If IsPlayerDead() Then Return $FAIL

	MoveTo(-8850, -6950)
	WaitForEnemyInRange()
	UseSkillEx($CORSAIRS_HEART_OF_SHADOW, GetNearestEnemyToAgent(GetMyAgent()))
	DefendAgainstCorsairs()

	UseHeroSkill(2, $CORSAIRS_WINNOWING)
	MoveTo(-9783,-7073, 25, 0)
	WaitForBohseda()
	CommandHero(2, -13778, -10156)
	UseSkillEx($CORSAIRS_DWARVEN_STABILITY)
	RandomSleep(50)
	CastAllDefensiveSkills()
	If IsPlayerDead() Then Return $FAIL

	MoveTo(-9730,-7350, 25, 0)
	GoNPC($captainBohseda)
	RandomSleep(1000)
	Dialog(0x85)
	RandomSleep(1000)

	While IsRecharged($CORSAIRS_WHIRLING_DEFENSE) And IsPlayerAlive()
		UseSkillEx($CORSAIRS_WHIRLING_DEFENSE)
		RandomSleep(200)
	WEnd
	If IsPlayerDead() Then Return $FAIL

	For $i = 0 To 7
		DefendAgainstCorsairs()
		If $i < 6 Then Attack(GetNearestEnemyToAgent(GetMyAgent()))
		RandomSleep(1000)
	Next
	If IsPlayerDead() Then Return $FAIL

	Local $target = GetNearestEnemyToCoords(-8920, -6950)
	UseSkillEx($CORSAIRS_DEATHS_CHARGE, $target)
	CancelAction()
	RandomSleep(100)

	Local $counter = 0
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	While IsPlayerAlive() And $foesCount > 0 And $counter < 28
		DefendAgainstCorsairs()
		If $counter > 3 Then Attack(GetNearestEnemyToAgent(GetMyAgent()))
		RandomSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	WEnd
	If IsPlayerDead() Then Return $FAIL

	Info('Looting')
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPIRIT)
	If $foesCount == 0 Then
		PickUpItems(OnlyCastTogetherAsOne)
	Else
		PickUpItems(DefendAgainstCorsairs)
	EndIf

	Return $SUCCESS
EndFunc


;~ Function to use all defensive skills
Func CastAllDefensiveSkills()
	UseSkillEx($CORSAIRS_SHROUD_OF_DISTRESS)
	RandomSleep(50)
	UseSkillEx($CORSAIRS_TOGETHER_AS_ONE)
	RandomSleep(50)
	UseSkillEx($CORSAIRS_MENTAL_BLOCK)
	RandomSleep(50)
	UseSkillEx($CORSAIRS_FEIGNED_NEUTRALITY)
	RandomSleep(50)
EndFunc


;~ Function to survive once enemies are dead
Func OnlyCastTogetherAsOne()
	If IsRecharged($CORSAIRS_TOGETHER_AS_ONE) Then
		UseSkillEx($CORSAIRS_TOGETHER_AS_ONE)
		RandomSleep(50)
	EndIf
EndFunc


;~ Function to defend against the corsairs
Func DefendAgainstCorsairs($Hidden = False)
	If IsRecharged($CORSAIRS_TOGETHER_AS_ONE) Then
		UseSkillEx($CORSAIRS_TOGETHER_AS_ONE)
		RandomSleep(50)
	EndIf
	If Not $Hidden And IsRecharged($CORSAIRS_MENTAL_BLOCK) And GetEffectTimeRemaining(GetEffect($ID_MENTAL_BLOCK)) == 0 Then
		UseSkillEx($CORSAIRS_MENTAL_BLOCK)
		RandomSleep(50)
	EndIf
	If Not $Hidden And IsRecharged($CORSAIRS_SHROUD_OF_DISTRESS) Then
		UseSkillEx($CORSAIRS_SHROUD_OF_DISTRESS)
		RandomSleep(50)
	EndIf
	If Not $Hidden And IsRecharged($CORSAIRS_FEIGNED_NEUTRALITY) Then
		UseSkillEx($CORSAIRS_FEIGNED_NEUTRALITY)
		RandomSleep(50)
	EndIf
EndFunc


;~ Wait for closest enemy to come within range
Func WaitForEnemyInRange()
	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	While (IsPlayerAlive() And GetDistance($me, $target) > $RANGE_SPELLCAST)
		DefendAgainstCorsairs()
		RandomSleep(500)
		$me = GetMyAgent()
		$target = GetNearestEnemyToAgent($me)
	WEnd
EndFunc


;~ Wait for Bohseda and Dunkoro to shut up and for Bohseda to be interactible
Func WaitForBohseda()
	While (IsPlayerAlive() And (TimerDiff($bohseda_timer) < 53000 Or Not IsRecharged($CORSAIRS_WHIRLING_DEFENSE) Or GetEnergy() < 30))
		DefendAgainstCorsairs(True)
		RandomSleep(500)
	WEnd
EndFunc