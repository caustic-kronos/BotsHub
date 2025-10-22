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

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $LuxonFactionInformations = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild'
; Average duration ~ 20m
Global Const $LUXONS_FARM_DURATION = 20 * 60 * 1000
Global Const $ID_unknown_outpost_deposit_points = 193

Global $DonatePoints = True


;~ Main loop for the luxon faction farm
Func LuxonFactionFarm($STATUS)
	If GetMapID() <> $ID_Aspenwood_Gate_Luxon Then
		Info('Moving to Outpost')
		DistrictTravel($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
	EndIf

	LuxonFarmSetup()

	If $STATUS <> 'RUNNING' Then Return 2

	MoveTo(-4268, 11628)
	MoveTo(-5300, 13300)
	Move(-5493, 13712)
	RandomSleep(1000)
	WaitMapLoading($ID_Mount_Qinkai, 10000, 2000)
	ResetFailuresCounter()
	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = VanquishMountQinkai()
	AdlibUnRegister('TrackGroupStatus')

	; Temporarily change a failure into a pause for debugging :
	;If $result == 1 Then $result = 2
	Return $result
EndFunc


;~ Setup for the luxon points farm
Func LuxonFarmSetup()
	If GetLuxonFaction() > (GetMaxLuxonFaction() - 25000) Then
		Info('Turning in Luxon faction')
		DistrictTravel($ID_unknown_outpost_deposit_points, $DISTRICT_NAME)
		RandomSleep(200)
		GoNearestNPCToCoords(9076, -1111)

		If $DonatePoints Then
			While GetLuxonFaction() >= 5000
				DonateFaction('Luxon')
				RandomSleep(500)
			WEnd
		Else
			Info('Buying Jade Shards')
			Dialog(131)
			RandomSleep(500)
			$temp = Floor(GetLuxonFaction() / 5000)
			$id = 8388609 + ($temp * 256)
			Dialog($id)
			RandomSleep(550)
		EndIf
		RandomSleep(500)
		DistrictTravel($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
	EndIf

	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Info('Withdrawing gold for shrines benediction')
		RandomSleep(250)
		WithdrawGold(100)
		RandomSleep(250)
	EndIf

	SwitchMode($ID_HARD_MODE)
EndFunc


;~ Vanquish the map
Func VanquishMountQinkai()
	Info('Taking blessing')
	GoNearestNPCToCoords(-8394, -9801)
	Dialog(0x85)
	RandomSleep(1000)
	Dialog(0x86)
	RandomSleep(1000)

	If MoveAggroAndKill(-11400, -9000, 'Yetis') Then Return 1
	If MoveAggroAndKill(-13500, -10000, 'Yeti 1') Then Return 1
	If MoveAggroAndKill(-15000, -8000, 'Yeti 2') Then Return 1
	If MoveAggroAndKill(-17500, -10500, 'Yeti Ranger Boss') Then Return 1
	If MoveAggroAndKill(-12000, -4500, 'Rot Wallows') Then Return 1
	If MoveAggroAndKill(-12500, -3000, 'Yeti 3') Then Return 1
	If MoveAggroAndKill(-14000, -2500, 'Yeti Ritualist Boss') Then Return 1
	If MoveAggroAndKill(-12000, -3000, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(-10500, -500, 'Rot Wallow 1', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(-11000, 5000, 'Yeti 4') Then Return 1
	If MoveAggroAndKill(-10000, 7000, 'Yeti 5') Then Return 1
	If MoveAggroAndKill(-8500, 8000, 'Yeti Monk Boss') Then Return 1
	If MoveAggroAndKill(-5000, 6500, 'Yeti 6') Then Return 1
	If MoveAggroAndKill(-3000, 8000, 'Yeti 7', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(-5000, 4000, 'Yeti 8') Then Return 1
	If MoveAggroAndKill(-7000, 1000, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(-9000, -1500, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(-6500, -4500, 'Rot Wallow 2', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(-7000, -7500, 'Rot Wallow 3') Then Return 1
	If MoveAggroAndKill(-4000, -7500, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(0, -9500, 'Rot Wallow 4') Then Return 1
	If MoveAggroAndKill(5000, -7000, 'Oni 1') Then Return 1
	If MoveAggroAndKill(6500, -8500, 'Oni 2', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(5000, -3500, 'Leftovers', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(500, -2000, 'Leftovers') Then Return 1
	If MoveAggroAndKill(-1500, -3000, 'Naga 1') Then Return 1
	If MoveAggroAndKill(1000, 1000, 'Rot Wallow 5') Then Return 1
	If MoveAggroAndKill(6500, 1000, 'Rot Wallow 6') Then Return 1
	If MoveAggroAndKill(5500, 5000, 'Leftovers') Then Return 1
	If MoveAggroAndKill(4000, 5500, 'Rot Wallow 7') Then Return 1
	If MoveAggroAndKill(6500, 7500, 'Rot Wallow 8') Then Return 1
	If MoveAggroAndKill(8000, 6000, 'Naga 2') Then Return 1
	If MoveAggroAndKill(9500, 7000, 'Naga 3') Then Return 1
	If MoveAggroAndKill(10500, 8000, 'Naga 4', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(12000, 7500, 'Naga 5', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(16000, 7000, 'Naga 6') Then Return 1
	If MoveAggroAndKill(15500, 4500, 'Leftovers') Then Return 1
	If MoveAggroAndKill(18000, 3000, 'Oni 3') Then Return 1
	If MoveAggroAndKill(16500, 1000, 'Leftovers') Then Return 1
	If MoveAggroAndKill(13500, -1500, 'Naga 7', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(12500, -3500, 'Naga 8', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(14000, -6000, 'Outcast Warrior Boss', $RANGE_SPIRIT) Then Return 1
	If MoveAggroAndKill(13000, -6000, 'Leftovers', $RANGE_COMPASS) Then Return 1
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return 1
	EndIf
	Return 0
EndFunc