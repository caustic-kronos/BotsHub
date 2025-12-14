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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $SpiritSlaves_Skillbar = 'OgejkOrMLTmXfXfb0kkX4OcX5iA'
Global Const $SpiritSlavesFarmInformations = '[CURRENTLY BROKEN]' & @CRLF _
	& 'For best results, have :' & @CRLF _
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
Global Const $SPIRIT_SLAVES_FARM_DURATION = 10 * 60 * 1000

Global $SPIRIT_SLAVES_FARM_SETUP = False

; Skill numbers declared to make the code WAY more readable (UseSkill($Skill_Conviction is better than UseSkill(1))
Global Const $SS_Sand_Shards					= 1
Global Const $SS_I_am_unstoppable				= 2
Global Const $SS_Mystic_Vigor					= 3
Global Const $SS_Vow_of_Strength				= 4
Global Const $SS_Extend_Enchantments			= 5
Global Const $SS_Deaths_Charge					= 6
Global Const $SS_Mirage_Cloak					= 7
Global Const $SS_Ebon_Battle_Standard_of_Honor	= 8
;Global Const $SS_Heart_of_Fury					= 8

; Reduction from mysticism (50%) and increase from spirit (30%) are included
Global Const $SS_SkillsArray =		[$SS_Sand_Shards,	$SS_I_am_unstoppable,	$SS_Mystic_Vigor,	$SS_Vow_of_Strength,	$SS_Extend_Enchantments,	$SS_Deaths_Charge,	$SS_Mirage_Cloak,	$SS_Ebon_Battle_Standard_of_Honor]
Global Const $SS_SkillsCostsArray =	[7,					7,						4,					4,						7,							7,					7,					13]
Global Const $skillCostsMap = MapFromArrays($SS_SkillsArray, $SS_SkillsCostsArray)


;~ Main loop of the farm
Func SpiritSlavesFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $SPIRIT_SLAVES_FARM_SETUP And SetupSpiritSlavesFarm() == $FAIL Then Return $PAUSE

	UseConsumable($ID_Slice_of_Pumpkin_Pie)

	Info('Killing group 1 @ North')
	If FarmNorthGroup() == $FAIL Then Return RestartAfterDeath()
	Info('Killing group 2 @ South')
	If FarmSouthGroup() == $FAIL Then Return RestartAfterDeath()
	Info('Killing group 3 @ South')
	If FarmSouthGroup() == $FAIL Then Return RestartAfterDeath()
	Info('Killing group 4 @ North')
	If FarmNorthGroup() == $FAIL Then Return RestartAfterDeath()
	Info('Killing group 5 @ North')
	If FarmNorthGroup() == $FAIL Then Return RestartAfterDeath()

	Info('Moving out of the zone and back again')
	Move(-7735, -8380)
	RezoneToTheShatteredRavines()

	Return $SUCCESS
EndFunc


;~ Farm setup : going to the Shattered Ravines
Func SetupSpiritSlavesFarm()
	If GetMapID() <> $ID_The_Shattered_Ravines Then
		If TravelToOutpost($ID_Bone_Palace, $DISTRICT_NAME) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_Lightbringer_Title)

		If SetupPlayerSpiritSlavesFarm() == $FAIL Then Return $FAIL
		LeaveParty() ; solo farmer

		While Not $SPIRIT_SLAVES_FARM_SETUP
			If RunToShatteredRavines() == $FAIL Then ContinueLoop
			$SPIRIT_SLAVES_FARM_SETUP = True
		WEnd
	EndIf
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_Dervish Then
		LoadSkillTemplate($SpiritSlaves_Skillbar)
    Else
    	Warn('Should run this farm as dervish')
    	Return $FAIL
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
	Return $SUCCESS
EndFunc


