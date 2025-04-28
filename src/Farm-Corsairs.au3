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

; Possible improvements : add second hero, use winnowing - get further away from Bunkoro/Bohseda
; Using third hero for more speed is a bad idea - you'd lose aggro

Opt('MustDeclareVars', 1)

Local Const $CorsairsBotVersion = '0.4'

; ==== Constants ====
Local Const $RACorsairsFarmerSkillbar = 'OgcSc5PT3lCHIQHQj1xlpZ4O'
Local Const $CorsairsFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- A shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A spear +5 energy +5 armor or +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- Dunkoro'
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain) is better than UseSkillEx(1))
Local Const $Corsairs_DwarvenStability = 1
Local Const $Corsairs_WhirlingDefense = 2
Local Const $Corsairs_HeartOfShadow = 3
Local Const $Corsairs_ShroudOfDistress = 4
Local Const $Corsairs_TogetherAsOne = 5
Local Const $Corsairs_MentalBlock = 6
Local Const $Corsairs_FeignedNeutrality = 7
Local Const $Corsairs_DeathsCharge = 8

; Hero Build
Local Const $Corsairs_MakeHaste = 1
Local Const $Corsairs_CauterySignet = 2
Local Const $Corsairs_Winnowing = 1
Local Const $Corsairs_MysticHealing = 2

Local $CORSAIRS_FARM_SETUP = False
Local $Bohseda_Timer

;~ Main method to farm Corsairs
Func CorsairsFarm($STATUS)
	If Not $CORSAIRS_FARM_SETUP Then
		SetupCorsairsFarm()
		$CORSAIRS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return CorsairsFarmLoop()
EndFunc


;~ Corsairs farm setup
Func SetupCorsairsFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Moddok_Crevice Then DistrictTravel($ID_Moddok_Crevice, $DISTRICT_NAME)
	SwitchMode($ID_HARD_MODE)
	LeaveGroup()
	AddHero($ID_Dunkoro)
	AddHero($ID_Melonni)
	LoadSkillTemplate($RACorsairsFarmerSkillbar)
	;LoadSkillTemplate($RACorsairsFarmerSkillbar, 1)
	;LoadSkillTemplate($RACorsairsFarmerSkillbar, 2)
	DisableHeroSkillSlot(1, $Corsairs_MakeHaste)
	DisableHeroSkillSlot(2, $Corsairs_Winnowing)
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func CorsairsFarmLoop()
	Info('Entering mission')
	GoToNPC(GetNearestNPCToCoords(-13875, -12800))
	RndSleep(250)
	Dialog(0x00000084)
	RndSleep(500)
	WaitMapLoading($ID_Moddok_Crevice)
	UseSkillEx($Corsairs_DwarvenStability)
	RndSleep(100)
	UseSkillEx($Corsairs_WhirlingDefense)
	RndSleep(100)
	UseHeroSkill(1, $Corsairs_MakeHaste, GetMyAgent())
	RndSleep(100)
	$Bohseda_Timer = TimerInit()
	; Furthest point from Bohseda
	CommandHero(1, -13778, -10156)
	CommandHero(2, -10850, -7025)
	MoveTo(-9050, -7000)
	Local $Captain_Bohseda = GetNearestNPCToCoords(-9850, -7250)
	UseSkillEx($Corsairs_HeartOfShadow, $Captain_Bohseda)
	RndSleep(100)
	MoveTo(-8020, -6500)
	MoveTo(-7400, -4750)
	CastAllDefensiveSkills()
	MoveTo(-7300, -4500)

	If GetIsDead() Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	MoveTo(-8100, -6550)
	DefendAgainstCorsairs()

	If GetIsDead() Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	MoveTo(-8850, -6950)
	WaitForEnemyInRange()
	UseSkillEx($Corsairs_HeartOfShadow, GetNearestEnemyToAgent(GetMyAgent()))
	DefendAgainstCorsairs()

	UseHeroSkill(2, $Corsairs_Winnowing)
	MoveTo(-9783,-7073, 0)
	WaitForBohseda()
	CommandHero(2, -13778, -10156)
	UseSkillEx($Corsairs_DwarvenStability)
	RndSleep(20)
	CastAllDefensiveSkills()

	If GetIsDead() Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	MoveTo(-9730,-7350, 0)
	GoNPC($Captain_Bohseda)
	RndSleep(1000)
	Dialog(0x00000085)
	RndSleep(1000)

	While IsRecharged($Corsairs_WhirlingDefense) And Not GetIsDead()
		UseSkillEx($Corsairs_WhirlingDefense)
		RndSleep(200)
	WEnd

	If GetIsDead() Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	For $i = 0 To 7
		DefendAgainstCorsairs()
		If $i < 6 Then Attack(GetNearestEnemyToAgent(GetMyAgent()))
		RndSleep(1000)
	Next

	If GetIsDead() Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	Local $target = GetNearestEnemyToCoords(-8920, -6950)
	UseSkillEx($Corsairs_DeathsCharge, $target)
	CancelAction()
	RndSleep(100)

	Local $counter = 0
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	While Not GetIsDead() And $foesCount > 0 And $counter < 28
		DefendAgainstCorsairs()
		If $counter > 3 Then Attack(GetNearestEnemyToAgent(GetMyAgent()))
		RndSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	WEnd

	If GetIsDead() Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	Info('Looting')
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPIRIT)
	If $foesCount == 0 Then
		PickUpItems(OnlyCastTogetherAsOne)
	Else
		PickUpItems(DefendAgainstCorsairs)
	EndIf

	BackToModdokCreviceOutpost()
	Return 0
