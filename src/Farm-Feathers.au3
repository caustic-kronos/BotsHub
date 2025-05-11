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
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements : rewrite it all

Opt('MustDeclareVars', 1)

Global Const $FeathersBotVersion = '3.0'

; ==== Constants ====
Global Const $DAFeathersFarmerSkillbar = 'OgejkmrMbSmXfbaXNXTQ3lEYsXA'
Global Const $FeathersFarmInformations = 'For best results, have :' & @CRLF _
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

; Skill numbers declared to make the code WAY more readable (UseSkillEx($Feathers_SandShards) is better than UseSkillEx(1))
Global Const $Feathers_SandShards = 1
Global Const $Feathers_VowOfStrength = 2
Global Const $Feathers_StaggeringForce = 3
Global Const $Feathers_EremitesAttack = 4
Global Const $Feathers_Dash = 5
Global Const $Feathers_DwarvenStability = 6
Global Const $Feathers_Conviction = 7
Global Const $Feathers_MysticRegeneration = 8

Global Const $ModelID_Sensali_Claw = 3944
Global Const $ModelID_Sensali_Darkfeather = 3946
Global Const $ModelID_Sensali_Cutter = 3948

Global $FEATHERS_FARM_SETUP = False

;~ Main method to farm feathers
Func FeathersFarm($STATUS)
	If Not $FEATHERS_FARM_SETUP Then
		SetupFeathersFarm()
		$FEATHERS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return FeathersFarmLoop()
EndFunc


;~ Feathers farm setup
Func SetupFeathersFarm()
	Info('Setting up farm')
	If GetMapID() <> $ID_Seitung_Harbor Then DistrictTravel($ID_Seitung_Harbor, $DISTRICT_NAME)
	SwitchMode($ID_NORMAL_MODE)
	LeaveGroup()
	LoadSkillTemplate($DAFeathersFarmerSkillbar)

	Info('Entering Jaya Bluffs')
	Local $me = GetMyAgent()
	Local $X = DllStructGetData($me, 'X')
	Local $Y = DllStructGetData($me, 'Y')

	If ComputeDistance($X, $Y, 17300, 17300) > 5000 Then
		MoveTo(17000, 12400)
	EndIf

	If ComputeDistance($X, $Y, 17300, 17300) > 4400 Then
		MoveTo(19000, 13450)
	EndIf

	If ComputeDistance($X, $Y, 17300, 17300) > 1800 Then
		MoveTo(18750, 16000)
	EndIf

	MoveTo(17300, 17300)
	Move(16800, 17550)
	WaitMapLoading($ID_Jaya_Bluffs, 10000, 2000)
	Move(10970, -13360)
	WaitMapLoading($ID_Seitung_Harbor, 10000, 2000)
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func FeathersFarmLoop()
	Info('Entering Jaya Bluffs')
	Move(16800, 17550)
	WaitMapLoading($ID_Jaya_Bluffs, 10000, 2000)

	Info('Running to Sensali.')
	UseConsumable($ID_Birthday_Cupcake)
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

	If GetIsDead() Then
		BackToSeitungHarborOutpost()
		Return 1
	EndIf

	BackToSeitungHarborOutpost()
	Return 0
EndFunc


;~ Return to Seitung Harbor outpost
Func BackToSeitungHarborOutpost()
	Info('Porting to Seitung Harbor')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Seitung_Harbor, 10000, 2000)
EndFunc


;~ Move and ... run ? Who the fuck wrote this ?
Func MoveRun($x, $y, $timeOut = 2*60*1000)
	If GetIsDead() Then Return
	Local $me = GetMyAgent()
	Local $deadlock = TimerInit()

	Move($x, $y)
	While Not GetIsDead() And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $x, $y) > 250
		If TimerDiff($deadlock) > $timeOut Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While Not GetIsDead() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsRecharged($Feathers_DwarvenStability) Then UseSkillEx($Feathers_DwarvenStability)
		If IsRecharged($Feathers_Dash) Then UseSkillEx($Feathers_Dash)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HP') < 0.95 And GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If DllStructGetData($me, 'MoveX') = 0 And DllStructGetData($me, 'MoveY') = 0 Then Move($x, $y)
		RndSleep(250)
		$me = GetMyAgent()
	WEnd
EndFunc


