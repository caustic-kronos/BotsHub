#CS ===========================================================================
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
#CE ===========================================================================

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :
; - noticed some scenarios where map is not cleared - check whether this can be fixed by adding a few additional locations

Opt('MustDeclareVars', 1)

; ==== Constantes ====
Global Const $KurzickFactionInformations = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild'
; Average duration ~ 40m
Global Const $KURZICKS_FARM_DURATION = 41 * 60 * 1000

Global $DonatePoints = True

;~ Main loop for the kurzick faction farm
Func KurzickFactionFarm($STATUS)
	If GetMapID() <> $ID_House_Zu_Heltzer Then
		Info('Moving to Outpost')
		DistrictTravel($ID_House_Zu_Heltzer, $DISTRICT_NAME)
	EndIf

	KurzickFarmSetup()

	If $STATUS <> 'RUNNING' Then Return 2
	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = VanquishFerndale()
	AdlibUnRegister('TrackGroupStatus')

	; Temporarily change a failure into a pause for debugging :
	;If $result == 1 Then $result = 2
	Return $result
EndFunc


;~ Setup for kurzick farm
Func KurzickFarmSetup()
	If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then
		Info('Turning in Kurzick faction')
		RndSleep(200)
		GoNearestNPCToCoords(5390, 1524)

		If $DonatePoints Then
			While GetKurzickFaction() >= 5000
				DonateFaction('kurzick')
				RndSleep(500)
			WEnd
		Else
			Info('Buying Amber fragments')
			Dialog(131)
			RndSleep(550)
			Local $temp = Floor(GetKurzickFaction() / 5000)
			Local $id = 8388609 + ($temp * 256)
			Dialog($id)
			RndSleep(550)
		EndIf
		RndSleep(500)
	EndIf

	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Info('Withdrawing gold for shrines benediction')
		RndSleep(250)
		WithdrawGold(100)
		RndSleep(250)
	EndIf

	SwitchMode($ID_HARD_MODE)
EndFunc


