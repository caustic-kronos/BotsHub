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

; Possible improvements : rewrite it all

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $DA_FEATHERS_FARMER_SKILLBAR = 'OgejkmrMbSmXfbaXNXTQ3lEYsXA'
Global Const $FEATHERS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Prayers' & @CRLF _
	& '- 10 in Scythe Mastery' & @CRLF _
	& '- 10 in Mysticism' & @CRLF _
	& '- A scythe with +5 energy and +20% enchantment duration' & @CRLF _
	& '- A one handed weapon +5 energy and +20% enchantment duration' & @CRLF _
	& '- A shield' & @CRLF _
	& '- Windwalker or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Average duration ~ 8m20
Global Const $FEATHERS_FARM_DURATION = (8 * 60 + 20) * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($FEATHERS_SAND_SHARDS) is better than UseSkillEx(1))
Global Const $FEATHERS_SAND_SHARDS			= 1
Global Const $FEATHERS_VOW_OF_STRENGTH		= 2
Global Const $FEATHERS_STAGGERING_FORCE		= 3
Global Const $FEATHERS_EREMITES_ATTACK		= 4
Global Const $FEATHERS_DASH					= 5
Global Const $FEATHERS_DWARVEN_STABILITY	= 6
Global Const $FEATHERS_CONVICTION			= 7
Global Const $FEATHERS_MYSTIC_REGENERATION	= 8

Global Const $MODELID_SENSALI_CLAW			= 3995
Global Const $MODELID_SENSALI_DARKFEATHER	= 3997
Global Const $MODELID_SENSALI_CUTTER		= 3999

Global $feathers_farm_setup = False

;~ Main method to farm feathers
Func FeathersFarm()
	If Not $feathers_farm_setup And SetupFeathersFarm() == $FAIL Then Return $PAUSE

	GoToJayaBluffs()
	Local $result = FeathersFarmLoop()
	ResignAndReturnToOutpost($ID_SEITUNG_HARBOR)
	Return $result
EndFunc


