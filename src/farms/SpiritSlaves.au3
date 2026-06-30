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
#include '../../lib/GWA2_ID_Items.au3'
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID_Skills.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'


; ==== Constants ====
Global Const $SPIRIT_SLAVES_RITUALIST_SKILLBAR = 'OAWjMwhM5QRAmAsiLBWMEP0krlA'
Global Const $SPIRIT_SLAVES_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 Restoration Magic' &@CRLF _
	& '- 12 Inspiration Magic' & @CRLF _
	& '- Herald insignias, Superior Vigor and 3 attunement runes'& @CRLF _
	& '- the quest Destroy the Ungrateful Slaves not completed'
Global Const $SPIRIT_SLAVES_FARM_DURATION = 10 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkill($SS_MANTRA_OF_RESOLVE is better than UseSkill(1))
Global Const $SS_MANTRA_OF_RESOLVE				= 1
Global Const $SS_CHANNELING						= 2
Global Const $SS_GREAT_DWARF_ARMOR				= 3
Global Const $SS_ARCANE_ECHO					= 4
Global Const $SS_VENGEFUL_WAS_KHANHEI			= 5
Global Const $SS_VENGEFUL_WEAPON				= 6
Global Const $SS_I_AM_UNSTOPPABLE				= 7
Global Const $SS_MINDBENDER						= 8