;~ Move and kill I suppose
Func MoveKill($x, $y, $waitForSettle = True, $timeout = 5*60*1000)
	If GetIsDead() Then Return False
	Local $Angle = 0
	Local $stuckCount = 0
	Local $Blocked = 0
	Local $deadlock = TimerInit()

	Move($x, $y)
	Local $me = GetMyAgent()
	; TODO: fix this mess
	While ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $x, $y) > 250
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While Not GetIsDead() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
			If GetIsDead() Then Return False
		EndIf
		If GetIsDead() Then Return False
		If IsRecharged($Feathers_DwarvenStability) Then UseSkillEx($Feathers_DwarvenStability)
		If IsRecharged($Feathers_Dash) Then UseSkillEx($Feathers_Dash)
		$me = GetMyAgent()
		If DllStructGetData($me, 'HP') < 0.9 Then
			If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
			If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		EndIf
		$me = GetMyAgent()
		If CountFoesInRangeOfAgent($me, 1200, IsSensali) > 1 Then
			Sleep(2000)
			Kill($waitForSettle)
		EndIf
		$me = GetMyAgent()
		If DllStructGetData($me, 'MoveX') = 0 And DllStructGetData($me, 'MoveY') = 0 Then
			$Blocked += 1
			If $Blocked <= 5 Then
				Move($x, $y)
			Else
				$me = GetMyAgent()
				$Angle += 40
				Move(DllStructGetData($me, 'X')+300*sin($Angle), DllStructGetData($me, 'Y')+300*cos($Angle))
				Sleep(2000)
				Move($x, $y)
			EndIf
		EndIf
		$stuckCount += 1
		If $stuckCount > 25 Then
			$stuckCount = 0
			SendChat('stuck', '/')
			RndSleep(50)
		EndIf
		RndSleep(250)
		$me = GetMyAgent()
	WEnd
EndFunc


;~ Kill foes
Func Kill($waitForSettle = True)
	If GetIsDead() Then Return

	Local $deadlock, $timeout = 2*60*1000

	Local $stuckCount = 0
	SendChat('stuck', '/')
	RndSleep(50)
	If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Feathers_SandShards)
	If $waitForSettle Then
		If Not WaitForSettle() Then Return False
	EndIf
	SendChat('stuck', '/')
	RndSleep(50)
	Local $target = GetNearestEnemyToAgent(GetMyAgent())
	ChangeWeaponSet(1)
	If IsRecharged($Feathers_VowOfStrength) Then UseSkillEx($Feathers_VowOfStrength)
	If GetEnergy() >= 10 Then
		UseSkillEx($Feathers_StaggeringForce)
		UseSkillEx($Feathers_EremitesAttack, $target)
	EndIf
	ChangeWeaponSet(1)

	$deadlock = TimerInit()

	While CountFoesInRangeOfAgent(GetMyAgent(), 900, IsSensali) > 0
		If TimerDiff($deadlock) > $timeout Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While Not GetIsDead() And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
			If GetIsDead() Then Return False
		EndIf
		If GetIsDead() Then Return
		$target = GetNearestEnemyToAgent(GetMyAgent())
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 And CountFoesInRangeOfAgent(GetMyAgent(), 300, IsSensali) > 1 Then UseSkillEx($Feathers_SandShards)
		If IsRecharged($Feathers_VowOfStrength) <= 0 Then UseSkillEx($Feathers_VowOfStrength)
		$stuckCount += 1
		If $stuckCount > 100 Then
			$stuckCount = 0
			SendChat('stuck', '/')
			RndSleep(50)
		EndIf

		Sleep(250)
		Attack($target)
	WEnd
	RndSleep(500)
	Info('Looting')
	PickUpItems()
	CheckForChests()
	ChangeWeaponSet(2)
EndFunc


;~ Wait for foes to settle, I guess ?
Func WaitForSettle($Timeout = 10000)
	Local $me = GetMyAgent()
	Local $target
	Local $deadlock = TimerInit()
	While Not GetIsDead() And CountFoesInRangeOfAgent(-2,900) == 0 And (TimerDiff($deadlock) < 5000)
		If GetIsDead() Then Return False
		If DllStructGetData($me, 'HP') < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Feathers_SandShards)
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords(null, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd

	If CountFoesInRangeOfAgent($me, 900) == 0 Then Return False

	$deadlock = TimerInit()
	While (GetDistance($me, $target) > $RANGE_NEARBY) And (TimerDiff($deadlock) < $Timeout)
		If GetIsDead() Then Return False
		If DllStructGetData($me, 'HP') < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Feathers_SandShards)
		Sleep(250)
		$me = GetMyAgent()
		$target = GetFurthestNPCInRangeOfCoords(null, DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $RANGE_EARSHOT)
	WEnd
	Return True
EndFunc


;~ Return True if agent is a Sensali
Func IsSensali($agent)
	Local $playerNumber = DllStructGetData($agent, 'PlayerNumber')
	If $playerNumber = $ModelID_Sensali_Claw Or $playerNumber = $ModelID_Sensali_Darkfeather Or $playerNumber = $ModelID_Sensali_Cutter Then
		Return True
	Else
		Return False
	EndIf
EndFunc