#CS
#################################
#								#
#	Follower Bot				#
#								#
#################################
Author: Night
#CE

#include-once
#RequireAdmin
#NoTrayIcon

#include 'GWA2_Headers.au3'
#include 'GWA2.au3'
#include 'Utils.au3'

; Possible improvements :
; - Correct a crash happening when someone picks up items the bot wanted to pick up
; - Correct a bug that makes the bot want to repeatedly open chests
; - speed up the bot by all ways possible (since it casts shouts it's always lagging behind)
;		- using a cupcake and a pumpkin pie might be a good idea

Opt('MustDeclareVars', 1)

Local Const $FollowerBotVersion = '0.1'

; ==== Constantes ====
Local Const $FollowerSkillbar = 'OgcTcZ88Z6u844AiHRnJuE3R4AA'
Local Const $FollowerInformations = 'This bot makes your character follow the player at position 1 in group.' & @CRLF _
	& 'It will also attack everything that gets in range.'
	
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Raptors_MarkOfPain)  is better than UseSkillEx(1))
Local $Player_Profession_ID
Local $Follower_AttackSkill1 = null
Local $Follower_AttackSkill2 = null
Local $Follower_AttackSkill3 = null
Local $Follower_AttackSkill4 = null
Local $Follower_AttackSkill5 = null
Local $Follower_AttackSkill6 = null
Local $Follower_AttackSkill7 = null
Local $Follower_AttackSkill8 = null
Local $Follower_MaintainSkill1 = null
Local $Follower_MaintainSkill2 = null
Local $Follower_MaintainSkill3 = null
Local $Follower_MaintainSkill4 = null
Local $Follower_MaintainSkill5 = null
Local $Follower_MaintainSkill6 = null
Local $Follower_MaintainSkill7 = null
Local $Follower_MaintainSkill8 = null
Local $Follower_RunningSkill = null

Local $FollowerFarmSetup = False
Local $playerIDs

;~ Main loop
Func FollowerFarm($STATUS)
	If Not $FollowerFarmSetup Then FollowerSetup()
	
	While $STATUS == 'RUNNING' And CountSlots() > 5
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
			Case else
				FollowerLoop()
		EndSwitch
	WEnd
	
	$FollowerFarmSetup = False
	AdlibUnRegister()

	If $STATUS <> 'RUNNING' Then Return 2
	Return 0
EndFunc


Func FollowerSetup()
	$Player_Profession_ID = GetHeroProfession(0, False)
	Out('Setting up follower bot')
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
		Case else
			DefaultSetup()
    EndSwitch
	$FollowerFarmSetup = True
EndFunc


Func FollowerLoop($RunFunction = DefaultRun, $FightFunction = DefaultFight)
	Local Static $firstPlayerID = GetFirstPlayerOfGroupID()
	$RunFunction()
	GoPlayer($firstPlayerID)
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
	If $foesCount > 0 Then
		Out('Foes in range detected, starting fight')
		While Not GetIsDead(-2) And $foesCount > 0
			$FightFunction()
			$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
		WEnd
		Out('Fight is over')
	EndIf
	CheckForChests()

	IF (GUICtrlRead($LootNothingCheckbox) == $GUI_UNCHECKED) Then
		PickUpItems(null, DefaultShouldPickItem, 1500)
	EndIf

	RndSleep(1000)
EndFunc


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


Func DefaultRun()
	If $Follower_RunningSkill <> null And IsRecharged($Follower_RunningSkill) Then UseSkillEx($Follower_RunningSkill)
EndFunc


Func DefaultFight()
	AttackOrUseSkill(1000, $Follower_MaintainSkill1, $Follower_MaintainSkill2, $Follower_MaintainSkill3, $Follower_MaintainSkill4, $Follower_MaintainSkill5, $Follower_MaintainSkill6, $Follower_MaintainSkill7, $Follower_MaintainSkill8)
	AttackOrUseSkill(1000, $Follower_AttackSkill1, $Follower_AttackSkill2, $Follower_AttackSkill3, $Follower_AttackSkill4, $Follower_AttackSkill5, $Follower_AttackSkill6, $Follower_AttackSkill7, $Follower_AttackSkill8)
EndFunc


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


Func ParagonSetup()
	Out('Paragon setup - Heroic Refrain')

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