; Spirit from Arm of Insanity might cast a Quickening Zephyr close enough to reduce recast by 50% and increase costs by 30%
Global $spirit_slaves_farm_setup = False


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
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_RITUALIST Then
		LoadSkillTemplate($SPIRIT_SLAVES_RITUALIST_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as a ritualist')
		Return $FAIL
	EndIf
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
	UseSkillEx($SS_MINDBENDER)
	MoveTo(-12650, 2600)
	MoveTo(-10950, 4250)
	; Going to wurm's spoor
	ChangeTarget(GetNearestSignpostToCoords(-10950, 4250))
	RandomSleep(500)
	Info('Taking wurm')
	TargetNearestItem()
	ActionInteract()
	RandomSleep(1500)
	UseSkillEx(5)
	MoveTo(-8255, 5320)

	; Starting from there, there might be enemies on the way
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
		; If dead it is not worth rezzing better just restart running
		If IsPlayerDead() Then Return $FAIL
	WEnd
	MoveTo(-4500, 19700)
	RandomSleep(3000)
	MoveTo(-4500, 19700)
	; If dead it is not worth rezzing better just restart running
	If IsPlayerDead() Then Return $FAIL

	; Entering The Shattered Ravines
	Info('Entering The Shattered Ravines : careful')
	MoveTo(-4500, 20150)
	Move(-4500, 21000)
	RandomSleep(1000)
	If Not WaitMapLoading($ID_THE_SHATTERED_RAVINES, 10000, 2000) Then Return $FAIL
	; Hurry up before dying
	MoveTo(-9700, -10750)
	UseSkillEx($SS_MINDBENDER)
	MoveTo(-7900, -10550)
	Return $SUCCESS
EndFunc


;~ Farm loop
Func SpiritSlavesFarmLoop()
	Local $bottomPosition = [-8500, -6400]
	Local $topPosition = [-8900, -4600]
	; 5 Groups to kill
	For $group = 1 To 5
		If $group <> 4 Then MoveTo(-7465, -7900, 0, 0)
		; For the first group, we need the allies to die first	-	First wave
		If $group == 1 Then WaitForAlliesDead()
		Local $balled = True
		; The bottom group comes only the first three times		-	First, Second and Third waves
		If $group >= 1 And $group <= 3 Then $balled = WaitForFoesBall($bottomPosition)
		; The top group comes twice - 							-	Second and Fourth waves
		If $group == 2 Or $group == 5 Then $balled = WaitForFoesBall($topPosition)
		; FIXME: Sometimes groups get in range of player - we could fix with starting the fight
		; for now we just die and restart the zone
		If IsPlayerDead() Then Return RestartAfterDeath()
		Info('Killing group ' & $group)
		If ($balled ? FarmGroup() : QuickFarmGroup()) == $FAIL Then Return RestartAfterDeath()
	Next

	Info('Moving out of the zone and back again')
	RezoneToTheShatteredRavines()
	Return $SUCCESS
EndFunc


;~ Wait for all ennemies to be balled
Func WaitForFoesBall($position)
	Local $deadlock = TimerInit()
	Local $target = Null
	Local $foesCount = 0
	Local $validation = 0
	Local $me = GetMyAgent()
	Local $nearestFoe = GetNearestEnemyToAgent($me)
	; Wait until all foes are balled - as long as foes are not aggroed
	While IsPlayerAlive() And $foesCount < 8 And $validation < 2 And TimerDiff($deadlock) < 120000
		If $foesCount == 8 Then $validation += 1
		RandomSleep(1000)
		$target = GetNearestNPCInRangeOfCoords($position[0], $position[1], $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT)
		If $target <> Null Then $foesCount = CountFoesInRangeOfAgent($target, $RANGE_AREA)
		$me = GetMyAgent()
		$nearestFoe = GetNearestEnemyToAgent($me)
		Debug('foes: ' & $foesCount & '/8')
		If GetDistance($me, $nearestFoe) <= $MOB_AGGRO_RANGE Then Return False
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Warn('Timed out waiting for mobs to ball')
	Return True
EndFunc


;~ Farm groups
Func FarmGroup()
	Local $target = GetNearestNPCInRangeOfCoords(-8850, -5500, $ID_ALLEGIANCE_FOE, $RANGE_EARSHOT * 2)
	If IsRecharged($SS_MINDBENDER) Then UseSkillEx($SS_MINDBENDER)
	GetAlmostInRangeOfAgent($target)

	; Need a lot of energy in case both energy spirits are there: Zephyr add 30% mana cost and quicksand adds 1 energy
	Local $waitCount = 0
	While GetEnergy() < 40 And $waitCount < 10
		; Recovering 4e
		Sleep(3000)
		$waitCount += 1
	WEnd

	UseSkillEx($SS_MANTRA_OF_RESOLVE)
	; Recovering 8e
	RandomSleep(6000)
	UseSkillEx($SS_CHANNELING)
	Local $channeling_timer = TimerInit()
	; Recovering 2e
	RandomSleep(1500)
	UseSkillEx($SS_GREAT_DWARF_ARMOR)
	Local $great_dwarf_armor_timer = TimerInit()
	UseSkillEx($SS_ARCANE_ECHO)

	; Aggro foes
	Move(DllStructGetData($target, 'X'), DllStructGetData($target, 'Y'))
	RandomSleep(1000)
	UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
	Local $vengeful_was_khanhei_timer = TimerInit()

	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
	While $foesCount > 0
		If TimerDiff($vengeful_was_khanhei_timer) > 9000 Then
			If IsRecharged($SS_ARCANE_ECHO) And GetSkillbarSkillID($SS_ARCANE_ECHO) == $ID_VENGEFUL_WAS_KHANHEI Then
				UseSkillEx($SS_ARCANE_ECHO)
				$vengeful_was_khanhei_timer = TimerInit()
			ElseIf IsRecharged($SS_VENGEFUL_WAS_KHANHEI) Then
				UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
				$vengeful_was_khanhei_timer = TimerInit()
			EndIf
		EndIf
		If GetEnergy() >= 15 And IsRecharged($SS_VENGEFUL_WEAPON) Then UseSkillEx($SS_VENGEFUL_WEAPON)
		; No point getting ~2-3 energy
		If $foesCount > 3 And TimerDiff($channeling_timer) > 44000 Then
			UseSkillEx($SS_CHANNELING)
			$channeling_timer = TimerInit()
		EndIf
		; No point going defensive against so few enemies
		If $foesCount > 3 And TimerDiff($great_dwarf_armor_timer) > 38000 Then
			UseSkillEx($SS_GREAT_DWARF_ARMOR)
			$great_dwarf_armor_timer = TimerInit()
		EndIf
		Sleep(250)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	CleanseFromCripple()
	UseSkillEx($SS_MINDBENDER)
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Wait for allies to be dead
Func WaitForAlliesDead()
	Local $deadlock = TimerInit()
	Local $target = GetNearestNPCToCoords(-8600, -5810)

	; Wait until foes are in range of allies
	Local $distance = GetDistanceToPoint($target, -8600, -5810)
	While $distance < $RANGE_EARSHOT And TimerDiff($deadlock) < 120000
		RandomSleep(2000)
		$target = GetNearestNPCToCoords(-8600, -5810)
		$distance = GetDistanceToPoint($target, -8600, -5810)
		Debug('Target: ' & $distance)
	WEnd
	If (TimerDiff($deadlock) > 120000) Then Warn('Timed out waiting for allies to be dead')
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


;~ Rezoning to reset the farm
Func RezoneToTheShatteredRavines()
	Info('Rezoning')
	; Exiting to Jokos Domain
	If IsRecharged($SS_MINDBENDER) Then UseSkillEx($SS_MINDBENDER)
	MoveTo(-7800, -10250)
	If IsRecharged($SS_MINDBENDER) Then UseSkillEx($SS_MINDBENDER)
	MoveTo(-9000, -10900)
	If IsRecharged($SS_MINDBENDER) Then UseSkillEx($SS_MINDBENDER)
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
	UseSkillEx($SS_MINDBENDER)
	MoveTo(-7900, -10550)
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
	Local $temporaryPosition[] = [$startX + $xMove45degrees, $startY + $yMove45degrees]
	Return $temporaryPosition
EndFunc


;~ Sped up version in case we are caught off guard
Func QuickFarmGroup()
	MoveTo(-7475, -8040)

	UseSkillEx($SS_MANTRA_OF_RESOLVE)
	PingSleep(50)
	UseSkillEx($SS_CHANNELING)
	Local $channeling_timer = TimerInit()
	PingSleep(50)
	UseSkillEx($SS_GREAT_DWARF_ARMOR)
	Local $great_dwarf_armor_timer = TimerInit()
	UseSkillEx($SS_ARCANE_ECHO)
	PingSleep(50)
	UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
	Local $vengeful_was_khanhei_timer = TimerInit()

	Local $foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
	While $foesCount > 0
		If TimerDiff($vengeful_was_khanhei_timer) > 9000 Then
			If IsRecharged($SS_ARCANE_ECHO) And GetSkillbarSkillID($SS_ARCANE_ECHO) == $ID_VENGEFUL_WAS_KHANHEI Then
				UseSkillEx($SS_ARCANE_ECHO)
				$vengeful_was_khanhei_timer = TimerInit()
			ElseIf IsRecharged($SS_VENGEFUL_WAS_KHANHEI) Then
				UseSkillEx($SS_VENGEFUL_WAS_KHANHEI)
				$vengeful_was_khanhei_timer = TimerInit()
			EndIf
		EndIf
		If $foesCount < 5 And GetEnergy() >= 15 And IsRecharged($SS_VENGEFUL_WEAPON) Then UseSkillEx($SS_VENGEFUL_WEAPON)
		; No point getting ~2-3 energy
		If $foesCount > 3 And TimerDiff($channeling_timer) > 44000 Then
			UseSkillEx($SS_CHANNELING)
			$channeling_timer = TimerInit()
		EndIf
		; No point going defensive against so few enemies
		If $foesCount > 3 And TimerDiff($great_dwarf_armor_timer) > 38000 Then
			UseSkillEx($SS_GREAT_DWARF_ARMOR)
			$great_dwarf_armor_timer = TimerInit()
		EndIf
		Sleep(250)
		$foesCount = CountFoesInRangeOfAgent(GetMyAgent(), $RANGE_SPELLCAST + 200)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	CleanseFromCripple()
	UseSkillEx($SS_MINDBENDER)
	PickUpItems()
	Return $SUCCESS
EndFunc