#include-once

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"
#include <File.au3>

; ==== Constantes ====
Local Const $SpiritSlaves_Skillbar = "OgCjkOrMLTmXfXfbkXcX0k5iibA"
Local Const $SpiritSlavesFarmInformations = "For best results, have :" & @CRLF _
	& "- 16 Earth Prayers" &@CRLF _
	& "- 13 Mysticism" & @CRLF _
	& "- 4 Scythe Mastery" & @CRLF _
	& "- Windwalker insignias"& @CRLF _
	& "- A scythe of enchanting q4 or less with the inscription 'I have the power' (+5 energy)" & @CRLF _
	& "- any PCons you wish to use"

Local $SpiritSlaves_Farm_Setup = False

Local $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Local Const $SS_Sand_Shards = 1
Local Const $SS_Mystic_Vigor  = 2
Local Const $SS_Vow_of_Strength = 3
Local Const $SS_Extend_Enchantments = 4
Local Const $SS_Mirage_Cloak = 5
Local Const $SS_I_am_unstoppable = 6
Local Const $SS_Ebon_Battle_Standard_of_Honor = 7
Local Const $SS_Heart_of_Fury = 8


;~ Main loop of the farm
Func SpiritSlavesFarm($STATUS)
	$loggingFile = FileOpen("spiritslaves_farm.log" , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	If CountSlots() < 5 Then
		Out("Inventory full, pausing.")
		Return 2
	EndIf
	
	If $STATUS <> "RUNNING" Then Return
	
	While Not($SpiritSlaves_Farm_Setup) 
		SpiritSlavesFarmSetup()
	WEnd
	
	If $STATUS <> "RUNNING" Then Return

	Out("Killing group 1 @ North")
	FarmNorthGroup()
	Out("Killing group 2 @ South")
	FarmSouthGroup()
	Out("Killing group 3 @ South")
	FarmSouthGroup()
	Out("Killing group 4 @ North")
	FarmNorthGroup()
	Out("Killing group 5 @ North")
	FarmNorthGroup()


	Out("Moving out of the zone and back again")
	RezoneToTheShatteredRavines()

	FileClose($loggingFile)
	Return 0
EndFunc


;~ Farm setup : going to the Shattered Ravines
Func SpiritSlavesFarmSetup()
	If GetMapID() <> $ID_The_Shattered_Ravines Then
		If GetMapID() <> $ID_Bone_Palace Then
			Out("Travelling to Bone Palace")
			DistrictTravel($ID_Bone_Palace, $ID_EUROPE, $ID_FRENCH)
		EndIf
		SwitchMode($ID_HARD_MODE)
		LeaveGroup()

		; Exiting to Jokos Domain
		MoveTo(-14520, 6009)
		MoveTo(-14820, 3400)
		WaitMapLoading($ID_Jokos_Domain)
		RndSleep(500)
		MoveTo(-12657, 2609)
		MoveTo(-10938, 4254)
		; Going to wurm's spoor
		ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
		RndSleep(500)
		Out("Taking wurm")
		ActionInteract()
		RndSleep(1000)
		; Starting from there there might be enemies on the way
		MoveTo(-8255, 5320)
		If (CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST) > 0) Then	UseSkillEx(5)
		MoveTo(-8624, 10636)
		If (CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST) > 0) Then UseSkillEx(5)
		MoveTo(-8261, 12808)
		; Starting from there there definitely are enemies on the way
		Move(-3838, 19196)
		While Not GetIsDead(-2) And DllStructGetData(GetAgentByID(-2), "MoveX") <> 0 And DllStructGetData(GetAgentByID(-2), "MoveY") <> 0
			If (CountFoesInRangeOfAgent(-2, $RANGE_NEARBY) > 0 And IsRecharged(5)) Then UseSkillEx(5)
			RndSleep(500)
		WEnd
		
		; If dead it's not worth rezzing better just restart running
		If (GetIsDead(-2)) Then Return
		
		MoveTo(-4486, 19700)
		RndSleep(3000)
		MoveTo(-4486, 19700)

		; If dead it's not worth rezzing better just restart running
		If (GetIsDead(-2)) Then Return
		
		; Entering The Shattered Ravines
		Out("Entering The Shattered Ravines : careful")
		MoveTo(-4522, 20622)
		WaitMapLoading($ID_The_Shattered_Ravines, 10000, 2000)
		; Hurry up before dying
		MoveTo(-9714, -10767)
		MoveTo(-7919, -10530)
	EndIf
	$SpiritSlaves_Farm_Setup = True
EndFunc


;~ Rezoning to reset the farm
Func RezoneToTheShatteredRavines()
	Out("Rezoning")
	; Exiting to Jokos Domain
	MoveTo(-8056, -9293)
	MoveTo(-10656, -11293)
	WaitMapLoading($ID_Jokos_Domain)
	RndSleep(500)
	; Reentering The Shattered Ravines
	MoveTo(-4422, 19422)
	MoveTo(-4522, 20622)
	WaitMapLoading($ID_The_Shattered_Ravines)
	RndSleep(500)
	; Hurry up before dying
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
EndFunc


;~ Farm the north group (group 1, 4 and 5)
Func FarmNorthGroup()
	MoveTo(-7375, -7767)
	WaitForFoesBall()
	KillSequence(-8598, -5810)