Func RunToShatteredRavines()
	; Exiting to Jokos Domain
	TravelToOutpost($ID_Bone_Palace, $DISTRICT_NAME)
	MoveTo(-14520, 6009)
	Move(-14820, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_Jokos_Domain) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12657, 2609)
	ChangeWeaponSet(4)
	MoveTo(-10938, 4254)
	; Going to wurm's spoor
	ChangeTarget(GetNearestSignpostToCoords(-10938, 4254))
	RandomSleep(500)
	Info('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
	; Starting from there there might be enemies on the way
	MoveTo(-8255, 5320)
	Local $me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8624, 10636)
	$me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8261, 12808)
	Move(-3838, 19196)
	$me = GetMyAgent()
	While IsPlayerAlive() And IsPlayerMoving()
		If (CountFoesInRangeOfAgent($me, $RANGE_NEARBY) > 0 And IsRecharged(5)) Then UseSkillEx(5)
		RandomSleep(500)
		$me = GetMyAgent()
	WEnd

	; If dead it's not worth rezzing better just restart running
	If IsPlayerDead() Then Return $FAIL

	MoveTo(-4486, 19700)
	RandomSleep(3000)
	MoveTo(-4486, 19700)

	; If dead it's not worth rezzing better just restart running
	If IsPlayerDead() Then Return $FAIL

	; Entering The Shattered Ravines
	ChangeWeaponSet(1)
	Info('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_The_Shattered_Ravines, 10000, 2000) Then Return $FAIL
	; Hurry up before dying
	MoveTo(-9714, -10767)
	MoveTo(-7919, -10530)
	Return $SUCCESS
EndFunc


;~ Rezoning to reset the farm
Func RezoneToTheShatteredRavines()
	Info('Rezoning')
	; Exiting to Jokos Domain
	MoveTo(-7800, -10250)
	MoveTo(-9000, -10900)
	MoveTo(-10500, -11000)
	Move(-10656, -11293)
	RandomSleep(1000)
	WaitMapLoading($ID_Jokos_Domain)
	RandomSleep(500)
	; Reentering The Shattered Ravines
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
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
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8598, -5810, $ID_Allegiance_Foe, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	ChangeWeaponSet(1)
	UseSkillEx($SS_Sand_Shards)
	RandomSleep(3500)
	UseSkillEx($SS_I_am_unstoppable)
	RandomSleep(3500)
	UseSkillEx($SS_Mystic_Vigor)
	RandomSleep(300)
	UseSkillEx($SS_Vow_of_Strength)
	RandomSleep(20)
	UseSkillEx($SS_Extend_Enchantments)
	RandomSleep(20)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8598, -5810, $RANGE_AREA)
	$targetFoe = BetterGetNearestNPCToCoords($ID_Allegiance_Foe, $positionToGo[0], $positionToGo[1], $RANGE_EARSHOT)

	UseSkillEx($SS_Deaths_Charge, $targetFoe)
	RandomSleep(20)
	If GetEnergy() > $skillCostsMap[$SS_Mirage_Cloak] Then UseSkillEx($SS_Mirage_Cloak)
	RandomSleep(20)
	If GetEnergy() > $skillCostsMap[$SS_Ebon_Battle_Standard_of_Honor] Then UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RandomSleep(20)

	If IsPlayerDead() Then Return $FAIL
	If KillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Farm the south group (group 2 and 3)
Func FarmSouthGroup()
	CleanseFromCripple()
	MoveTo(-7830, -7860)
	CleanseFromCripple()
	; Wait until an enemy is past the correct aggro line
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
	Local $deadlock = TimerInit()
	While IsPlayerAlive() And $foesCount < 8 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
		CleanseFromCripple()
	WEnd
	CleanseFromCripple()
	; We want foes between -8055,-9200 and -8055,-9300
	Move(-7735, -8380)
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	$deadlock = TimerInit()
	; Wait until an enemy is aggroed
	While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), 950)
	WEnd
	If IsPlayerDead() Then Return $FAIL

	ChangeWeaponSet(1)
	MoveTo(-7800, -7680, 0)

	UseSkillEx($SS_Sand_Shards)
	RandomSleep(2000)
	UseSkillEx($SS_Mystic_Vigor)
	RandomSleep(750)
	UseSkillEx($SS_Vow_of_Strength)
	RandomSleep(200)

	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	Local $targetFoe = BetterGetNearestNPCToCoords($ID_Allegiance_Foe, $positionToGo[0], $positionToGo[1], $RANGE_SPELLCAST)
	UseSkillEx($SS_I_am_unstoppable)
	RandomSleep(20)
	UseSkillEx($SS_Extend_Enchantments)
	RandomSleep(20)
	UseSkillEx($SS_Deaths_Charge, $targetFoe)
	RandomSleep(20)
	If GetEnergy() > $skillCostsMap[$SS_Mirage_Cloak] Then UseSkillEx($SS_Mirage_Cloak)
	RandomSleep(20)
	If GetEnergy() > $skillCostsMap[$SS_Ebon_Battle_Standard_of_Honor] Then UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
	RandomSleep(20)

	If IsPlayerDead() Then Return $FAIL
	If KillSequence() == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Kill a mob group
