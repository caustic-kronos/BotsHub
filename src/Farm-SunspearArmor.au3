#CS ===========================================================================
; Author: An anonymous fan of Dhuum
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


Opt('MustDeclareVars', 1)

; ==== Constantes ====
Global Const $SunspearArmorInformations = 'Sunspear armor farm with 7heroes GWReborn s comp'
; Average duration ~ 15m
Global Const $SUNSPEAR_ARMOR_FARM_DURATION = 15 * 60 * 1000
Global $SUNSPEAR_ARMOR_FARM_SETUP = False

;~ Main loop for the Sunspear Armor farm
Func SunspearArmorFarm($STATUS)
	If GetMapID() <> $ID_Dajkah_Inlet_Outpost Then
		Info('Moving to Kodash Bazaar')
		DistrictTravel($ID_Dajkah_Inlet_Outpost, $DISTRICT_NAME)
		WaitMapLoading($ID_Dajkah_Inlet_Outpost, 10000, 2000)
	EndIf
	If Not $SUNSPEAR_ARMOR_FARM_SETUP Then SunspearArmorSetup()

	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = SunspearArmorClean()
	AdlibUnRegister('TrackGroupStatus')
	; Temporarily change a failure into a pause for debugging :
	;If $result == 1 Then $result = 2
	Return $result
EndFunc

Func SunspearArmorSetup()
	;LeaveGroup()
	;RndSleep(500)
	;AddHero($ID_Norgu)
	;RndSleep(500)
	;AddHero($ID_Gwen)
	;RndSleep(500)
	;AddHero($ID_Razah)
	;RndSleep(500)
	;AddHero($ID_Master_Of_Whispers)
	;RndSleep(500)
	;AddHero($ID_Livia)
	;RndSleep(500)
	;AddHero($ID_Olias)
	;RndSleep(500)
	;AddHero($ID_Xandra)
	;RndSleep(500)
	$SUNSPEAR_ARMOR_FARM_SETUP = True
	Info('Setup completed')
EndFunc

;~ Cleaning SunspearArmors func
Func SunspearArmorClean()
	GoToNPC(GetNearestNPCToCoords(-2884, -2572))
	RndSleep(250)
	Dialog(0x00000087)
	RndSleep(500)
	WaitMapLoading($ID_Dajkah_Inlet_Mission, 10000, 2000)
	MoveTo(25752.28, -3139.02)
	RndSleep(62000)
	If MoveAggroAndKill(22595, -484) Then Return 1
	If MoveAggroAndKill(21032, 1357) Then Return 1
	If MoveAggroAndKill(20006, 3631) Then Return 1
	If MoveAggroAndKill(20548, 4762, 'Lord 1') Then Return 1
	If MoveAggroAndKill(20834, 5205, 'Cleaning') Then Return 1
	If MoveAggroAndKill(20548, 4762) Then Return 1
	MoveTo(18991, 3166)
	Info('Bridge 1')
	MoveTo(17809, 3999)
	Info('Bridge 2')
	If MoveAggroAndKill(3043, -625, 'Cleaning right downstairs') Then Return 1
	If MoveAggroAndKill(-459, -2790, 'Cleaning left downstairs') Then Return 1
	MoveTo(-2337, -5236)
	If MoveAggroAndKill(-3041, -5971, 'Cleaning left upstairs') Then Return 1
	If MoveAggroAndKill(-4624, -5597) Then Return 1
	If MoveAggroAndKill(-3602, -4455, 'Lord 2') Then Return 1
	If MoveAggroAndKill(-4624, -5597) Then Return 1
	If MoveAggroAndKill(-3041, -5971) Then Return 1
	If MoveAggroAndKill(-459, -2790) Then Return 1
	If MoveAggroAndKill(3043, -625) Then Return 1
	MoveTo(4878, 2035)
	If MoveAggroAndKill(5258, 2388, 'Cleaning right upstairs') Then Return 1
	If MoveAggroAndKill(4425, 3445, 'Lord 3') Then Return 1
	MoveTo(5258, 2388)
	MoveTo(4878, 2035)
	MoveTo(-1775, 1634)
	MoveTo(-2077, 1961)
	Info('2nd portal')
	MoveTo(-22281, -1947)
	If MoveAggroAndKill(-24882, -2719) Then Return 1
	If MoveAggroAndKill(-28780, -3676, 'Lord 4') Then Return 1
	If MoveAggroAndKill(-24882, -2719) Then Return 1
	If MoveAggroAndKill(-21963, 624, 'Last Lords gate') Then Return 1
	If MoveAggroAndKill(-20928, 3428) Then Return 1
	MoveTo(-20263, 4476)
	If MoveAggroAndKill(-19880, 4086, 'Lord 5') Then Return 1
	RndSleep(500)
	Resign()
	RndSleep(3500)
	RndSleep(12000)
	WaitMapLoading($ID_Dajkah_Inlet_Outpost, 10000, 2000)
	Return 0
EndFunc