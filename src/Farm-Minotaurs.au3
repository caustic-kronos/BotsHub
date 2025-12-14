#CS ===========================================================================
; Author: JackLinesMatthews
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
Global Const $MinotaursFarmInformations = 'For best results, have :' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& '- Solid heroes team composition, which can be loaded from GUI' & @CRLF _
	& '' & @CRLF _
	& 'This bot farms minotaur horns which can be salvaged for materials, or given to Nicholas the Traveler' & @CRLF
; Average duration ~ 8m
Global Const $MINOTAURS_FARM_DURATION = 8 * 60 * 1000
Global $MINOTAURS_FARM_SETUP = False


;~ Main loop for the minotaurs farm
Func MinotaursFarm($STATUS)
	If Not $MINOTAURS_FARM_SETUP Then SetupMinotaursFarm()

	GoToProphetsPath()
	;ResetFailuresCounter()
	;AdlibRegister('TrackPartyStatus', 10000)
	Local $result = FarmMinotaurs()
	;AdlibUnRegister('TrackPartyStatus')
	Return $result
EndFunc


;~ Setup for the farm
Func SetupMinotaursFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Augury_Rock, $DISTRICT_NAME)
	SwitchToHardModeIfEnabled()
	If SetupPlayerMinotaursFarm() == $FAIL Then Return $FAIL
	If SetupTeamMinotaursFarm() == $FAIL Then Return $FAIL
	$MINOTAURS_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerMinotaursFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
	Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
	EndIf
	Sleep(250 + GetPing())
	If GUICtrlRead($GUI_Checkbox_WeaponSlot) == $GUI_CHECKED Then
		Info('Setting player weapon slot to ' & $WEAPON_SLOT & ' according to GUI settings')
		ChangeWeaponSet($WEAPON_SLOT)
	Else
		Info('Automatic player weapon slot setting is disabled. Assuming that player sets weapon slot manually')
	EndIf
	Sleep(250 + GetPing())
EndFunc


Func SetupTeamMinotaursFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
	Else
		Info('Automatic team builds setup is disabled. Assuming that team builds are set up manually')
	EndIf
	Sleep(500 + GetPing())
EndFunc


;~ Move out of outpost into Prophet's 'Path
Func GoToProphetsPath()
	TravelToOutpost($ID_Augury_Rock, $DISTRICT_NAME)
	While GetMapID() <> $ID_Prophets_Path
		Info('Moving to Prophet''s Path')
		MoveTo(-17071, -1065)
		MoveTo(-18069, -1026)
		MoveTo(-18853, -444)
		MoveTo(-20100, -400)
		RandomSleep(1000)
		WaitMapLoading($ID_Prophets_Path, 10000, 2000)
	WEnd
EndFunc


;~ Vanquish the minotaurs
Func FarmMinotaurs()
	If GetMapID() <> $ID_Prophets_Path Then Return $FAIL

	Local Static $minotaurs[12][3] = [ _ ; 12 groups to vanquish
		[18870, -6, 'Minotaurs group 1'], _
		[18828, 2201, 'Minotaurs group 2'], _
		[17106, 1459, 'Minotaurs group 3'], _
		[14424, 134, 'Minotaurs group 4'], _
		[10852, 1967, 'Minotaurs group 5'], _
		[10704, 6422, 'Minotaurs group 6'], _
		[9081, 7155, 'Minotaurs group 7'], _
		[8755, 10512, 'Minotaurs group 8'], _
		[12348, 10156, 'Minotaurs group 9'], _
		[7001, 8789, 'Minotaurs group 10'], _
		[5155, 8838, 'Minotaurs group 11'], _
		[2616, 7615, 'Minotaurs group 12'] _
	]

	If MoveAggroAndKillGroups($minotaurs, 1, 12) == $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc