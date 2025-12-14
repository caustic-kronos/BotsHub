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

; Possible improvements : none, this is perfect ;)

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $RAMantidsFarmerSkillbar = 'OgcTYxr+5B5ozOgFHCIuT4AdAA'
Global Const $MantidsHeroSkillbar = 'OQijEqmMKODbe8OGAYi7x3YWMA'
Global Const $MantidsFarmInformations = 'For best results, have :' & @CRLF _
	& '- 14 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 8 in Beast Mastery' & @CRLF _
	& '- A shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A one hand weapon with +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
Global Const $MANTIDS_FARM_DURATION = 1 * 60 * 1000 + 30 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Mantids_DeadlyParadox) is better than UseSkillEx(1))
Global Const $Mantids_DeadlyParadox			= 1
Global Const $Mantids_ShadowForm			= 2
Global Const $Mantids_ShroudOfDistress		= 3
Global Const $Mantids_LightningReflexes		= 4
Global Const $Mantids_WayOfPerfection		= 5
Global Const $Mantids_DeathsCharge			= 6
Global Const $Mantids_WhirlingDefense		= 7
Global Const $Mantids_EdgeOfExtinction		= 8

; Hero Build
Global Const $Mantids_VocalWasSogolon		= 1
Global Const $Mantids_Incoming				= 2
Global Const $Mantids_FallBack				= 3
Global Const $Mantids_EnduringHarmony		= 5
Global Const $Mantids_TheyreOnFire			= 6
Global Const $Mantids_MakeHaste				= 7
Global Const $Mantids_BladeturnRefrain		= 8

Global $MANTIDS_FARM_SETUP = False

;~ Main method to farm Mantids
Func MantidsFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $MANTIDS_FARM_SETUP And SetupMantidsFarm() == $FAIL Then Return $PAUSE

	GoToWajjunBazaar()
	Local $result = MantidsFarmLoop()
	ReturnBackToOutpost($ID_Nahpui_Quarter)
	Return $result
EndFunc


;~ Mantids farm setup
Func SetupMantidsFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_Nahpui_Quarter, $DISTRICT_NAME) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerMantidsFarm() == $FAIL Then Return $FAIL
	If SetupTeamMantidsFarm() == $FAIL Then Return $FAIL

	GoToWajjunBazaar()
	MoveTo(9100, -19600)
	Move(9100, -20500)
	RandomSleep(1000)
	WaitMapLoading($ID_Nahpui_Quarter, 10000, 2000)
	$MANTIDS_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMantidsFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Ranger Then
		LoadSkillTemplate($RAMantidsFarmerSkillbar)
    Else
    	Warn('Should run this farm as ranger')
    	Return $FAIL
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


Func SetupTeamMantidsFarm()
	Info('Setting up team')
	LeaveParty()
	Sleep(500 + GetPing())
	AddHero($ID_General_Morgahn)
	LoadSkillTemplate($MantidsHeroSkillbar, 1)
	DisableAllHeroSkills(1)
	Sleep(500 + GetPing())
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Wajjun Bazaar
Func GoToWajjunBazaar()
	TravelToOutpost($ID_Nahpui_Quarter, $DISTRICT_NAME)
	While GetMapID() <> $ID_Wajjun_Bazaar
		Info('Moving to Wajjun Bazaar')
		;If (Not IsOverLine(0, 1, -12500, 0, DllStructGetData(GetMyAgent(), 'Y'))) Then MoveTo(-22000, 12500)
		MoveTo(-22000, 12500)
		Move(-21750, 14500)
		RandomSleep(1000)
		WaitMapLoading($ID_Wajjun_Bazaar, 10000, 2000)
	WEnd
EndFunc


;~ Mantids farm loop
Func MantidsFarmLoop()
	If GetMapID() <> $ID_Wajjun_Bazaar Then Return $FAIL
	Local $target

	UseHeroSkill(1, $Mantids_VocalWasSogolon)
	RandomSleep(1500)
	UseHeroSkill(1, $Mantids_Incoming)
	AdlibRegister('UseFallBack', 8000)

	; Move to spot before aggro
	MoveTo(3150, -16350, 0)
	RandomSleep(1500)
	UseHeroSkill(1, $Mantids_EnduringHarmony, GetMyAgent())
	RandomSleep(1500)
	UseHeroSkill(1, $Mantids_TheyreOnFire)
	UseHeroSkill(1, $Mantids_MakeHaste, GetMyAgent())
	UseSkillEx($Mantids_DeadlyParadox)
	RandomSleep(20)
	UseHeroSkill(1, $Mantids_BladeturnRefrain, GetMyAgent())
	UseSkillEx($Mantids_ShroudOfDistress)
	RandomSleep(20)
	UseSkillEx($Mantids_ShadowForm)
	RandomSleep(20)
	CommandAll(9000, -19500)

	; Aggro the three groups
	$target = GetNearestNPCInRangeOfCoords(700, -16700, $ID_Allegiance_Foe, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(-800, -15800)

	$target = GetNearestNPCInRangeOfCoords(-1350, -16250, $ID_Allegiance_Foe, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(-700, -14800)

	$target = GetNearestNPCInRangeOfCoords(-1600, -14500, $ID_Allegiance_Foe, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(0, -14300)

	; Monk Balling spot
	MoveTo(1050, -14950, 0)
	While Not IsRecharged($Mantids_ShadowForm)
		RandomSleep(500)
	WEnd
	UseSkillEx($Mantids_ShadowForm)
	RandomSleep(20)
	UseSkillEx($Mantids_LightningReflexes)
	RandomSleep(20)
	UseSkillEx($Mantids_WayOfPerfection)
	RandomSleep(2000)
	If IsPlayerDead() Then Return $FAIL

	; Balling the rest
	$target = GetNearestEnemyToCoords(-450, -14400)
	While IsRecharged($Mantids_DeathsCharge) And IsPlayerAlive()
		UseSkillEx($Mantids_DeathsCharge, $target)
		RandomSleep(200)
	WEnd
	MoveTo(-230, -14100)
	MoveTo(-800, -14750)
	RandomSleep(1500)

	; Killing
	MoveTo(-230, -14100)
	Local $center = FindMiddleOfFoes(-250, -14250, $RANGE_AREA)
	MoveTo($center[0], $center[1])
	AdlibRegister('UseWhirlingDefense', 500)
	UseSkillEx($Mantids_EdgeOfExtinction)

	; Wait for all mobs to be registered dead or wait 3s
	Local $me = GetMyAgent()
	Local $foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY)
	Local $counter = 0
	While IsPlayerAlive() And $foesCount > 0 And $counter < 3
		RandomSleep(1000)
		$counter = $counter + 1
		$me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_NEARBY)
	WEnd
	RandomSleep(1000)

	If IsPlayerDead() Then Return $FAIL

	Info('Looting')
	PickUpItems()
	FindAndOpenChests()

	Return $SUCCESS
EndFunc


;~ Paragon Hero uses Fallback
Func UseFallBack()
	UseHeroSkill(1, $Mantids_FallBack)
	AdlibUnRegister('UseFallBack')
EndFunc


;~ Use Whirling Defense skill
Func UseWhirlingDefense()
	While IsRecharged($Mantids_WhirlingDefense) And IsPlayerAlive()
		UseSkillEx($Mantids_WhirlingDefense)
		RandomSleep(50)
	WEnd
	AdlibUnRegister('UseWhirlingDefense')
EndFunc