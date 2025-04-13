; Author: caustic-kronos (aka Kronos, Night, Svarog)
; Copyright 2025 caustic-kronos
;
; Licensed under the Apache License, Version 2.0 (the "License");
; you may not use this file except in compliance with the License.
; You may obtain a copy of the License at
; http://www.apache.org/licenses/LICENSE-2.0
;
; Unless required by applicable law or agreed to in writing, software
; distributed under the License is distributed on an "AS IS" BASIS,
; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
; See the License for the specific language governing permissions and
; limitations under the License.

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $FeathersBotVersion = '3.0'

; ==== Constantes ====
Local Const $DAFeathersFarmerSkillbar = 'OgejkmrMbSmXfbaXNXTQ3lEYsXA'
Local Const $FeathersFarmInformations = 'For best results, have :' & @CRLF _
	& '- 16 in Earth Prayers' & @CRLF _
	& '- 10 in Scythe Mastery' & @CRLF _
	& '- 10 in Mysticism' & @CRLF _
	& '- A scythe with +5 energy and +20% enchantment duration' & @CRLF _
	& '- A one handed weapon +5 energy and +20% enchantment duration' & @CRLF _
	& '- A shield' & @CRLF _
	& '- Windwalker or Blessed insignias on all the armor pieces' & @CRLF _
	& '- A superior vigor rune'
; Skill numbers declared to make the code WAY more readable (UseSkillEx($Feathers_SandShards) is better than UseSkillEx(1))
Local Const $Feathers_SandShards = 1
Local Const $Feathers_VowOfStrength = 2
Local Const $Feathers_StaggeringForce = 3
Local Const $Feathers_EremitesAttack = 4
Local Const $Feathers_Dash = 5
Local Const $Feathers_DwarvenStability = 6
Local Const $Feathers_Conviction = 7
Local Const $Feathers_MysticRegeneration = 8

Local Const $ModelID_Sensali_Claw = 3944
Local Const $ModelID_Sensali_Darkfeather = 3946
Local Const $ModelID_Sensali_Cutter = 3948

Local $FEATHERS_FARM_SETUP = False

;~ Main method to farm Feathers
Func FeathersFarm($STATUS)
	If Not $FEATHERS_FARM_SETUP Then
		SetupFeathersFarm()
		$FEATHERS_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return FeathersFarmLoop()
EndFunc


Func SetupFeathersFarm()
	Out('Setting up farm')
	If GetMapID() <> $ID_Seitung_Harbor Then
		DistrictTravel($ID_Seitung_Harbor, $ID_EUROPE, $ID_FRENCH)
	EndIf
	SwitchMode($ID_NORMAL_MODE)
	LeaveGroup()
	LoadSkillTemplate($DAFeathersFarmerSkillbar)

	Out('Entering Jaya Bluffs')
	Local $Me = GetAgentByID(-2)
	Local $X = DllStructGetData($Me, 'X')
	Local $Y = DllStructGetData($Me, 'Y')
	
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
	Out('Preparations complete')
EndFunc


;~ Farm loop
Func FeathersFarmLoop()
	Out('Entering Jaya Bluffs')
	Move(16800, 17550)
	WaitMapLoading($ID_Jaya_Bluffs, 10000, 2000)

	Out("Running to Sensali.")
	UseConsumable($ID_Birthday_Cupcake)
	MoveTo(9000, -12680)
	MoveTo(7588, -10609)
	MoveTo(2900, -9700)
	MoveTo(1540, -6995)
	Out("Farming Sensali.")
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
		
	If GetIsDead(-2) Then
		BackToSeitungHarborOutpost()
		Return 1
	EndIf

	BackToSeitungHarborOutpost()
	Return 0
EndFunc


Func BackToSeitungHarborOutpost()
	Out('Porting to Seitung Harbor')
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Seitung_Harbor, 10000, 2000)
EndFunc


Func MoveRun($x, $y, $timeOut = 2*60*1000)
	If GetIsDead(-2) Then Return
	Local $me = GetAgentByID(-2)
	Local $deadlock = TimerInit()
	
	Move($x, $y)
	While Not GetIsDead(-2) And ComputeDistance(DllStructGetData($me, 'X'), DllStructGetData($me, 'Y'), $x, $y) > 250
		If TimerDiff($deadlock) > $timeOut Then
			Resign()
			Sleep(3000)
			$deadlock = TimerInit()
			While Not GetIsDead(-2) And TimerDiff($deadlock) < 30000
				Sleep(3000)
				If TimerDiff($deadlock) > 15000 Then Resign()
			WEnd
		EndIf
		If IsRecharged($Feathers_DwarvenStability) Then UseSkillEx($Feathers_DwarvenStability)
		If IsRecharged($Feathers_Dash) Then UseSkillEx($Feathers_Dash)
		$me = GetAgentByID(-2)
		If DllStructGetData($me, "HP") < 0.95 And GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If DllStructGetData($me, 'MoveX') = 0 And DllStructGetData($me, 'MoveY') = 0 Then Move($x, $y)
		RndSleep(250)
	WEnd 
EndFunc

