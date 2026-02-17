#CS ===========================================================================
; Author: ian
; Contributor: ---
; Copyright 2026 caustic-kronos
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
; - noticed some scenarios where map is not cleared - check whether this can be fixed by adding a few additional locations

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $KURZICK_FACTION_DRAZACH_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot does not load hero builds - please use your own teambuild' & @CRLF _
	& 'An Alternative Farm to Ferndale. This Bot will farm Drazach Thicket'
; Average duration ~ 25m
Global Const $KURZICKS_FARM_DRAZACH_DURATION = 25 * 60 * 1000

Global $kurzick_farm_drazach_setup = False

;~ Main loop for the kurzick faction farm
Func KurzickFactionFarmDrazach()
	ManageFactionPointsKurzickFarm()
	If Not $kurzick_farm_drazach_setup Then KurzickFarmDrazachSetup()
	GetGoldForShrineBenediction()
	GoToDrazach()
	Local $result = VanquishDrazach()
	AdlibUnRegister('TrackPartyStatus')
	Return $result
EndFunc

;~ Setup for kurzick farm
Func KurzickFarmDrazachSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	SwitchMode($ID_HARD_MODE)

	$kurzick_farm_drazach_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc

;~ Move out of outpost into Drazach
Func GoToDrazach()
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	While GetMapID() <> $ID_DRAZACH_THICKET
		Info('Moving to Drazach')
		MoveTo(-5930, 14270)
		Move(-6550, 14550)
		RandomSleep(1000)
		WaitMapLoading($ID_DRAZACH_THICKET, 10000, 2000)
	WEnd
	If GetMapID() <> $ID_DRAZACH_THICKET Then Return $FAIL
EndFunc

Func VanquishDrazach()
	Info('Taking blessing')
	MoveTo(-4930, -16385)
	GoNearestNPCToCoords(-5620, -16370)
	If GetLuxonFaction() > GetKurzickFaction() Then
		Dialog(0x81)
		Sleep(1000)
		Dialog(0x2)
		Sleep(1000)
		Dialog(0x84)
		Sleep(1000)
		Dialog(0x86)
		RandomSleep(1000)
	Else
		Dialog(0x85)
		RandomSleep(1000)
		Dialog(0x86)
		RandomSleep(1000)
	EndIf

	Local Static $foes[][] = [ _
		[-6506,		-16099,		'Start'					], _
		[-8581,		-15354,		'Approach'				], _
		[-8627,		-13151,		'Clear first big batch'	], _
		[-6128,		-11242,		'Path'					], _
		[-5173,		-10858,		'Path'					], _
		[-6368,		-9313,		'Kill Mesmer Boss'		], _
		[-7827,		-9681,		'Kill Mesmer Boss'		], _
		[-6021,		-8358,		'Clear smaller groups'	], _
		[-5184,		-6307,		'Clear smaller groups'	], _
		[-4643,		-5336,		'Clear smaller groups'	], _
		[-7368,		-6043,		'Clear smaller groups'	], _
		[-9514,		-6539,		'Clear smaller groups'	], _
		[-10988,	-8177,		'Kill Necro Boss'		], _
		[-11388,	-7827,		'Kill Necro Boss'		], _
		[-11291,	-5987,		'Small groups north'	], _
		[-11380,	-3787,		'Small groups north'	], _
		[-10641,	-1714,		'Small groups north'	], _
		[-8659,		-2268,		'Oni spawn point'		], _
		[-7019,		-976,		'Undergrowth group'		], _
		[-4464,		780,		'Undergrowth group'		], _
		[-4464,		780,		'Back NW'				], _
		[-7019,		-976,		'Back NW'				], _
		[-10575,	489,		'Back NW'				], _
		[-11266,	2581,		'Back NW'				], _
		[-10444,	4234,		'Back NW'				], _
		[-12820,	4153,		'Back NW'				], _
		[-12804,	6357,		'Oni spawn point'		], _
		[-12074,	8448,		'Kill Mantis'			], _
		[-10212,	10309,		'Kill Mantis'			], _
		[-8211,		11407,		'Kill Mantis'			], _
		[-7754,		9436,		'Oni spawn point'		], _
		[-6167,		9447,		'Kill Wardens'			], _
		[-4815,		10528,		'Kill Wardens'			], _
		[-5479,		7343,		'Kill Wardens'			], _
		[-5289,		4998,		'Kill Wardens'			], _
		[-2484,		7233,		'Kill Wardens'			], _
		[-3367,		9928,		'Kill Wardens'			], _
		[-3394,		11746,		'Kill Ranger Boss'		], _
		[-4869,		12948,		'Kill Ranger Boss'		], _
		[-5932,		13806,		'Kill Ranger Boss'		], _
		[-4848,		15585,		'Wardens + Dragon Moss'	], _
		[-5701,		16202,		'Back'					], _
		[-3141,		16025,		'Back'					], _
		[-787,		15014,		'Back'					], _
		[1462,		15520,		'Back'					], _
		[4282,		14447,		'Oni spawn point'		], _
		[4605,		12623,		'Kill Wardens'			], _
		[2966,		11883,		'Kill Wardens'			], _
		[1147,		9904,		'Kill Wardens'			], _
		[-1241,		8426,		'Kill Wardens'			], _
		[1612,		10091,		'Kill Wardens'			], _
		[3292,		10628,		'Kill Wardens'			], _
		[4957,		8302,		'Kill Wardens'			], _
		[7123,		5813,		'Kill Wardens'			], _
		[8363,		9446,		'Kill Wardens'			], _
		[8723,		11237,		'Kill Wardens'			], _
		[7363,		13697,		'Kill Wardens'			], _
		[10668,		11515,		'Kill Wardens'			], _
		[13930,		10779,		'Kill Wardens'			], _
		[14685,		7077,		'To Wardens'			], _
		[11869,		5679,		'To Wardens'			], _
		[8744,		4192,		'To Wardens'			], _
		[6187,		6313,		'To Wardens'			], _
		[9159,		3654,		'To Wardens'			], _
		[11257,		338,		'To Wardens'			], _
		[8844,		303,		'Undergrowth groups'	], _
		[5613,		296,		'Undergrowth groups'	], _
		[2832,		3850,		'Undergrowth groups'	], _
		[4588,		5461,		'More Wardens'			], _
		[-599,		3401,		'More Wardens'			], _
		[-1528,		5116,		'Path'					], _
		[-1292,		2307,		'Path'					], _
		[-2693,		-4748,		'Last enemies'			], _
		[-454,		-4876,		'Last enemies'			], _
		[1888,		-4833,		'Last enemies'			], _
		[4022,		-5717,		'Last enemies'			], _
		[3528,		-7154,		'Last enemies'			], _
		[1103,		-6744,		'Last enemies'			], _
		[455,		-9067,		'Last enemies'			], _
		[2772,		-9397,		'Ritualist bosses'		] _
	]

	For $i = 0 To UBound($foes) - 1
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2]) == $FAIL Then Return $FAIL
	Next
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	Else
		Info('Map has been fully vanquished.')
		Return $SUCCESS
	EndIf
EndFunc