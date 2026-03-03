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

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $ELA_KOURNANS_FARMER_SKILLBAR = 'OgdTkYG/HCHMXctUVwHC3xVI1BA'
Global Const $R_KOURNANS_HERO_SKILLBAR = 'OgATYnLjZB6C+Zn76OzGAAAA'
Global Const $RT_KOURNANS_HERO_SKILLBAR = 'OACjAyhDJPBTy58M5CAAAAAAAA'
Global Const $P_KOURNANS_HERO_SKILLBAR = 'OQijEqmMKO84dM92HbiH26YcMA'
Global Const $KOURNANS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Magic' & @CRLF _
	& '- 13 in Energy Storage' & @CRLF _
	& '- 3 in Shadow Arts' & @CRLF _
	& '- Any weapon that gives you energy or maybe life' & @CRLF _
	& '- A spear +5 energy +20% enchantment duration' & @CRLF _
	& '- Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune' & @CRLF _
	& '- The quest Fish in a Barrel not completed'
; Average duration ~ 2m10s ~ First run is 2m40s with setup
Global Const $KOURNANS_FARM_DURATION = (2 * 60 + 25) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($RAPTORS_MARK_OF_PAIN) is better than UseSkillEx(1))
Global Const $KOURNANS_INTENSITY						= 1
Global Const $KOURNANS_EBON_BATTLE_STANDARD_OF_HONOR	= 2
Global Const $KOURNANS_MINDBENDER						= 3
Global Const $KOURNANS_EARTHQUAKE						= 4
Global Const $KOURNANS_DRAGONS_STOMP					= 5
Global Const $KOURNANS_DEATHS_CHARGE					= 6
Global Const $KOURNANS_AFTERSHOCK						= 7
Global Const $KOURNANS_SHOCKWAVE						= 8

Global Const $KOURNANS_RANGER_HERO					= $ID_MARGRID_THE_SLY
;Global Const $KOURNANS_RANGER_HERO					= $ID_ACOLYTE_JIN
;Global Const $KOURNANS_RANGER_HERO					= $ID_PYRE_FIERCESHOT
Global Const $KOURNANS_RITUALIST_HERO				= $ID_XANDRA
;Global Const $KOURNANS_RITUALIST_HERO				= $ID_RAZAH
Global Const $KOURNANS_PARAGON_HERO					= $ID_GENERAL_MORGAHN
;Global Const $KOURNANS_PARAGON_HERO				= $ID_KEIRAN_THACKERAY
;Global Const $KOURNANS_PARAGON_HERO				= $ID_HAYDA

Global Const $KOURNANS_RANGER_HERO_POSITION			= 1
Global Const $KOURNANS_RITUALIST_HERO_POSITION		= 2
Global Const $KOURNANS_PARAGON_HERO_POSITION		= 3

Global Const $KOURNANS_EDGE_OF_EXTINCTION	= 1
Global Const $KOURNANS_LACERATE				= 2
Global Const $KOURNANS_BRAMBLES				= 3
Global Const $KOURNANS_NATURES_RENEWAL		= 4
Global Const $KOURNANS_MUDDY_TERRAIN		= 5
Global Const $KOURNANS_PESTILENCE			= 6

Global Const $KOURNANS_RITUAL_LORD			= 1
Global Const $KOURNANS_EARTHBIND			= 2
Global Const $KOURNANS_VITAL_WEAPON			= 3
Global Const $KOURNANS_DEATH_PACT_SIGNET	= 4

Global $kournans_farm_setup = False


;~ Main method to farm Kournans
Func KournansFarm()
	If Not $kournans_farm_setup And If SetupKournansFarm() == $FAIL Then Return $PAUSE

	GoToCommandPost()
	Local $result = KournansFarmLoop()
	ResignAndReturnToOutpost($ID_SUNSPEAR_SANCTUARY)
	Return $result
EndFunc


;~ Kournans farm setup
Func SetupKournansFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_SUNSPEAR_SANCTUARY, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)

	If SetupPlayerKournansFarm() == $FAIL Then Return $FAIL
	If SetupTeamKournansFarm() == $FAIL Then Return $FAIL

	RandomSleep(50)
	GoToCommandPost()
	MoveTo(-200, 4350)
	Move(-500, 3500)
	RandomSleep(1000)
	WaitMapLoading($ID_SUNSPEAR_SANCTUARY, 10000, 2000)
	$kournans_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerKournansFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_ELEMENTALIST Then
		LoadSkillTemplate($ELA_KOURNANS_FARMER_SKILLBAR)
	Else
		Warn('Should run this farm as elementalist')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func SetupTeamKournansFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	RandomSleep(500)
	AddHero($KOURNANS_RANGER_HERO)
	AddHero($KOURNANS_RITUALIST_HERO)
	AddHero($KOURNANS_PARAGON_HERO)
	RandomSleep(500)
	If GetPartySize() <> 4 Then
		Warn('Could not set up party correctly. Team size different than 4')
		Return $FAIL
	EndIf
	LoadSkillTemplate($R_KOURNANS_HERO_SKILLBAR, $KOURNANS_RANGER_HERO_POSITION)
	LoadSkillTemplate($RT_KOURNANS_HERO_SKILLBAR, $KOURNANS_RITUALIST_HERO_POSITION)
	LoadSkillTemplate($P_KOURNANS_HERO_SKILLBAR, $KOURNANS_PARAGON_HERO_POSITION)
	RandomSleep(250)
	DisableAllHeroSkills(1)
	DisableAllHeroSkills(2)
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Command Post
Func GoToCommandPost()
	TravelToOutpost($ID_SUNSPEAR_SANCTUARY, $district_name)
	If GetQuestByID($ID_QUEST_FISH_IN_A_BARREL) <> Null Then
		Info('Abandoning quest')
		AbandonQuest($ID_QUEST_FISH_IN_A_BARREL)
	EndIf
	While GetMapID() <> $ID_COMMAND_POST
		Info('Moving to Command Post')
		MoveTo(-1500, 2000)
		MoveTo(-600, 3700)
		Move(0, 5000)
		RandomSleep(1000)
		WaitMapLoading($ID_COMMAND_POST, 10000, 2000)
	WEnd
