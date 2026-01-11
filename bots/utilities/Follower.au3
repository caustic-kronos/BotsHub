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
; - Correct a crash happening when someone picks up items the bot wanted to pick up
; - Correct a bug that makes the bot want to repeatedly open chests
; - speed up the bot by all ways possible (since it casts shouts it's always lagging behind)
;		- using a cupcake and a pumpkin pie might be a good idea

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $FOLLOWER_INFORMATIONS = 'This bot makes your character follow the first other player in party.' & @CRLF _
	& 'It will attack everything that gets in range.' & @CRLF _
	& 'It will loot all items it can loot.' & @CRLF _
	& 'It will also loot all chests in range.'

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
				;FollowerLoop(DefaultRun, ParagonFight)
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
Func FollowerLoop($RunFunction = DefaultRun, $FightFunction = DefaultFight)
	Local Static $firstPlayer = Null, $currentMap = Null
	; Whenever player travels to a new explorable location, then current map ID is saved and first player agent is refreshed, because changing location can change agent ID of player
	If GetMapID() <> $currentMap Then
		$firstPlayer = GetFirstPlayerOfParty()
		$currentMap = GetMapID()
	EndIf
	$RunFunction()
	GoPlayer($firstPlayer)
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	If $foesCount > 0 Then
		Debug('Foes in range detected, starting fight')
		While IsPlayerAlive() And $foesCount > 0
			$FightFunction()
			$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
		WEnd
		Debug('Fight is over')
	EndIf
	FindAndOpenChests()

	If CountSlots(1, $bags_count) > 0 Then PickUpItems(Null, DefaultShouldPickItem, 1500)

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
	Local $Wild_Blow = 1
	Local $Soldiers_Strike = 2
	Local $Desperation_Blow = 3
	Local $Run_As_One = 4
	Local $Together_As_One = 5
	Local $Never_Rampage_Alone = 6
	Local $Ebon_Battle_Standard_Of_Honor = 7
	Local $Comfort_Animal = 8

	$follower_maintain_skill_1 = $Together_As_One
	$follower_maintain_skill_2 = $Ebon_Battle_Standard_Of_Honor
	$follower_maintain_skill_3 = $Run_As_One
	$follower_maintain_skill_4 = $Never_Rampage_Alone
	$follower_attack_skill_1 = $Wild_Blow
	$follower_attack_skill_2 = $Soldiers_Strike
	$follower_attack_skill_3 = $Desperation_Blow
	$follower_running_skill = $Run_As_One
EndFunc


;~ Paragon follower setup
Func ParagonSetup()
	Info('Paragon setup - Heroic Refrain')

	Local $Heroic_Refrain = 8
	;Local $Aggressive_Refrain = 7
	Local $Burning_Refrain = 7
	Local $For_Great_Justice = 6
	Local $To_The_Limit = 5
	Local $Save_Yourselves = 4
	Local $Theres_Nothing_To_Fear = 3
	Local $Stand_Your_Ground = 2
	Local $Theyre_On_Fire = 1

	$follower_maintain_skill_1 = $Heroic_Refrain
	$follower_maintain_skill_2 = $Burning_Refrain
	$follower_maintain_skill_3 = $For_Great_Justice
	$follower_maintain_skill_4 = $To_The_Limit
	$follower_maintain_skill_5 = $Save_Yourselves
	$follower_maintain_skill_6 = $Theres_Nothing_To_Fear
	$follower_maintain_skill_7 = $Stand_Your_Ground
	$follower_maintain_skill_8 = $Theyre_On_Fire

	AdlibRegister('ParagonRefreshShouts', 12000)
	;AdlibUnRegister()
EndFunc


;~ Paragon function to cast shouts on all party members
Func ParagonRefreshShouts()
	Info('Refresh shouts on party')
	Local Static $selfRecast = False
	MoveToMiddleOfPartyWithTimeout(5000)
	RandomSleep(20)
	Local $partyMembers = GetPartyInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	If UBound($partyMembers) < 4 Then Return

	UseSkillEx($follower_maintain_skill_8)
	RandomSleep(20)
	If ($selfRecast Or GetEffectTimeRemaining(GetEffect($ID_HEROIC_REFRAIN)) == 0) And GetEnergy() > 15 Then
		UseSkillEx($follower_maintain_skill_1, GetMyAgent())
		RandomSleep(20)
		If $selfRecast Then
			UseSkillEx($follower_maintain_skill_2, GetMyAgent())
			RandomSleep(20)
			$selfRecast = False
		Else
			$selfRecast = True
		EndIf
	Else
		$party = GetParty()

		Local $ownID = DllStructGetData(GetMyAgent(), 'ID')

		; This solution is imperfect because we recast HR every time
		Local Static $i = 1
		If UBound($party) > 1 Then
			If DllStructGetData($party[$i], 'ID') == $ownID Or $i > UBound($party) Then $i = Mod($i, UBound($party)) + 1
			If GetEnergy() > 15 Then
				UseSkillEx($follower_maintain_skill_1, $party[$i])
				RandomSleep(20)
			EndIf
			If GetEnergy() > 20 Then
				UseSkillEx($follower_maintain_skill_2, $party[$i])
				RandomSleep(20)
			EndIf
			$i = Mod($i, UBound($party)) + 1
		EndIf

		; This solution would be better - but effects can't be accessed on other heroes/characters
		;Local $HeroNumber
		;For $member In $party
		;	If DllStructGetData($member, 'ID') == $ownID Then ContinueLoop
		;	$HeroNumber = GetHeroNumberByAgentID(DllStructGetData($member, 'ID'))
		;	If ($HeroNumber == Null Or GetEffectTimeRemaining(GetEffect($ID_HEROIC_REFRAIN), $HeroNumber) == 0) And GetEnergy() > 15 Then
		;		UseSkillEx($follower_maintain_skill_1, $member)
		;		RandomSleep(GetPing() + 20)
		;		ExitLoop
		;	EndIf
		;	If ($HeroNumber == Null Or GetEffectTimeRemaining(GetEffect($ID_BURNING_REFRAIN), $HeroNumber) == 0) And GetEnergy() > 20 Then
		;		UseSkillEx($follower_maintain_skill_2, $member)
		;		RandomSleep(GetPing() + 20)
		;		ExitLoop
		;	EndIf
		;Next
	EndIf
EndFunc


;~ Paragon fight function
Func ParagonFight()
	If IsRecharged($follower_maintain_skill_7) Then UseSkillEx($follower_maintain_skill_7)
	RandomSleep(GetPing() + 20)
	If IsRecharged($follower_maintain_skill_6) Then UseSkillEx($follower_maintain_skill_6)
	RandomSleep(GetPing() + 20)
	If IsRecharged($follower_maintain_skill_3) Then UseSkillEx($follower_maintain_skill_3)
	RandomSleep(GetPing() + 20)
	If GetSkillbarSkillAdrenaline($follower_maintain_skill_5) < 200 And IsRecharged($follower_maintain_skill_4) Then UseSkillEx($follower_maintain_skill_4)
	RandomSleep(GetPing() + 20)
	If GetSkillbarSkillAdrenaline($follower_maintain_skill_5) == 200 Then UseSkillEx($follower_maintain_skill_5)
	RandomSleep(GetPing() + 20)
	Attack(GetNearestEnemyToAgent(GetMyAgent()))
	RandomSleep(1000)
EndFunc


;~ Get first player of the party team other than yourself. If no other player found in the party team then function returns Null
Func GetFirstPlayerOfParty()
	Local $party = GetParty()
	Local $ownID = DllStructGetData(GetMyAgent(), 'ID')
	Local $firstPlayer = Null
	For $member In $party
		If DllStructGetData($member, 'ID') == $ownID Then ContinueLoop
		Local $HeroNumber = GetHeroNumberByAgentID(DllStructGetData($member, 'ID'))
		If $HeroNumber == Null Then
			$firstPlayer = $member
			Return $firstPlayer
		EndIf
	Next
	Return Null
EndFunc