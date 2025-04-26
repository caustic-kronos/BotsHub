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

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $MantidsBotVersion = '0.1'

; ==== Constantes ====
Local Const $RAMantidsFarmerSkillbar = 'OgcTYxr+5B5ozOgFHCIuT4AdAA'
Local Const $MantidsHeroSkillbar = 'OQijEqmMKODbe8OGAYi7x3YWMA'
Local Const $MantidsFarmInformations = 'For best results, have :' & @CRLF _
	& '- 14 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 8 in Beast Mastery' & @CRLF _
	& '- A shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A one hand weapon with +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Mantids_DeadlyParadox) is better than UseSkillEx(1))
Local Const $Mantids_DeadlyParadox = 1
Local Const $Mantids_ShadowForm = 2
Local Const $Mantids_ShroudOfDistress = 3
Local Const $Mantids_LightningReflexes = 4
Local Const $Mantids_WayOfPerfection = 5
Local Const $Mantids_DeathsCharge = 6
Local Const $Mantids_WhirlingDefense = 7
Local Const $Mantids_EdgeOfExtinction = 8

; Hero Build
Local Const $Mantids_VocalWasSogolon = 1
Local Const $Mantids_Incoming = 2
Local Const $Mantids_FallBack = 3
Local Const $Mantids_EnduringHarmony = 5
Local Const $Mantids_TheyreOnFire = 6
Local Const $Mantids_MakeHaste = 7
Local Const $Mantids_BladeturnRefrain = 8

Local $MANTIDS_FARM_SETUP = False

;~ Main method to farm Mantids
Func MantidsFarm($STATUS)
	If Not $MANTIDS_FARM_SETUP Then
		SetupMantidsFarm()
		$MANTIDS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return MantidsFarmLoop()
EndFunc


Func SetupMantidsFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Nahpui_Quarter Then DistrictTravel($ID_Nahpui_Quarter, $DISTRICT_NAME)

	SwitchMode($ID_HARD_MODE)
	LeaveGroup()
	AddHero($ID_General_Morgahn)
	
	LoadSkillTemplate($RAMantidsFarmerSkillbar)
	LoadSkillTemplate($MantidsHeroSkillbar, 1)
	DisableAllHeroSkills(1)

	Info('Entering Wajjun Bazaar')
	MoveTo(-22000, 12500)
	MoveTo(-21750, 14500)
	WaitMapLoading($ID_Wajjun_Bazaar, 10000, 2000)
	MoveTo(9100, -19600)
	MoveTo(9100, -20500)
	WaitMapLoading($ID_Nahpui_Quarter, 10000, 2000)
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func MantidsFarmLoop()
	Info('Entering Wajjun Bazaar')
	Local $target
	If (Not IsOverLine(0, 1, -12500, 0, DllStructGetData(GetAgentById(-2), 'Y'))) Then MoveTo(-22000, 12500)
	MoveTo(-21750, 14500)
	WaitMapLoading($ID_Wajjun_Bazaar, 10000, 2000)
	UseHeroSkill(1, $Mantids_VocalWasSogolon)
	RndSleep(1500)
	UseHeroSkill(1, $Mantids_Incoming)
	AdlibRegister('UseFallBack', 8000)

	; Move to spot before aggro
	MoveTo(3150, -16350, 0)
	RndSleep(1500)
	UseHeroSkill(1, $Mantids_EnduringHarmony, -2)
	RndSleep(1500)
	UseHeroSkill(1, $Mantids_TheyreOnFire)
	UseHeroSkill(1, $Mantids_MakeHaste, -2)
	UseSkillEx($Mantids_DeadlyParadox)
	RndSleep(20)
	UseHeroSkill(1, $Mantids_BladeturnRefrain, -2)
	UseSkillEx($Mantids_ShroudOfDistress)
	RndSleep(20)
	UseSkillEx($Mantids_ShadowForm)
	RndSleep(20)
	CommandAll(9000, -19500)

	; Aggro the three groups
	$target = GetNearestNPCInRangeOfCoords(3, 700, -16700, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(-800, -15800)

	$target = GetNearestNPCInRangeOfCoords(3, -1350, -16250, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(-700, -14800)

	$target = GetNearestNPCInRangeOfCoords(3, -1600, -14500, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(0, -14300)

	; Monk Balling spot
	MoveTo(1050, -14950, 0)
	While Not IsRecharged($Mantids_ShadowForm)
		RndSleep(500)
	WEnd
	UseSkillEx($Mantids_ShadowForm)
	RndSleep(20)
	UseSkillEx($Mantids_LightningReflexes)
	RndSleep(20)
	UseSkillEx($Mantids_WayOfPerfection)
	RndSleep(2000)
	If GetIsDead(-2) Then
		BackToNahpuiQuarterOutpost()
		Return 1
	EndIf

	; Balling the rest
	$target = GetNearestEnemyToCoords(-450, -14400)
	While IsRecharged($Mantids_DeathsCharge) And Not GetIsDead(-2)
		UseSkillEx($Mantids_DeathsCharge, $target)
		RndSleep(200)
	WEnd
	MoveTo(-230, -14100)
	MoveTo(-800, -14750)
	RndSleep(1500)

	; Killing
	MoveTo(-230, -14100)
	Local $center = FindMiddleOfFoes(-250, -14250, $RANGE_AREA)
	MoveTo($center[0], $center[1])
	AdlibRegister('UseWhirlingDefense', 500)
	UseSkillEx($Mantids_EdgeOfExtinction)

	; Wait for all mobs to be registered dead or wait 3s
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	Local $counter = 0
	While Not GetIsDead(-2) And $foesCount > 0 And $counter < 3
		RndSleep(1000)
		$counter = $counter + 1
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_NEARBY)
	WEnd
	RndSleep(1000)

	If GetIsDead(-2) Then
		BackToNahpuiQuarterOutpost()
		Return 1
	EndIf

	Info('Looting')
	PickUpItems()
	CheckForChests()

	BackToNahpuiQuarterOutpost()
	Return 0
EndFunc


Func UseFallBack()
	UseHeroSkill(1, $Mantids_FallBack)
	AdlibUnRegister()
EndFunc

Func UseWhirlingDefense()
	While IsRecharged($Mantids_WhirlingDefense) And Not GetIsDead(-2)
		UseSkillEx($Mantids_WhirlingDefense)
		RndSleep(50)
	WEnd
	AdlibUnRegister()
EndFunc


Func BackToNahpuiQuarterOutpost()
	Info('Porting to Nahpui Quarter')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Nahpui_Quarter, 10000, 2000)
EndFunc