Func ParagonRefreshShouts()
	Out('Refresh shouts on group')
	Local Static $selfRecast = False
	MoveToMiddleOfGroupWithTimeout(5000)
	RndSleep(20)
	Local $partyMembers = GetPartyInRangeOfAgent(-2, $RANGE_SPELLCAST)
	If $partyMembers[0] < 4 Then Return
	
	UseSkillEx($Follower_MaintainSkill8)
	RndSleep(20)
	If ($selfRecast Or GetEffectTimeRemaining(GetEffect($ID_Heroic_Refrain)) == 0) And GetEnergy(-2) > 15 Then
		UseSkillEx($Follower_MaintainSkill1, -2)
		RndSleep(20)
		If $selfRecast Then
			UseSkillEx($Follower_MaintainSkill2, -2)
			RndSleep(20)
			$selfRecast = False
		Else
			$selfRecast = True
		EndIf
	Else
		$partyMembers = GetParty()

		Local $ownID = DllStructGetData(GetAgentByID(-2), 'ID')

		;This solution is imperfect because we recast HR every time
		Local Static $i = 1
		If $partyMembers[0] > 1 Then
			If DllStructGetData($partyMembers[$i], 'ID') == $ownID Or $i > $partyMembers[0] Then $i = Mod($i, $partyMembers[0]) + 1
			If GetEnergy(-2) > 15 Then
				UseSkillEx($Follower_MaintainSkill1, $partyMembers[$i])
				RndSleep(20)
			EndIf
			If GetEnergy(-2) > 20 Then
				UseSkillEx($Follower_MaintainSkill2, $partyMembers[$i])
				RndSleep(20)
			EndIf
			$i = Mod($i, $partyMembers[0]) + 1
		EndIf
		
		;This solution would be better - but effects can't be accessed on other heroes/characters
		;Local $HeroNumber
		;For $i = 1 To $partyMembers[0]
		;	If DllStructGetData($partyMembers[$i], 'ID') == $ownID Then ContinueLoop
		;	$HeroNumber = GetHeroNumberByAgentID(DllStructGetData($partyMembers[$i], 'ID'))
		;	If ($HeroNumber == 0 Or GetEffectTimeRemaining(GetEffect($ID_Heroic_Refrain), $HeroNumber) == 0) And GetEnergy(-2) > 15 Then
		;		UseSkillEx($Follower_MaintainSkill1, $partyMembers[$i])
		;		RndSleep(GetPing() + 20)
		;		ExitLoop
		;	EndIf
		;	If ($HeroNumber == 0 Or GetEffectTimeRemaining(GetEffect($ID_Burning_Refrain), $HeroNumber) == 0) And GetEnergy(-2) > 20 Then
		;		UseSkillEx($Follower_MaintainSkill2, $partyMembers[$i])
		;		RndSleep(GetPing() + 20)
		;		ExitLoop
		;	EndIf
		;Next
	EndIf
EndFunc


Func ParagonFight()
	If IsRecharged($Follower_MaintainSkill7) Then UseSkillEx($Follower_MaintainSkill7)
	RndSleep(GetPing() + 20)
	If IsRecharged($Follower_MaintainSkill6) Then UseSkillEx($Follower_MaintainSkill6)
	RndSleep(GetPing() + 20)
	If IsRecharged($Follower_MaintainSkill3) Then UseSkillEx($Follower_MaintainSkill3)
	RndSleep(GetPing() + 20)
	If GetSkillbarSkillAdrenaline($Follower_MaintainSkill5) < 200 And IsRecharged($Follower_MaintainSkill4) Then UseSkillEx($Follower_MaintainSkill4)
	RndSleep(GetPing() + 20)
	If GetSkillbarSkillAdrenaline($Follower_MaintainSkill5) == 200 Then UseSkillEx($Follower_MaintainSkill5)
	RndSleep(GetPing() + 20)
	Attack(GetNearestEnemyToAgent(-2))
	RndSleep(1000)
EndFunc


Func GetFirstPlayerOfGroupID()
	Local $partyMembers = GetParty()
	Local $ownID = DllStructGetData(GetAgentByID(-2), 'ID')
	Local $firstPlayerID = 0
	For $i = 1 To $partyMembers[0]
		If DllStructGetData($partyMembers[$i], 'ID') == $ownID Then ContinueLoop
		Local $HeroNumber = GetHeroNumberByAgentID(DllStructGetData($partyMembers[$i], 'ID'))
		If $HeroNumber == 0 Then
			$firstPlayerID = DllStructGetData($partyMembers[$i], 'ID')
			ExitLoop
		EndIf
	Next
	Return $firstPlayerID
EndFunc


;~ Returns the coordinates in the middle of the group
Func FindMiddleOfGroup()
	Local $position[2] = [0, 0]
	Local $partyMembers = GetParty()
	Local $partySize = 0
	Local $ownID = DllStructGetData(GetAgentByID(-2), 'ID')
	For $i = 1 To $partyMembers[0]
		If GetDistance(-2, $partyMembers[$i]) < $RANGE_SPIRIT And DllStructGetData($partyMembers[$i], 'ID') <> $ownID Then 
			$position[0] += DllStructGetData($partyMembers[$i], 'X')
			$position[1] += DllStructGetData($partyMembers[$i], 'Y')
			$partySize += 1
		EndIf
	Next
	$position[0] = $position[0] / $partySize
	$position[1] = $position[1] / $partySize
	Return $position
EndFunc


;~ Move to a location in a limited time
Func MoveToMiddleOfGroupWithTimeout($timeOut)
	Local $lMe
	Local $lMapLoadingOld, $lMapLoading = GetMapLoading()
	Local $timer = TimerInit()
	Local $position = FindMiddleOfGroup()
	Move($position[0], $position[1], 0)
	While ComputeDistance(DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $position[0], $position[1]) > $RANGE_ADJACENT And TimerDiff($timer) > $timeOut
		If GetIsDead(-2) Then ExitLoop
		$lMapLoadingOld = $lMapLoading
		$lMapLoading = GetMapLoading()
		If $lMapLoading <> $lMapLoadingOld Then ExitLoop
		$position = FindMiddleOfGroup()
		Sleep(200)
	WEnd
EndFunc