EndFunc


;~ Kournans farm loop
Func KournansFarmLoop()
	If GetMapID() <> $ID_COMMAND_POST Then Return $FAIL

	MoveTo(1250, 7300)
	TalkToMargrid()
	MoveTo(800, 6500)
	MoveTo(-1000, 6300)
	MoveTo(-3200, 9000)
	Move(-4000, 10000)
	RandomSleep(1000)
	WaitMapLoading($ID_SUNWARD_MARCHES, 10000, 2000)
	MoveTo(13500, -4000)
	MoveTo(11500, -2500)

	; Find the kournans and get in spirit range
	; Move to the correct range of the enemies (who are not enemies at this points)(close so that they are affected by spirits but not too close)
	Local $targetFoe = GetNearestNPCInRangeOfCoords(9600, -650, Null, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe, $RANGE_SPIRIT - 500)
	Local $me = GetMyAgent()
	Local $x = DllStructGetData($me, 'X')
	Local $y = DllStructGetData($me, 'Y')
	CommandAll($X, $y)
	RandomSleep(2000)
	CastOnlyNecessarySpiritsAndBoons($x, $y)
	CommandAll(16000, -7000)

	UseSkillEx($KOURNANS_INTENSITY)
	UseSkillEx($KOURNANS_MINDBENDER)
	Local $positionToGo = FindMiddleOfFoes(9600, -650, $RANGE_EARSHOT)
	$targetFoe = BetterGetNearestNPCToCoords($ID_ALLEGIANCE_FOE, $positionToGo[0], $positionToGo[1], $RANGE_SPELLCAST)
	GetAlmostInRangeOfAgent($targetFoe)
	RandomSleep(50)
	UseSkillEx($KOURNANS_EBON_BATTLE_STANDARD_OF_HONOR)
	UseSkillEx($KOURNANS_EARTHQUAKE, $targetFoe)
	UseSkill($KOURNANS_DRAGONS_STOMP, $targetFoe)
	Sleep(1500)
	UseSkillEx($KOURNANS_INTENSITY)
	Sleep(1500)
	UseSkillEx($KOURNANS_DEATHS_CHARGE, $targetFoe)
	UseSkillEx($KOURNANS_AFTERSHOCK)
	UseSkillEx($KOURNANS_SHOCKWAVE)
	RandomSleep(2000)
	If IsPlayerDead() Then Return $FAIL
	Info('Picking up loot')
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Cast the mandatory spirits and boons
Func CastOnlyNecessarySpiritsAndBoons($safeX, $safeY)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_EDGE_OF_EXTINCTION)
	; Get closer to the non-enemies to trigger them into enemies
	Local $targetFoe = GetFurthestNPCInRangeOfCoords(Null, 9600, -650, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe, $RANGE_EARSHOT - 50)
	; Move back to be safe for a few seconds
	MoveTo($safeX, $safeY)
	RandomSleep(4000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_MUDDY_TERRAIN)
	RandomSleep(6000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_BRAMBLES)
	RandomSleep(3000)
	UseHeroSkill($KOURNANS_RITUALIST_HERO_POSITION, $KOURNANS_RITUAL_LORD)
	UseHeroSkill($KOURNANS_RITUALIST_HERO_POSITION, $KOURNANS_EARTHBIND)
	RandomSleep(1500)
	UseHeroSkill($KOURNANS_RITUALIST_HERO_POSITION, $KOURNANS_VITAL_WEAPON, GetMyAgent())
	RandomSleep(1500)
EndFunc


;~ Cast all of the spirits and boons - it is not necessary
Func CastFullSpiritsAndBoons($safeX, $safeY)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_EDGE_OF_EXTINCTION)
	; Get closer to the non-enemies to trigger them into enemies
	Local $targetFoe = GetFurthestNPCInRangeOfCoords(Null, 9600, -650, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe, $RANGE_EARSHOT -100)
	; Move back to be safe for a few seconds
	MoveTo($safeX, $safeY)
	RandomSleep(5000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_BRAMBLES)
	RandomSleep(6000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_LACERATE)
	RandomSleep(4000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_NATURES_RENEWAL)
	RandomSleep(6000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_MUDDY_TERRAIN)
	RandomSleep(6000)
	UseHeroSkill($KOURNANS_RANGER_HERO_POSITION, $KOURNANS_PESTILENCE)
	RandomSleep(3000)
	UseHeroSkill($KOURNANS_RITUALIST_HERO_POSITION, $KOURNANS_RITUAL_LORD)
	UseHeroSkill($KOURNANS_RITUALIST_HERO_POSITION, $KOURNANS_EARTHBIND)
	RandomSleep(1500)
	UseHeroSkill($KOURNANS_RITUALIST_HERO_POSITION, $KOURNANS_VITAL_WEAPON, GetMyAgent())
	RandomSleep(1500)
EndFunc


;~ Talk to Margrid and take her quest
Func TalkToMargrid()
	Info('Talking to Margrid')
	GoNearestNPCToCoords(1250, 7300)
	RandomSleep(1000)
	Info('Taking quest')
	AcceptQuest($ID_FISH_IN_A_BARREL)
	RandomSleep(500)
EndFunc