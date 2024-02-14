#include-once

#include "GWA2.au3"
#include "GWA2_Headers.au3"
#include "GWA2_ID.au3"
#include "Utils.au3"
#include <File.au3>

; ==== Constantes ====
Local Const $SpiritSlaves_Skillbar = "OgejkOrMLTmXfXfb0kkX4OcX5iA"
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
Local Const $SS_I_am_unstoppable = 2
Local Const $SS_Mystic_Vigor  = 3
Local Const $SS_Vow_of_Strength = 4
Local Const $SS_Extend_Enchantments = 5
Local Const $SS_Deaths_Charge = 6
Local Const $SS_Mirage_Cloak = 7
Local Const $SS_Ebon_Battle_Standard_of_Honor = 8
;Local Const $SS_Heart_of_Fury = 8


;~ Main loop of the farm
Func SpiritSlavesFarm($STATUS)
	$loggingFile = FileOpen("logs/spiritslaves_farm.log" , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	If CountSlots() < 5 Then
		Out("Inventory full, pausing.")
		Return 2
	EndIf
		
	While Not($SpiritSlaves_Farm_Setup) 
		SpiritSlavesFarmSetup()
	WEnd
	
	If $STATUS <> "RUNNING" Then Return

	UseConsumable($ID_Slice_of_Pumpkin_Pie)

	Out("Killing group 1 @ North")
	FarmNorthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out("Killing group 2 @ South")
	FarmSouthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out("Killing group 3 @ South")
	FarmSouthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out("Killing group 4 @ North")
	FarmNorthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out("Killing group 5 @ North")
	FarmNorthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()

	Out("Moving out of the zone and back again")
	Move(-7735, -8380)
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
		ChangeWeaponSet(2)
		MoveTo(-10938, 4254)
		; Going to wurm's spoor
		ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
		RndSleep(500)
		Out("Taking wurm")
		ActionInteract()
		RndSleep(1000)
		; Starting from there there might be enemies on the way
		MoveTo(-8255, 5320)
		If (CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT) > 0) Then	UseSkillEx(5)
		MoveTo(-8624, 10636)
		If (CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
		MoveTo(-8261, 12808)
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
		ChangeWeaponSet(1)
		Out("Entering The Shattered Ravines : careful")
		MoveTo(-4500, 20150)
		MoveTo(-4500, 21000)
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
	MoveTo(-7800, -10250)
	MoveTo(-9000, -10900)
	MoveTo(-10500, -11000)
	MoveTo(-10656, -11293)
	WaitMapLoading($ID_Jokos_Domain)
	RndSleep(500)
	; Reentering The Shattered Ravines
	MoveTo(-4500, 20150)
	MoveTo(-4500, 21000)
	WaitMapLoading($ID_The_Shattered_Ravines, 10000, 2000)
	; Hurry up before dying
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
EndFunc


;~ Farm the north group (group 1, 4 and 5)
Func FarmNorthGroup()
	MoveTo(-7375, -7767)
	WaitForFoesBall()
	WaitForEnergy()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(3, -8598, -5810, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	UseSkillEx($SS_Sand_Shards)
	RndSleep(3500)
	UseSkillEx($SS_I_am_unstoppable)
	RndSleep(3500)
	UseSkillEx($SS_Mystic_Vigor)
	RndSleep(300)
	UseSkillEx($SS_Vow_of_Strength)
	RndSleep(20)
	UseSkillEx($SS_Extend_Enchantments)
	RndSleep(20)
	If (GetIsDead(-2)) Then Return
	
	Local $positionToGo = FindMiddleOfFoes(-8598, -5810, $RANGE_AREA)
	$targetFoe = BetterGetNearestNPCToCoords(3, $positionToGo[0], $positionToGo[1], $RANGE_EARSHOT)

	UseSkillEx($SS_Deaths_Charge, $targetFoe)
	RndSleep(20)
	UseSkillEx($SS_Mirage_Cloak)
	RndSleep(20)
	UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RndSleep(20)
	
	If (GetIsDead(-2)) Then Return

	KillSequence()
EndFunc


;~ Farm the south group (group 2 and 3)
Func FarmSouthGroup()
	MoveTo(-7830, -7860)
	; Wait until an enemy is past the correct aggro line
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
	Local $deadlock = TimerInit()
	While Not GetIsDead(-2) And $foesCount < 8 And TimerDiff($deadlock) < 120000
		RndSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
	WEnd

	;We want foes between -8055;-9200 and -8055;-9300
	Move(-7735, -8380)
	$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
	$deadlock = TimerInit()
	; Wait until an enemy is aggroed
	While Not GetIsDead(-2) And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RndSleep(100)
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
	WEnd
	If (GetIsDead(-2)) Then Return

	MoveTo(-7830, -7860, 0)
	
	UseSkillEx($SS_Sand_Shards)
	RndSleep(2000)
	UseSkillEx($SS_Mystic_Vigor)
	RndSleep(750)
	UseSkillEx($SS_Vow_of_Strength)
	RndSleep(200)
	
	If (GetIsDead(-2)) Then Return
		
	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	Local $targetFoe = BetterGetNearestNPCToCoords(3, $positionToGo[0], $positionToGo[1], $RANGE_SPELLCAST)
	UseSkillEx($SS_I_am_unstoppable)
	RndSleep(20)
	UseSkillEx($SS_Extend_Enchantments)
	RndSleep(20)
	UseSkillEx($SS_Deaths_Charge, $targetFoe)
	RndSleep(20)
	UseSkillEx($SS_Mirage_Cloak)
	RndSleep(20)
	UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RndSleep(20)
	
	If (GetIsDead(-2)) Then Return
	
	KillSequence()
EndFunc


;~ Kill a mob group
Func KillSequence()
	Out("Killing group")
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	
	While Not GetIsDead(-2) And $foesCount > 0 And TimerDiff($deadlock) < 100000
		If IsRecharged($SS_Mystic_Vigor) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Vigor)) == 0 Then
			UseSkillEx($SS_Mystic_Vigor)
			RndSleep(20)
		EndIf
		If $foesCount > 1 And IsRecharged($SS_Mirage_Cloak) And GetEffectTimeRemaining(GetEffect($ID_Mirage_Cloak)) == 0 Then
			UseSkillEx($SS_Extend_Enchantments)
			RndSleep(20)
			UseSkillEx($SS_Mirage_Cloak)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_I_am_unstoppable) Then
			UseSkillEx($SS_I_am_unstoppable)
			RndSleep(20)
		EndIf
		;If GetSkillbarSkillAdrenaline($SS_Heart_of_Fury) = 80 Then
		;	UseSkillEx($SS_Heart_of_Fury)
		;	RndSleep(20)
		;EndIf
		If $foesCount > 3 And IsRecharged($SS_Sand_Shards) And GetEffectTimeRemaining(GetEffect($ID_Sand_Shards)) == 0 Then
			UseSkillEx($SS_Sand_Shards)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_Ebon_Battle_Standard_of_Honor) And GetEnergy(-2) > 9 Then
			UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
			RndSleep(20)
		EndIf
		Local $casterSpirit = GetFurthestNPCToCoords(3, null, null, $RANGE_AREA)
		If $foesCount < 5 And GetDistance(-2, $casterSpirit) > $RANGE_ADJACENT Then
			ChangeTarget($casterSpirit)
		Else
			TargetNearestEnemy()
		EndIf
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
		If $foesCount > 0 Then AttackOrUseSkill(1000, $SS_Vow_of_Strength, 20)
	WEnd
	If (GetIsDead(-2)) Then Return
	CleanseFromCripple()
	Out("Looting")
	PickUpItems(CleanseFromCripple)
