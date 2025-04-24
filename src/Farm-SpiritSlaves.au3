; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include-once

#include '../lib/GWA2.au3'
#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'
#include <File.au3>

; ==== Constantes ====
Local Const $SpiritSlaves_Skillbar = 'OgejkOrMLTmXfXfb0kkX4OcX5iA'
Local Const $SpiritSlavesFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 Earth Prayers' &@CRLF _
	& '- 13 Mysticism' & @CRLF _
	& '- 4 Scythe Mastery' & @CRLF _
	& '- Windwalker insignias'& @CRLF _
	& '- Anything of enchanting without zealous on slot 1' & @CRLF _
	& '- A scythe of enchanting q4 or less with zealous mod on slot 2' & @CRLF _
	& '- Anything defensive on slot 4' & @CRLF _
	& '- any PCons you wish to use' & @CRLF _
	& '- the quest Destroy the Ungrateful Slaves not completed' & @CRLF _
	& 'Note: the farm works less efficiently during events because of the amount of loot'

Local $SPIRIT_SLAVES_FARM_SETUP = False

Local $loggingFile

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Local Const $SS_Sand_Shards = 1
Local Const $SS_I_am_unstoppable = 2
Local Const $SS_Mystic_Vigor = 3
Local Const $SS_Vow_of_Strength = 4
Local Const $SS_Extend_Enchantments = 5
Local Const $SS_Deaths_Charge = 6
Local Const $SS_Mirage_Cloak = 7
Local Const $SS_Ebon_Battle_Standard_of_Honor = 8
;Local Const $SS_Heart_of_Fury = 8

; Reduction from mysticism (50%) and increase from spirit (30%) are included
Local Const $SS_SkillsArray =		[$SS_Sand_Shards,	$SS_I_am_unstoppable,	$SS_Mystic_Vigor,	$SS_Vow_of_Strength,	$SS_Extend_Enchantments,	$SS_Deaths_Charge,	$SS_Mirage_Cloak,	$SS_Ebon_Battle_Standard_of_Honor]
Local Const $SS_SkillsCostsArray =	[7,					7,						4,					4,						7,							7,					7,					13]
Local Const $skillCostsMap = MapFromArrays($SS_SkillsArray, $SS_SkillsCostsArray)


;~ Main loop of the farm
Func SpiritSlavesFarm($STATUS)
	$loggingFile = FileOpen(@ScriptDir & '/logs/spiritslaves_farm.log' , $FO_APPEND + $FO_CREATEPATH + $FO_UTF8)

	While Not($SPIRIT_SLAVES_FARM_SETUP)
		SpiritSlavesFarmSetup()
	WEnd

	If $STATUS <> 'RUNNING' Then Return 2

	UseConsumable($ID_Slice_of_Pumpkin_Pie)

	Out('Killing group 1 @ North')
	FarmNorthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out('Killing group 2 @ South')
	FarmSouthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out('Killing group 3 @ South')
	FarmSouthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out('Killing group 4 @ North')
	FarmNorthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()
	Out('Killing group 5 @ North')
	FarmNorthGroup()
	If (GetIsDead(-2)) Then Return RestartAfterDeath()

	Out('Moving out of the zone and back again')
	Move(-7735, -8380)
	RezoneToTheShatteredRavines()

	FileClose($loggingFile)
	Return 0
EndFunc


