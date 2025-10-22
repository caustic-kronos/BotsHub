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

; ==== Constants ====
Global Const $LightbringerFarm2Informations = 'Lightbringer title farm'
; Average duration ~ 45m
Global Const $LIGHTBRINGER_FARM2_DURATION = 45 * 60 * 1000
Global $LIGHTBRINGER_FARM2_SETUP = False

;~ Main loop for the Lightbringer title farm
Func LightbringerFarm2($STATUS)
	If GetMapID() <> $ID_Kodash_Bazaar Then
		Info('Moving to Kodash Bazaar')
		DistrictTravel($ID_Kodash_Bazaar, $DISTRICT_NAME)
		WaitMapLoading($ID_Kodash_Bazaar, 10000, 2000)
	EndIf
	If Not $LIGHTBRINGER_FARM2_SETUP Then LightbringerSetup()

	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = Lightbringer()
	AdlibUnRegister('TrackGroupStatus')
	; Temporarily change a failure into a pause for debugging :
	;If $result == 1 Then $result = 2
	Return $result
EndFunc

Func LightbringerSetup()
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
	SwitchMode($ID_HARD_MODE)
	MoveTo(-2186, -1916)
	MoveTo(-3811, 1177)
	MoveTo(-953, 4199)
	MoveTo(-850, 4700)
	RndSleep(5000)
	WaitMapLoading($ID_Mirror_of_Lyss, 10000, 2000)
	MoveTo(-19350, -16900)
	RndSleep(5000)
	WaitMapLoading($ID_Kodash_Bazaar, 10000, 2000)
	$LIGHTBRINGER_FARM2_SETUP = True
	Info('Setup completed')
EndFunc

;~ Cleaning Lightbringers func
Func Lightbringer()
	MoveTo(-850, 4700)
	RndSleep(5000)
	WaitMapLoading($ID_Mirror_of_Lyss, 10000, 2000)
	MoveTo(-19296, -14111)

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-20867, -13147))
	RndSleep(1000)
	Dialog(0x85)
	RndSleep(1000)
	MoveTo(-13760, -13924)
	MoveTo(-10600, -12671)
	MoveTo(-4785, -14912)

	If MoveAggroAndKill(-2451, -15086, 'Group 1/10') Then Return 1
	If MoveAggroAndKill(1174, -13787, 'Plants') Then Return 1
	If MoveAggroAndKill(6728, -12014, 'Plants') Then Return 1
	If MoveAggroAndKill(9554, -14517, 'Kournans + boss') Then Return 1
	If MoveAggroAndKill(16856, -14068, 'Plants') Then Return 1
	If MoveAggroAndKill(19428, -13168, 'Group 2/10') Then Return 1
	If MoveAggroAndKill(16961, -7251, 'Group 3/10') Then Return 1
	If MoveAggroAndKill(20212, -5510, 'Group 4/10') Then Return 1
	If MoveAggroAndKill(20373, -580, 'Group 5/10') Then Return 1
	If MoveAggroAndKill(19778, 2882, 'Group 6/10') Then Return 1
	If MoveAggroAndKill(19561, 6432, 'Group 7/10') Then Return 1
	If MoveAggroAndKill(15914, 10322, 'Group 8/10') Then Return 1
	MoveTo(12116, 7908)
	If MoveAggroAndKill(12932, 6907, 'Group 9/10') Then Return 1
	If MoveAggroAndKill(12956, 2637, 'Group 10/10') Then Return 1
	Info('Groups are destroyed, resign and do it again')
	MoveTo(12856, 2627)
	RndSleep(500)
	Resign()
	RndSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Kodash_Bazaar, 10000, 2000)
	Return 0
EndFunc