EndFunc


;~ Returns the coordinates in the middle of a group of foes
Func FindMiddleOfFoes($posX, $posY, $range)
	Local $position[2] = [0, 0]
	Local $nearestFoe = GetNearestEnemyToCoords($posX, $posY)
	Local $foes = GetFoesInRangeOfAgent($nearestFoe, $RANGE_AREA)
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
		Out("foes: " & $foesCount & "/8")
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out("Timed out waiting for mobs to ball")
	Out("Mobs balled")
EndFunc


;~ Wait for all ennemies to be balled and allies to be dead
Func WaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	; Wait until foes are in range of allies
	While ComputeDistance(-8598, -5810, DllStructGetData($target, 'X'), DllStructGetData($target, 'Y')) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RndSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out("Timed out waiting for allies to be dead")
	Out("Allies all died")
EndFunc


;~ Respawn and rezone if we die
Func RestartAfterDeath()
	Local $deadlockTimer = TimerInit()
	While GetIsDead(-2)
		Out("Waiting for resurrection")
		RndSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$SpiritSlaves_Farm_Setup = True
			Out("Travelling to Bone Palace")
			DistrictTravel($ID_Bone_Palace, $ID_EUROPE, $ID_FRENCH)
			Return 1
		EndIf
	WEnd
	RezoneToTheShatteredRavines()
	Return 1
EndFunc


;~ Wait to have enough energy before jumping into the next group
Func WaitForEnergy()
	While (GetEnergy(-2) < 20) And Not GetIsDead(-2)
		RndSleep(1000)
	WEnd
EndFunc


;~ Cleanse if the character has a condition (cripple)
Func CleanseFromCripple()
	If (GetHasCondition(-2)) Then UseSkillEx($SS_I_am_unstoppable)
EndFunc


;~ Give True if the given agent is past a specific line where we should take aggro
Func IsPastAggroLine($agent)
	Return Not IsOverLine(0, 7000, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc


;~ @Unused
;~ Unused but good learning practice ;)
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