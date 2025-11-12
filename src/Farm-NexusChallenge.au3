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
Global Const $NexusChallengeinformations = 'Mysterious armor farm'
; Average duration ~ 20m
Global Const $NEXUS_CHALLENGE_FARM_DURATION = 20 * 60 * 1000

;~ Main loop for the Mysterious armor farm
Func NexusChallengeFarm($STATUS)
	NexusChallengeSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	EnterNexusChallengeMission()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = NexusChallenge()
	AdlibUnRegister('TrackPartyStatus')
	Sleep(15000) ; wait 15 seconds to ensure end mission timer of 15 seconds has elapsed
	TravelToOutpost($ID_Nexus, $DISTRICT_NAME)
	Return $result
EndFunc


Func NexusChallengeSetup()
	Info('Setting up farm')
	If GetMapID() <> $ID_Nexus Then
		TravelToOutpost($ID_Nexus, $DISTRICT_NAME)
	Else ; resigning to return to outpost in case when player is in Nexus Challenge that has the same map ID as Nexus outpost (555)
		Resign()
		Sleep(4000)
		ReturnToOutpost()
		Sleep(6000)
	EndIf
	SetDisplayedTitle($ID_Lightbringer_Title)
	SwitchMode($ID_NORMAL_MODE)

	; Assuming that team has been set up correctly manually
	;SetupTeamNexusChallengeFarm()
	Info('Preparations complete')
EndFunc


Func SetupTeamNexusChallengeFarm()
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	RandomSleep(500)
	AddHero($ID_Norgu)
	RandomSleep(500)
	AddHero($ID_Xandra)
	RandomSleep(500)
	AddHero($ID_Master_Of_Whispers)
	Sleep(1000)
	If GetPartySize() <> 4 Then
    	Warn("Could not set up party correctly. Team size different than 4")
	EndIf
EndFunc


Func EnterNexusChallengeMission()
	If GetMapID() <> $ID_Nexus Then TravelToOutpost($ID_Nexus, $DISTRICT_NAME)
	; Unfortunately Nexus Challenge map has the same map ID as Nexus outpost, so it is hard to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Nexus Challenge map
	Local Static $StartX = -391
	Local Static $StartY = -335
	While GetDistanceToPoint(GetMyAgent(), $StartX, $StartY) > $RANGE_EARSHOT ; = 1000
		Info('Entering Nexus mission')
		; Lance la quête
		MoveTo(-2218, -5033)
		GoToNPC(GetNearestNPCToCoords(-2218, -5033))
		Notice('Talking to NPC')
		Sleep(1000)
		Dialog(0x88)
		Sleep(10000) ; wait 10 seconds to ensure that player exited outpost and entered mission
	WEnd
EndFunc


;~ Cleaning Nexus challenge function
Func NexusChallenge()
	If GetMapID() <> $ID_Nexus Then Return $FAIL
	Sleep(50000)

	; Sinon on fait les 5 groupes
	Local $foes[18][3] = [ _ ;~ 9 groups to defeat in each loop
		[1-2675, 3301, 'Group 1'], _ ;~ First loop
		[1-55, 3297, 'Group 2'], _
		[1-1759, 993, 'Group 3'], _
		[13834, 2759, 'Group 4'], _
		[12479, -1967, 'Group 5'], _
		[11572, -616, 'Group 6'], _
		[1668, -3516, 'Group 7'], _
		[1-3723, -3662, 'Group 8'], _
		[1-3809, 880, 'Group 9'], _
		[1-2675, 3301, 'Group 1'], _ ;~ Second loop
		[1-55, 3297, 'Group 2'], _
		[1-1759, 993, 'Group 3'], _
		[13834, 2759, 'Group 4'], _
		[12479, -1967, 'Group 5'], _
		[11572, -616, 'Group 6'], _
		[1668, -3516, 'Group 7'], _
		[1-3723, -3662, 'Group 8'], _
		[1-3809, 880, 'Group 9'] _
	]
		Local $x, $y, $log, $range
		For $i = 0 To UBound($foes) - 1
			$x = $foes[$i][0]
			$y = $foes[$i][1]
			$log = $foes[$i][2]
			If MoveAggroAndKill($x, $y, $log) == $FAIL Then Return $FAIL
			If $i == 8 Then Notice('First loop completed')
			If $i == 17 Then Notice('Second loop completed, reset')
		Next

	Return $SUCCESS
EndFunc