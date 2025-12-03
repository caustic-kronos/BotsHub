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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements : add second hero, use winnowing - get further away from Bunkoro/Bohseda
; Using third hero for more speed is a bad idea - you'd lose aggro

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $RACorsairsFarmerSkillbar = 'OgcSc5PT3lCHIQHQj1xlpZ4O'
Global Const $MoPCorsairsHeroSkillbar = 'OwkjAlNpJP3Ya8HRmAAAAAAAA'
Global Const $DRCorsairsHeroSkillbar = 'OgKjwOqMGPPn7LAAAAAAA+mhD'
Global Const $CorsairsFarmInformations = 'For best results, have :' & @CRLF _
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

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain) is better than UseSkillEx(1))
Global Const $Corsairs_DwarvenStability		= 1
Global Const $Corsairs_WhirlingDefense		= 2
Global Const $Corsairs_HeartOfShadow		= 3
Global Const $Corsairs_ShroudOfDistress		= 4
Global Const $Corsairs_TogetherAsOne		= 5
Global Const $Corsairs_MentalBlock			= 6
Global Const $Corsairs_FeignedNeutrality	= 7
Global Const $Corsairs_DeathsCharge			= 8

; Hero Build
Global Const $Corsairs_MakeHaste		= 1
Global Const $Corsairs_CauterySignet	= 2
Global Const $Corsairs_Winnowing		= 1
Global Const $Corsairs_MysticHealing	= 2

Global $CORSAIRS_FARM_SETUP = False
Global $Bohseda_Timer

;~ Main method to farm Corsairs
Func CorsairsFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $CORSAIRS_FARM_SETUP And SetupCorsairsFarm() == $FAIL Then Return $PAUSE
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	EnterCorsairsModdokCreviceMission()
	Local $result = CorsairsFarmLoop()
	Info('Returning back to the outpost')
	Sleep(1000)
	Resign()
	Sleep(4000)
	ReturnToOutpost()
	Sleep(6000)
	Return $result
EndFunc


;~ Corsairs farm setup
Func SetupCorsairsFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Moddok_Crevice Then
		TravelToOutpost($ID_Moddok_Crevice, $DISTRICT_NAME)
	Else ; resigning to return to outpost in case when player is in Moddok Crevice mission that has the same map ID as Moddok Crevice outpost (427)
		Resign()
		Sleep(4000)
		ReturnToOutpost()
		Sleep(6000)
	EndIf
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerCorsairsFarm() == $FAIL Then Return $FAIL
	If SetupTeamCorsairsFarm() == $FAIL Then Return $FAIL
	$CORSAIRS_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


Func SetupPlayerCorsairsFarm()
	Info('Setting up player build skill bar')
	Sleep(500 + GetPing())
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Ranger Then
		LoadSkillTemplate($RACorsairsFarmerSkillbar)
    Else
    	Warn('Should run this farm as ranger')
 		Return $FAIL
   EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamCorsairsFarm()
	Info('Setting up team')
	Sleep(500 + GetPing())
	LeaveParty()
	AddHero($ID_Dunkoro)
	AddHero($ID_Melonni)
	Sleep(500 + GetPing())
	If GetPartySize() <> 3 Then
		Warn('Could not set up party correctly. Team size different than 3')
		Return $FAIL
	EndIf
	LoadSkillTemplate($MoPCorsairsHeroSkillbar, 1)
	LoadSkillTemplate($DRCorsairsHeroSkillbar, 2)
	Sleep(500 + GetPing())
	DisableHeroSkillSlot(1, $Corsairs_MakeHaste)
	DisableHeroSkillSlot(2, $Corsairs_Winnowing)
EndFunc


Func EnterCorsairsModdokCreviceMission()
	If GetMapID() <> $ID_Moddok_Crevice Then TravelToOutpost($ID_Moddok_Crevice, $DISTRICT_NAME)
	; Unfortunately Moddok Crevice mission map has the same map ID as Moddok Crevice outpost, so it is hard to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Moddok Crevice mission map
	Local Static $StartX = -11468
	Local Static $StartY = -7267
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		Info('Entering Moddok Crevice mission')
		GoToNPC(GetNearestNPCToCoords(-13875, -12800))
		RandomSleep(250)
		Dialog(0x84)
		Sleep(10000) ; wait 10 seconds to ensure that player exited outpost and entered mission
	WEnd
EndFunc


;~ Farm loop
Func CorsairsFarmLoop()
	If GetMapID() <> $ID_Moddok_Crevice Then Return $FAIL

	UseSkillEx($Corsairs_DwarvenStability)
	RandomSleep(100)
	UseSkillEx($Corsairs_WhirlingDefense)
	RandomSleep(100)
	UseHeroSkill(1, $Corsairs_MakeHaste, GetMyAgent())
	RandomSleep(100)
	$Bohseda_Timer = TimerInit()
	; Furthest point from Bohseda
	CommandHero(1, -13778, -10156)
	CommandHero(2, -10850, -7025)
	MoveTo(-9050, -7000)
	Local $Captain_Bohseda = GetNearestNPCToCoords(-9850, -7250)
	UseSkillEx($Corsairs_HeartOfShadow, $Captain_Bohseda)
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
	UseSkillEx($Corsairs_HeartOfShadow, GetNearestEnemyToAgent(GetMyAgent()))
	DefendAgainstCorsairs()

	UseHeroSkill(2, $Corsairs_Winnowing)
	MoveTo(-9783,-7073, 0)
	WaitForBohseda()
	CommandHero(2, -13778, -10156)
	UseSkillEx($Corsairs_DwarvenStability)
	RandomSleep(20)
	CastAllDefensiveSkills()
	If IsPlayerDead() Then Return $FAIL

	MoveTo(-9730,-7350, 0)
	GoNPC($Captain_Bohseda)
	RandomSleep(1000)
	Dialog(0x85)
	RandomSleep(1000)

	While IsRecharged($Corsairs_WhirlingDefense) And IsPlayerAlive()
		UseSkillEx($Corsairs_WhirlingDefense)
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
	UseSkillEx($Corsairs_DeathsCharge, $target)
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
	UseSkillEx($Corsairs_ShroudOfDistress)
	RandomSleep(20)
	UseSkillEx($Corsairs_TogetherAsOne)
	RandomSleep(20)
	UseSkillEx($Corsairs_MentalBlock)
	RandomSleep(20)
	UseSkillEx($Corsairs_FeignedNeutrality)
	RandomSleep(20)
EndFunc


;~ Function to survive once enemies are dead
Func OnlyCastTogetherAsOne()
	If IsRecharged($Corsairs_TogetherAsOne) Then
		UseSkillEx($Corsairs_TogetherAsOne)
		RandomSleep(GetPing() + 20)
	EndIf
EndFunc


;~ Function to defend against the corsairs
Func DefendAgainstCorsairs($Hidden = False)
	If IsRecharged($Corsairs_TogetherAsOne) Then
		UseSkillEx($Corsairs_TogetherAsOne)
		RandomSleep(GetPing() + 20)
	EndIf
	If Not $Hidden And IsRecharged($Corsairs_MentalBlock) And GetEffectTimeRemaining(GetEffect($ID_Mental_Block)) == 0 Then
		UseSkillEx($Corsairs_MentalBlock)
		RandomSleep(GetPing() + 20)
	EndIf
	If Not $Hidden And IsRecharged($Corsairs_ShroudOfDistress) Then
		UseSkillEx($Corsairs_ShroudOfDistress)
		RandomSleep(GetPing() + 20)
	EndIf
	If Not $Hidden And IsRecharged($Corsairs_FeignedNeutrality) Then
		UseSkillEx($Corsairs_FeignedNeutrality)
		RandomSleep(GetPing() + 20)
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
	While (IsPlayerAlive() And (TimerDiff($Bohseda_Timer) < 53000 Or Not IsRecharged($Corsairs_WhirlingDefense) Or GetEnergy() < 30))
		DefendAgainstCorsairs(True)
		RandomSleep(500)
	WEnd
EndFunc