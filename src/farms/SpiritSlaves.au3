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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $SPIRIT_SLAVES_DERVISH_SKILLBAR = 'OgejkOrMLTmXfXfb0kkX4OcX5iA'
Global Const $SPIRIT_SLAVES_RITUALIST_SKILLBAR = 'OAWjEkDZITRAsimALBWMiAeQEPA'
Global Const $SPIRIT_SLAVES_FARM_INFORMATIONS = 'Please use ritualist for this farm as dervish fails too often' & @CRLF _
	& 'For best results, have :' & @CRLF _
	& '- 16 Restoration Magic' &@CRLF _
	& '- 9 Illusion Magic' & @CRLF _
	& '- 9 Inspiration Magic' & @CRLF _
	& '- Herald insignias, Superior Vigor and 3 attunement runes'& @CRLF _
	& '- the quest Destroy the Ungrateful Slaves not completed' & @CRLF _
	& 'Note: the farm works less efficiently during events because of the amount of loot'
Global Const $SPIRIT_SLAVES_FARM_DURATION = 10 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkill($SKILL_CONVICTION is better than UseSkill(1))
Global Const $SS_SAND_SHARDS					= 1
Global Const $SS_I_AM_UNSTOPPABLE				= 2
Global Const $SS_MYSTIC_VIGOR					= 3
Global Const $SS_VOW_OF_STRENGTH				= 4
Global Const $SS_EXTEND_ENCHANTMENTS			= 5
Global Const $SS_DEATHS_CHARGE					= 6
Global Const $SS_MIRAGE_CLOAK					= 7
Global Const $SS_EBON_BATTLE_STANDARD_OF_HONOR	= 8

Global Const $SS_MANTRA_OF_RESOLVE				= 1
Global Const $SS_GREAT_DWARF_ARMOR				= 2
Global Const $SS_CHANNELING						= 3
Global Const $SS_ARCANE_ECHO					= 4
Global Const $SS_VENGEFUL_WAS_KHANHEI			= 5
Global Const $SS_ANCESTORS_VISAGE				= 6
Global Const $SS_SYMPATHETIC_VISAGE				= 7
Global Const $SS_VENGEFUL_WEAPON				= 8

; Reduction from mysticism (50%) and increase from spirit (30%) are included
Global Const $SS_SKILLS_ARRAY =		[$SS_SAND_SHARDS,	$SS_I_AM_UNSTOPPABLE,	$SS_MYSTIC_VIGOR,	$SS_VOW_OF_STRENGTH,	$SS_EXTEND_ENCHANTMENTS,	$SS_DEATHS_CHARGE,	$SS_MIRAGE_CLOAK,	$SS_EBON_BATTLE_STANDARD_OF_HONOR]
Global Const $SS_SKILLS_COSTS_ARRAY =	[7,					7,						4,					4,						7,							7,					7,					13]
Global Const $SKILL_COSTS_MAP = MapFromArrays($SS_SKILLS_ARRAY, $SS_SKILLS_COSTS_ARRAY)

Global $spirit_slaves_farm_setup = False

Local $ss_vengeful_was_khanhei_timer
Local $ss_visage_timer
Local $ss_vengeful_weapon_timer
Local $ss_great_dwarf_armor_timer

;~ Main loop of the farm
Func SpiritSlavesFarm()
	If Not $spirit_slaves_farm_setup And SetupSpiritSlavesFarm() == $FAIL Then Return $PAUSE
	Return SpiritSlavesFarmLoop()
EndFunc


;~ Farm setup : going to the Shattered Ravines
Func SetupSpiritSlavesFarm()
	If GetMapID() <> $ID_THE_SHATTERED_RAVINES Then
		If TravelToOutpost($ID_BONE_PALACE, $district_name) == $FAIL Then Return $FAIL
		SwitchMode($ID_HARD_MODE)
		SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)

		If SetupPlayerSpiritSlavesFarm() == $FAIL Then Return $FAIL
		LeaveParty()

		While Not $spirit_slaves_farm_setup
			If RunToShatteredRavines() == $FAIL Then ContinueLoop
			$spirit_slaves_farm_setup = True
		WEnd
	EndIf
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerSpiritSlavesFarm()
	Info('Setting up player build skill bar')
	Local $me = GetMyAgent()
	If DllStructGetData($me, 'Primary') == $ID_DERVISH Then
		LoadSkillTemplate($SPIRIT_SLAVES_DERVISH_SKILLBAR)
	ElseIf DllStructGetData($me, 'Primary') == $ID_RITUALIST Then
		LoadSkillTemplate($SPIRIT_SLAVES_RITUALIST_SKILLBAR)
	Else
		Warn('Should run this farm as dervish or ritualist')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


