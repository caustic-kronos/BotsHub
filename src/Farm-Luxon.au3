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

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', 1)

Local Const $LuxonFactionBotVersion = '0.1'

; ==== Constantes ====
Local Const $LuxonFactionSkillbar = ''
Local Const $LuxonFactionInformations = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild'

Local $groupIsAlive = True
Local $DonatePoints = True


Local Const $ID_unknown_outpost_deposit_points = 193

;~ Main loop
Func LuxonFactionFarm($STATUS)
	If GetMapID() <> $ID_Aspenwood_Gate_Luxon Then
		Info('Moving to Outpost')
		DistrictTravel($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
		WaitMapLoading($ID_Aspenwood_Gate_Luxon, 10000, 2000)
	EndIf

	LuxonFarmSetup()

	If $STATUS <> 'RUNNING' Then Return 2

	MoveTo(-4268, 11628)
	MoveTo(-4980, 12425)
	MoveTo(-5493, 13712)
	WaitMapLoading($ID_Mount_Qinkai, 10000, 2000)
	$groupIsAlive = True
	AdlibRegister('LuxonGroupIsAlive', 30000)
	Local $result = VanquishMountQinkai()
	AdlibUnRegister('LuxonGroupIsAlive')

	; Temporarily change a failure into a pause for debugging :
	If $result == 1 Then $result = 2
	If $STATUS <> 'RUNNING' Then Return 2
	If (CountSlots() < 10) Then
		Info('Inventory full, pausing.')
		$result = 2
	EndIf

	Return $result
EndFunc


Func LuxonFarmSetup()
	If GetLuxonFaction() > (GetMaxLuxonFaction() - 25000) Then
		Info('Turning in Luxon faction')
		DistrictTravel($ID_unknown_outpost_deposit_points, $DISTRICT_NAME)
		WaitMapLoading($ID_unknown_outpost_deposit_points, 10000, 2000)
		RndSleep(200)
		GoNearestNPCToCoords(9076, -1111)

		If $DonatePoints Then
			While GetLuxonFaction() >= 5000
				DonateFaction('Luxon')
				RndSleep(500)
			WEnd
		Else
			Info('Buying Jade Shards')
			Dialog(131)
			RndSleep(500)
			$temp = Floor(GetLuxonFaction() / 5000)
			$id = 8388609 + ($temp * 256)
			Dialog($id)
			RndSleep(550)
		EndIf
		RndSleep(500)
		DistrictTravel($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
		WaitMapLoading($ID_Aspenwood_Gate_Luxon, 10000, 2000)
	EndIf

	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Info('Withdrawing gold for shrines benediction')
		RndSleep(250)
		WithdrawGold(100)
		RndSleep(250)
	EndIf

	SwitchMode($ID_HARD_MODE)
EndFunc


Func VanquishMountQinkai()
	Info('Taking blessing')
	GoNearestNPCToCoords(-8394, -9801)
	Dialog(0x85)
	RndSleep(1000)
	Dialog(0x86)
	RndSleep(1000)

	If MapClearMoveAndAggro(-11400, -9000, 'Yetis') Then Return 1
	If MapClearMoveAndAggro(-13500, -10000, 'Yeti 1') Then Return 1
	If MapClearMoveAndAggro(-15000, -8000, 'Yeti 2') Then Return 1
	If MapClearMoveAndAggro(-17500, -10500, 'Yeti Ranger Boss') Then Return 1
	If MapClearMoveAndAggro(-12000, -4500, 'Rot Wallows') Then Return 1
	If MapClearMoveAndAggro(-12500, -3000, 'Yeti 3') Then Return 1
	If MapClearMoveAndAggro(-14000, -2500, 'Yeti Ritualist Boss') Then Return 1
	If MapClearMoveAndAggro(-12000, -3000, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-10500, -500, 'Rot Wallow 1', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-11000, 5000, 'Yeti 4') Then Return 1
	If MapClearMoveAndAggro(-10000, 7000, 'Yeti 5') Then Return 1
	If MapClearMoveAndAggro(-8500, 8000, 'Yeti Monk Boss') Then Return 1
	If MapClearMoveAndAggro(-5000, 6500, 'Yeti 6') Then Return 1
	If MapClearMoveAndAggro(-3000, 8000, 'Yeti 7', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-5000, 4000, 'Yeti 8') Then Return 1
	If MapClearMoveAndAggro(-7000, 1000, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-9000, -1500, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-6500, -4500, 'Rot Wallow 2', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-7000, -7500, 'Rot Wallow 3') Then Return 1
	If MapClearMoveAndAggro(-4000, -7500, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(0, -9500, 'Rot Wallow 4') Then Return 1
	If MapClearMoveAndAggro(5000, -7000, 'Oni 1') Then Return 1
	If MapClearMoveAndAggro(6500, -8500, 'Oni 2', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(5000, -3500, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(500, -2000, 'Leftovers') Then Return 1
	If MapClearMoveAndAggro(-1500, -3000, 'Naga 1') Then Return 1
	If MapClearMoveAndAggro(1000, 1000, 'Rot Wallow 5') Then Return 1
	If MapClearMoveAndAggro(6500, 1000, 'Rot Wallow 6') Then Return 1
	If MapClearMoveAndAggro(5500, 5000, 'Leftovers') Then Return 1
	If MapClearMoveAndAggro(4000, 5500, 'Rot Wallow 7') Then Return 1
	If MapClearMoveAndAggro(6500, 7500, 'Rot Wallow 8') Then Return 1
	If MapClearMoveAndAggro(8000, 6000, 'Naga 2') Then Return 1
	If MapClearMoveAndAggro(9500, 7000, 'Naga 3') Then Return 1
	If MapClearMoveAndAggro(10500, 8000, 'Naga 4', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(12000, 7500, 'Naga 5', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(16000, 7000, 'Naga 6') Then Return 1
	If MapClearMoveAndAggro(15500, 4500, 'Leftovers') Then Return 1
	If MapClearMoveAndAggro(18000, 3000, 'Oni 3') Then Return 1
	If MapClearMoveAndAggro(16500, 1000, 'Leftovers') Then Return 1
	If MapClearMoveAndAggro(13500, -1500, 'Naga 7', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(12500, -3500, 'Naga 8', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(14000, -6000, 'Outcast Warrior Boss', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(13000, -6000, 'Leftovers', $RANGE_COMPASS) Then Return 1
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return 1
	EndIf
	Return 0
EndFunc


Func UnusedOldScanning()
	If MapClearMoveAndAggro(-13046, -9347, 'Yeti 1') Then Return 1
	If MapClearMoveAndAggro(-17348, -9895, 'Yeti 2') Then Return 1
	If MapClearMoveAndAggro(-14702, -6671, 'Oni and Wallows 1') Then Return 1
	If MapClearMoveAndAggro(-11080, -6126, 'Oni and Wallows 2', 2000) Then Return 1
	If MapClearMoveAndAggro(-13426, -2344, 'Yeti') Then Return 1
	If MapClearMoveAndAggro(-15055, -3226, 'TomTom') Then Return 1
	If MapClearMoveAndAggro(-9448, -283, 'Guardian and Wallows') Then Return 1
	If MapClearMoveAndAggro(-9918, 2826, 'Yeti 1', 2000) Then Return 1
	If MapClearMoveAndAggro(-8721, 7682, 'Yeti 2') Then Return 1
	If MapClearMoveAndAggro(-3250, 8400, 'Yeti 3', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(-7474, -1144, 'Guardian and Wallows 1') Then Return 1
	If MapClearMoveAndAggro(-9666, 2625, 'Guardian and Wallows 2') Then Return 1
	If MapClearMoveAndAggro(-5895, -3959, 'Guardian and Wallows 3') Then Return 1
	If MapClearMoveAndAggro(-3509, -8000, 'Patrol') Then Return 1
	If MapClearMoveAndAggro(-195, -9095, 'Oni 1') Then Return 1
	If MapClearMoveAndAggro(6298, -8707, 'Oni 2') Then Return 1
	If MapClearMoveAndAggro(3981, -3295, 'Bridge') Then Return 1
	If MapClearMoveAndAggro(496, -2581, 'Naga 1', 2000) Then Return 1
	If MapClearMoveAndAggro(2069, 1127, 'Guardian and Wallows 1') Then Return 1
	If MapClearMoveAndAggro(5859, 1599, 'Guardian and Wallows 2') Then Return 1
	If MapClearMoveAndAggro(6412, 6572, 'Guardian and Wallows 3') Then Return 1
	If MapClearMoveAndAggro(8550, 7000, 'Naga 1', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(11000, 8250, 'Naga 2', $RANGE_SPIRIT) Then Return 1
	If MapClearMoveAndAggro(14403, 6938, 'Oni 1') Then Return 1
	If MapClearMoveAndAggro(18080, 3127, 'Oni 2') Then Return 1
	If MapClearMoveAndAggro(13518, -35, 'Naga 1') Then Return 1
	If MapClearMoveAndAggro(13450, -6084, 'Naga 2', 4000) Then Return 1
	If MapClearMoveAndAggro(13764, -4816, 'Naga 3', 4000) Then Return 1
	If MapClearMoveAndAggro(13450, -6084, 'Naga 4', 4000) Then Return 1
	If MapClearMoveAndAggro(13764, -4816, 'Naga 5', 4000) Then Return 1
EndFunc

Func LuxonGroupIsAlive()
	$groupIsAlive = IsGroupAlive()
EndFunc