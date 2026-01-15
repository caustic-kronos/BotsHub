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

; Possible improvements : none, this is perfect ;)

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $RA_MANTIDS_FARMER_SKILLBAR = 'OgcTYxr+5B5ozOgFHCIuT4AdAA'
Global Const $MANTIDS_HERO_SKILLBAR = 'OQijEqmMKODbe8OmEbi7x3YWMA'
Global Const $MANTIDS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 14 in Expertise' & @CRLF _
	& '- 12 in Shadow Arts' & @CRLF _
	& '- 8 in Beast Mastery' & @CRLF _
	& '- A shield with the inscription Through Thick and Thin (+10 armor against Piercing damage)' & @CRLF _
	& '- A one hand weapon with +5 energy +20% enchantment duration' & @CRLF _
	& '- Sentry or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
Global Const $MANTIDS_FARM_DURATION = 1 * 60 * 1000 + 30 * 1000

; You can select which paragon hero to use in the farm here, among 3 heroes available. Uncomment below line for hero to use
; party hero ID that is used to add hero to the party team
Global Const $MANTIDS_HERO_PARTY_ID = $ID_GENERAL_MORGAHN
;Global Const $MANTIDS_HERO_PARTY_ID = $ID_KEIRAN_THACKERAY
;Global Const $MANTIDS_HERO_PARTY_ID = $ID_HAYDA
Global Const $MANTIDS_HERO_INDEX = 1

; Skill numbers declared to make the code WAY more readable (UseSkillEx($MANTIDS_SERPENTS_QUICKNESS) is better than UseSkillEx(1))
Global Const $MANTIDS_SERPENTS_QUICKNESS	= 1
Global Const $MANTIDS_SHADOWFORM			= 2
Global Const $MANTIDS_SHROUD_OF_DISTRESS	= 3
Global Const $MANTIDS_LIGHTNING_REFLEXES	= 4
Global Const $MANTIDS_WAY_OF_PERFECTION		= 5
Global Const $MANTIDS_DEATHS_CHARGE			= 6
Global Const $MANTIDS_WHIRLING_DEFENSE		= 7
Global Const $MANTIDS_EDGE_OF_EXTINCTION	= 8

; Hero Build
Global Const $MANTIDS_VOCAL_WAS_SOGOLON		= 1
Global Const $MANTIDS_INCOMING				= 2
Global Const $MANTIDS_FALLBACK				= 3
Global Const $MANTIDS_BRACEYOURSELF			= 4
Global Const $MANTIDS_ENDURING_HARMONY		= 5
Global Const $MANTIDS_THEY_RE_ON_FIRE		= 6
Global Const $MANTIDS_MAKE_HASTE			= 7
Global Const $MANTIDS_BLADETURN_REFRAIN		= 8

Global $mantids_farm_setup = False


;~ Main method to farm Mantids
Func MantidsFarm()
	If Not $mantids_farm_setup And SetupMantidsFarm() == $FAIL Then Return $PAUSE

	GoToWajjunBazaar()
	Local $result = MantidsFarmLoop()
	ResignAndReturnToOutpost($ID_NAHPUI_QUARTER)
	Return $result
EndFunc


;~ Mantids farm setup
Func SetupMantidsFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_NAHPUI_QUARTER, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerMantidsFarm() == $FAIL Then Return $FAIL
	If SetupTeamMantidsFarm() == $FAIL Then Return $FAIL

	GoToWajjunBazaar()
	MoveTo(9100, -19600)
	Move(9100, -20500)
	RandomSleep(1000)
	WaitMapLoading($ID_NAHPUI_QUARTER, 10000, 2000)
	$mantids_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMantidsFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RANGER Then
		LoadSkillTemplate($RA_MANTIDS_FARMER_SKILLBAR)
	Else
		Warn('Should run this farm as ranger')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamMantidsFarm()
	Info('Setting up team')
	LeaveParty()
	RandomSleep(500)
	AddHero($MANTIDS_HERO_PARTY_ID)
	LoadSkillTemplate($MANTIDS_HERO_SKILLBAR, $MANTIDS_HERO_INDEX)
	DisableAllHeroSkills($MANTIDS_HERO_INDEX)
	RandomSleep(500)
	If GetPartySize() <> 2 Then
		Warn('Could not set up party correctly. Team size different than 2')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Wajjun Bazaar