Func MoveKill($x, $y, $aWaitForSettle = True, $aTimeout = 5*60*1000)
	If GetIsDead(-2) Then Return False
	Local $Me = GetAgentByID(-2)
	Local $Angle = 0
	Local $lStuckCount = 0
	Local $Blocked = 0
	Local $lDeadlock = TimerInit()	
	
	Move($x, $y)
	While ComputeDistance(DllStructGetData($Me, 'X'), DllStructGetData($Me, 'Y'), $x, $y) > 250
		If TimerDiff($lDeadlock) > $aTimeout Then
			Resign()
			Sleep(3000)
			$lDeadlock = TimerInit()
			While Not GetIsDead(-2) And TimerDiff($lDeadlock) < 30000
				Sleep(3000)
				If TimerDiff($lDeadlock) > 15000 Then Resign()
			WEnd
			If GetIsDead(-2) Then Return False
		EndIf
		If GetIsDead(-2) Then Return False
		If IsRecharged($Feathers_DwarvenStability) Then UseSkillEx($Feathers_DwarvenStability)
		If IsRecharged($Feathers_Dash) Then UseSkillEx($Feathers_Dash)
		If DllStructGetData($Me, "HP") < 0.9 Then
			If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
			If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		EndIf
		TargetNearestEnemy()
		$Me = GetAgentByID(-2)
		If CountFoesInRangeOfAgent(-2, 1200, IsSensali) > 1 Then
			Sleep(2000)
			Kill($aWaitForSettle)
		EndIf
		If DllStructGetData($Me, 'MoveX') = 0 And DllStructGetData($Me, 'MoveY') = 0 Then
			$Blocked += 1
			If $Blocked <= 5 Then
				Move($x, $y)
			Else
				$Me = GetAgentByID(-2)
				$Angle += 40
				Move(DllStructGetData($Me, 'X')+300*sin($Angle), DllStructGetData($Me, 'Y')+300*cos($Angle))
				Sleep(2000)
				Move($x, $y)
			EndIf
		EndIf
		$lStuckCount += 1
		If $lStuckCount > 25 Then
			$lStuckCount = 0
			SendChat("stuck", "/")
			RndSleep(50)
		EndIf
		RndSleep(250)
	WEnd
EndFunc ;==> MoveKill


Func Kill($aWaitForSettle = True)
	If GetIsDead(-2) Then Return
	
	Local $lDeadlock, $lTimeout = 2*60*1000
		
	Local $lStuckCount = 0
	SendChat("stuck", "/")
	RndSleep(50)
	If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Feathers_SandShards)
	If $aWaitForSettle Then
		If Not WaitForSettle() Then Return False
	EndIf
	SendChat("stuck", "/")
	RndSleep(50)
	TargetNearestEnemy()
	ChangeWeaponSet(1)
	If IsRecharged($Feathers_VowOfStrength) Then UseSkillEx($Feathers_VowOfStrength)
	If GetEnergy(-2) >= 10 Then
		UseSkillEx($Feathers_StaggeringForce)
		UseSkillEx($Feathers_EremitesAttack, -1)
	EndIf
	ChangeWeaponSet(1)
	
	$lDeadlock = TimerInit()
	
	While CountFoesInRangeOfAgent(-2, 900, IsSensali) > 0
		If TimerDiff($lDeadlock) > $lTimeout Then
			Resign()
			Sleep(3000)
			$lDeadlock = TimerInit()
			Do
				Sleep(3000)
				If TimerDiff($lDeadlock) > 15000 Then Resign()
			Until GetIsDead(-2) Or TimerDiff($lDeadlock) > 30000
			If GetIsDead(-2) Then Return False
		EndIf
		If GetIsDead(-2) Then Return
		TargetNearestEnemy()
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 And CountFoesInRangeOfAgent(-2, 300, IsSensali) > 1 Then UseSkillEx($Feathers_SandShards)
		If IsRecharged($Feathers_VowOfStrength) <= 0 Then UseSkillEx($Feathers_VowOfStrength)
		$lStuckCount += 1
		If $lStuckCount > 100 Then
			$lStuckCount = 0
			SendChat("stuck", "/")
			RndSleep(50)
		EndIf
		
		Sleep(250)
		Attack(-1)		
	WEnd
	RndSleep(500)
	Out('Looting')
	PickUpItems()
	CheckForChests()
	ChangeWeaponSet(2)
EndFunc


Func WaitForSettle($Timeout = 10000)
	Local $Target
	Local $Deadlock = TimerInit()
	While Not GetIsDead(-2) And CountFoesInRangeOfAgent(-2,900) == 0 And (TimerDiff($Deadlock) < 5000)
		If GetIsDead(-2) Then Return False
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Feathers_SandShards)
		Sleep(250)
		$Target = GetFurthestNPCInRangeOfCoords(null, DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $RANGE_EARSHOT)
	WEnd 

	If CountFoesInRangeOfAgent(-2, 900) == 0 Then Return False

	Local $Deadlock = TimerInit()
	While (GetDistance(-2, $Target) > $RANGE_NEARBY) And (TimerDiff($Deadlock) < $Timeout)
		If GetIsDead(-2) Then Return False
		If DllStructGetData(GetAgentByID(-2), "HP") < 0.7 Then Return True
		If GetEffectTimeRemaining($ID_Mystic_Regeneration) <= 0 Then UseSkillEx($Feathers_MysticRegeneration)
		If GetEffectTimeRemaining($ID_Conviction) <= 0 Then UseSkillEx($Feathers_Conviction)
		If GetEffectTimeRemaining($ID_Sand_Shards) <= 0 Then UseSkillEx($Feathers_SandShards)
		Sleep(250)	
		$Target = GetFurthestNPCInRangeOfCoords(null, DllStructGetData(GetAgentByID(-2), 'X'), DllStructGetData(GetAgentByID(-2), 'Y'), $RANGE_EARSHOT)
	WEnd 
	Return True
EndFunc


Func IsSensali($agent)
	Local $playerNumber = DllStructGetData($agent, 'PlayerNumber')
	If $playerNumber = $ModelID_Sensali_Claw Or $playerNumber = $ModelID_Sensali_Darkfeather Or $playerNumber = $ModelID_Sensali_Cutter Then
		Return True
	Else
		Return False
	EndIf
EndFunc