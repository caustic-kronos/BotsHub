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
Global Const $SunspearArmorFarmInformations = 'Sunspear armor farm with 7heroes GWReborn s comp'
; Average duration ~ 15m
Global Const $SUNSPEAR_ARMOR_FARM_DURATION = 15 * 60 * 1000
Global $SUNSPEAR_ARMOR_FARM_SETUP = False

;~ Main loop for the Sunspear Armor farm
Func SunspearArmorFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $SUNSPEAR_ARMOR_FARM_SETUP Then SunspearArmorSetup()

	EnterSunspearArmorChallenge()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = SunspearArmorClean()
	AdlibUnRegister('TrackPartyStatus')

	Info('Returning back to the outpost') ; in this case outpost has the same map ID as farm location
	ResignAndReturnToOutpost()
	Return $result
EndFunc


Func SunspearArmorSetup()
	Info('Setting up farm')
	If GetMapID() <> $ID_Dajkah_Inlet Then
		TravelToOutpost($ID_Dajkah_Inlet, $DISTRICT_NAME)
	Else ; resigning to return to outpost in case when player is in Dajkah Inlet Challenge that has the same map ID as Dajkah Inlet outpost (554)
		ResignAndReturnToOutpost()
	EndIf
	SwitchToHardModeIfEnabled()
	SetupPlayerSunspearArmorFarm()
	SetupTeamSunspearArmorFarm()
	$SUNSPEAR_ARMOR_FARM_SETUP = True
	Info('Setup completed')
EndFunc


Func SetupPlayerSunspearArmorFarm()
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


Func SetupTeamSunspearArmorFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up team according to GUI settings')
		SetupTeamUsingGUISettings()
    Else
		Info('Automatic team builds setup is disabled. Assuming that team builds are set up manually')
    EndIf
	Sleep(500 + GetPing())
	If GetPartySize() <> 8 Then
		Warn('Could not set up party correctly. Team size different than 8')
	EndIf
EndFunc


Func EnterSunspearArmorChallenge()
	TravelToOutpost($ID_Dajkah_Inlet, $DISTRICT_NAME)
	Info('Entering Dajkah Inlet challenge')
	; Unfortunately Dajkah Inlet Challenge map has the same map ID as Dajkah Inlet outpost, so it is hard to tell if player left the outpost
	; Therefore below loop checks if player is in close range of coordinates of that start zone where player initially spawns in Dajkah Inlet Challenge map
	Local Static $StartX = 29886
	Local Static $StartY = -3956
	While Not IsAgentInRange(GetMyAgent(), $StartX, $StartY, $RANGE_EARSHOT)
		GoToNPC(GetNearestNPCToCoords(-2884, -2572))
		RandomSleep(250)
		Dialog(0x87)
		Sleep(8000) ; wait 8 seconds to ensure that player exited outpost and entered challenge
	WEnd
EndFunc


;~ Cleaning Sunspear Armors function
Func SunspearArmorClean()
	If GetMapID() <> $ID_Dajkah_Inlet Then Return $FAIL
	MoveTo(25752.28, -3139.02)
	RandomSleep(62000)

	Local Static $foes[33][3] = [ _ ; 23 groups to vanquish + 10 movements
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

	If MoveAggroAndKillGroups($foes, 1, 7) == $FAIL Then Return $FAIL
	Info('Bridge 1')
	If MoveAggroAndKillGroups($foes, 8, 8) == $FAIL Then Return $FAIL
	Info('Bridge 2')
	If MoveAggroAndKillGroups($foes, 9, 25) == $FAIL Then Return $FAIL
	Info('2nd portal')
	If MoveAggroAndKillGroups($foes, 26, 33) == $FAIL Then Return $FAIL

	RandomSleep(500)
	Return $SUCCESS
EndFunc