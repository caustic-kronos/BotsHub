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

; Possible improvements :
; - Correct a crash happening when someone picks up items the bot wanted to pick up
; - Correct a bug that makes the bot want to repeatedly open chests
; - speed up the bot by all ways possible (since it casts shouts it's always lagging behind)
;		- using a cupcake and a pumpkin pie might be a good idea

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $FollowerInformations = 'This bot makes your character follow the first other player in party.' & @CRLF _
	& 'It will attack everything that gets in range.' & @CRLF _
	& 'It will loot all items it can loot.' & @CRLF _
	& 'It will also loot all chests in range.'

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain) is better than UseSkillEx(1))
Global $Player_Profession_ID
Global $Follower_AttackSkill1 = Null
Global $Follower_AttackSkill2 = Null
Global $Follower_AttackSkill3 = Null
Global $Follower_AttackSkill4 = Null
Global $Follower_AttackSkill5 = Null
Global $Follower_AttackSkill6 = Null
Global $Follower_AttackSkill7 = Null
Global $Follower_AttackSkill8 = Null
Global $Follower_MaintainSkill1 = Null
Global $Follower_MaintainSkill2 = Null
Global $Follower_MaintainSkill3 = Null
Global $Follower_MaintainSkill4 = Null
Global $Follower_MaintainSkill5 = Null
Global $Follower_MaintainSkill6 = Null
Global $Follower_MaintainSkill7 = Null
Global $Follower_MaintainSkill8 = Null
Global $Follower_RunningSkill = Null

Global $FOLLOWER_SETUP = False
Global $playerIDs

;~ Main loop
Func FollowerFarm($STATUS)
	If Not $FOLLOWER_SETUP Then FollowerSetup()

	While $STATUS == 'RUNNING' And CountSlots(1, $BAGS_COUNT) > 5
		Switch $Player_Profession_ID
			Case $ID_Warrior
				FollowerLoop()
			Case $ID_Ranger
				FollowerLoop()
			Case $ID_Monk
				FollowerLoop()
			Case $ID_Mesmer
				FollowerLoop()
			Case $ID_Necromancer
				FollowerLoop()
			Case $ID_Elementalist
				FollowerLoop()
			Case $ID_Ritualist
				FollowerLoop()
			Case $ID_Assassin
				FollowerLoop()
			Case $ID_Paragon
				FollowerLoop()
				;FollowerLoop(DefaultRun, ParagonFight)
			Case $ID_Dervish
				FollowerLoop()
			Case Else
				FollowerLoop()
		EndSwitch
	WEnd

	$FOLLOWER_SETUP = False
	AdlibUnRegister()
	Return $STATUS <> 'RUNNING' ? $PAUSE : $SUCCESS
EndFunc


;~ Follower setup
Func FollowerSetup()
	$Player_Profession_ID = GetHeroProfession(0, False)
	Info('Setting up follower bot')
	Switch $Player_Profession_ID
		Case $ID_Warrior
			DefaultSetup()
		Case $ID_Ranger
			RangerSetup()
		Case $ID_Monk
			DefaultSetup()
		Case $ID_Mesmer
			DefaultSetup()
		Case $ID_Necromancer
			DefaultSetup()
		Case $ID_Elementalist
			DefaultSetup()
		Case $ID_Ritualist
			DefaultSetup()
		Case $ID_Assassin
			DefaultSetup()
		Case $ID_Paragon
			DefaultSetup()
			;ParagonSetup()
		Case $ID_Dervish
			DefaultSetup()
		Case Else
			DefaultSetup()
	EndSwitch
	$FOLLOWER_SETUP = True
EndFunc


;~ Follower loop
Func FollowerLoop($RunFunction = DefaultRun, $FightFunction = DefaultFight)
	Local Static $firstPlayer = GetFirstPlayerOfParty()
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

	PickUpItems(Null, DefaultShouldPickItem, 1500)

	RandomSleep(1000)
EndFunc


;~ Default class setup
Func DefaultSetup()
	$Follower_AttackSkill1 = 1
	$Follower_AttackSkill2 = 2
	$Follower_AttackSkill3 = 3
	$Follower_AttackSkill4 = 4
	$Follower_AttackSkill5 = 5
	$Follower_AttackSkill6 = 6
	$Follower_AttackSkill7 = 7
	$Follower_AttackSkill8 = 8
EndFunc


;~ Default class run method
Func DefaultRun()
	If $Follower_RunningSkill <> Null And IsRecharged($Follower_RunningSkill) Then UseSkillEx($Follower_RunningSkill)
EndFunc


