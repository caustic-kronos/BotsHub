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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :
; - noticed some scenarios where map is not cleared - check whether this can be fixed by adding a few additional locations

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $KurzickFactionInformations = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild'
; Average duration ~ 40m
Global Const $KURZICKS_FARM_DURATION = 41 * 60 * 1000

Global $DonatePoints = True

;~ Main loop for the kurzick faction farm
Func KurzickFactionFarm($STATUS)
	KurzickFarmSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToFerndale()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VanquishFerndale()
	AdlibUnRegister('TrackPartyStatus')

	; Temporarily change a failure into a pause for debugging :
	;If $result == $FAIL Then $result = $PAUSE
	TravelToOutpost($ID_House_Zu_Heltzer, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Setup for kurzick farm
Func KurzickFarmSetup()
	Info('Setting up farm')
	If GetMapID() <> $ID_House_Zu_Heltzer Then TravelToOutpost($ID_House_Zu_Heltzer, $DISTRICT_NAME)

	SetupPlayerKurzickFarm()
	SetupTeamKurzickFarm()

	If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then
		RandomSleep(200)
		GoNearestNPCToCoords(5390, 1524)

		If $DonatePoints Then
			Info('Donating Kurzick faction points')
			While GetKurzickFaction() >= 5000
				DonateFaction('kurzick')
				RandomSleep(500)
			WEnd
		Else
			Info('Converting Kurzick faction points into Amber Chunks')
			Dialog(0x83)
			RandomSleep(550)
			Local $temp = Floor(GetKurzickFaction() / 5000)
			Local $dialogID = 0x800001 + ($temp * 256)
			Dialog($dialogID)
			RandomSleep(550)
		EndIf
		RandomSleep(500)
	EndIf

	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Info('Withdrawing gold for shrines benediction')
		RandomSleep(250)
		WithdrawGold(100)
		RandomSleep(250)
	EndIf

	SwitchMode($ID_HARD_MODE)
	Info('Preparations complete')
EndFunc


Func SetupPlayerKurzickFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		Sleep(500 + GetPing())
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
    Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamKurzickFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Automatic team builds setup is disabled. Assuming that team builds are set up manually')
    EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
    	Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


;~ Move out of outpost into Ferndale
Func GoToFerndale()
	If GetMapID() <> $ID_House_Zu_Heltzer Then TravelToOutpost($ID_House_Zu_Heltzer, $DISTRICT_NAME)
	While GetMapID() <> $ID_Ferndale
		Info('Moving to Ferndale')
		MoveTo(7810, -726)
		MoveTo(10042, -1173)
		Move(10446, -1147)
		RandomSleep(1000)
		WaitMapLoading($ID_Ferndale, 10000, 2000)
	WEnd
EndFunc


;~ Vanquish the Ferndale map
Func VanquishFerndale()
	If GetMapID() <> $ID_Ferndale Then Return $FAIL
	Info('Taking blessing')
	GoNearestNPCToCoords(-12909, 15616)
	Dialog(0x81)
	Sleep(1000)
	Dialog(0x2)
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	Dialog(0x86)
	RandomSleep(1000)

	Local Static $foes[117][4] = [ _ ; 117 groups to vanquish
		[-11733, 16729, 'Mantis Group 1', $AGGRO_RANGE], _
		[-11942, 18468, 'Mantis Group 2', $AGGRO_RANGE], _
		[-11178, 20073, 'Mantis Group 3', $AGGRO_RANGE], _
		[-11008, 16972, 'Mantis Group 4', $AGGRO_RANGE], _
		[-11238, 15226, 'Mantis Group 5', $AGGRO_RANGE], _
		[-9122, 14794, 'Mantis Group 6', $AGGRO_RANGE], _
		[-10965, 13496, 'Mantis Group 7', $AGGRO_RANGE], _
		[-10570, 11789, 'Mantis Group 8', $AGGRO_RANGE], _
		[-10138, 10076, 'Mantis Group 9', $AGGRO_RANGE], _
		[-10289, 8329, 'Mantis Group 10', $AGGRO_RANGE], _
		[-8587, 8739, 'Dredge Boss Warrior 1', $AGGRO_RANGE], _
		[-6853, 8496, 'Dredge Boss Warrior 2', $AGGRO_RANGE], _
		[-5211, 7841, 'Dredge Patrol', $AGGRO_RANGE], _
		[-4059, 11325, 'Missing Dredge Patrol', $AGGRO_RANGE], _
		[-4328, 6317, 'Oni and Dredge Patrol 1', $AGGRO_RANGE], _
		[-4454, 4558, 'Oni and Dredge Patrol 2', $AGGRO_RANGE], _
		[-4650, 2812, 'Dredge Patrol Again', $AGGRO_RANGE], _
		[-9326, 1601, 'Missing Patrol 1', $AGGRO_RANGE], _
		[-11000, 2219, 'Missing Patrol 2', $RANGE_COMPASS], _
		[-6313, 2778, 'Missing Patrol 3', $AGGRO_RANGE], _
		[-4447, 1055, 'Dredge Patrol', 3000], _
		[-3832, -586, 'Warden and Dredge Patrol 1', 3000], _
		[-3143, -2203, 'Warden and Dredge Patrol 2', 3000], _
		[-5780, -4665, 'Warden and Dredge Patrol 3', 3000], _
		[-2541, -3848, 'Warden Group / Mesmer Boss 1', 3000], _
		[-2108, -5549, 'Warden Group / Mesmer Boss 2', 3000], _
		[-1649, -7250, 'Warden Group / Mesmer Boss 3', $RANGE_SPIRIT], _
		[0, -10000, 'Dredge Patrol and Mesmer Boss', $RANGE_SPIRIT], _
		[526, -10001, 'Warden Group 1', $AGGRO_RANGE], _
		[1947, -11033, 'Warden Group 2', $AGGRO_RANGE], _
		[3108, -12362, 'Warden Group 3', $AGGRO_RANGE], _
		[2932, -14112, 'Kirin Group 1', $AGGRO_RANGE], _
		[2033, -15621, 'Kirin Group 2', $AGGRO_RANGE], _
		[1168, -17145, 'Kirin Group 3', $AGGRO_RANGE], _
		[-254, -18183, 'Kirin Group 4', $AGGRO_RANGE], _
		[-1934, -18692, 'Kirin Group 5', $AGGRO_RANGE], _
		[-3676, -18939, 'Warden Patrol 1', $AGGRO_RANGE], _
		[-5433, -18839, 'Warden Patrol 2', 3000], _
		[-3679, -18830, 'Warden Patrol 3', $AGGRO_RANGE], _
		[-1925, -18655, 'Warden Patrol 4', $AGGRO_RANGE], _
		[-274, -18040, 'Warden Patrol 5', $AGGRO_RANGE], _
		[1272, -17199, 'Warden Patrol 6', $AGGRO_RANGE], _
		[2494, -15940, 'Warden Patrol 7', $AGGRO_RANGE], _
		[3466, -14470, 'Warden Patrol 8', $AGGRO_RANGE], _
		[4552, -13081, 'Warden Patrol 9', $AGGRO_RANGE], _
		[6279, -12777, 'Warden Patrol 10', $AGGRO_RANGE], _
		[7858, -13545, 'Warden Patrol 11', $AGGRO_RANGE], _
		[8396, -15221, 'Warden Patrol 12', $AGGRO_RANGE], _
		[9117, -16820, 'Warden Patrol 13', $AGGRO_RANGE], _
		[10775, -17393, 'Warden Patrol 14', 3000], _
		[9133, -16782, 'Warden Patrol 15', $AGGRO_RANGE], _
		[8366, -15202, 'Warden Patrol 16', $AGGRO_RANGE], _
		[8083, -13466, 'Warden Patrol 17', $AGGRO_RANGE], _
		[6663, -12425, 'Warden Patrol 18', $AGGRO_RANGE], _
		[5045, -11738, 'Warden Patrol 19', $AGGRO_RANGE], _
		[4841, -9983, 'Warden Patrol 20', $AGGRO_RANGE], _
		[5262, -8277, 'Warden Patrol 21', $AGGRO_RANGE], _
		[5726, -6588, 'Warden Patrol 22', $AGGRO_RANGE], _
		[5076, -4955, 'Dredge Patrol / Bridge / Boss 1', $AGGRO_RANGE], _
		[4453, -3315, 'Dredge Patrol / Bridge / Boss 2', 3000], _
		[5823, -2204, 'Dredge Patrol 1', $AGGRO_RANGE], _
		[7468, -1606, 'Dredge Patrol 2', $AGGRO_RANGE], _
		[8591, -248, 'Dredge Patrol 3', 3000], _
		[8765, 1497, 'Dredge Patrol 4', $AGGRO_RANGE], _
		[9756, 2945, 'Dredge Patrol 5', $AGGRO_RANGE], _
		[11344, 3722, 'Dredge Patrol 6', $AGGRO_RANGE], _
		[14000, 1500, 'Oni Spot', $RANGE_SPIRIT], _
		[12899, 2912, 'Dredge Patrol 7', 3000], _
		[12663, 4651, 'Dredge Patrol 8', $AGGRO_RANGE], _
		[13033, 6362, 'Dredge Patrol 9', $AGGRO_RANGE], _
		[13018, 8121, 'Dredge Patrol 10', $AGGRO_RANGE], _
		[11596, 9159, 'Dredge Patrol 11', $AGGRO_RANGE], _
		[11880, 10895, 'Dredge Patrol 12', $AGGRO_RANGE], _
		[11789, 12648, 'Dredge Patrol 13', $AGGRO_RANGE], _
		[10187, 13369, 'Dredge Patrol 14', $AGGRO_RANGE], _
		[8569, 14054, 'Dredge Patrol 15', 3000], _
		[8641, 15803, 'Dredge Patrol 16', 3000], _
		[10025, 16876, 'Dredge Patrol 17', 3000], _
		[11318, 18944, 'Dredge Patrol 18', 3000], _
		[8621, 15831, 'Dredge Patrol 19', 3000], _
		[7382, 14594, 'Dredge Patrol 20', 3000], _
		[6253, 13257, 'Dredge Patrol 21', 3000], _
		[5531, 11653, 'Dredge Patrol 22', 3000], _
		[6036, 8799, 'Dredge Patrol 23', $AGGRO_RANGE], _
		[4752, 7594, 'Dredge Patrol 24', $AGGRO_RANGE], _
		[3630, 6240, 'Dredge Patrol 25', $AGGRO_RANGE], _
		[4831, 4966, 'Dredge Patrol 26', $AGGRO_RANGE], _
		[6390, 4141, 'Dredge Patrol 27', $AGGRO_RANGE], _
		[4833, 4958, 'Dredge Patrol 28', $AGGRO_RANGE], _
		[3167, 5498, 'Dredge Patrol 29', $AGGRO_RANGE], _
		[2129, 4077, 'Dredge Patrol 30', 3000], _
		[3151, 5502, 'Dredge Patrol 31', $AGGRO_RANGE], _
		[-2234, 311, 'Dredge Patrol 32', 3000], _
		[2474, 4345, 'Dredge Patrol 33', 3000], _
		[3294, 5899, 'Dredge Patrol 34', 3000], _
		[3072, 7643, 'Dredge Patrol 35', 3000], _
		[1836, 8906, 'Dredge Patrol 36', 3000], _
		[557, 10116, 'Dredge Patrol 37', 3000], _
		[-545, 11477, 'Dredge Patrol 38', 3000], _
		[-1413, 13008, 'Dredge Patrol 39', 3000], _
		[-2394, 14474, 'Dredge Patrol 40', 3000], _
		[-3986, 15218, 'Dredge Patrol 41', 3000], _
		[-5319, 16365, 'Dredge Patrol 42', 3000], _
		[-5238, 18121, 'Dredge Patrol 43', 3000], _
		[-7916, 19630, 'Dredge Patrol 44', 3000], _
		[-3964, 19324, 'Dredge Patrol 45', 3000], _
		[-2245, 19684, 'Dredge Patrol 46', 3000], _
		[-802, 18685, 'Dredge Patrol 47', 3000], _
		[74, 17149, 'Dredge Patrol 48', 3000], _
		[611, 15476, 'Dredge Patrol 49', 4000], _
		[2139, 14618, 'Dredge Patrol 50', 4000], _
		[3883, 14448, 'Dredge Patrol 51', 4000], _
		[5624, 14226, 'Dredge Patrol 52', 4000], _
		[7384, 14094, 'Dredge Patrol 53', 4000], _
		[8223, 12552, 'Dredge Patrol 54', 4000], _
		[7148, 11167, 'Dredge Patrol 55', 4000], _
		[5427, 10834, 'Dredge Patrol 56', 2 * $RANGE_COMPASS] _
	]

	If MoveAggroAndKillGroups($foes, 1, UBound($foes)) == $FAIL Then Return $FAIL
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc