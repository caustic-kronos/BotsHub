; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $CorsairsBotVersion = '0.4'

; ==== Constantes ====
Local Const $RACorsairsFarmerSkillbar = 'OgcSc5PT3lCHIQHQj1xlpZ4O'
Local Const $CorsairsFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- A shield with the inscription "Through Thick and Thin" (+10 armor against Piercing damage)' & @CRLF _
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


Func SetupCorsairsFarm()
	Out('Setting up farm')
	If GetMapID() <> $ID_Moddok_Crevice Then
		DistrictTravel($ID_Moddok_Crevice, $ID_EUROPE, $ID_FRENCH)
	EndIf
	SwitchMode($ID_HARD_MODE)
	LeaveGroup()
	AddHero($ID_Dunkoro)
	Out('Preparations complete')
EndFunc


;~ Farm loop
Func CorsairsFarmLoop()
	Out('Entering mission')
	GoToNPC(GetNearestNPCToCoords(-13875, -12800))
	RndSleep(250)
	Dialog(0x00000084)
	RndSleep(500)
	WaitMapLoading($ID_Moddok_Crevice)
	UseSkillEx($Corsairs_DwarvenStability)
	RndSleep(100)
	UseSkillEx($Corsairs_WhirlingDefense)
	RndSleep(100)
	UseHeroSkill(1, $Corsairs_MakeHaste, -2)
	RndSleep(100)
	$Bohseda_Timer = TimerInit()
	CommandHero(1, -13750, -10150)

	MoveTo(-9050, -7000)
	Local $Captain_Bohseda = GetNearestNPCToCoords(-9850, -7250)
	UseSkillEx($Corsairs_HeartOfShadow, $Captain_Bohseda)
	RndSleep(100)
	MoveTo(-8020, -6500)
	MoveTo(-7400, -4750)
	CastAllDefensiveSkills()
	MoveTo(-7300, -4500)

	If GetIsDead(-2) Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	MoveTo(-8100, -6550)
	DefendAgainstCorsairs()

	If GetIsDead(-2) Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	MoveTo(-8850, -6950)
	WaitForEnemyInRange()
	UseSkillEx($Corsairs_HeartOfShadow, GetNearestEnemyToAgent(-2))
	DefendAgainstCorsairs()

	MoveTo(-9783,-7073, 0)
	WaitForBohseda()
	UseSkillEx($Corsairs_DwarvenStability)
	RndSleep(20)
	CastAllDefensiveSkills()

	If GetIsDead(-2) Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	MoveTo(-9730,-7350, 0)
	GoNPC($Captain_Bohseda)
	RndSleep(1000)
	Dialog(0x00000085)
	RndSleep(1000)

	While IsRecharged($Corsairs_WhirlingDefense) And Not GetIsDead(-2)
		UseSkillEx($Corsairs_WhirlingDefense)
		RndSleep(200)
	WEnd

	If GetIsDead(-2) Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	For $i = 0 To 13
		DefendAgainstCorsairs()
		if $i < 13 Then Attack(GetNearestEnemyToAgent(-2))
		RndSleep(1000)
	Next

	If GetIsDead(-2) Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	Local $target = GetNearestEnemyToCoords(-8920, -6950)
	UseSkillEx($Corsairs_DeathsCharge, $target)
	RndSleep(100)

	Local $counter = 0
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	While Not GetIsDead(-2) And $foesCount > 0 And $counter < 22
		DefendAgainstCorsairs()
		If $counter > 3 Then Attack(GetNearestEnemyToAgent(-2))
		RndSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	WEnd

	If GetIsDead(-2) Then
		BackToModdokCreviceOutpost()
		Return 1
	EndIf

	Out('Looting')
	$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_SPIRIT)
	If $foesCount == 0 Then
		PickUpItems(OnlyCastTogetherAsOne, AlsoPickLowReqItems)
	Else
		PickUpItems(DefendAgainstCorsairs, AlsoPickLowReqItems)
	EndIf

	BackToModdokCreviceOutpost()
	Return 0
EndFunc


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


Func OnlyCastTogetherAsOne()
	If IsRecharged($Corsairs_TogetherAsOne) Then
		UseSkillEx($Corsairs_TogetherAsOne)
		RndSleep(GetPing() + 20)
	EndIf
EndFunc


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


Func BackToModdokCreviceOutpost()
	Out('Porting to Moddok Crevice (city)')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Moddok_Crevice, 10000, 2000)
EndFunc


Func WaitForEnemyInRange()
	Local $target = GetNearestEnemyToAgent(-2)
	While (Not GetIsDead(-2) And GetDistance($target, -2) > $RANGE_SPELLCAST)
		DefendAgainstCorsairs()
		RndSleep(500)
		$target = GetNearestEnemyToAgent(-2)
	WEnd
EndFunc


Func WaitForBohseda()
	While (Not GetIsDead(-2) And (TimerDiff($Bohseda_Timer) < 53000 Or Not IsRecharged($Corsairs_WhirlingDefense) Or GetEnergy(-2) < 30))
		DefendAgainstCorsairs(True)
		RndSleep(500)
	WEnd
EndFunc