;~ Vanquish the Ferndale map
Func VanquishFerndale()
	MoveTo(7810, -726)
	MoveTo(10042, -1173)
	Move(10446, -1147, 5)
	RndSleep(1000)
	WaitMapLoading($ID_Ferndale, 10000, 2000)
	ResetFailuresCounter()

	Info('Taking blessing')
	GoNearestNPCToCoords(-12909, 15616)
	Dialog(0x81)
	Sleep(1000)
	Dialog(0x2)
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	Dialog(0x86)
	RndSleep(1000)

	If MoveAggroAndKill(-11733, 16729, 'Mantis Group 1') Then Return 1
	If MoveAggroAndKill(-11942, 18468, 'Mantis Group 2') Then Return 1
	If MoveAggroAndKill(-11178, 20073, 'Mantis Group 3') Then Return 1
	If MoveAggroAndKill(-11008, 16972, 'Mantis Group 4') Then Return 1
	If MoveAggroAndKill(-11238, 15226, 'Mantis Group 5') Then Return 1
	If MoveAggroAndKill(-9122, 14794, 'Mantis Group 6') Then Return 1
	If MoveAggroAndKill(-10965, 13496, 'Mantis Group 7') Then Return 1
	If MoveAggroAndKill(-10570, 11789, 'Mantis Group 8') Then Return 1
	If MoveAggroAndKill(-10138, 10076, 'Mantis Group 9') Then Return 1
	If MoveAggroAndKill(-10289, 8329, 'Mantis Group 10') Then Return 1

	If MoveAggroAndKill(-8587, 8739, 'Dredge Boss Warrior 1') Then Return 1
	If MoveAggroAndKill(-6853, 8496, 'Dredge Boss Warrior 2') Then Return 1

	If MoveAggroAndKill(-5211, 7841, 'Dredge Patrol') Then Return 1

	If MoveAggroAndKill(-4059, 11325, 'Missing Dredge Patrol') Then Return 1

	If MoveAggroAndKill(-4328, 6317, 'Oni and Dredge Patrol 1') Then Return 1
	If MoveAggroAndKill(-4454, 4558, 'Oni and Dredge Patrol 2') Then Return 1

	If MoveAggroAndKill(-4650, 2812, 'Dredge Patrol Again') Then Return 1

	If MoveAggroAndKill(-9326, 1601, 'Missing Patrol 1') Then Return 1
	If MoveAggroAndKill(-11000, 2219, 'Missing Patrol 2', $RANGE_COMPASS) Then Return 1
	If MoveAggroAndKill(-6313, 2778, 'Missing Patrol 3') Then Return 1

	If MoveAggroAndKill(-4447, 1055, 'Dredge Patrol', 3000) Then Return 1

	If MoveAggroAndKill(-3832, -586, 'Warden and Dredge Patrol 1', 3000) Then Return 1
	If MoveAggroAndKill(-3143, -2203, 'Warden and Dredge Patrol 2', 3000) Then Return 1
	If MoveAggroAndKill(-5780, -4665, 'Warden and Dredge Patrol 3', 3000) Then Return 1

	If MoveAggroAndKill(-2541, -3848, 'Warden Group / Mesmer Boss 1', 3000) Then Return 1
	If MoveAggroAndKill(-2108, -5549, 'Warden Group / Mesmer Boss 2', 3000) Then Return 1
	If MoveAggroAndKill(-1649, -7250, 'Warden Group / Mesmer Boss 3', $RANGE_SPIRIT) Then Return 1

	If MoveAggroAndKill(0, -10000, 'Dredge Patrol and Mesmer Boss', $RANGE_SPIRIT) Then Return 1

	If MoveAggroAndKill(526, -10001, 'Warden Group 1') Then Return 1
	If MoveAggroAndKill(1947, -11033, 'Warden Group 2') Then Return 1
	If MoveAggroAndKill(3108, -12362, 'Warden Group 3') Then Return 1

	If MoveAggroAndKill(2932, -14112, 'Kirin Group 1') Then Return 1
	If MoveAggroAndKill(2033, -15621, 'Kirin Group 2') Then Return 1
	If MoveAggroAndKill(1168, -17145, 'Kirin Group 3') Then Return 1
	If MoveAggroAndKill(-254, -18183, 'Kirin Group 4') Then Return 1
	If MoveAggroAndKill(-1934, -18692, 'Kirin Group 5') Then Return 1

	If MoveAggroAndKill(-3676, -18939, 'Warden Patrol 1') Then Return 1
	If MoveAggroAndKill(-5433, -18839, 'Warden Patrol 2', 3000) Then Return 1
	If MoveAggroAndKill(-3679, -18830, 'Warden Patrol 3') Then Return 1
	If MoveAggroAndKill(-1925, -18655, 'Warden Patrol 4') Then Return 1
	If MoveAggroAndKill(-274, -18040, 'Warden Patrol 5') Then Return 1
	If MoveAggroAndKill(1272, -17199, 'Warden Patrol 6') Then Return 1
	If MoveAggroAndKill(2494, -15940, 'Warden Patrol 7') Then Return 1
	If MoveAggroAndKill(3466, -14470, 'Warden Patrol 8') Then Return 1
	If MoveAggroAndKill(4552, -13081, 'Warden Patrol 9') Then Return 1
	If MoveAggroAndKill(6279, -12777, 'Warden Patrol 10') Then Return 1
	If MoveAggroAndKill(7858, -13545, 'Warden Patrol 11') Then Return 1
	If MoveAggroAndKill(8396, -15221, 'Warden Patrol 12') Then Return 1
	If MoveAggroAndKill(9117, -16820, 'Warden Patrol 13') Then Return 1
	If MoveAggroAndKill(10775, -17393, 'Warden Patrol 14', 3000) Then Return 1
	If MoveAggroAndKill(9133, -16782, 'Warden Patrol 15') Then Return 1
	If MoveAggroAndKill(8366, -15202, 'Warden Patrol 16') Then Return 1
	If MoveAggroAndKill(8083, -13466, 'Warden Patrol 17') Then Return 1
	If MoveAggroAndKill(6663, -12425, 'Warden Patrol 18') Then Return 1
	If MoveAggroAndKill(5045, -11738, 'Warden Patrol 19') Then Return 1
	If MoveAggroAndKill(4841, -9983, 'Warden Patrol 20') Then Return 1
	If MoveAggroAndKill(5262, -8277, 'Warden Patrol 21') Then Return 1
	If MoveAggroAndKill(5726, -6588, 'Warden Patrol 22') Then Return 1

	If MoveAggroAndKill(5076, -4955, 'Dredge Patrol / Bridge / Boss 1') Then Return 1
	If MoveAggroAndKill(4453, -3315, 'Dredge Patrol / Bridge / Boss 2', 3000) Then Return 1

	If MoveAggroAndKill(5823, -2204, 'Dredge Patrol 1') Then Return 1
	If MoveAggroAndKill(7468, -1606, 'Dredge Patrol 2') Then Return 1
	If MoveAggroAndKill(8591, -248, 'Dredge Patrol 3', 3000) Then Return 1
	If MoveAggroAndKill(8765, 1497, 'Dredge Patrol 4') Then Return 1
	If MoveAggroAndKill(9756, 2945, 'Dredge Patrol 5') Then Return 1
	If MoveAggroAndKill(11344, 3722, 'Dredge Patrol 6') Then Return 1
	If MoveAggroAndKill(14000, 1500, 'Oni Spot', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(12899, 2912, 'Dredge Patrol 7', 3000) Then Return 1
	If MoveAggroAndKill(12663, 4651, 'Dredge Patrol 8') Then Return 1
	If MoveAggroAndKill(13033, 6362, 'Dredge Patrol 9') Then Return 1
	If MoveAggroAndKill(13018, 8121, 'Dredge Patrol 10') Then Return 1
	If MoveAggroAndKill(11596, 9159, 'Dredge Patrol 11') Then Return 1
	If MoveAggroAndKill(11880, 10895, 'Dredge Patrol 12') Then Return 1
	If MoveAggroAndKill(11789, 12648, 'Dredge Patrol 13') Then Return 1
	If MoveAggroAndKill(10187, 13369, 'Dredge Patrol 14') Then Return 1
	If MoveAggroAndKill(8569, 14054, 'Dredge Patrol 15', 3000) Then Return 1
	If MoveAggroAndKill(8641, 15803, 'Dredge Patrol 16', 3000) Then Return 1
	If MoveAggroAndKill(10025, 16876, 'Dredge Patrol 17', 3000) Then Return 1
	If MoveAggroAndKill(11318, 18944, 'Dredge Patrol 18', 3000) Then Return 1
	If MoveAggroAndKill(8621, 15831, 'Dredge Patrol 19', 3000) Then Return 1
	If MoveAggroAndKill(7382, 14594, 'Dredge Patrol 20', 3000) Then Return 1
	If MoveAggroAndKill(6253, 13257, 'Dredge Patrol 21', 3000) Then Return 1
	If MoveAggroAndKill(5531, 11653, 'Dredge Patrol 22', 3000) Then Return 1
	If MoveAggroAndKill(6036, 8799, 'Dredge Patrol 23') Then Return 1
	If MoveAggroAndKill(4752, 7594, 'Dredge Patrol 24') Then Return 1
	If MoveAggroAndKill(3630, 6240, 'Dredge Patrol 25') Then Return 1
	If MoveAggroAndKill(4831, 4966, 'Dredge Patrol 26') Then Return 1
	If MoveAggroAndKill(6390, 4141, 'Dredge Patrol 27') Then Return 1
	If MoveAggroAndKill(4833, 4958, 'Dredge Patrol 28') Then Return 1
	If MoveAggroAndKill(3167, 5498, 'Dredge Patrol 29') Then Return 1
	If MoveAggroAndKill(2129, 4077, 'Dredge Patrol 30', 3000) Then Return 1
	If MoveAggroAndKill(3151, 5502, 'Dredge Patrol 31') Then Return 1
	If MoveAggroAndKill(-2234, 311, 'Dredge Patrol 32', 3000) Then Return 1
	If MoveAggroAndKill(2474, 4345, 'Dredge Patrol 33', 3000) Then Return 1
	If MoveAggroAndKill(3294, 5899, 'Dredge Patrol 34', 3000) Then Return 1
	If MoveAggroAndKill(3072, 7643, 'Dredge Patrol 35', 3000) Then Return 1
	If MoveAggroAndKill(1836, 8906, 'Dredge Patrol 36', 3000) Then Return 1
	If MoveAggroAndKill(557, 10116, 'Dredge Patrol 37', 3000) Then Return 1
	If MoveAggroAndKill(-545, 11477, 'Dredge Patrol 38', 3000) Then Return 1
	If MoveAggroAndKill(-1413, 13008, 'Dredge Patrol 39', 3000) Then Return 1
	If MoveAggroAndKill(-2394, 14474, 'Dredge Patrol 40', 3000) Then Return 1
	If MoveAggroAndKill(-3986, 15218, 'Dredge Patrol 41', 3000) Then Return 1
	If MoveAggroAndKill(-5319, 16365, 'Dredge Patrol 42', 3000) Then Return 1
	If MoveAggroAndKill(-5238, 18121, 'Dredge Patrol 43', 3000) Then Return 1
	If MoveAggroAndKill(-7916, 19630, 'Dredge Patrol 44', 3000) Then Return 1
	If MoveAggroAndKill(-3964, 19324, 'Dredge Patrol 45', 3000) Then Return 1
	If MoveAggroAndKill(-2245, 19684, 'Dredge Patrol 46', 3000) Then Return 1
	If MoveAggroAndKill(-802, 18685, 'Dredge Patrol 47', 3000) Then Return 1
	If MoveAggroAndKill(74, 17149, 'Dredge Patrol 48', 3000) Then Return 1
	If MoveAggroAndKill(611, 15476, 'Dredge Patrol 49', 4000) Then Return 1
	If MoveAggroAndKill(2139, 14618, 'Dredge Patrol 50', 4000) Then Return 1
	If MoveAggroAndKill(3883, 14448, 'Dredge Patrol 51', 4000) Then Return 1
	If MoveAggroAndKill(5624, 14226, 'Dredge Patrol 52', 4000) Then Return 1
	If MoveAggroAndKill(7384, 14094, 'Dredge Patrol 53', 4000) Then Return 1
	If MoveAggroAndKill(8223, 12552, 'Dredge Patrol 54', 4000) Then Return 1
	If MoveAggroAndKill(7148, 11167, 'Dredge Patrol 55', 4000) Then Return 1
	If MoveAggroAndKill(5427, 10834, 'Dredge Patrol 56', 2 * $RANGE_COMPASS) Then Return 1
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return 1
	EndIf
	Return 0
EndFunc