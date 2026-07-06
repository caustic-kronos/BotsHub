#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2026 caustic-kronos
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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'

; Improvements:
; - try to reduce bodyblocks at first group with clever movements
; - if only 9 drakes spawn (instead of 10) one drake will stay alive - we could hack at it until it dies


; ==== Constants ====
Global Const $DRAKE_FLESH_FARMER_SKILLBAR = 'OQQUc4oQt6SWC0kqM9F5F5ija7gA'
Global Const $DRAKE_FLESH_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- the quest Drakes on the Plain that makes the drakes show up (without it you cant farm)' & @CRLF _
	& '- 12 in Curses' & @CRLF _
	& '- 12 in Tactics' & @CRLF _
	& '- 10 in Swordsmanship' & @CRLF _
	& '- the rest in Strength' & @CRLF _
	& '- A tactic shield +30 health with +10 armor against Dragons' & @CRLF _
	& '- A sword +5 energy +7 armor against physical damage' & @CRLF _
	& '- Knights insignias on all the armor pieces and a run of superior absorption' & @CRLF _
	& '- A superior vigor rune'
Global Const $DRAKE_FLESH_FARM_DURATION = 45 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($DRAKE_FLESH_MARK_OF_PAIN) is better than UseSkillEx(1))
Global Const $DRAKE_FLESH_MARK_OF_PAIN					= 1
Global Const $DRAKE_FLESH_I_AM_UNSTOPPABLE				= 2
Global Const $DRAKE_FLESH_PROTECTORS_DEFENSE			= 3
Global Const $DRAKE_FLESH_HUNDRED_BLADES				= 4
Global Const $DRAKE_FLESH_WARY_STANCE					= 5
Global Const $DRAKE_FLESH_EBON_BATTLE_STANDARD_OF_HONOR	= 6
Global Const $DRAKE_FLESH_SOLDIERS_DEFENSE				= 7
Global Const $DRAKE_FLESH_WHIRLWIND_ATTACK				= 8

; Hero Build
Global Const $DRAKE_FLESH_KOSS_SKILLBAR					= 'OQkiExm8Yivx6YWMAAAQiBAA'
Global Const $DRAKE_FLESH_KOSS_ENDURING_HARMONY			= 1
Global Const $DRAKE_FLESH_KOSS_MAKE_HASTE				= 2
Global Const $DRAKE_FLESH_KOSS_HELP						= 3
Global Const $DRAKE_FLESH_KOSS_BLADETURN_REFRAIN		= 4

Global Const $DRAKE_FLESH_MONK_MARK_OF_PROTECTION		= 1

Global $drake_flesh_farm_setup = False

;~ Main method to farm Drake Flesh
Func DrakeFleshFarm()
	If Not $drake_flesh_farm_setup And SetupDrakeFleshFarm() == $FAIL Then Return $PAUSE

	LeaveToTheFloodPlainsOfMahnkelon()
	Local $result = DrakeFleshFarmLoop()
	ResignAndReturnToOutpost($ID_RILOHN_REFUGE)
	Return $result
EndFunc


;~ Drake flesh farm setup
Func SetupDrakeFleshFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_RILOHN_REFUGE, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_HARD_MODE)
	If SetupPlayerDrakeFleshFarm() == $FAIL Then Return $FAIL
	If SetupTeamDrakeFleshFarm() == $FAIL Then Return $FAIL
	LeaveToTheFloodPlainsOfMahnkelon()
	MoveTo(-15300, 9000)
	Move(-15400, 9250)
	RandomSleep(1000)
	WaitMapLoading($ID_RILOHN_REFUGE, 10000, 1000)
	$drake_flesh_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Setting up character with proper attributes and skills
Func SetupPlayerDrakeFleshFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_WARRIOR Then
		LoadSkillTemplate($DRAKE_FLESH_FARMER_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as warrior')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Setting up the team with Koss and Tahlkora
Func SetupTeamDrakeFleshFarm()
	If IsTeamAutoSetup() Then Return $SUCCESS

	Info('Setting up team')
	LeaveParty()
	If AddHero($ID_KOSS) == $FAIL Or AddHero($ID_TAHLKORA) == $FAIL Then
		Error('Could not add Koss or Tahlkora to team.')
		Return $FAIL
	EndIf
	RandomSleep(150)
	LoadSkillTemplate($DRAKE_FLESH_KOSS_SKILLBAR, 1)
	RandomSleep(150)
	DisableAllHeroSkills(1)
	SetHeroBehaviour(1, $ID_HERO_AVOIDING)
	RandomSleep(150)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into the Flood Plains of Mahnkelon
Func LeaveToTheFloodPlainsOfMahnkelon()
	TravelToOutpost($ID_RILOHN_REFUGE, $district_name)
	While GetMapID() <> $ID_THE_FLOODPLAIN_OF_MAHNKELON
		Info('Moving to The Floodplain of Mahnkelon')
		MoveTo(-15400, 9250)
		Move(-15300, -9000)
		RandomSleep(1000)
		WaitMapLoading($ID_THE_FLOODPLAIN_OF_MAHNKELON, 10000, 1000)
	WEnd
EndFunc


;~ Farm loop
Func DrakeFleshFarmLoop()
	If GetMapID() <> $ID_THE_FLOODPLAIN_OF_MAHNKELON Then Return $FAIL

	; Speed boosting character then flagging Koss away
	Local $me = GetMyAgent()
	Move(-14050, 8650)
	UseHeroSkillEx(1, $DRAKE_FLESH_KOSS_ENDURING_HARMONY, $me)
	PingSleep(50)
	UseHeroSkillEx(1, $DRAKE_FLESH_KOSS_MAKE_HASTE, $me)
	PingSleep(50)
	UseHeroSkillEx(1, $DRAKE_FLESH_KOSS_HELP, $me)
	PingSleep(50)
	UseHeroSkill(2, $DRAKE_FLESH_MONK_MARK_OF_PROTECTION, $me)
	UseHeroSkillEx(1, $DRAKE_FLESH_KOSS_BLADETURN_REFRAIN, $me)
	CommandHero(1, -18300, 3600)
	CommandHero(2, -18300, 3600)

	; Getting in range of drakes, using MoP on one
	MoveTo(-13120, 8930)
	$me = GetMyAgent()
	Local $target = GetNearestEnemyToAgent($me)
	; Force casting MoP on target
	While IsRecharged($DRAKE_FLESH_MARK_OF_PAIN)
		UseSkillEx($DRAKE_FLESH_MARK_OF_PAIN, $target)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	PingSleep(50)
	
	; Use IAU not too late so we still have enduring harmony on it
	UseSkillEx($DRAKE_FLESH_I_AM_UNSTOPPABLE)

	; Lateral move to avoid drakes
	$me = GetMyAgent()
	MoveTo(DllStructGetData($me, 'X') - 150, DllStructGetData($me, 'Y') + 175)

	; Running further away
	MoveTo(-12100, 10400)
	MoveTo(-10650, 10500)
	If IsPlayerDead() Then
		Warn('Got bodyblocked by first drake group')
		Return $FAIL
	EndIf

	; Aggro second group
	Local $target = GetNearestNPCInRangeOfCoords(-7950, 11500, $ID_ALLEGIANCE_FOE, $RANGE_SPIRIT)
	MoveTo(-9800, 11250)
	AggroAgent($target)

	; Three options for spiking:
	; (-9930, 10650) - spot behind, to the right - difficult, often bodyblock
	; (-10200, 11750) - spot behind, to the left - way should be clear unless we went very far east
	; (-9410, 12015) - spot middle, to the left
	; (-8235, 11500) - furthest spot, if second group is very far east

	; Spiking spots to the left
	If DllStructGetData(GetMyAgent(), 'X') < -8400 Then
		; Lateral move to avoid drakes behind us
		$me = GetMyAgent()
		MoveTo(DllStructGetData($me, 'X') - 100, DllStructGetData($me, 'Y') + 200)
		If DllStructGetData(GetMyAgent(), 'X') > -9100 Then
			MoveTo(-9410, 12015)
		Else
			MoveTo(-10200, 11750)
		EndIf
	; We went too far east to aggro the second group - using different spiking point
	Else
		MoveTo(-8235, 11500)
	EndIf
	If KillDrakes() == $FAIL Then Return $FAIL

	; Loooooooooot
	Info('Picking up loot')
	RandomSleep(1000)
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Kill drakes
Func KillDrakes()
	Info('Clearing Drakes')

	UseSkillEx($DRAKE_FLESH_PROTECTORS_DEFENSE)
	RandomSleep(50)
	UseSkillEx($DRAKE_FLESH_HUNDRED_BLADES)
	RandomSleep(50)
	; For early spikes energy is a bit rough on energy - waiting on wary stance to be ready
	While GetEnergy() < 10
		RandomSleep(250)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	UseSkillEx($DRAKE_FLESH_WARY_STANCE)
	; Waiting for enough energy to do EBSoH, soldier's defense and MoP
	While GetEnergy() < 25
		RandomSleep(250)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	UseSkillEx($DRAKE_FLESH_EBON_BATTLE_STANDARD_OF_HONOR)
	RandomSleep(50)
	UseSkillEx($DRAKE_FLESH_SOLDIERS_DEFENSE)
	; Waiting until we can cast Mark of Pain
	While Not IsRecharged($DRAKE_FLESH_MARK_OF_PAIN) Or GetEnergy() < 10
		RandomSleep(100)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	; If we selected mop target we already hexed, we pick another
	Local $me = GetMyAgent()
	Local $mopTarget = GetNearestEnemyToAgent($me)
	While GetHasHex($mopTarget)
		$mopTarget = GetNearestEnemyToAgent($mopTarget)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	UseSkillEx($DRAKE_FLESH_MARK_OF_PAIN, $mopTarget)
	RandomSleep(50)

	; Waiting for adrenaline, but it should be full already
	While GetSkillbarSkillAdrenaline($DRAKE_FLESH_WHIRLWIND_ATTACK) <> 130
		RandomSleep(50)
		If IsPlayerDead() Then Return $FAIL
	WEnd

	; Spiking with whirlwind finally
	$me = GetMyAgent()
	While GetSkillbarSkillAdrenaline($DRAKE_FLESH_WHIRLWIND_ATTACK) == 130
		UseSkillEx($DRAKE_FLESH_WHIRLWIND_ATTACK, GetNearestEnemyToAgent($me))
		RandomSleep(250)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd	
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc