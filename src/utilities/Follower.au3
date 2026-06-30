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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'

; Possible improvements :
; - Correct a crash happening when someone picks up items the bot wanted to pick up
; - speed up the bot by all ways possible (since it casts shouts it is always lagging behind)
;		- using a cupcake and a pumpkin pie might be a good idea


; ==== Constants ====
Global Const $FOLLOWER_INFORMATIONS = 'This bot makes your character follow the first other player in party.' & @CRLF _
	& 'It will attack everything that gets in range.' & @CRLF _
	& 'It will loot all items it can loot.' & @CRLF _
	& 'It will also loot all chests in range.'

Global Const $FOLLOWER_LEASH_RANGE = $RANGE_SPELLCAST - 200

; Skill numbers declared to make the code WAY more readable (UseSkillEx($RAPTORS_MARK_OF_PAIN) is better than UseSkillEx(1))
Global $player_profession_ID
Global $follower_attack_skill_1 = Null
Global $follower_attack_skill_2 = Null
Global $follower_attack_skill_3 = Null
Global $follower_attack_skill_4 = Null
Global $follower_attack_skill_5 = Null
Global $follower_attack_skill_6 = Null
Global $follower_attack_skill_7 = Null
Global $follower_attack_skill_8 = Null
Global $follower_maintain_skill_1 = Null
Global $follower_maintain_skill_2 = Null
Global $follower_maintain_skill_3 = Null
Global $follower_maintain_skill_4 = Null
Global $follower_maintain_skill_5 = Null
Global $follower_maintain_skill_6 = Null
Global $follower_maintain_skill_7 = Null
Global $follower_maintain_skill_8 = Null
Global $follower_running_skill = Null

Global $follower_setup = False

;~ Main loop
Func FollowerFarm()
	If Not $follower_setup Then FollowerSetup()

	While $runtime_status == 'RUNNING'
		Switch $player_profession_ID
			Case $ID_WARRIOR
				FollowerLoop()
			Case $ID_RANGER
				FollowerLoop()
			Case $ID_MONK
				FollowerLoop()
			Case $ID_MESMER
				FollowerLoop()
			Case $ID_NECROMANCER
				FollowerLoop()
			Case $ID_ELEMENTALIST
				FollowerLoop()
			Case $ID_RITUALIST
				FollowerLoop()
			Case $ID_ASSASSIN
				FollowerLoop()
			Case $ID_PARAGON
				FollowerLoop()
			Case $ID_DERVISH
				FollowerLoop()
			Case Else
				FollowerLoop()
		EndSwitch
	WEnd

	$follower_setup = False
	AdlibUnRegister()
	Return $runtime_status <> 'RUNNING' ? $PAUSE : $SUCCESS
EndFunc


;~ Follower setup
Func FollowerSetup()
	$player_profession_ID = GetHeroProfession(0, False)
	Info('Setting up follower bot')
	Switch $player_profession_ID
		Case $ID_WARRIOR
			DefaultSetup()
		Case $ID_RANGER
			RangerSetup()
		Case $ID_MONK
			DefaultSetup()
		Case $ID_MESMER
			DefaultSetup()
		Case $ID_NECROMANCER
			DefaultSetup()
		Case $ID_ELEMENTALIST
			DefaultSetup()
		Case $ID_RITUALIST
			DefaultSetup()
		Case $ID_ASSASSIN
			DefaultSetup()
		Case $ID_PARAGON
			DefaultSetup()
			;ParagonSetup()
		Case $ID_DERVISH
			DefaultSetup()
		Case Else
			DefaultSetup()
	EndSwitch
	$follower_setup = True
EndFunc


;~ Follower loop
Func FollowerLoop($runFunction = DefaultRun, $fightFunction = DefaultFight)
	Local Static $leaderID = Null, $currentMap = Null, $resigned = False

	Local $mapID = GetMapID()
	If $mapID <> $currentMap Then
		$currentMap = $mapID
		$leaderID = Null
		$resigned = False
		SkipCinematic()
		WaitMapLoading($mapID)
	EndIf

	If $leaderID == Null Then
		If GetMapType() == $ID_EXPLORABLE Then $leaderID = FollowerResolveLeaderID()
		If $leaderID == Null Then
			RandomSleep(500)
			Return
		EndIf
	EndIf

	$runFunction()
	Local $leader = GetAgentByID($leaderID)
	GoPlayer($leader)

	If GetMapType() == $ID_EXPLORABLE Then
		If Not $resigned Then
			Info('Auto-resigning on explorable entry')
			Resign()
			$resigned = True
			RandomSleep(500)
		EndIf

		Local $me = GetMyAgent()
		$leader = GetAgentByID($leaderID)
		If $leader <> Null And GetDistance($me, $leader) <= $FOLLOWER_LEASH_RANGE Then
			Local $foesCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
			While IsPlayerAlive() And $foesCount > 0
				$fightFunction()
				$me = GetMyAgent()
				$leader = GetAgentByID($leaderID)
				If $leader <> Null And GetDistance($me, $leader) > $FOLLOWER_LEASH_RANGE Then ExitLoop
				$foesCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
			WEnd
			FindAndOpenChests()

			If CountSlots(1, $bags_count) > 0 Then PickUpItems(Null, DefaultShouldPickItem, 1500)
		EndIf
	EndIf

	RandomSleep(1000)
