#CS ===========================================================================
; Author: An anonymous fan of Dhuum
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


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $NornFarmInformations = 'Norn title farm, bring solid heroes composition'
; Average duration ~ 45m
Global Const $NORN_FARM_DURATION = 45 * 60 * 1000


;~ Main loop for the norn faction farm
Func NornTitleFarm($STATUS)
	NornTitleFarmSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToVarajarFells()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VanquishVarajarFells()
	AdlibUnRegister('TrackPartyStatus')
	; Temporarily change a failure into a pause for debugging :
	;If $result == $FAIL Then $result = $PAUSE
	TravelToOutpost($ID_Olafstead, $DISTRICT_NAME)
	Return $result
EndFunc


Func NornTitleFarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Olafstead, $DISTRICT_NAME)
	SetDisplayedTitle($ID_Norn_Title)
	SwitchMode($ID_HARD_MODE)
	; Assuming that team has been set up correctly manually
	;SetupTeamNornTitleFarm()
	Info('Preparations complete')
EndFunc


Func SetupTeamNornTitleFarm()
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	RandomSleep(500)
	AddHero($ID_Norgu)
	RandomSleep(500)
	AddHero($ID_Gwen)
	RandomSleep(500)
	AddHero($ID_Razah)
	RandomSleep(500)
	AddHero($ID_Master_Of_Whispers)
	RandomSleep(500)
	AddHero($ID_Livia)
	RandomSleep(500)
	AddHero($ID_Olias)
	RandomSleep(500)
	AddHero($ID_Xandra)
	Sleep(1000)
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


;~ Move out of outpost into the Varajar Fells
Func GoToVarajarFells()
	If GetMapID() <> $ID_Olafstead Then TravelToOutpost($ID_Olafstead, $DISTRICT_NAME)
	While GetMapID() <> $ID_Varajar_Fells
		Info('Moving to the Varajar Fells')
		MoveTo(222, 756)
		MoveTo(-1435, 1217)
		RandomSleep(5000)
		WaitMapLoading($ID_Varajar_Fells, 10000, 2000)
	WEnd
EndFunc


;~ Cleaning Varajar Fells function
Func VanquishVarajarFells()
	If GetMapID() <> $ID_Varajar_Fells Then Return $FAIL

	Local Static $foes[49][4] = [ _ ; 43 groups to vanquish + 6 movements
		[-5278, -5771, 'Berserker', $AGGRO_RANGE], _
		[-5456, -7921, 'Berserker', $AGGRO_RANGE], _
		[-8793, -5837, 'Berserker', $AGGRO_RANGE], _
		[-14092, -9662, 'Vaettir and Berserker', $AGGRO_RANGE], _
		[-17260, -7906, 'Vaettir and Berserker', $AGGRO_RANGE], _
		[-21964, -12877, 'Jotun', 2500], _
		[-22275, -12462, 'Moving', $AGGRO_RANGE], _
		[-21671, -2163, 'Berserker', $AGGRO_RANGE], _
		[-19592, 772, 'Berserker', $AGGRO_RANGE], _
		[-13795, -751, 'Berserker', $AGGRO_RANGE], _
		[-17012, -5376, 'Berserker', $AGGRO_RANGE], _
		[-8351, -2633, 'Berserker', $AGGRO_RANGE], _
		[-4362, -1610, 'Moving', $AGGRO_RANGE], _
		[-4316, 4033, 'Lake', $AGGRO_RANGE], _
		[-8809, 5639, 'Lake', $AGGRO_RANGE], _
		[-14916, 2475, 'Lake', $AGGRO_RANGE], _
		[-16051, 6492, 'Elemental', $AGGRO_RANGE], _
		[-16934, 11145, 'Elemental', $AGGRO_RANGE], _
		[-19378, 14555, 'Elemental', $AGGRO_RANGE], _
		[-15932, 9386, '', $AGGRO_RANGE], _
		[-13777, 8097, 'Moving', $AGGRO_RANGE], _
		[-4729, 15385, 'Lake', $AGGRO_RANGE], _
		[-1810, 4679, 'Modniir', $AGGRO_RANGE], _
		[-6911, 5240, 'Moving', $AGGRO_RANGE], _
		[-15471, 6384, 'Boss', $AGGRO_RANGE], _
		[-411, 5874, 'Moving', $AGGRO_RANGE], _
		[2859, 3982, 'Modniir', $AGGRO_RANGE], _
		[4909, -4259, 'Ice Imp', $AGGRO_RANGE], _
		[7514, -6587, 'Ice Imp', $AGGRO_RANGE], _
		[3800, -6182, 'Berserker', $AGGRO_RANGE], _
		[7755, -11467, 'Berserker', $AGGRO_RANGE], _
		[15403, -4243, 'Elementals and Griffins', $AGGRO_RANGE], _
		[21597, -6798, 'Elementals and Griffins', $AGGRO_RANGE], _
		[22883, -4248, '', $AGGRO_RANGE], _
		[18606, -1894, '', $AGGRO_RANGE], _
		[14969, -4048, '', $AGGRO_RANGE], _
		[13599, -7339, '', $AGGRO_RANGE], _
		[10056, -4967, 'Ice Imp', $AGGRO_RANGE], _
		[10147, -1630, 'Ice Imp', $AGGRO_RANGE], _
		[8963, 4043, 'Ice Imp', $AGGRO_RANGE], _
		[15576, 7156, '', $AGGRO_RANGE], _
		[22838, 7914, 'Berserker', 2500], _
		[18067, 8766, 'Moving', $AGGRO_RANGE], _
		[13311, 11917, 'Modniir and Elemental', $AGGRO_RANGE], _
		[11126, 10443, 'Modniir and Elemental', $AGGRO_RANGE], _
		[5575, 4696, 'Modniir and Elemental', 2500], _
		[-503, 9182, 'Modniir and Elemental', $AGGRO_RANGE], _
		[1582, 15275, 'Modniir and Elemental', 2500], _
		[7857, 10409, 'Modniir and Elemental', 2500] _
	]

	MoveTo(-2484, 118)
	MoveTo(-3059, -419)
	MoveTo(-3301, -2008)
	MoveTo(-2034, -4512)

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-2034, -4512))
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 1, 6) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-25274, -11970))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 7, 11) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-12071, -4274))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 12, 16) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-11282, 5466))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 17, 19) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-22751, 14163))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 20, 22) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-2290, 14879))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 23, 33) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(24522, -6532))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 34, 40) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(8963, 4043))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 41, 42) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(22961, 12757))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 43, 44) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(13714, 14520))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 45, 49) == $FAIL Then Return $FAIL

	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc