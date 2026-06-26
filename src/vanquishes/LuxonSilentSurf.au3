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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $LUXON_SILENT_SURF_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot does not load hero builds - please use your own teambuild'
; Average duration ~ 20m
Global Const $LUXONS_SILENT_SURF_DURATION = 30 * 60 * 1000

Global $luxon_silent_surf_setup = False


;~ Main loop for the luxon faction farm
Func LuxonSilentSurfFarm()
	If Not $luxon_silent_surf_setup Then LuxonSilentSurfSetup()

	ManageFactionPointsLuxonFarm()
	GetGoldForShrineBenediction()
	GoToSilentSurf()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VanquishSilentSurf()
	AdlibUnRegister('TrackPartyStatus')
	Return $result
EndFunc


;~ Setup for the luxon points farm
Func LuxonSilentSurfSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Leviathan_Pits, $district_name)
	SwitchMode($ID_HARD_MODE)
	$luxon_silent_surf_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Silent Surf
Func GoToSilentSurf()
	TravelToOutpost($ID_Leviathan_Pits, $district_name)
	While GetMapID() <> $ID_SILENT_SURF
		Info('Moving to Silent Surf')
		MoveTo(8800, -26150)
		Move(9000, -26600)
		RandomSleep(1000)
		WaitMapLoading($ID_SILENT_SURF, 10000, 2000)
	WEnd
EndFunc


;~ Vanquish Silent Surf map
Func VanquishSilentSurf()
	GoNearestNPCToCoords(11300, 24400)
	TakeFactionBlessing('luxon')

	If IsHardmodeEnabled() Then UseConset()
	UseSummoningStone()

	Local $foes = [ _
		[12800,		20200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[11350,		16800,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[11100,		14000,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[11100,		9100,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[9650,		5400,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[10550,		750,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[8600,		2600,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[7050,		-250,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[5500,		2200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[6700,		-3900,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[8550,		-5800,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[8400,		-7350,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[5575,		-7850,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[9950,		-10800,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[7650,		-13600,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[7400,		-16330,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[9800,		-17700,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[9200,		-18500,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[6100,		-13400,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[8800,		-12700,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[10200,		-16200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[4100,		-15000,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[1525,		-14600,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-450,		-18200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-100,		-13900,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[1800,		-11700,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-3050,		-11500,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-4600,		-10800,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-6200,		-8100,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-3150,		-6400,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-4150,		-3700,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-4575,		-2900,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-4950,		-150,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-5700,		2700,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-3150,		3800,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-4450,		6200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-2125,		6500,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-5100,		9000,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-5250,		9200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-6800,		6500,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-6300,		14500,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-4100,		15650,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-1900,		12900,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-700,		10200	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[1400,		15150,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[4800,		15900,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[6450,		20200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[6900,		22450,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[4450,		16750,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[2600,		11600,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[1650,		8250,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[7450,		8200,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[7800,		10900,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[2900,		9800,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[5250,		8300,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[4100,		6500,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[6700,		6000,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[9850,		6950,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[9400,		5450,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[4250,		4000,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[550,		3250,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[1550,		100,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-500,		-1100,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[-150,		-5000,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[100,		-5300,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[1850,		-6600,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[5300,		-9250,	' ',	$WIDE_PLAYER_AGGRO_RANGE	], _
		[3300,		-3150,	' ',	$RANGE_COMPASS				] _
	]

	For $i = 0 To UBound($foes) - 1
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2], $foes[$i][3]) == $FAIL Then Return $FAIL
	Next

	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	Else
		Info('Map has been fully vanquished.')
		Return $SUCCESS
	EndIf
EndFunc