EndFunc


;~ Default class setup
Func DefaultSetup()
	$follower_attack_skill_1 = 1
	$follower_attack_skill_2 = 2
	$follower_attack_skill_3 = 3
	$follower_attack_skill_4 = 4
	$follower_attack_skill_5 = 5
	$follower_attack_skill_6 = 6
	$follower_attack_skill_7 = 7
	$follower_attack_skill_8 = 8
EndFunc


;~ Default class run method
Func DefaultRun()
	If $follower_running_skill <> Null And IsRecharged($follower_running_skill) Then UseSkillEx($follower_running_skill)
EndFunc


;~ Default class fight method
Func DefaultFight()
	AttackOrUseSkill(1000, $follower_maintain_skill_1, $follower_maintain_skill_2, $follower_maintain_skill_3, $follower_maintain_skill_4, $follower_maintain_skill_5, $follower_maintain_skill_6, $follower_maintain_skill_7, $follower_maintain_skill_8)
	AttackOrUseSkill(1000, $follower_attack_skill_1, $follower_attack_skill_2, $follower_attack_skill_3, $follower_attack_skill_4, $follower_attack_skill_5, $follower_attack_skill_6, $follower_attack_skill_7, $follower_attack_skill_8)
EndFunc


;~ Ranger follower setup
Func RangerSetup()
	Local $wildBlow = 1
	Local $soldiersStrike = 2
	Local $desperationBlow = 3
	Local $runAsOne = 4
	Local $togetherAsOne = 5
	Local $neverRampageAlone = 6
	Local $ebonBattleStandardOfHonor = 7
	Local $comfortAnimal = 8

	$follower_maintain_skill_1 = $togetherAsOne
	$follower_maintain_skill_2 = $ebonBattleStandardOfHonor
	$follower_maintain_skill_3 = $runAsOne
	$follower_maintain_skill_4 = $neverRampageAlone
	$follower_attack_skill_1 = $wildBlow
	$follower_attack_skill_2 = $soldiersStrike
	$follower_attack_skill_3 = $desperationBlow
	$follower_running_skill = $runAsOne
EndFunc


;~ Resolve the leader's agent struct by reading the agent ID directly out of the player record array.
;~ Works in both outposts and explorables. Bypasses the lib's GetFirstPlayerOfParty, which fails in
;~ outposts because party agent structs report LoginNumber=0 there.
;~ Player records are 80 bytes wide; agent ID is at offset 0 of each record.
Func FollowerResolveLeaderID()
	Local $myLoginNumber = DllStructGetData(GetMyAgent(), 'LoginNumber')
	Local $partyMembers = GetParty()
	For $member In $partyMembers
		Local $loginNumber = DllStructGetData($member, 'LoginNumber')
		If $loginNumber <= 0 Then ContinueLoop
		If $loginNumber == $myLoginNumber Then ContinueLoop
		Return DllStructGetData($member, 'ID')
	Next
	Return Null
EndFunc


;~ Get first player of the party team other than yourself. If no other player found in the party team then function returns Null
Func GetFirstPlayerOfParty()
	Local $selfLoginNumber = DllStructGetData(GetMyAgent(), 'LoginNumber')
	Local $playerCount = GetPlayerCount()

	Local $party = GetParty()

	For $i = 0 To $playerCount - 1
		Local $slotLoginNumber = GetPartyPlayerLoginNumber($i)

		If $slotLoginNumber == 0 Then ContinueLoop
		If $slotLoginNumber == $selfLoginNumber Then ContinueLoop

		For $member In $party
			If DllStructGetData($member, 'LoginNumber') == $slotLoginNumber Then
				Return $member
			EndIf
		Next
	Next

	Return Null
EndFunc