EndFunc


;~ Function to use all defensive skills
Func CastAllDefensiveSkills()
	UseSkillEx($Corsairs_ShroudOfDistress)
	RndSleep(20)
	UseSkillEx($Corsairs_TogetherAsOne)
	RndSleep(20)
	UseSkillEx($Corsairs_MentalBlock)
	RndSleep(20)
	UseSkillEx($Corsairs_FeignedNeutrality)
	RndSleep(20)
EndFunc


;~ Function to survive once enemies are dead
Func OnlyCastTogetherAsOne()
	If IsRecharged($Corsairs_TogetherAsOne) Then
		UseSkillEx($Corsairs_TogetherAsOne)
		RndSleep(GetPing() + 20)
	EndIf
EndFunc


;~ Function to defend against the corsairs
Func DefendAgainstCorsairs($Hidden = False)
	If IsRecharged($Corsairs_TogetherAsOne) Then
		UseSkillEx($Corsairs_TogetherAsOne)
		RndSleep(GetPing() + 20)
	EndIf
	If Not $Hidden And IsRecharged($Corsairs_MentalBlock) And GetEffectTimeRemaining(GetEffect($ID_Mental_Block)) == 0 Then
		UseSkillEx($Corsairs_MentalBlock)
		RndSleep(GetPing() + 20)
	EndIf
	If Not $Hidden And IsRecharged($Corsairs_ShroudOfDistress) Then
		UseSkillEx($Corsairs_ShroudOfDistress)
		RndSleep(GetPing() + 20)
	EndIf
	If Not $Hidden And IsRecharged($Corsairs_FeignedNeutrality) Then
		UseSkillEx($Corsairs_FeignedNeutrality)
		RndSleep(GetPing() + 20)
	EndIf
EndFunc


;~ Resign and returns to Modook Crevice (city)
Func BackToModdokCreviceOutpost()
	Info('Porting to Moddok Crevice (city)')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Moddok_Crevice, 10000, 2000)
EndFunc


;~ Wait for closest enemy to be in range
Func WaitForEnemyInRange()
	Local $me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	While (Not GetIsDead() And GetDistance($target, $me) > $RANGE_SPELLCAST)
		DefendAgainstCorsairs()
		RndSleep(500)
		$me = GetMyAgent()
		$target = GetNearestEnemyToAgent($me)
	WEnd
EndFunc


;~ Wait for Bohseda and Dunkoro to shut up and for Bohseda to be interactible
Func WaitForBohseda()
	While (Not GetIsDead() And (TimerDiff($Bohseda_Timer) < 53000 Or Not IsRecharged($Corsairs_WhirlingDefense) Or GetEnergy() < 30))
		DefendAgainstCorsairs(True)
		RndSleep(500)
	WEnd
EndFunc