; Author: TDawg
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

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $SoOFarmerSkillbar = ''
Global Const $SoOFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1esurge replaced by a ROJ, inept replaced by blinding surge)' & @CRLF _
	& 'xxmn average in NM' & @CRLF _
	& 'xxmn average in HM with cons (automatically used if HM is on)' & @CRLF _

Global Const $ID_SoO_Torch = 22342

Global $SOO_FARM_SETUP = False
Global $SoODeathsCount = 0


;~ Main method to farm SoO
Func SoOFarm($STATUS)
	If Not $SOO_FARM_SETUP Then
		SetupSoOFarm()
		$SOO_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return SoOFarmLoop()
EndFunc


;~ SoO farm setup
Func SetupSoOFarm()
	Info('Setting up farm')
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Vloxs_Fall Then DistrictTravel($ID_Vloxs_Fall, $DISTRICT_NAME)

	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf

	$SoODeathsCount = 0
	Info('Making way to portal')
	MoveTo(16448, 14830)
	MoveTo(15827, 13368)
	Move(15450, 12680)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Arbor_Bay)
		Sleep(500)
		MoveTo(15827, 13368)
		Move(15450, 12680)
	WEnd

	AdlibRegister('SoOGroupIsAlive', 10000)

	Local $aggroRange = $RANGE_SPELLCAST + 100
	Info('Making way to Shards of Orr')
	MoveTo(16327, 11607)
	GoToNPC(GetNearestNPCToCoords(16362, 11627))
	RndSleep(250)
	Dialog(0x84)
	RndSleep(500)

	While $SoODeathsCount < 6 And Not SoOIsInRange (11156, -17802, 1250)
		MoveAggroAndKill(13122, 10437, '1', $aggroRange)
		MoveAggroAndKill(10668, 6530, '2', $aggroRange)
		MoveAggroAndKill(9028, -1613, '3', $aggroRange)
		MoveAggroAndKill(8803, -5104, '4', $aggroRange)
		MoveAggroAndKill(8125, -8247, '5', $aggroRange)
		If SoOIsFailure() Then Return 1
		MoveAggroAndKill(8634, -11529, '6', $aggroRange)
		MoveAggroAndKill(9559, -13494, '7', $aggroRange)
		MoveAggroAndKill(10314, -16111, '8', $aggroRange)
		MoveAggroAndKill(11156, -17802, '9', $aggroRange)
		If SoOIsFailure() Then Return 1
	WEnd
	AdlibUnRegister('SoOGroupIsAlive')
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func SoOFarmLoop()
	AdlibRegister('SoOGroupIsAlive', 10000)

	Local $aggroRange = $RANGE_SPELLCAST + 100

	Info('Get quest reward')
	MoveTo(11996, -17846)
	GoToNPC(GetNearestNPCToCoords(12056, -17882))
	RndSleep(250)
	Dialog(0x832407)
	RndSleep(500)
	; Doubled to secure
	GoToNPC(GetNearestNPCToCoords(12056, -17882))
	Dialog(0x832407)
	RndSleep(500)

	Info('Get in dungeon to reset quest')
	MoveTo(11177, -17683)
	RndSleep(500)
	MoveTo(10218, -18864)
	RndSleep(500)
	MoveTo(9519, -19968)
	RndSleep(500)
	Move(9250, -20200)
	RndSleep(2000)
	While Not WaitMapLoading($ID_SoO_lvl1)
		Sleep(500)
		MoveTo(9519, -19968)
		Move(9250, -20200)
	WEnd
	RndSleep(2000)

	Info('Get out of dungeon to reset quest')
	RndSleep(2000)
	Move(-15000, 8600)
	RndSleep(500)
	Move(-15650, 8900)
	RndSleep(2000)
	While Not WaitMapLoading($ID_Arbor_Bay)
		Info('Stuck, retrying')
		Sleep(500)
		MoveTo(-15000, 8600)
		Move(-15650, 8900)
	WEnd
	RndSleep(2000)


	Info('Get quest')
	MoveTo(10218, -18864)
	RndSleep(500)
	MoveTo(11177, -17683)
	RndSleep(500)
	MoveTo(11996, -17846)
	RndSleep(500)
	GoToNPC(GetNearestNPCToCoords(12056, -17882))
	RndSleep(250)
	Dialog(0x832401)
	RndSleep(500)
	; Doubled to secure
	GoToNPC(GetNearestNPCToCoords(12056, -17882))
	RndSleep(250)
	Dialog(0x832401)
	RndSleep(500)
	Info('Talk to Shandra again if already had quest')
	GoToNPC(GetNearestNPCToCoords(12056, -17882))
	RndSleep(250)
	Dialog(0x832405)
	RndSleep(500)
	; Doubled to secure
	GoToNPC(GetNearestNPCToCoords(12056, -17882))
	RndSleep(250)
	Dialog(0x832405)
	RndSleep(500)

	Info('Get back in')
	MoveTo(11177, -17683)
	RndSleep(500)
	MoveTo(10218, -18864)
	RndSleep(500)
	MoveTo(9519, -19968)
	RndSleep(500)
	Move(9250, -20200)
	RndSleep(2000)
	While Not WaitMapLoading($ID_SoO_lvl1)
		Sleep(500)
		MoveTo(9519, -19968)
		Move(9250, -20200)
	WEnd

	; Waiting to be alive before retrying
	While Not IsGroupAlive()
		Sleep(2000)
	WEnd

	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While $SoODeathsCount < 6 And Not SoOIsInRange(9232, 11483, 1250)
		SafeMoveAggroAndKill(-11686, 10427, 'Getting blessing', $aggroRange)
		GoToNPC(GetNearestNPCToCoords(-11657, 10465))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(500)

		SafeMoveAggroAndKill(-10486, 9587, '1', $aggroRange)
		SafeMoveAggroAndKill(-6196, 10260, '2', $aggroRange)
		SafeMoveAggroAndKill(-3819, 11737, '3', $aggroRange)
		SafeMoveAggroAndKill(-1123, 13649, '4', $aggroRange)
		SafeMoveAggroAndKill(2734, 16041, '5', $aggroRange)
		SafeMoveAggroAndKill(3877, 14790, '6', $aggroRange)
		SafeMoveAggroAndKill(4771, 13659, '7', $aggroRange)
		SafeMoveAggroAndKill(6780, 13039, '8', $aggroRange)
		SafeMoveAggroAndKill(8056, 12349, '9', $aggroRange)
		SafeMoveAggroAndKill(9232, 11483, 'Triggering beacon 2', $aggroRange)
	WEnd

	While $SoODeathsCount < 6 And Not SoOIsInRange(16134, 11781, 1250)
		SafeMoveAggroAndKill(6799, 11264, 'Killing boss for key', $aggroRange)
		PickUpItems()
		SafeMoveAggroAndKill(11298, 13891, '1', $aggroRange)
		SafeMoveAggroAndKill(13255, 15175, '2', $aggroRange)
		SafeMoveAggroAndKill(15708, 17138, '3', $aggroRange)
		SafeMoveAggroAndKill(16884, 12527, '4', $aggroRange)
		SafeMoveAggroAndKill(16134, 11781, 'Triggering beacon 3', $aggroRange)
	WEnd

	While $SoODeathsCount < 6 And Not SoOIsInRange(20002, 903, 1250)
		SafeMoveAggroAndKill(15441, 9372, '1', $aggroRange)
		SafeMoveAggroAndKill(14348, 6452, '2', $aggroRange)
		SafeMoveAggroAndKill(14917, 5384, '3', $aggroRange)

		Info('Open dungeon door')
		ClearTarget()
		RndSleep(500)
		Moveto(15041, 5475)
		RndSleep(500)
		ActionInteract()
		ActionInteract()
		RndSleep(500)
		Moveto(15094, 5493)
		RndSleep(500)
		ActionInteract()
		ActionInteract()

		SafeMoveAggroAndKill(17146, 2643, '4', $aggroRange)
		SafeMoveAggroAndKill(18209, 1609, '5', $aggroRange)
		SafeMoveAggroAndKill(20002, 903, '6', $aggroRange)
	WEnd

	Info('Going through portal')
	Move(20400, 1300)
	RndSleep(2000)
	While Not WaitMapLoading($ID_SoO_lvl2)
		Sleep(500)
		MoveTo(20002, 903)
		Move(20400, 1300)
	WEnd
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While $SoODeathsCount < 6 And Not SoOIsInRange(-18725, -9171, 1250)
		SafeMoveAggroAndKill(-14032, -19407, 'Getting blessing', $aggroRange)
		GoToNPC(GetNearestNPCToCoords(-14076, -19457))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(500)

		SafeMoveAggroAndKill(-14215, -17456, '1', $aggroRange)
		SafeMoveAggroAndKill(-16191, -16740, '2', $aggroRange)
		SafeMoveAggroAndKill(-16616, -16499, '3', $aggroRange)

		Info('Open torch chest')
		ClearTarget()
		RndSleep(500)
		Moveto(-14709, -16548)
		Sleep(1500)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(-14709, -16548)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(-14709, -16548)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(15000)

		Info('Pick up torch')
		PickUpTorch()
		RndSleep(2000)

		SafeMoveAggroAndKill(-9259, -17322, '4', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		RndSleep(2000)
		SafeMoveAggroAndKill(-11242, -14612, '5', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		RndSleep(2000)

		Info('Light up torch')
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Get in torch room')
		Moveto(-10033, -12701)

		Info('Lighting brazier 1')
		Moveto(-11019, -11550)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Lighting brazier 2')
		Moveto(-9028, -9021)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Lighting brazier 3')
		Moveto(-6805, -11511)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Lighting brazier 4')
		Moveto(-8984, -13842)
		Sleep(250)
		ActionInteract()
		Sleep(1250)

		Info('Drop torch')
		DropBundle()
		RndSleep(500)
		Info('Kill group')
		SafeMoveAggroAndKill(-9358, -12411, '6', $aggroRange)
		SafeMoveAggroAndKill(-10143, -11136, '7', $aggroRange)
		SafeMoveAggroAndKill(-8871, -9951, '8', $aggroRange)
		SafeMoveAggroAndKill(-7722, -11522, '9', $aggroRange)
		RndSleep(1000)

		Moveto(-8912, -13586)
		Sleep(500)
		Info('Pick up torch')
		PickUpTorch()
		RndSleep(2000)

		SafeMoveAggroAndKill(-10542, -9557, '10', $aggroRange)
		SafeMoveAggroAndKill(-10727, -4438, '11', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		RndSleep(2000)
		SafeMoveAggroAndKill(-6886, -4236, '12', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		RndSleep(2000)
		SafeMoveAggroAndKill(-5873, -3392, '13', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		RndSleep(2000)
		SafeMoveAggroAndKill(-4073, -4072, '14', $aggroRange)
		PickUpTorch()
		RndSleep(2000)
		SafeMoveAggroAndKill(-3900, -4163, '14', $aggroRange)
		PickUpTorch()
		RndSleep(2000)

		Info('Light up torch')
		Moveto(-3717, -4254)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 1')
		Moveto(-8251, -3240)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 2')
		Moveto(-8278, -1670)
		Sleep(250)
		ActionInteract()
		Sleep(1250)

		Info('Drop torch')
		DropBundle()
		RndSleep(500)

		SafeMoveAggroAndKill(-6553, -2347, '12', $aggroRange)
		SafeMoveAggroAndKill(-7733, -2487, '13', $aggroRange)
		SafeMoveAggroAndKill(-6481, -2668, '14', $aggroRange)
		PickUpItems()
		SafeMoveAggroAndKill(-11204, -4331, '15', $aggroRange)
		SafeMoveAggroAndKill(-14674, -4442, '16', $aggroRange)
		SafeMoveAggroAndKill(-16007, -8640, '17', $aggroRange)
		SafeMoveAggroAndKill(-17735, -9337, '18', $aggroRange)

		Info('Open dungeon door')
		ClearTarget()
		RndSleep(500)
		Moveto(-18725, -9171)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(-18725, -9171)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(-18725, -9171)
		ActionInteract()
		RndSleep(500)
		ActionInteract()

		Moveto(-18725, -9171)
	WEnd

	Info('Going through portal')
	Move(-19300, -8200)
	RndSleep(2000)
	While Not WaitMapLoading($ID_SoO_lvl3)
		Sleep(500)
		Moveto(-18725, -9171)
		Move(-19300, -8200)
	WEnd
	RndSleep(2000)


	Info('------------------------------------')
	Info('Third floor')
	If IsHardmodeEnabled() Then UseConset()

	While $SoODeathsCount < 6 And Not SoOIsInRange (-1265, 7891, 1250)
		SafeMoveAggroAndKill(17325, 18961, 'Getting blessing', $aggroRange)
		GoToNPC(GetNearestNPCToCoords(17544, 18810))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(500)

		SafeMoveAggroAndKill(17544, 18810, '1', $aggroRange)
		SafeMoveAggroAndKill(9452, 18513, '2', $aggroRange)
		SafeMoveAggroAndKill(8908, 17239, '3', $aggroRange)
		SafeMoveAggroAndKill(6527, 12936, '4', $aggroRange)
		SafeMoveAggroAndKill(3025, 8401, '5', $aggroRange)
		SafeMoveAggroAndKill(949, 7412, '6', $aggroRange)
		SafeMoveAggroAndKill(-347, 6459, '7', $aggroRange)
		SafeMoveAggroAndKill(-1265, 7891, '6', $aggroRange)
	WEnd

	While $SoODeathsCount < 6 And Not SoOIsInRange (-9214, 6323, 1250)
		SafeMoveAggroAndKill(-1537, 8503, 'Triggering beacon 2', $aggroRange)
		SafeMoveAggroAndKill(-4519, 6447, '1', $aggroRange)
		SafeMoveAggroAndKill(-6523, 5533, '2', $aggroRange)
		SafeMoveAggroAndKill(-8892, 4015, '3', $aggroRange)
		SafeMoveAggroAndKill(-11581, 2165, '4', $aggroRange)

		Info('Run time, fun time')
		SafeMoveAggroAndKill(-4723, 6703, '1', $aggroRange)
		SafeMoveAggroAndKill(-1337, 7825, '2', $aggroRange)
		SafeMoveAggroAndKill(2913, 8190, '3', $aggroRange)
		SafeMoveAggroAndKill(5846, 11037, '4', $aggroRange)
		SafeMoveAggroAndKill(9796, 18960, '5', $aggroRange)
		SafeMoveAggroAndKill(14068, 19549, '6', $aggroRange)
		SafeMoveAggroAndKill(16186, 17667, '7', $aggroRange)

		Info('Open torch chest')
		ClearTarget()
		RndSleep(500)
		Moveto(16134, 17590)
		Sleep(1500)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(16134, 17590)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(15000)

		Info('Pick up torch')
		PickUpTorch()
		RndSleep(2000)

		Info('Light up torch')
		Moveto(15692, 17111)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 1')
		Moveto(12969, 19842)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 2')
		Moveto(12969, 19842)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Moveto(9657, 18783)

		Info('Light up brazier 3')
		Moveto(8236, 16950)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Moveto(6988, 13337)

		Info('Light up brazier 4')
		Moveto(5549, 9920)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 5')
		Moveto(-536, 6109)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Moveto(-2346, 7961)
		Moveto(-4329, 6606)

		Info('Light up brazier 6')
		Moveto(-3814, 5599)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 7')
		Moveto(-4959, 7558)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 8')
		Moveto(-7532, 4536)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 9')
		Moveto(-8814, 3727)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 10')
		Moveto(-11044, 482)
		Sleep(250)
		ActionInteract()
		Sleep(1500)
		ActionInteract()
		Sleep(250)

		Info('Light up brazier 11')
		Moveto(-12686, 2945)
		Sleep(250)
		ActionInteract()
		Sleep(1500)

		Info('Drop torch')
		DropBundle()
		RndSleep(500)

		Info('Keyboss')
		SafeMoveAggroAndKill(-10637, 2904, '1', $aggroRange)
		SafeMoveAggroAndKill(-9481, 1639, '2', $aggroRange)
		SafeMoveAggroAndKill(-10936, 4004, '3', $aggroRange)

		Moveto(-9984, 2908)
		PickUpItems()

		SafeMoveAggroAndKill(-9202, 6165, '4', $aggroRange)

		Info('Open dungeon door')
		ClearTarget()
		RndSleep(500)
		Moveto(-9214, 6323)
		Sleep(1500)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(-9214, 6323)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
		RndSleep(500)
		Moveto(-9214, 6323)
		ActionInteract()
		RndSleep(500)
		ActionInteract()
	WEnd

	Local $aggroRange = $RANGE_SPELLCAST + 300

	While $SoODeathsCount < 6 And Not SoOIsInRange(-16789, 18426, 1250)
		Info('Boss room')
		SafeMoveAggroAndKill(-9926, 8007, '1', $aggroRange)
		SafeMoveAggroAndKill(-8490, 9370, '2', $aggroRange)
		SafeMoveAggroAndKill(-10279, 11402, '3', $aggroRange)
		SafeMoveAggroAndKill(-13028, 13825, '4', $aggroRange)
		SafeMoveAggroAndKill(-15001, 15223, '5', $aggroRange)
		Info('Boss fight, go in and move around to make sure its aggroed')
		SafeMoveAggroAndKill(-16828, 16628, '6', $aggroRange)
		SafeMoveAggroAndKill(-15470, 17614, '7', $aggroRange)
		SafeMoveAggroAndKill(-16789, 18426, '8', $aggroRange)
	WEnd

	MoveTo(-15753, 17417)
	MoveTo(-15743, 16832)
	Info('Opening chest')
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()
	; Doubled to try securing the looting
	MoveTo(-15743, 16832)
	Info('Opening chest')
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()

	Info('Chest looted')
	Info('Waiting for timer end + some more')
	AdlibUnRegister('SoOGroupIsAlive')
	Sleep(190000)
	While Not WaitMapLoading($ID_Arbor_Bay)
		Sleep(500)
	WEnd

	Info('Finished Run')
	Return 0
EndFunc


;~ Did run fail ?
Func SoOIsFailure()
	If ($SoODeathsCount > 5) Then
		AdlibUnregister('SoOGroupIsAlive')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the groupIsAlive variable, this function is run on a fixed timer
Func SoOGroupIsAlive()
	$SoODeathsCount += IsGroupAlive() ? 0 : 1
EndFunc


;~ Is in range of coordinates
Func SoOIsInRange($X, $Y, $range)
	Local $myX = DllStructGetData(GetMyAgent(), 'X')
	Local $myY = DllStructGetData(GetMyAgent(), 'Y')

	If ($myX < $X + $range) And ($myX > $X - $range) And ($myY < $Y + $range) And ($myY > $Y - $range) Then
		Return True
	EndIf
	Return False
EndFunc


;~ Pick up the torch
Func PickUpTorch()
	Local $agent
	Local $item
	Local $deadlock
	For $i = 1 To GetMaxAgents()
		$agent = GetAgentByID($i)
		If (DllStructGetData($agent, 'Type') <> 0x400) Then ContinueLoop
		$item = GetItemByAgentID($i)
		If (DllStructGetData(($item), 'ModelID') == $ID_SoO_Torch) Then
			Info('Torch: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			$deadlock = TimerInit()
			While GetAgentExists($i)
				RndSleep(500)
				If GetIsDead() Then Return
				If TimerDiff($deadlock) > 20000 Then
					Error('Could not get torch at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
					Return False
				EndIf
			WEnd
			Return True
		EndIf
	Next
	Return False
EndFunc