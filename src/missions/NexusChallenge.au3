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
Global Const $NEXUS_CHALLENGE_INFORMATIONS = 'Mysterious armor farm'
; Average duration ~ 20m
Global Const $NEXUS_CHALLENGE_FARM_DURATION = 20 * 60 * 1000

Global $nexus_challenge_setup = False


;~ Main loop for the Mysterious armor farm
Func NexusChallengeFarm()
	If Not $nexus_challenge_setup And NexusChallengeSetup() == $FAIL Then Return $FAIL

	EnterNexusChallengeMission()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = NexusChallenge()
	AdlibUnRegister('TrackPartyStatus')
	; wait 15 seconds to ensure end mission timer of 15 seconds has elapsed
	Sleep(15000)
	Info('Returning back to the outpost')
	ResignAndReturnToOutpost($ID_THE_SHADOW_NEXUS, true)
	Return $result
EndFunc


Func NexusChallengeSetup()
	Info('Setting up farm')
	If GetMapID() <> $ID_THE_SHADOW_NEXUS Then
		TravelToOutpost($ID_THE_SHADOW_NEXUS, $district_name)
	Else
		ResignAndReturnToOutpost($ID_THE_SHADOW_NEXUS, true)
	EndIf
	SetDisplayedTitle($ID_LIGHTBRINGER_TITLE)
	SwitchMode($ID_NORMAL_MODE)
	If GetPartySize() <> $ID_TEAM_SIZE_SMALL Then
		Error('Party not set up correctly. Team size different than ' & $ID_TEAM_SIZE_SMALL)
		Return $FAIL
	EndIf
	$nexus_challenge_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func EnterNexusChallengeMission()
	TravelToOutpost($ID_THE_SHADOW_NEXUS, $district_name)
	; Unfortunately Nexus Challenge map has the same map ID as Nexus outpost, so it is harder to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Nexus Challenge map
	Local Static $startX = -391
	Local Static $startY = -335
	While Not IsAgentInRange(GetMyAgent(), $startX, $startY, $RANGE_EARSHOT)
		Info('Entering Nexus mission')
		MoveTo(-2218, -5033)
		GoToNPC(GetNearestNPCToCoords(-2218, -5033))
		Info('Talking to NPC')
		Sleep(1000)
		Dialog(0x88)
		; wait 8 seconds to ensure that player exited outpost and entered mission
		Sleep(8000)
	WEnd
EndFunc


;~ Cleaning Nexus challenge function
Func NexusChallenge()
	If GetMapID() <> $ID_THE_SHADOW_NEXUS Then Return $FAIL
	Sleep(50000)

	; 9 groups to defeat in each loop
	Local Static $foes[][] = [ _
		_ ; First loop
		[-2675,		3301,	'Group 1'], _
		[-55,		3297,	'Group 2'], _
		[-1759,		993,	'Group 3'], _
		[3834,		2759,	'Group 4'], _
		[2479,		-1967,	'Group 5'], _
		[1572,		-616,	'Group 6'], _
		[668,		-3516,	'Group 7'], _
		[-3723,		-3662,	'Group 8'], _
		[-3809,		880,	'Group 9'], _
		_ ; Second loop
		[-2675,		3301,	'Group 1'], _
		[-55,		3297,	'Group 2'], _
		[-1759,		993,	'Group 3'], _
		[3834,		2759,	'Group 4'], _
		[2479,		-1967,	'Group 5'], _
		[1572,		-616,	'Group 6'], _
		[668,		-3516,	'Group 7'], _
		[-3723,		-3662,	'Group 8'], _
		[-3809,		880,	'Group 9'] _
	]
	For $i = 0 To 8
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2]) == $FAIL Then Return $FAIL
	Next
	Info('First loop completed')

	For $i = 9 To 17
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2]) == $FAIL Then Return $FAIL
	Next
	Info('Second loop completed, reset')

	Return $SUCCESS
EndFunc