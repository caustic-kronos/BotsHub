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

#include '../../lib/GWA2.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/Utils.au3'


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $SUNSPEAR_ARMOR_FARM_INFORMATIONS = 'Sunspear armor farm with 7heroes GWReborn s comp'
; Average duration ~ 15m
Global Const $SUNSPEAR_ARMOR_FARM_DURATION = 15 * 60 * 1000

Global $sunspear_armor_farm_setup = False

;~ Main loop for the Sunspear Armor farm
Func SunspearArmorFarm()
	If Not $sunspear_armor_farm_setup Then SunspearArmorSetup()

	EnterSunspearArmorChallenge()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = SunspearArmorClean()
	AdlibUnRegister('TrackPartyStatus')

	Info('Returning back to the outpost')
	ResignAndReturnToOutpost($ID_DAJKAH_INLET, true)
	Return $result
EndFunc


Func SunspearArmorSetup()
	Info('Setting up farm')
	If GetMapID() <> $ID_DAJKAH_INLET Then
		TravelToOutpost($ID_DAJKAH_INLET, $district_name)
	Else
		ResignAndReturnToOutpost($ID_DAJKAH_INLET, true)
	EndIf
	SwitchToHardModeIfEnabled()
	$sunspear_armor_farm_setup = True
	Info('Setup completed')
EndFunc


Func EnterSunspearArmorChallenge()
	TravelToOutpost($ID_DAJKAH_INLET, $district_name)
	Info('Entering Dajkah Inlet challenge')
	; Unfortunately Dajkah Inlet Challenge map has the same map ID as Dajkah Inlet outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Dajkah Inlet Challenge map
	Local Static $StartX = 29886
	Local Static $StartY = -3956
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		GoToNPC(GetNearestNPCToCoords(-2884, -2572))
		RandomSleep(250)
		Dialog(0x87)
		; wait 8 seconds to ensure that player exited outpost and entered challenge
		Sleep(8000)
	WEnd
EndFunc


;~ Cleaning Sunspear Armors function
Func SunspearArmorClean()
	If GetMapID() <> $ID_DAJKAH_INLET Then Return $FAIL
	MoveTo(25752.28, -3139.02)
	RandomSleep(62000)

	; 23 groups to vanquish + 10 movements
	Local Static $foes[33][3] = [ _
		[22595, -484, 'Moving and aggroing'], _
		[21032, 1357, 'Moving and aggroing'], _
		[20006, 3631, 'Moving and aggroing'], _
		[20548, 4762, 'Lord 1'], _
		[20834, 5205, 'Cleaning'], _
		[20548, 4762, 'Moving and aggroing'], _
		[18991, 3166, 'Moving'], _
		[17809, 3999, 'Moving'], _
		[3043, -625, 'Cleaning right downstairs'], _
		[-459, -2790, 'Cleaning left downstairs'], _
		[-2337, -5236, 'Moving'], _
		[-3041, -5971, 'Cleaning left upstairs'], _
		[-4624, -5597, 'Moving and aggroing'], _
		[-3602, -4455, 'Lord 2'], _
		[-4624, -5597, 'Moving and aggroing'], _
		[-3041, -5971, 'Moving and aggroing'], _
		[-459, -2790, 'Moving and aggroing'], _
		[3043, -625, 'Moving and aggroing'], _
		[4878, 2035, 'Moving'], _
		[5258, 2388, 'Cleaning right upstairs'], _
		[4425, 3445, 'Lord 3'], _
		[5258, 2388, 'Moving'], _
		[4878, 2035, 'Moving'], _
		[-1775, 1634, 'Moving'], _
		[-2077, 1961, 'Moving'], _
		[-22281, -1947, 'Moving'], _
		[-24882, -2719, 'Moving and aggroing'], _
		[-28780, -3676, 'Lord 4'], _
		[-24882, -2719, 'Moving and aggroing'], _
		[-21963, 624, 'Last Lords gate'], _
		[-20928, 3428, 'Moving and aggroing'], _
		[-20263, 4476, 'Moving'], _
		[-19880, 4086, 'Lord 5'] _
	]

	For $i = 0 To 6
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2]) == $FAIL Then Return $FAIL
	Next
	Info('Bridge 1')
	If MoveAggroAndKillInRange($foes[7][0], $foes[7][1], $foes[7][2]) == $FAIL Then Return $FAIL
	Info('Bridge 2')
	For $i = 8 To 24
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2]) == $FAIL Then Return $FAIL
	Next
	Info('2nd portal')
	For $i = 25 To 32
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2]) == $FAIL Then Return $FAIL
	Next

	RandomSleep(500)
	Return $SUCCESS
EndFunc