Func GoToWajjunBazaar()
	TravelToOutpost($ID_NAHPUI_QUARTER, $district_name)
	While GetMapID() <> $ID_WAJJUN_BAZAAR
		Info('Moving to Wajjun Bazaar')
		;If (Not IsOverLine(0, 1, -12500, 0, DllStructGetData(GetMyAgent(), 'Y'))) Then MoveTo(-22000, 12500)
		MoveTo(-22000, 12500)
		Move(-21750, 14500)
		RandomSleep(1000)
		WaitMapLoading($ID_WAJJUN_BAZAAR, 10000, 2000)
	WEnd
EndFunc


;~ Mantids farm loop
Func MantidsFarmLoop()
	If GetMapID() <> $ID_WAJJUN_BAZAAR Then Return $FAIL
	Local $target

	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_VOCAL_WAS_SOGOLON)
	RandomSleep(1500)
	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_INCOMING)
	AdlibRegister('MantidsUseFallBack', 8000)

	; Move to spot before aggro
	MoveTo(3150, -16350, 0)
	RandomSleep(1500)
	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_ENDURING_HARMONY, GetMyAgent())
	RandomSleep(1500)
	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_THEY_RE_ON_FIRE)
	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_MAKE_HASTE, GetMyAgent())
	UseSkillEx($MANTIDS_SERPENTS_QUICKNESS)
	RandomSleep(50)
	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_BLADETURN_REFRAIN, GetMyAgent())
	UseSkillEx($MANTIDS_SHROUD_OF_DISTRESS)
	RandomSleep(50)
	UseSkillEx($MANTIDS_SHADOWFORM)
	UseHeroSkill(1, $MANTIDS_BRACEYOURSELF, GetMyAgent())
	RandomSleep(50)
	CommandAll(9000, -19500)

	; Aggro the three groups
	$target = GetNearestNPCInRangeOfCoords(700, -16700, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(-800, -15800)

	$target = GetNearestNPCInRangeOfCoords(-1350, -16250, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(-700, -14800)

	$target = GetNearestNPCInRangeOfCoords(-1600, -14500, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	AggroAgent($target)
	MoveTo(0, -14300)

	; Monk Balling spot
	MoveTo(1050, -14950, 0)
	While Not IsRecharged($MANTIDS_SHADOWFORM)
		RandomSleep(500)
	WEnd
	UseSkillEx($MANTIDS_SHADOWFORM)
	RandomSleep(50)
	UseSkillEx($MANTIDS_LIGHTNING_REFLEXES)
	RandomSleep(50)
	UseSkillEx($MANTIDS_WAY_OF_PERFECTION)
	RandomSleep(2000)
	If IsPlayerDead() Then Return $FAIL

	; Balling the rest
	$target = GetNearestEnemyToCoords(-450, -14400)
	While IsRecharged($MANTIDS_DEATHS_CHARGE) And IsPlayerAlive()
		UseSkillEx($MANTIDS_DEATHS_CHARGE, $target)
		RandomSleep(200)
	WEnd
	MoveTo(-230, -14100)
	MoveTo(-800, -14750)
	RandomSleep(1500)

	; Killing
	MoveTo(-230, -14100)
	Local $center = FindMiddleOfFoes(-250, -14250, $RANGE_AREA)
	MoveTo($center[0], $center[1])
	AdlibRegister('MantidsUseWhirlingDefense', 500)
	UseSkillEx($MANTIDS_EDGE_OF_EXTINCTION)

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
	Info('Picking up loot')
	; Tripled to secure the looting of items
	For $i = 1 To 3
		PickUpItems()
		RandomSleep(50)
	Next
	FindAndOpenChests()
	Return $SUCCESS
EndFunc


;~ Paragon Hero uses Fallback
Func MantidsUseFallBack()
	UseHeroSkill($MANTIDS_HERO_INDEX, $MANTIDS_FALLBACK)
	AdlibUnRegister('MantidsUseFallBack')
EndFunc


;~ Use Whirling Defense skill
Func MantidsUseWhirlingDefense()
	While IsRecharged($MANTIDS_WHIRLING_DEFENSE) And IsPlayerAlive()
		UseSkillEx($MANTIDS_WHIRLING_DEFENSE)
		RandomSleep(50)
	WEnd
	AdlibUnRegister('MantidsUseWhirlingDefense')
EndFunc