Func RunToShatteredRavines()
	TravelToOutpost($ID_BONE_PALACE, $district_name)
	; Exiting to Joko's Domain
	MoveTo(-14500, 6000)
	Move(-14800, 3400)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_JOKOS_DOMAIN) Then Return $FAIL
	RandomSleep(500)
	MoveTo(-12650, 2600)
	;ChangeWeaponSet(4)
	MoveTo(-10950, 4250)
	; Going to wurm's spoor
	ChangeTarget(GetNearestSignpostToCoords(-10950, 4250))
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
	MoveTo(-8600, 10600)
	$me = GetMyAgent()
	If (CountFoesInRangeOfAgent($me, $RANGE_EARSHOT) > 0) Then UseSkillEx(5)
	MoveTo(-8250, 12800)
	Move(-3850, 19200)
	$me = GetMyAgent()
	While IsPlayerMoving()
		If (CountFoesInRangeOfAgent($me, $RANGE_NEARBY) > 0 And IsRecharged(5)) Then UseSkillEx(5)
		RandomSleep(500)
		$me = GetMyAgent()
		If IsPlayerDead() Then Return $FAIL
	WEnd

	MoveTo(-4500, 19700)
	RandomSleep(3000)
	MoveTo(-4500, 19700)
	; If dead it's not worth rezzing better just restart running
	If IsPlayerDead() Then Return $FAIL

	; Entering The Shattered Ravines
	;ChangeWeaponSet(1)
	Info('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	; Hurry up before dying
	MoveTo(-9700, -10750)
	MoveTo(-7900, -10550)
	Return $SUCCESS
EndFunc


;~ Farm loop
Func SpiritSlavesFarmLoop()
	UseConsumable($ID_SLICE_OF_PUMPKIN_PIE)

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
	Move(-7750, -8400)
	RezoneToTheShatteredRavines()
	Return $SUCCESS
EndFunc


;~ Rezoning to reset the farm
Func RezoneToTheShatteredRavines()
	Info('Rezoning')
	; Exiting to Jokos Domain
	MoveTo(-7800, -10250)
	MoveTo(-9000, -10900)
	MoveTo(-10500, -11000)
	Move(-10650, -11300)
	RandomSleep(1000)
	WaitMapLoading($ID_JOKOS_DOMAIN)
	RandomSleep(500)
	; Reentering The Shattered Ravines
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000)
	; Hurry up before dying
	MoveTo(-9700, -10750)
	MoveTo(-7900, -10550)
EndFunc


;~ Farm the north group (group 1, 4 and 5)
Func FarmNorthGroup()
	Local $me = GetMyAgent()
	If DllStructGetData($me, 'Primary') == $ID_RITUALIST Then
		RitualistFarmNorthGroup()
	Else
		DervishFarmNorthGroup()
	EndIf
EndFunc


Func RitualistFarmNorthGroup()
	MoveTo(-7350, -7750, 0)
	WaitForFoesBall()
	WaitForEnergy()
	UseSkillEx($SS_MANTRA_OF_RESOLVE)
	RandomSleep(6500)
	UseSkillEx($SS_GREAT_DWARF_ARMOR)
	$ss_great_dwarf_armor_timer = TimerInit()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8600, -5800, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	UseSkillEx($SS_CHANNELING)
	RandomSleep(2000)
	UseSkillEx($SS_ARCANE_ECHO)
	RandomSleep(7000)
	; Aggro foes
	Move(-8600, -5800)
	RandomSleep(1000)
	UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
	$ss_vengeful_was_khanhei_timer = TimerInit()
	RandomSleep(50)
	UseSkillEx($SS_SYMPATHETIC_VISAGE)
	$ss_visage_timer = TimerInit()
	RandomSleep(50)

	Local $positionToGo = FindMiddleOfFoes(-8600, -5800, $RANGE_AREA)
	Return RitualistKillSequence($positionToGo[0], $positionToGo[1])
EndFunc


;~ Farm the south group (group 2 and 3)
Func FarmSouthGroup()
	Local $me = GetMyAgent()
	If DllStructGetData($me, 'Primary') == $ID_RITUALIST Then
		RitualistFarmSouthGroup()
	Else
		DervishFarmSouthGroup()
	EndIf
EndFunc


Func RitualistFarmSouthGroup()
	;CleanseFromCripple()
	MoveTo(-7830, -7860)
	;CleanseFromCripple()
	; Wait until an enemy is past the correct aggro line
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
	Local $deadlock = TimerInit()
	While $foesCount < 8 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
		;CleanseFromCripple()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	;CleanseFromCripple()
	; We want foes between -8055,-9200 and -8055,-9300
	Move(-7735, -8380)
	UseSkillEx($SS_MANTRA_OF_RESOLVE)
	RandomSleep(7500)
	UseSkillEx($SS_GREAT_DWARF_ARMOR)
	RandomSleep(3000)
	UseSkillEx($SS_CHANNELING)
	RandomSleep(3000)
	UseSkillEx($SS_ARCANE_ECHO)
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	$deadlock = TimerInit()
	; Wait until an enemy is aggroed
	While $foesCount == 0 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
	$ss_vengeful_was_khanhei_timer = TimerInit()
	RandomSleep(50)
	UseSkillEx($SS_SYMPATHETIC_VISAGE)
	$ss_visage_timer = TimerInit()
	RandomSleep(50)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	Return RitualistKillSequence($positionToGo[0], $positionToGo[1])
EndFunc


Func RitualistKillSequence($x, $y)
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	While $foesCount > 0
		If TimerDiff($ss_vengeful_was_khanhei_timer) > 10000 Then
			If IsRecharged($SS_ARCANE_ECHO) And GetSkillbarSkillID($SS_ARCANE_ECHO) == $ID_VENGEFUL_WAS_KHANHEI Then
				UseSkillEx($SS_ARCANE_ECHO)
				$ss_vengeful_was_khanhei_timer = TimerInit()
				RandomSleep(50)
			ElseIf IsRecharged($SS_VENGEFUL_WAS_KHANHEI) Then
				UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
				$ss_vengeful_was_khanhei_timer = TimerInit()
				RandomSleep(50)
			EndIf
		EndIf
		If TimerDiff($ss_visage_timer) > 9000 Then
			If IsRecharged($SS_ANCESTORS_VISAGE) Then
				UseSkillEx($SS_ANCESTORS_VISAGE)
				$ss_visage_timer = TimerInit()
				RandomSleep(50)
			ElseIf IsRecharged($SS_SYMPATHETIC_VISAGE) Then
				UseSkillEx($SS_SYMPATHETIC_VISAGE)
				$ss_visage_timer = TimerInit()
				RandomSleep(50)
			EndIf
		EndIf
		If TimerDiff($ss_vengeful_weapon_timer) > 3000 And GetDistanceToPoint(GetMyAgent(), $x, $y) < $RANGE_AREA Then
			UseSkillEx($SS_VENGEFUL_WEAPON)
			$ss_vengeful_weapon_timer = TimerInit()
			RandomSleep(50)
		EndIf
		If TimerDiff($ss_great_dwarf_armor_timer) > 38000 Then
			UseSkillEx($SS_GREAT_DWARF_ARMOR)
			$ss_great_dwarf_armor_timer = TimerInit()
			RandomSleep(50)
		EndIf
		Move($x, $y, 0)
		Sleep(250)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	RandomSleep(1000)
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Wait for all ennemies to be balled
Func WaitForFoesBall()
	WaitForAlliesDead()

	Local $deadlock = TimerInit()
	Local $target = GetNearestEnemyToCoords(-8600, -5810)
	Local $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
	Local $validation = 0

	; Wait until all foes are balled
	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(3000)
		$target = GetNearestEnemyToCoords(-8600, -5810)
		$foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		Debug('foes: ' & $foesCount & '/8')
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Info('Timed out waiting for mobs to ball')
EndFunc


;~ Wait for allies to be dead
Func WaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8600, -5810)

	; Wait until foes are in range of allies
	While GetDistanceToPoint($target, -8600, -5810) < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(5000)
		$target = GetNearestNPCToCoords(-8600, -5810)
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
			$spirit_slaves_farm_setup = True
			Info('Travelling to Bone Palace')
			DistrictTravel($ID_BONE_PALACE, $district_name)
			Return $FAIL
		EndIf
	WEnd
	RezoneToTheShatteredRavines()
	Return $FAIL
EndFunc


;~ Wait to have enough energy before jumping into the next group
Func WaitForEnergy()
	While (GetEnergy() < 30) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


;~ Cleanse if the character has a condition (cripple)
Func CleanseFromCripple()
	If (GetHasCondition(GetMyAgent()) And GetEffect($ID_CRIPPLED) <> Null) Then UseSkillEx($SS_I_AM_UNSTOPPABLE)
EndFunc