Func KillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	Local $casterFoesMap[]
	ChangeWeaponSet(2)
	While IsPlayerAlive() And $foesCount > 0 And TimerDiff($deadlock) < 100000
		If IsRecharged($SS_Mystic_Vigor) And GetEffectTimeRemaining(GetEffect($ID_Mystic_Vigor)) == 0 And GetEnergy() > $skillCostsMap[$SS_Mystic_Vigor] Then
			UseSkillEx($SS_Mystic_Vigor)
			RandomSleep(20)
		EndIf
		If $foesCount > 1 And IsRecharged($SS_Mirage_Cloak) And GetEffectTimeRemaining(GetEffect($ID_Mirage_Cloak)) == 0 And GetEnergy() > ($skillCostsMap[$SS_Extend_Enchantments] + $skillCostsMap[$SS_Mirage_Cloak]) Then
			UseSkillEx($SS_Extend_Enchantments)
			RandomSleep(20)
			UseSkillEx($SS_Mirage_Cloak)
			RandomSleep(20)
		EndIf
		If IsRecharged($SS_I_am_unstoppable) And GetEnergy() > $skillCostsMap[$SS_I_am_unstoppable] Then
			UseSkillEx($SS_I_am_unstoppable)
			RandomSleep(20)
		EndIf
		If $foesCount > 3 And IsRecharged($SS_Sand_Shards) And GetEffectTimeRemaining(GetEffect($ID_Sand_Shards)) == 0 And GetEnergy() > $skillCostsMap[$SS_Sand_Shards] Then
			UseSkillEx($SS_Sand_Shards)
			RandomSleep(20)
		EndIf
		If IsRecharged($SS_Ebon_Battle_Standard_of_Honor) And GetEffectTimeRemaining(GetEffect($ID_Ebon_Battle_Standard_of_Honor)) == 0 And GetEnergy() > $skillCostsMap[$SS_Ebon_Battle_Standard_of_Honor] Then
			UseSkillEx($SS_Ebon_Battle_Standard_of_Honor)
			RandomSleep(20)
		EndIf
		If IsRecharged($SS_Vow_of_Strength) And GetEnergy() > $skillCostsMap[$SS_Vow_of_Strength] Then
			UseSkillEx($SS_Vow_of_Strength)
			RandomSleep(20)
		EndIf
		Local $me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
		If $foesCount > 0 Then
			Local $casterFoe = GetFurthestNPCInRangeOfCoords($ID_Allegiance_Foe, Null, Null, $RANGE_AREA + 88)
			Local $casterFoeId = DllStructGetData($casterFoe, 'ID')
			Local $distance = GetDistance($me, $casterFoe)
			If $foesCount < 5 And GetDistance($me, $casterFoe) > $RANGE_ADJACENT Then
				Debug('One foe is distant')
				If $casterFoesMap[$casterFoeId] == Null Then
					$casterFoesMap[$casterFoeId] = 0
				ElseIf $casterFoesMap[$casterFoeId] == 2 Then
					Debug('Moving to fight that foe')
					Local $timer = TimerInit()
					;MoveAvoidingBodyBlock(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'X'), 1000)
					While IsPlayerAlive() And GetDistance($me, $casterFoe) > $RANGE_ADJACENT And TimerDiff($timer) < 1000
						Move(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'Y'))
						RandomSleep(100)
					WEnd
				EndIf
				$casterFoesMap[$casterFoeId] += 1
			EndIf
			$me = GetMyAgent()
			Local $nearestFoe = GetNearestEnemyToAgent($me)
			If GetDistance($me, $nearestFoe) < $RANGE_AREA + 88 Then
				Attack($nearestFoe)
			EndIf
			RandomSleep(1000)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
	WEnd
	ChangeWeaponSet(1)

	If IsPlayerDead() Then Return $FAIL
	CleanseFromCripple()
	RandomSleep(1000)
	PickUpItems(CleanseFromCripple)
	Return IsPlayerAlive()? $SUCCESS : $FAIL
EndFunc


;~ Wait for all ennemies to be balled
Func WaitForFoesBall()
	WaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8598, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0

	; Wait until all foes are balled
	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(3000)
		$target = GetNearestEnemyToCoords(-8598, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		Debug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for mobs to ball')
EndFunc


;~ Wait for all enemies to be balled and allies to be dead
Func WaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8598, -5810)

	; Wait until foes are in range of allies
	While GetDistanceToPoint($target, -8598, -5810) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(5000)
		$target = GetNearestNPCToCoords(-8598, -5810)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for allies to be dead')
EndFunc


;~ Respawn and rezone if we die
Func RestartAfterDeath()
	Local $deadlockTimer = TimerInit()
	Info('Waiting for resurrection')
	While IsPlayerDead()
		RandomSleep(1000)
		If TimerDiff($deadlockTimer) > 60000 Then
			$SPIRIT_SLAVES_FARM_SETUP = True
			Info('Travelling to Bone Palace')
			DistrictTravel($ID_Bone_Palace, $DISTRICT_NAME)
			Return $FAIL
		EndIf
	WEnd
	RezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


;~ Wait to have enough energy before jumping into the next group
Func WaitForEnergy()
	While (GetEnergy() < 20) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


;~ Wait to have death's charge recharged
Func WaitForDeathsCharge()
	While Not IsRecharged($SS_Deaths_Charge) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


;~ Cleanse if the character has a condition (cripple)
Func CleanseFromCripple()
	If (GetHasCondition(GetMyAgent()) And GetEffect($ID_Crippled) <> Null) Then UseSkillEx($SS_I_am_unstoppable)
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
