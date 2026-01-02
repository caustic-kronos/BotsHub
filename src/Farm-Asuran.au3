#CS ===========================================================================
; Author: JackLinesMatthews
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
Global Const $AsuranFarmInformations = 'Asuran title farm, bring solid heroes composition'
; Average duration ~ 45m
Global Const $ASURAN_FARM_DURATION = 45 * 60 * 1000
Global $ASURAN_FARM_SETUP = False


;~ Main loop for the asuran faction farm
Func AsuranTitleFarm($STATUS)
	If Not $ASURAN_FARM_SETUP Then AsuranTitleFarmSetup()

	GoToMagusStones()
	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = VanquishMagusStones()
	AdlibUnRegister('TrackGroupStatus')
	Return $result
EndFunc


Func AsuranTitleFarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Rata_Sum, $DISTRICT_NAME)
	SetDisplayedTitle($ID_Asura_Title)
	SwitchMode($ID_HARD_MODE)
	TrySetupPlayerUsingGUISettings()
	TrySetupTeamUsingGUISettings()
	$ASURAN_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Magus Stones
Func GoToMagusStones()
	TravelToOutpost($ID_Rata_Sum, $DISTRICT_NAME)
	While GetMapID() <> $ID_Magus_Stones
		Info('Moving to Magus Stones')
		MoveTo(16342, 13855)
		Move(16450, 13300)
		RandomSleep(1000)
		WaitMapLoading($ID_Magus_Stones, 10000, 2000)
	WEnd
EndFunc


Func VanquishMagusStones()
	If GetMapID() <> $ID_Magus_Stones Then Return $FAIL

	Local Static $foes[83][3] = [ _ ; 67 groups to vanquish + 16 movements
		_ ; blessing
		[16722, 11774, 'Moving'], _
		[17383, 8685, 'Moving'], _
		[18162, 6670, 'First Spider Group'], _
		[18447, 4537, 'Second Spider Group'], _
		[18331, 2108, 'Spider Pop'], _
		[17526, 143, 'Spider Pop 2'], _
		[17205, -1355, 'Third Spider Group'], _
		[17366, -5132, 'Krait Group'], _
		[18111, -8030, 'Krait Group'], _
		_ ; blessing
		[18613, -11799, 'Froggy Group'], _
		[17154, -15669, 'Krait Patrol'], _
		[14250, -16744, 'Second Patrol'], _
		[12186, -14139, 'Krait Patrol'], _
		[12540, -13440, 'Krait Patrol'], _
		[13234, -9948, 'Krait Group'], _
		[8875, -9065, 'Krait Group'], _
		[4671, -8699, 'Krait Patrol'], _
		[1534, -5493, 'Krait Group'], _
		[1052, -7074, 'Moving'], _
		[-1029, -8724, 'Spider Group'], _
		[-3439, -10339, 'Krait Group'], _
		[-3024, -12586, 'Spider Cave'], _
		[-2797, -13645, 'Spider Cave'], _
		[-3393, -15633, 'Spider Cave'], _
		[-4635, -16643, 'Spider Pop'], _
		[-7814, -17796, 'Spider Group'], _
		_ ; blessing
		[-9111, -17237, 'Moving'], _
		[-10963, -15506, 'Ranger Boss Group'], _
		[-12885, -14651, 'Froggy Group'], _
		[-13975, -17857, 'Corner Spiders'], _
		[-11912, -10641, 'Froggy Group'], _
		[-8760, -9933, 'Krait Boss Warrior'], _
		[-14030, -9780, 'Froggy Coing Group'], _
		[-12368, -7330, 'Froggy Group'], _
		[-16527, -8175, 'Froggy Patrol'], _
		[-17391, -5984, 'Froggy Group'], _
		[-15704, -3996, 'Froggy Patrol'], _
		[-16609, -2607, 'Moving'], _
		[-15476, 186, 'Moving'], _
		[-16480, 2522, 'Krait Group'], _
		[-17090, 5252, 'Krait Group'], _
		_ ; blessing
		[-18640, 8724, 'Moving'], _
		[-18484, 12021, 'Krait Patrol'], _
		[-17180, 13093, 'Krait Patrol'], _
		[-15072, 14075, 'Froggy Group'], _
		[-11888, 15628, 'Froggy Group'], _
		[-12043, 18463, 'Froggy Boss Warrior'], _
		[-8876, 17415, 'Froggy Group'], _
		[-5778, 19838, 'Froggy Group'], _
		[-10970, 16860, 'Moving Back'], _
		[-9301, 15054, 'Moving'], _
		[-5379, 16642, 'Krait Group'], _
		[-4430, 17268, 'Krait Group'], _
		[-2974, 14197, 'Krait Group'], _
		[-5228, 12475, 'Boss Patrol'], _
		[-3468, 10837, 'Lonely Patrol'], _
		_ ; blessing
		[-3804, 8017, 'Krait Group'], _
		[-1346, 12360, 'Moving'], _
		[874, 14367, 'Moving'], _
		[3572, 13698, 'Krait Group Standing'], _
		[5899, 14205, 'Moving'], _
		[7407, 11867, 'Krait Group'], _
		[9541, 9027, 'Rider'], _
		[12639, 7537, 'Rider Group'], _
		[9064, 7312, 'Rider'], _
		[7986, 4365, 'Krait group'], _
		[6341, 3029, 'Krait Group'], _
		[7097, 92, 'Krait Group'], _
		_ ; blessing
		[8943, -985, 'Krait Boss'], _
		[10949, -2056, 'Krait Patrol'], _
		[13780, -5667, 'Rider Patrol'], _
		[12444, -793, 'Moving Back'], _
		[8193, -841, 'Moving Back'], _
		[3284, -1599, 'Krait Group'], _
		[-76, -1498, 'Krait Group'], _
		[578, 719, 'Krait Group'], _
		[316, 2489, 'Krait Group'], _
		[-1018, -1235, 'Moving Back'], _
		[-3195, -1538, 'Krait Patrol'], _
		[-6322, -2565, 'Krait Group'], _
		_ ; blessing
		[-11414, 4055, 'Leftovers Krait'], _
		[-6907, 8461, 'Moving'], _
		[-8689, 11227, 'Leftovers Krait and Rider'] _
	]

	Info('Taking Blessing')
	MoveTo(14865,13160)
	RandomSleep(1000)
	GoNearestNPCToCoords(14865,13160)
	RandomSleep(1000)
	Dialog(0x84)
	RandomSleep(1000)

	If MoveAggroAndKillGroups($foes, 1, 9) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoNearestNPCToCoords(18409, -8474)
	RandomSleep(2000)

	If MoveAggroAndKillGroups($foes, 10, 26) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoNearestNPCToCoords(-10109, -17520)
	RandomSleep(2000)

	If MoveAggroAndKillGroups($foes, 27, 41) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoNearestNPCToCoords(-19292, 8994)
	RandomSleep(2000)

	If MoveAggroAndKillGroups($foes, 42, 56) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoNearestNPCToCoords(-2037, 10758)
	RandomSleep(2000)

	If MoveAggroAndKillGroups($foes, 57, 68) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoNearestNPCToCoords(4893, 445)
	RandomSleep(2000)

	If MoveAggroAndKillGroups($foes, 69, 80) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoNearestNPCToCoords(-9231, -2629)
	RandomSleep(3000)

	If MoveAggroAndKillGroups($foes, 81, 83) == $FAIL Then Return $FAIL

	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	Else
		Info('Map has been fully vanquished.')
		Return $SUCCESS
	EndIf
EndFunc