;~ Farm setup : going to the Shattered Ravines
Func SpiritSlavesFarmSetup()
	If GetMapID() <> $ID_The_Shattered_Ravines Then
		If GetMapID() <> $ID_Bone_Palace Then
			Out('Travelling to Bone Palace')
			DistrictTravel($ID_Bone_Palace, $DISTRICT_NAME)
		EndIf
		SwitchMode($ID_HARD_MODE)
		LeaveGroup()

		LoadSkillTemplate($SpiritSlaves_Skillbar)
		SetDisplayedTitle($ID_Lightbringer_Title)

		; Exiting to Jokos Domain
		MoveTo(-14520, 6009)
		MoveTo(-14820, 3400)
		WaitMapLoading($ID_Jokos_Domain)
		RndSleep(500)
		MoveTo(-12657, 2609)
		ChangeWeaponSet(4)
		MoveTo(-10938, 4254)
		; Going to wurm's spoor
		ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
		RndSleep(500)
		Out('Taking wurm')
		ActionInteract()
		RndSleep(1500)
		UseSkillEx(5)
		; Starting from there there might be enemies on the way
		MoveTo(-8255, 5320)
		If (CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
		MoveTo(-8624, 10636)
		If (CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
		MoveTo(-8261, 12808)
		Move(-3838, 19196)
		While Not GetIsDead(-2) And DllStructGetData(GetAgentByID(-2), 'MoveX') <> 0 And DllStructGetData(GetAgentByID(-2), 'MoveY') <> 0
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
		Out('Entering The Shattered Ravines : careful')
		MoveTo(-4500, 20150)
		MoveTo(-4500, 21000)
		WaitMapLoading($ID_The_Shattered_Ravines, 10000, 2000)
		; Hurry up before dying
		MoveTo(-9714, -10767)
		MoveTo(-7919, -10530)
	EndIf
	$SPIRIT_SLAVES_FARM_SETUP = True
EndFunc


;~ Rezoning to reset the farm
Func RezoneToTheShatteredRavines()
	Out('Rezoning')
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
	MoveTo(-7375, -7767, 0)
	WaitForFoesBall()
	WaitForEnergy()
	WaitForDeathsCharge()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(3, -8598, -5810, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	ChangeWeaponSet(1)
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
	If GetEnergy(-2) > $skillCostsMap[$SS_Mirage_Cloak] Then UseSkillEx($SS_Mirage_Cloak)
	RndSleep(20)
	If GetEnergy(-2) > $skillCostsMap[$SS_Ebon_Battle_Standard_of_Honor] Then UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RndSleep(20)

	If (GetIsDead(-2)) Then Return

	KillSequence()
EndFunc


;~ Farm the south group (group 2 and 3)
Func FarmSouthGroup()
	CleanseFromCripple()
	MoveTo(-7830, -7860)
	CleanseFromCripple()
	; Wait until an enemy is past the correct aggro line
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
	Local $deadlock = TimerInit()
	While Not GetIsDead(-2) And $foesCount < 8 And TimerDiff($deadlock) < 120000
		RndSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
		CleanseFromCripple()
	WEnd
	CleanseFromCripple()
	; We want foes between -8055;-9200 and -8055;-9300
	Move(-7735, -8380)
	$foesCount = CountFoesInRangeOfAgent(-2, 950)
	$deadlock = TimerInit()
	; Wait until an enemy is aggroed
	While Not GetIsDead(-2) And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RndSleep(100)
		$foesCount = CountFoesInRangeOfAgent(-2, 950)
	WEnd
	If (GetIsDead(-2)) Then Return

	ChangeWeaponSet(1)
	MoveTo(-7800, -7680, 0)

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
	If GetEnergy(-2) > $skillCostsMap[$SS_Mirage_Cloak] Then UseSkillEx($SS_Mirage_Cloak)
	RndSleep(20)
	If GetEnergy(-2) > $skillCostsMap[$SS_Ebon_Battle_Standard_of_Honor] Then UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RndSleep(20)

	If (GetIsDead(-2)) Then Return

	KillSequence()
EndFunc


;~ Kill a mob group
Func KillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(-2, $RANGE_AREA)
	Local $casterFoePosition = [0,0,0,0]
	Local $casterFoesMap[]
	ChangeWeaponSet(2)
	While Not GetIsDead(-2) And $foesCount > 0 And TimerDiff($deadlock) < 100000
		If IsRecharged($SS_Mystic_Vigor) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Vigor)) == 0 And GetEnergy(-2) > $skillCostsMap[$SS_Mystic_Vigor] Then
			UseSkillEx($SS_Mystic_Vigor)
			RndSleep(20)
		EndIf
		If $foesCount > 1 And IsRecharged($SS_Mirage_Cloak) And GetEffectTimeRemaining(GetEffect($ID_Mirage_Cloak)) == 0 And GetEnergy(-2) > ($skillCostsMap[$SS_Extend_Enchantments] + $skillCostsMap[$SS_Mirage_Cloak]) Then
			UseSkillEx($SS_Extend_Enchantments)
			RndSleep(20)
			UseSkillEx($SS_Mirage_Cloak)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_I_am_unstoppable) And GetEnergy(-2) > $skillCostsMap[$SS_I_am_unstoppable] Then
			UseSkillEx($SS_I_am_unstoppable)
			RndSleep(20)
		EndIf
		If $foesCount > 3 And IsRecharged($SS_Sand_Shards) And GetEffectTimeRemaining(GetEffect($ID_Sand_Shards)) == 0 And GetEnergy(-2) > $skillCostsMap[$SS_Sand_Shards] Then
			UseSkillEx($SS_Sand_Shards)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_Ebon_Battle_Standard_of_Honor) And GetEffectTimeRemaining(GetEffect($ID_Ebon_Battle_Standard_of_Honor)) == 0 And GetEnergy(-2) > $skillCostsMap[$SS_Ebon_Battle_Standard_of_Honor] Then
			UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
			RndSleep(20)
		EndIf
		If IsRecharged($SS_Vow_of_Strength) And GetEnergy(-2) > $skillCostsMap[$SS_Vow_of_Strength] Then
			UseSkillEx($SS_Vow_of_Strength)
			RndSleep(20)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
		If $foesCount > 0 Then
			Local $casterFoe = GetFurthestNPCInRangeOfCoords(3, null, null, $RANGE_AREA + 88)
			Local $casterFoeId = DllStructGetData($casterFoe, 'ID')
			Local $distance = GetDistance(-2, $casterFoe)
			If $foesCount < 5 And GetDistance(-2, $casterFoe) > $RANGE_ADJACENT Then
				Out('One foe is distant')
				If $casterFoesMap[$casterFoeId] == null Then
					$casterFoesMap[$casterFoeId] = 0
				ElseIf $casterFoesMap[$casterFoeId] == 2 Then
					Out('Moving to fight that foe')
					Local $timer = TimerInit()
					;MoveAvoidingBodyBlock(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'X'), 1000)
					While Not GetIsDead(-2) And GetDistance(-2, $casterFoe) > $RANGE_ADJACENT And TimerDiff($timer) < 1000
						Move(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'Y'))
						RndSleep(100)
					WEnd
				EndIf
				$casterFoesMap[$casterFoeId] += 1
			EndIf
			Local $nearestFoe = GetNearestEnemyToAgent(-2)
			If GetDistance(-2, $nearestFoe) < $RANGE_AREA + 88 Then
				Attack($nearestFoe)
			EndIf
			RndSleep(1000)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(-2, $RANGE_EARSHOT)
	WEnd
	ChangeWeaponSet(1)

	If (GetIsDead(-2)) Then Return
	CleanseFromCripple()
	RndSleep(1000)
	PickUpItems(CleanseFromCripple)
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
		;Out('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Out('Timed out waiting for mobs to ball')
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
	If (TimerDiff($deadlock) > 120000) Then Out('Timed out waiting for allies to be dead')
EndFunc


;~ Respawn and rezone if we die
Func RestartAfterDeath()
	Local $deadlockTimer = TimerInit()
	Out('Waiting for resurrection')
	While GetIsDead(-2)
		RndSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$SPIRIT_SLAVES_FARM_SETUP = True
			Out('Travelling to Bone Palace')
			DistrictTravel($ID_Bone_Palace, $DISTRICT_NAME)
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


;~ Wait to have death's charge recharged
Func WaitForDeathsCharge()
	While Not IsRecharged($SS_Deaths_Charge) And Not GetIsDead(-2)
		RndSleep(1000)
	WEnd
EndFunc


;~ Cleanse if the character has a condition (cripple)
Func CleanseFromCripple()
	If (GetHasCondition(-2)) Then UseSkillEx($SS_I_am_unstoppable)
EndFunc


;~ Give True if the given agent is past a specific line where we should take aggro
Func IsPastAggroLine($agent)
	Return Not IsOverLine(1, 0, 6750, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
	; 6500 works too, but slightly too early, some mobs stay downstairs
	;Return Not IsOverLine(1, 0, 6500, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
	; 7000 works but is slightly too late, sometimes mobs do not get aggroed
	;Return Not IsOverLine(1, 0, 7000, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
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