EndFunc


;~ Farm the south group (group 2 and 3)
Func FarmSouthGroup()
	Move(-8000, -8900)
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
	Out("Waiting on aggro")
	; Wait until an enemy is aggroed
	While Not GetIsDead(-2) And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RndSleep(1000)
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
	WEnd
	Move(-8000, -8000)	;(-8219.03, -8150.75 alternative)
	KillSequence(-8068, -8870)
EndFunc


;~ Kill a mob group
Func KillSequence($posX, $posY)
	Out("Killing group")
	Local $targetFoe = GetNearestNPCInRangeOfCoords(3, $posX, $posY, $RANGE_SPELLCAST)
	GetAlmostInRangeOfAgent($targetFoe)
	UseSkillEx($SS_Sand_Shards)
	RndSleep(2500)
	UseSkillEx($SS_Mystic_Vigor)
	RndSleep(1000)
	UseSkillEx($SS_Vow_of_Strength)
	RndSleep(300)

	Local $positionToGo = FindMiddleOfFoes($posX, $posY)
	Local $temporaryPosition = GetTemporaryPosition(DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $positionToGo[0], $positionToGo[1])

	Move($positionToGo[0], $positionToGo[1])
	RndSleep(1000)
	UseSkillEx($SS_Extend_Enchantments)
	RndSleep(500)
	UseSkillEx($SS_Mirage_Cloak)
	UseSkillEx($SS_I_am_unstoppable)
	Move($temporaryPosition[0], $temporaryPosition[1])
	RndSleep(1000)
	Move($positionToGo[0], $positionToGo[1])
	RndSleep(1000)
	
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	; Wait until all foes are around
	While Not GetIsDead(-2) And $foesCount < 8 And TimerDiff($deadlock) < 3000
		RndSleep(200)
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	WEnd
	UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RndSleep(1100)

	While Not GetIsDead(-2) And $foesCount > 0 And TimerDiff($deadlock) < 100000
		If IsRecharged($SS_Mystic_Vigor) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Vigor)) == 0 Then
			UseSkillEx($SS_Mystic_Vigor)
			RndSleep(300)
		EndIf
		If IsRecharged($SS_Mirage_Cloak) And GetEffectTimeRemaining(GetEffect($ID_Mirage_Cloak)) == 0 Then
			UseSkillEx($SS_Extend_Enchantments)
			RndSleep(20)
			UseSkillEx($SS_Mirage_Cloak)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_I_am_unstoppable) Then
			UseSkillEx($SS_I_am_unstoppable)
			RndSleep(20)
		EndIf
		If GetSkillbarSkillAdrenaline($SS_Heart_of_Fury) = 80 Then
			UseSkillEx($SS_Heart_of_Fury)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_Sand_Shards) Then
			UseSkillEx($SS_Sand_Shards)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_Ebon_Battle_Standard_of_Honor) And GetEnergy($me) > 9 Then
			UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
			RndSleep(1100)
		EndIf
		TargetNearestEnemy()
		AttackOrUseSkill(1250, $SS_Vow_of_Strength, 300)
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_SPELLCAST)
	WEnd
	Out("Looting")
	PickUpItems()
EndFunc


Func FindMiddleOfFoes($posX, $posY)
	Local $position[2] = [0, 0]
	Local $foes = GetFoesInRangeOfCoords($posX, $posY, $RANGE_SPELLCAST)
	Local $foe
	For $i = 1 To $foes[0]
		$foe = $foes[$i]
		$position[0] += DllStructGetData($foe, 'X')
		$position[1] += DllStructGetData($foe, 'Y')
	Next
	$position[0] = $position[0] / $foes[0]
	$position[1] = $position[1] / $foes[0]
	Return $position
EndFunc


Func GetTemporaryPosition($startX, $startY, $endX, $endY)
	Local $distanceStartToEnd = ComputeDistance($startX, $startY, $endX, $endY)
	Local $xMovement = $endX - $startX
	Local $yMovement = $endY - $startY
	; To rotate a movement to the right: Y1 = -X0, X1 = Y0
	; That gives us the 90° movement, add it to the original and you get a 45° angle
	; Reduce it by 2 to have the correct length
	Local $xMove45degrees = ($xMovement + $yMovement) / 2
	Local $yMove45degrees = ($yMovement - $xMovement) / 2
	Local $temporaryPosition[2] = [$startX + $xMove45degrees, $startY + $yMove45degrees]
	Return $temporaryPosition
EndFunc


;~ Wait for all ennemies to be balled
Func WaitForFoesBall()
	WaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8598, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0
	
	; Wait until all foes are balled
	While Not GetIsDead(-2) And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RndSleep(3000)
		$target = GetNearestEnemyToCoords(-8598, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		Out("foes: " & $foesCount & "/" & $totalFoesCount)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out("Timed out waiting for mobs to ball")
	Out("Mobs balled")
EndFunc


;~ Wait for all ennemies to be balled and allies to be dead
Func WaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	; Wait until foes are in range of allies
	While ComputeDistance(-8598, -5810, DllStructGetData($target, 'X'), DllStructGetData($target, 'Y')) < $RANGE_SPELLCAST And TimerDiff($deadlock) < 120000
		RndSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out("Timed out waiting for allies to be dead")
	Out("Allies all died")
EndFunc