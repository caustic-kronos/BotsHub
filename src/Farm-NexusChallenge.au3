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
Global Const $NexusChallengeinformations = 'Mysterious armor farm'
; Average duration ~ 20m
Global Const $NEXUS_CHALLENGE_FARM_DURATION = 20 * 60 * 1000

;~ Main loop for the Mysterious armor farm
Func NexusChallengeFarm($STATUS)
	If GetMapID() <> $ID_Nexus Then
		Info('Moving to Nexus')
		DistrictTravel($ID_Nexus, $DISTRICT_NAME)
		WaitMapLoading($ID_Nexus, 10000, 2000)
	EndIf

	NexusChallengeSetup()

	AdlibRegister('TrackGroupStatus', 10000)
	Local $result = NexusChallenge()
	AdlibUnRegister('TrackGroupStatus')
	Return $result
EndFunc

Func NexusChallengeSetup()
	;LeaveGroup()
	;RndSleep(500)
	;AddHero($ID_Norgu)
	;RndSleep(500)
	;AddHero($ID_Xandra)
	;RndSleep(500)
	;AddHero($ID_Master_Of_Whispers)
	;RndSleep(500)
	SwitchMode($ID_NORMAL_MODE)
EndFunc

;~ Cleaning NexusChallenges func
Func NexusChallenge()
	; Lance la quête
	MoveTo(-2218, -5033)
	GoToNPC(GetNearestNPCToCoords(-2218, -5033))
	Notice('Talking to NPC')
	Sleep(1000)
	Dialog(0x88)
	Sleep(1000)
	RndSleep(4000)
	WaitMapLoading($ID_Nexus, 10000, 2000)
	Sleep(50000)

	; Sinon on fait les 5 groupes
	If MoveAggroAndKill(-2675, 3301, 'Group 1') Then Return 1
	If MoveAggroAndKill(-55, 3297, 'Group 2') Then Return 1
	If MoveAggroAndKill(-1759, 993, 'Group 3') Then Return 1
	If MoveAggroAndKill(3834, 2759, 'Group 4') Then Return 1
	If MoveAggroAndKill(2479, -1967, 'Group 5') Then Return 1
	If MoveAggroAndKill(1572, -616, 'Group 6') Then Return 1
	If MoveAggroAndKill(668, -3516, 'Group 7') Then Return 1
	If MoveAggroAndKill(-3723, -3662, 'Group 8') Then Return 1
	If MoveAggroAndKill(-3809, 880, 'Group 9') Then Return 1
	Notice('First loop completed')
	If MoveAggroAndKill(-2675, 3301, 'Group 1') Then Return 1
	If MoveAggroAndKill(-55, 3297, 'Group 2') Then Return 1
	If MoveAggroAndKill(-1759, 993, 'Group 3') Then Return 1
	If MoveAggroAndKill(3834, 2759, 'Group 4') Then Return 1
	If MoveAggroAndKill(2479, -1967, 'Group 5') Then Return 1
	If MoveAggroAndKill(1572, -616, 'Group 6') Then Return 1
	If MoveAggroAndKill(668, -3516, 'Group 7') Then Return 1
	If MoveAggroAndKill(-3723, -3662, 'Group 8') Then Return 1
	If MoveAggroAndKill(-3809, 880, 'Group 9') Then Return 1
	Notice('Second loop completed, reset')
	If MoveAggroAndKill(-2675, 3301, 'Group 1') Then Return 1
	If MoveAggroAndKill(-55, 3297, 'Group 2') Then Return 1
	If MoveAggroAndKill(-1759, 993, 'Group 3') Then Return 1
	If MoveAggroAndKill(3834, 2759, 'Group 4') Then Return 1
EndFunc