;~ Default class fight method
Func DefaultFight()
	AttackOrUseSkill(1000, $Follower_MaintainSkill1, $Follower_MaintainSkill2, $Follower_MaintainSkill3, $Follower_MaintainSkill4, $Follower_MaintainSkill5, $Follower_MaintainSkill6, $Follower_MaintainSkill7, $Follower_MaintainSkill8)
	AttackOrUseSkill(1000, $Follower_AttackSkill1, $Follower_AttackSkill2, $Follower_AttackSkill3, $Follower_AttackSkill4, $Follower_AttackSkill5, $Follower_AttackSkill6, $Follower_AttackSkill7, $Follower_AttackSkill8)
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

	$Follower_MaintainSkill1 = $Together_As_One
	$Follower_MaintainSkill2 = $Ebon_Battle_Standard_Of_Honor
	$Follower_MaintainSkill3 = $Run_As_One
	$Follower_MaintainSkill4 = $Never_Rampage_Alone
	$Follower_AttackSkill1 = $Wild_Blow
	$Follower_AttackSkill2 = $Soldiers_Strike
	$Follower_AttackSkill3 = $Desperation_Blow
	$Follower_RunningSkill = $Run_As_One
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

	$Follower_MaintainSkill1 = $Heroic_Refrain
	$Follower_MaintainSkill2 = $Burning_Refrain
	$Follower_MaintainSkill3 = $For_Great_Justice
	$Follower_MaintainSkill4 = $To_The_Limit
	$Follower_MaintainSkill5 = $Save_Yourselves
	$Follower_MaintainSkill6 = $Theres_Nothing_To_Fear
	$Follower_MaintainSkill7 = $Stand_Your_Ground
	$Follower_MaintainSkill8 = $Theyre_On_Fire

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

	UseSkillEx($Follower_MaintainSkill8)
	RandomSleep(20)
	If ($selfRecast Or GetEffectTimeRemaining(GetEffect($ID_Heroic_Refrain)) == 0) And GetEnergy() > 15 Then
		UseSkillEx($Follower_MaintainSkill1, GetMyAgent())
		RandomSleep(20)
		If $selfRecast Then
			UseSkillEx($Follower_MaintainSkill2, GetMyAgent())
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
				UseSkillEx($Follower_MaintainSkill1, $party[$i])
				RandomSleep(20)
			EndIf
			If GetEnergy() > 20 Then
				UseSkillEx($Follower_MaintainSkill2, $party[$i])
				RandomSleep(20)
			EndIf
			$i = Mod($i, UBound($party)) + 1
		EndIf

		; This solution would be better - but effects can't be accessed on other heroes/characters
		;Local $HeroNumber
		;For $member In $party
		;	If DllStructGetData($member, 'ID') == $ownID Then ContinueLoop
		;	$HeroNumber = GetHeroNumberByAgentID(DllStructGetData($member, 'ID'))
		;	If ($HeroNumber == Null Or GetEffectTimeRemaining(GetEffect($ID_Heroic_Refrain), $HeroNumber) == 0) And GetEnergy() > 15 Then
		;		UseSkillEx($Follower_MaintainSkill1, $member)
		;		RandomSleep(GetPing() + 20)
		;		ExitLoop
		;	EndIf
		;	If ($HeroNumber == Null Or GetEffectTimeRemaining(GetEffect($ID_Burning_Refrain), $HeroNumber) == 0) And GetEnergy() > 20 Then
		;		UseSkillEx($Follower_MaintainSkill2, $member)
		;		RandomSleep(GetPing() + 20)
		;		ExitLoop
		;	EndIf
		;Next
	EndIf
EndFunc


;~ Paragon fight function
Func ParagonFight()
	If IsRecharged($Follower_MaintainSkill7) Then UseSkillEx($Follower_MaintainSkill7)
	RandomSleep(GetPing() + 20)
	If IsRecharged($Follower_MaintainSkill6) Then UseSkillEx($Follower_MaintainSkill6)
	RandomSleep(GetPing() + 20)
	If IsRecharged($Follower_MaintainSkill3) Then UseSkillEx($Follower_MaintainSkill3)
	RandomSleep(GetPing() + 20)
	If GetSkillbarSkillAdrenaline($Follower_MaintainSkill5) < 200 And IsRecharged($Follower_MaintainSkill4) Then UseSkillEx($Follower_MaintainSkill4)
	RandomSleep(GetPing() + 20)
	If GetSkillbarSkillAdrenaline($Follower_MaintainSkill5) == 200 Then UseSkillEx($Follower_MaintainSkill5)
	RandomSleep(GetPing() + 20)
	Attack(GetNearestEnemyToAgent(GetMyAgent()))
	RandomSleep(1000)
EndFunc


;~ Get first player of the party team other than yourself. If no other player found in the party team then function returns Null
Func GetFirstPlayerOfParty()
	Local $party = GetParty()
	Local $ownID = DllStructGetData(GetMyAgent(), 'ID')
	Local $firstPlayer
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