;~ Give True if the given agent is past a specific line where we should take aggro
Func IsPastAggroLine($agent)
	Return Not IsOverLine(1, 0, 6750, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
	; 6500 works too, but slightly too early, some mobs stay downstairs
	;Return Not IsOverLine(1, 0, 6500, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
	; 7000 works but is slightly too late, sometimes mobs do not get aggroed
	;Return Not IsOverLine(1, 0, 7000, DllStructGetData($agent, 'X'), DllStructGetData($agent, 'Y'))
EndFunc


Func DervishFarmNorthGroup()
	MoveTo(-7375, -7767, 0)
	WaitForFoesBall()
	WaitForEnergy()
	WaitForDeathsCharge()
	Local $targetFoe = GetNearestNPCInRangeOfCoords(-8600, -5810, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
	GetAlmostInRangeOfAgent($targetFoe)
	;ChangeWeaponSet(1)
	UseSkillEx($SS_SAND_SHARDS)
	RandomSleep(3500)
	UseSkillEx($SS_I_AM_UNSTOPPABLE)
	RandomSleep(3500)
	UseSkillEx($SS_MYSTIC_VIGOR)
	RandomSleep(300)
	UseSkillEx($SS_VOW_OF_STRENGTH)
	RandomSleep(50)
	UseSkillEx($SS_EXTEND_ENCHANTMENTS)
	RandomSleep(50)
	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8600, -5810, $RANGE_AREA)
	$targetFoe = GetNearestEnemyToCoords($positionToGo[0], $positionToGo[1])

	UseSkillEx($SS_DEATHS_CHARGE, $targetFoe)
	RandomSleep(50)
	If GetEnergy() > $SKILL_COSTS_MAP[$SS_MIRAGE_CLOAK] Then UseSkillEx($SS_MIRAGE_CLOAK)
	RandomSleep(50)
	If GetEnergy() > $SKILL_COSTS_MAP[$SS_EBON_BATTLE_STANDARD_OF_HONOR] Then UseSkillEx($SS_EBON_BATTLE_STANDARD_OF_HONOR)
	RandomSleep(50)
	If IsPlayerDead() Then Return $FAIL
	Return DervishKillSequence()
EndFunc


Func DervishFarmSouthGroup()
	CleanseFromCripple()
	MoveTo(-7830, -7860)
	CleanseFromCripple()
	; Wait until an enemy is past the correct aggro line
	Local $foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
	Local $deadlock = TimerInit()
	While $foesCount < 8 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfCoords(-7400, -9400, $RANGE_SPELLCAST, IsPastAggroLine)
		CleanseFromCripple()
		If IsPlayerDead() Then Return $FAIL
	WEnd
	CleanseFromCripple()
	; We want foes between -8055,-9200 and -8055,-9300
	Move(-7735, -8380)
	$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	$deadlock = TimerInit()
	; Wait until an enemy is aggroed
	While IsPlayerAlive() And $foesCount == 0 And TimerDiff($deadlock) < 120000
		RandomSleep(100)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST)
	WEnd
	If IsPlayerDead() Then Return $FAIL

	;ChangeWeaponSet(1)
	MoveTo(-7800, -7680, 0)

	UseSkillEx($SS_SAND_SHARDS)
	RandomSleep(2000)
	UseSkillEx($SS_MYSTIC_VIGOR)
	RandomSleep(750)
	UseSkillEx($SS_VOW_OF_STRENGTH)
	RandomSleep(200)

	If IsPlayerDead() Then Return $FAIL

	Local $positionToGo = FindMiddleOfFoes(-8055, -9250, $RANGE_NEARBY)
	Local $targetFoe = GetNearestEnemyToCoords($positionToGo[0], $positionToGo[1])
	UseSkillEx($SS_I_AM_UNSTOPPABLE)
	RandomSleep(50)
	UseSkillEx($SS_EXTEND_ENCHANTMENTS)
	RandomSleep(50)
	UseSkillEx($SS_DEATHS_CHARGE, $targetFoe)
	RandomSleep(50)
	If GetEnergy() > $SKILL_COSTS_MAP[$SS_MIRAGE_CLOAK] Then UseSkillEx($SS_MIRAGE_CLOAK)
	RandomSleep(50)
	If GetEnergy() > $SKILL_COSTS_MAP[$SS_EBON_BATTLE_STANDARD_OF_HONOR] Then UseSkillEx($SS_EBON_BATTLE_STANDARD_OF_HONOR)
	RandomSleep(50)
	If IsPlayerDead() Then Return $FAIL

	Return DervishKillSequence()
EndFunc


;~ Kill a mob group
Func DervishKillSequence()
	Local $deadlock = TimerInit()
	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_AREA)
	Local $casterFoesMap[]
	;ChangeWeaponSet(2)
	While $foesCount > 0 And TimerDiff($deadlock) < 100000
		If IsRecharged($SS_MYSTIC_VIGOR) And GetEffectTimeRemaining(GetEffect($ID_MYSTIC_VIGOR)) == 0 And GetEnergy() > $SKILL_COSTS_MAP[$SS_MYSTIC_VIGOR] Then
			UseSkillEx($SS_MYSTIC_VIGOR)
			RandomSleep(50)
		EndIf
		If $foesCount > 1 And IsRecharged($SS_MIRAGE_CLOAK) And GetEffectTimeRemaining(GetEffect($ID_MIRAGE_CLOAK)) == 0 And GetEnergy() > ($SKILL_COSTS_MAP[$SS_EXTEND_ENCHANTMENTS] + $SKILL_COSTS_MAP[$SS_MIRAGE_CLOAK]) Then
			UseSkillEx($SS_EXTEND_ENCHANTMENTS)
			RandomSleep(50)
			UseSkillEx($SS_MIRAGE_CLOAK)
			RandomSleep(50)
		EndIf
		If IsRecharged($SS_I_AM_UNSTOPPABLE) And GetEnergy() > $SKILL_COSTS_MAP[$SS_I_AM_UNSTOPPABLE] Then
			UseSkillEx($SS_I_AM_UNSTOPPABLE)
			RandomSleep(50)
		EndIf
		If $foesCount > 3 And IsRecharged($SS_SAND_SHARDS) And GetEffectTimeRemaining(GetEffect($ID_SAND_SHARDS)) == 0 And GetEnergy() > $SKILL_COSTS_MAP[$SS_SAND_SHARDS] Then
			UseSkillEx($SS_SAND_SHARDS)
			RandomSleep(50)
		EndIf
		If IsRecharged($SS_EBON_BATTLE_STANDARD_OF_HONOR) And GetEffectTimeRemaining(GetEffect($ID_EBON_BATTLE_STANDARD_OF_HONOR)) == 0 And GetEnergy() > $SKILL_COSTS_MAP[$SS_EBON_BATTLE_STANDARD_OF_HONOR] Then
			UseSkillEx($SS_EBON_BATTLE_STANDARD_OF_HONOR)
			RandomSleep(50)
		EndIf
		If IsRecharged($SS_VOW_OF_STRENGTH) And GetEnergy() > $SKILL_COSTS_MAP[$SS_VOW_OF_STRENGTH] Then
			UseSkillEx($SS_VOW_OF_STRENGTH)
			RandomSleep(50)
		EndIf
		Local $me = GetMyAgent()
		$foesCount = CountFoesInRangeOfAgent($me, $RANGE_EARSHOT)
		If $foesCount > 0 Then
			Local $casterFoe = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_AREA + 88)
			Local $casterFoeID = DllStructGetData($casterFoe, 'ID')
			Local $distance = GetDistance($me, $casterFoe)
			If $foesCount < 5 And GetDistance($me, $casterFoe) > $RANGE_ADJACENT Then
				Debug('One foe is distant')
				If $casterFoesMap[$casterFoeID] == Null Then
					$casterFoesMap[$casterFoeID] = 0
				ElseIf $casterFoesMap[$casterFoeID] == 2 Then
					Debug('Moving to fight that foe')
					Local $timer = TimerInit()
					;MoveAvoidingBodyBlock(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'X'), 1000)
					While IsPlayerAlive() And GetDistance($me, $casterFoe) > $RANGE_ADJACENT And TimerDiff($timer) < 1000
						Move(DllStructGetData($casterFoe, 'X'), DllStructGetData($casterFoe, 'Y'))
						RandomSleep(100)
					WEnd
				EndIf
				$casterFoesMap[$casterFoeID] += 1
			EndIf
			$me = GetMyAgent()
			Local $nearestFoe = GetNearestEnemyToAgent($me)
			If GetDistance($me, $nearestFoe) < $RANGE_AREA + 88 Then
				Attack($nearestFoe)
			EndIf
			RandomSleep(1000)
		EndIf
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_EARSHOT)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	;ChangeWeaponSet(1)

	CleanseFromCripple()
	RandomSleep(1000)
	PickUpItems(CleanseFromCripple)
	Return $SUCCESS
EndFunc


;~ Wait to have death's charge recharged
Func WaitForDeathsCharge()
	While Not IsRecharged($SS_DEATHS_CHARGE) And IsPlayerAlive()
		RandomSleep(1000)
	WEnd
EndFunc


;~ @Unused but good learning practice ;)
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