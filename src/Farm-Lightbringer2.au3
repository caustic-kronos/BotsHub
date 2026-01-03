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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'


Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $LightbringerFarm2Informations = 'Lightbringer title farm'
; Average duration ~ 45m
Global Const $LIGHTBRINGER_FARM2_DURATION = 45 * 60 * 1000
Global $LIGHTBRINGER_FARM2_SETUP = False

;~ Main loop for the Lightbringer title farm
Func LightbringerFarm2($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $LIGHTBRINGER_FARM2_SETUP Then Lightbringer2FarmSetup()

	GoToMirrorOfLyss()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = FarmMirrorOfLyss()
	AdlibUnRegister('TrackPartyStatus')

	ReturnBackToOutpost($ID_Kodash_Bazaar)
	Return $result
EndFunc


Func Lightbringer2FarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Kodash_Bazaar, $DISTRICT_NAME)
	SetDisplayedTitle($ID_Lightbringer_Title)
	SwitchMode($ID_HARD_MODE)
	TrySetupPlayerUsingGUISettings()
	TrySetupTeamUsingGUISettings()

	GoToMirrorOfLyss()
	MoveTo(-19350, -16900)
	RandomSleep(5000)
	WaitMapLoading($ID_Kodash_Bazaar, 10000, 2000)
	$LIGHTBRINGER_FARM2_SETUP = True
	Info('Preparations completed')
EndFunc


;~ Move out of outpost into Mirror of Lyss
Func GoToMirrorOfLyss()
	TravelToOutpost($ID_Kodash_Bazaar, $DISTRICT_NAME)
	While GetMapID() <> $ID_Mirror_of_Lyss
		Info('Moving to Mirror of Lyss')
		MoveTo(-2186, -1916)
		MoveTo(-3811, 1177)
		MoveTo(-953, 4199)
		MoveTo(-850, 4700)
		RandomSleep(5000)
		WaitMapLoading($ID_Mirror_of_Lyss, 10000, 2000)
	WEnd
EndFunc


;~ Cleaning Lightbringers function
Func FarmMirrorOfLyss()
	If GetMapID() <> $ID_Mirror_of_Lyss Then Return $FAIL

	MoveTo(-19296, -14111)
	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-20867, -13147))
	RandomSleep(1000)
	Dialog(0x85)
	RandomSleep(1000)
	MoveAggroAndKill(-13760, -13924, 'Path 1')
	MoveAggroAndKill(-10600, -12671, 'Path 2')
	MoveAggroAndKill(-4785, -14912, 'Path 3')

	Local Static $foes[15][3] = [ _ ; 14 groups to clear + 1 position change
		[-2451, -15086, 'Group 1/10'], _
		[1174, -13787, 'Plants'], _
		[6728, -12014, 'Plants'], _
		[9554, -14517, 'Kournans + boss'], _
		[16856, -14068, 'Plants'], _
		[19428, -13168, 'Group 2/10'], _
		[16961, -7251, 'Group 3/10'], _
		[20212, -5510, 'Group 4/10'], _
		[20373, -580, 'Group 5/10'], _
		[19778, 2882, 'Group 6/10'], _
		[19561, 6432, 'Group 7/10'], _
		[15914, 10322, 'Group 8/10'], _
		[12116, 7908, 'Moving to position'], _
		[12932, 6907, 'Group 9/10'], _
		[12956, 2637, 'Group 10/10'] _
	]

	If MoveAggroAndKillGroups($foes, 1, UBound($foes)) == $FAIL Then Return $FAIL
	Info('Groups are destroyed, resigning and doing it again')
	Return $SUCCESS
EndFunc