;~ Feathers farm setup
Func SetupFeathersFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_SEITUNG_HARBOR, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	If SetupPlayerFeathersFarm() == $FAIL Then Return $FAIL
	LeaveParty()

	Info('Entering Jaya Bluffs')
	Local $me = GetMyAgent()

	If GetDistanceToPoint($me, 17300, 17300) > 5000 Then MoveTo(17000, 12400)
	If GetDistanceToPoint($me, 17300, 17300) > 4400 Then MoveTo(19000, 13450)
	If GetDistanceToPoint($me, 17300, 17300) > 1800 Then MoveTo(18750, 16000)

	GoToJayaBluffs()
	MoveTo(10500, -13100)
	Move(10970, -13360)
	RandomSleep(1000)
	WaitMapLoading($ID_SEITUNG_HARBOR, 10000, 2000)
	$feathers_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerFeathersFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_DERVISH Then
		LoadSkillTemplate($DA_FEATHERS_FARMER_SKILLBAR)
	Else
		Warn('Should run this farm as dervish')
		Return $FAIL
	EndIf
	RandomSleep(250)
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Jaya Bluffs
Func GoToJayaBluffs()
	TravelToOutpost($ID_SEITUNG_HARBOR, $district_name)
	While GetMapID() <> $ID_JAYA_BLUFFS
		Info('Moving to Jaya Bluffs')
		MoveTo(17300, 17300)
		Move(16800, 17550)
		RandomSleep(1000)
		WaitMapLoading($ID_JAYA_BLUFFS, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func FeathersFarmLoop()
	If GetMapID() <> $ID_JAYA_BLUFFS Then Return $FAIL

	Info('Running to Sensali.')
	UseConsumable($ID_BIRTHDAY_CUPCAKE)
	MoveTo(9000, -12680)
	MoveTo(7588, -10609)
	MoveTo(2900, -9700)
	MoveTo(1540, -6995)
	Info('Farming Sensali.')
	MoveKill(-472, -4342, False)
	MoveKill(-1536, -1686)
	MoveKill(586, -76)
	MoveKill(-1556, 2786)
	MoveKill(-2229, -815, True, 2*60*1000)
	MoveKill(-5247, -3290)
	MoveKill(-6994, -2273)
	MoveKill(-5042, -6638)
	MoveKill(-11040, -8577)
	MoveKill(-10860, -2840)
	MoveKill(-14900, -3000)
	MoveKill(-12200, 150)
	MoveKill(-12500, 4000)
	MoveKill(-12111, 1690)
	MoveKill(-10303, 4110)
	MoveKill(-10500, 5500)
	MoveKill(-9700, 2400)

	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Move and kill I suppose
Func MoveKill($x, $y, $waitForSettle = True, $timeout = 5*60*1000)
	Local $angle = 0
	Local $stuckCount = 0
	Local $blocked = 0
	Local $deadlock = TimerInit()

	Move($x, $y)
	Local $me = GetMyAgent()
	; TODO: fix this mess
	While GetDistanceToPoint($me, $x, $y) > 250
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsPlayerDead() Then Return $FAIL
		If IsRecharged($FEATHERS_DWARVEN_STABILITY) Then UseSkillEx($FEATHERS_DWARVEN_STABILITY)
		If IsRecharged($FEATHERS_DASH) Then UseSkillEx($FEATHERS_DASH)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HealthPercent') < 0.9 Then
			If GetEffectTimeRemaining($ID_MYSTIC_REGENERATION) <= 0 Then UseSkillEx($FEATHERS_MYSTIC_REGENERATION)
			If GetEffectTimeRemaining($ID_CONVICTION) <= 0 Then UseSkillEx($FEATHERS_CONVICTION)
		EndIf
		$me = GetMyAgent()
		If CountFoesInRangeOfAgent($me, 1200, IsSensali) > 1 Then
			Sleep(2000)
			Kill($waitForSettle)
		EndIf
		$me = GetMyAgent()
		If Not IsPlayerMoving() Then
			$blocked += 1
			If $blocked <= 5 Then
				Move($x, $y)
			Else
				$me = GetMyAgent()
				$angle += 40
				Move(DllStructGetData($me, 'X')+300*sin($angle), DllStructGetData($me, 'Y') + 300*cos($angle))
				Sleep(2000)
				Move($x, $y)
			EndIf
		EndIf
		$stuckCount += 1
		If $stuckCount > 25 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf
		RandomSleep(250)
		$me = GetMyAgent()
	WEnd
	Return IsPlayerAlive() ? $SUCCESS : $FAIL
EndFunc


;~ Kill foes
Func Kill($waitForSettle = True)
	Local $deadlock, $timeout = 2*60*1000

	Local $stuckCount = 0
	CheckAndSendStuckCommand()
	If GetEffectTimeRemaining($ID_SAND_SHARDS) <= 0 Then UseSkillEx($FEATHERS_SAND_SHARDS)
	If $waitForSettle Then
		If Not WaitForSettle() Then Return $FAIL
	EndIf
	CheckAndSendStuckCommand()
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeWeaponSet(1)
	If IsRecharged($FEATHERS_VOW_OF_STRENGTH) Then UseSkillEx($FEATHERS_VOW_OF_STRENGTH)
	If GetEnergy() >= 10 Then
		UseSkillEx($FEATHERS_STAGGERING_FORCE)
		UseSkillEx($FEATHERS_EREMITES_ATTACK, $target)
	EndIf
	ChangeWeaponSet(1)

	$deadlock = TimerInit()

	While CountFoesInRangeOfAgent(GetMyAgent(), 900, IsSensali) > 0
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While IsPlayerAlive() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsPlayerDead() Then Return $FAIL
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If GetEffectTimeRemaining($ID_MYSTIC_REGENERATION) <= 0 Then UseSkillEx($FEATHERS_MYSTIC_REGENERATION)
		If GetEffectTimeRemaining($ID_CONVICTION) <= 0 Then UseSkillEx($FEATHERS_CONVICTION)
		If GetEffectTimeRemaining($ID_SAND_SHARDS) <= 0 And CountFoesInRangeOfAgent(GetMyAgent(), 300, IsSensali) > 1 Then UseSkillEx($FEATHERS_SAND_SHARDS)
		If IsRecharged($FEATHERS_VOW_OF_STRENGTH) <= 0 Then UseSkillEx($FEATHERS_VOW_OF_STRENGTH)
		$stuckCount += 1
		If $stuckCount > 100 Then
			$stuckCount = 0
			CheckAndSendStuckCommand()
		EndIf

		Sleep(250)
		Attack($target)
	WEnd
	RandomSleep(500)
	Info('Looting')
	PickUpItems()
	FindAndOpenChests()
	ChangeWeaponSet(2)
	Return $SUCCESS
EndFunc


;~ Wait for foes to settle, I guess ?
Func WaitForSettle($Timeout = 10000)
	Local $me = GetMyAgent()
	Local $target
	Local $deadlock = TimerInit()
	While CountFoesInRangeOfAgent(-2,900) == 0 And (TimerDiff($deadlock) < 5000)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HealthPercent') < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_MYSTIC_REGENERATION) <= 0 Then UseSkillEx($FEATHERS_MYSTIC_REGENERATION)
		If GetEffectTimeRemaining($ID_CONVICTION) <= 0 Then UseSkillEx($FEATHERS_CONVICTION)
		If GetEffectTimeRemaining($ID_SAND_SHARDS) <= 0 Then UseSkillEx($FEATHERS_SAND_SHARDS)
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd

	If CountFoesInRangeOfAgent($me, 900) == 0 Then Return False

	$deadlock = TimerInit()
	While (GetDistance($me, $target) > $RANGE_NEARBY) And (TimerDiff($deadlock) < $Timeout)
		If IsPlayerDead() Then Return False
		If DllStructGetData($me, 'HealthPercent') < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_MYSTIC_REGENERATION) <= 0 Then UseSkillEx($FEATHERS_MYSTIC_REGENERATION)
		If GetEffectTimeRemaining($ID_CONVICTION) <= 0 Then UseSkillEx($FEATHERS_CONVICTION)
		If GetEffectTimeRemaining($ID_SAND_SHARDS) <= 0 Then UseSkillEx($FEATHERS_SAND_SHARDS)
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd
	Return True
EndFunc


;~ Return True if agent is a Sensali
Func IsSensali($agent)
	Local $modelID = DllStructGetData($agent, 'ModelID')
	Return $modelID == $MODELID_SENSALI_CLAW _
		Or $modelID == $MODELID_SENSALI_DARKFEATHER _
		Or $modelID == $MODELID_SENSALI_CUTTER
EndFunc
