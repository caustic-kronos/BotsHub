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

Opt('MustDeclareVars', True)

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
	LuxonFarmSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToMountQinkai()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VanquishMountQinkai()
	AdlibUnRegister('TrackPartyStatus')

	; Temporarily change a failure into a pause for debugging :
	;If $result == $FAIL Then $result = $PAUSE
	TravelToOutpost($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Setup for the luxon points farm
Func LuxonFarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
	; Assuming that team has been set up correctly manually
	If GetLuxonFaction() > (GetMaxLuxonFaction() - 25000) Then
		DistrictTravel($ID_unknown_outpost_deposit_points, $DISTRICT_NAME)
		RandomSleep(200)
		GoNearestNPCToCoords(9076, -1111)

		If $DonatePoints Then
			Info('Donating Luxon faction points')
			While GetLuxonFaction() >= 5000
				DonateFaction('Luxon')
				RandomSleep(500)
			WEnd
		Else
			Info('Converting Luxon faction points into Jadeite Shards')
			Dialog(0x83)
			RandomSleep(500)
			Local $temp = Floor(GetLuxonFaction() / 5000)
			Local $dialogID = 0x800001 + ($temp * 256)
			Dialog($dialogID)
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
	Info('Setup completed')
EndFunc


;~ Move out of outpost into Mount Qinkai
Func GoToMountQinkai()
	If GetMapID() <> $ID_Aspenwood_Gate_Luxon Then TravelToOutpost($ID_Aspenwood_Gate_Luxon, $DISTRICT_NAME)
	While GetMapID() <> $ID_Mount_Qinkai
		Info('Moving to Mount Qinkai')
		MoveTo(-4268, 11628)
		MoveTo(-5300, 13300)
		Move(-5493, 13712)
		RandomSleep(1000)
		WaitMapLoading($ID_Mount_Qinkai, 10000, 2000)
	WEnd
EndFunc


;~ Vanquish the Mount Qinkai map
Func VanquishMountQinkai()
	If GetMapID() <> $ID_Mount_Qinkai Then Return $FAIL
	Info('Taking blessing')
	GoNearestNPCToCoords(-8394, -9801)
	Dialog(0x85)
	RandomSleep(1000)
	Dialog(0x86)
	RandomSleep(1000)

	Local Static $foes[43][4] = [ _ ; 43 groups to vanquish
		[-11400, -9000, 'Yetis', $AGGRO_RANGE], _
		[-13500, -10000, 'Yeti 1', $AGGRO_RANGE], _
		[-15000, -8000, 'Yeti 2', $AGGRO_RANGE], _
		[-17500, -10500, 'Yeti Ranger Boss', $AGGRO_RANGE], _
		[-12000, -4500, 'Rot Wallows', $AGGRO_RANGE], _
		[-12500, -3000, 'Yeti 3', $AGGRO_RANGE], _
		[-14000, -2500, 'Yeti Ritualist Boss', $AGGRO_RANGE], _
		[-12000, -3000, 'Leftovers', $RANGE_SPIRIT], _
		[-10500, -500, 'Rot Wallow 1', $RANGE_SPIRIT], _
		[-11000, 5000, 'Yeti 4', $AGGRO_RANGE], _
		[-10000, 7000, 'Yeti 5', $AGGRO_RANGE], _
		[-8500, 8000, 'Yeti Monk Boss', $AGGRO_RANGE], _
		[-5000, 6500, 'Yeti 6', $AGGRO_RANGE], _
		[-3000, 8000, 'Yeti 7', $RANGE_SPIRIT], _
		[-5000, 4000, 'Yeti 8', $AGGRO_RANGE], _
		[-7000, 1000, 'Leftovers', $RANGE_SPIRIT], _
		[-9000, -1500, 'Leftovers', $RANGE_SPIRIT], _
		[-6500, -4500, 'Rot Wallow 2', $RANGE_SPIRIT], _
		[-7000, -7500, 'Rot Wallow 3', $AGGRO_RANGE], _
		[-4000, -7500, 'Leftovers', $RANGE_SPIRIT], _
		[0, -9500, 'Rot Wallow 4', $AGGRO_RANGE], _
		[5000, -7000, 'Oni 1', $AGGRO_RANGE], _
		[6500, -8500, 'Oni 2', $RANGE_SPIRIT], _
		[5000, -3500, 'Leftovers', $RANGE_SPIRIT], _
		[500, -2000, 'Leftovers', $AGGRO_RANGE], _
		[-1500, -3000, 'Naga 1', $AGGRO_RANGE], _
		[1000, 1000, 'Rot Wallow 5', $AGGRO_RANGE], _
		[6500, 1000, 'Rot Wallow 6', $AGGRO_RANGE], _
		[5500, 5000, 'Leftovers', $AGGRO_RANGE], _
		[4000, 5500, 'Rot Wallow 7', $AGGRO_RANGE], _
		[6500, 7500, 'Rot Wallow 8', $AGGRO_RANGE], _
		[8000, 6000, 'Naga 2', $AGGRO_RANGE], _
		[9500, 7000, 'Naga 3', $AGGRO_RANGE], _
		[10500, 8000, 'Naga 4', $RANGE_SPIRIT], _
		[12000, 7500, 'Naga 5', $RANGE_SPIRIT], _
		[16000, 7000, 'Naga 6', $AGGRO_RANGE], _
		[15500, 4500, 'Leftovers', $AGGRO_RANGE], _
		[18000, 3000, 'Oni 3', $AGGRO_RANGE], _
		[16500, 1000, 'Leftovers', $AGGRO_RANGE], _
		[13500, -1500, 'Naga 7', $RANGE_SPIRIT], _
		[12500, -3500, 'Naga 8', $RANGE_SPIRIT], _
		[14000, -6000, 'Outcast Warrior Boss', $RANGE_SPIRIT], _
		[13000, -6000, 'Leftovers', $RANGE_COMPASS] _
	]

	If MoveAggroAndKillGroups($foes, 1, UBound($foes)) == $FAIL Then Return $FAIL
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc