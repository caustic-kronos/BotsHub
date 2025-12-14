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
Global Const $VanguardTitleFarmInformations = 'Vanguard title farm'
; Average duration ~ 45m
Global Const $VANGUARD_TITLE_FARM_DURATION = 45 * 60 * 1000
Global $VANGUARD_FARM_SETUP = False


;~ Main loop for the vanguard faction farm
Func VanguardTitleFarm($STATUS)
	If Not $VANGUARD_FARM_SETUP Then VanguardTitleFarmSetup()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToDaladaUplands()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VanquishDaladaUplands()
	AdlibUnRegister('TrackPartyStatus')
	; Temporarily change a failure into a pause for debugging :
	;If $result == $FAIL Then $result = $PAUSE
	TravelToOutpost($ID_Doomlore_Shrine, $DISTRICT_NAME)
	Return $result
EndFunc


Func VanguardTitleFarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Doomlore_Shrine, $DISTRICT_NAME)
	SetDisplayedTitle($ID_Ebon_Vanguard_Title)
	SwitchMode($ID_HARD_MODE)
	SetupPlayerVanguardTitleFarm()
	SetupTeamVanguardTitleFarm()
	$VANGUARD_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


Func SetupPlayerVanguardTitleFarm()
	If GUICtrlRead($GUI_Checkbox_AutomaticTeamSetup) == $GUI_CHECKED Then
		Info('Setting up player build skill bar according to GUI settings')
		Sleep(500 + GetPing())
		LoadSkillTemplate(GUICtrlRead($GUI_Input_Build_Player))
    Else
		Info('Automatic player build setup is disabled. Assuming that player build is set up manually')
    EndIf
	;ChangeWeaponSet(1) ; change to other weapon slot or comment this line if necessary
	Sleep(500 + GetPing())
EndFunc


Func SetupTeamVanguardTitleFarm()
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


;~ Move out of outpost into Dalada Uplands
Func GoToDaladaUplands()
	TravelToOutpost($ID_Doomlore_Shrine, $DISTRICT_NAME)
	While GetMapID() <> $ID_Dalada_Uplands
		MoveTo(-15231, 13608)
		RandomSleep(1000)
		WaitMapLoading($ID_Dalada_Uplands, 10000, 2000)
	WEnd
EndFunc


;~ Cleaning Dalada Uplands function
Func VanquishDaladaUplands()
	If GetMapID() <> $ID_Dalada_Uplands Then Return $FAIL

	Local Static $foes[93][3] = [ _ ; 72 groups to vanquish + 21 movements
		[-12373, 12899, 'Move To Start'], _
		[-9464, 15937, 'Charr Group'], _
		[-9130, 13535, 'Moving'], _
		[-5532, 11281, 'Moving'], _
		[-3979, 9184, 'Mantid Group'], _
		[-355, 9296, 'Again mantid Group'], _
		[836, 12171, 'Charr Patrol'], _
		[884, 15641, 'Charr Group'], _
		[2956, 10496, 'Mantid Group'], _
		[5160, 11032, 'Moving'], _
		[5848, 11086, 'Mantid Group'], _
		[7639, 11839, 'Charr Patrol'], _
		[6494, 15729, 'Charr Patrol'], _
		[5704, 17469, 'Charr Group'], _
		[8572, 12365, 'Moving Back'], _
		[13960, 13432, 'Charr Group'], _
		[15385, 9899, 'Going Charr'], _
		[17089, 6922, 'Charr Group'], _
		[16363, 3809, 'Moving Gain'], _
		[15635, 710, 'Charr Group'], _
		[12754, 2740, 'Charr Seeker'], _
		[10068, 2580, 'Skale'], _
		[7663, 3236, 'Charr Seeker'], _
		[6152, 1706, 'Charr Seeker'], _
		[5086, -2187, 'Charr on the way'], _
		[3449, -3693, 'Charr Patrol'], _
		[7170, -4037, 'Moving'], _
		[8903, -1801, 'Second Skale'], _
		[6790, -6124, 'Moving'], _
		[3696, -9324, 'Charr Patrol'], _
		[8031, -10361, 'Charr on the way'], _
		[9282, -12837, 'Moving'], _
		[8817, -16314, 'Charr Patrol'], _
		[13337, -14025, 'Charr Patrol 2'], _
		[13675, -5513, 'Charr Group'], _
		[14760, -2224, 'Charr Group'], _
		[13378, -2577, 'Charr Group'], _
		[17500, -11685, 'Charr Group'], _
		[15290, -13688, 'Charr Seeker'], _
		[15932, -14104, 'Moving Back'], _
		[14934, -17261, 'Moving'], _
		[11509, -17586, 'Moving'], _
		[6031, -17582, 'Moving'], _
		[2846, -17340, 'Charr Group'], _
		[-586, -16529, 'Charr Seeker'], _
		[-4099, -14897, 'Moving'], _
		[-4217, -12620, 'Moving'], _
		[-8023, -13970, 'Charr Seeker'], _
		[-7326, -8852, 'Charr Seeker'], _
		[-8023, -13970, 'Charr Patrol'], _
		[-9808, -15103, 'Moving'], _
		[-10902, -16356, 'Skale Place'], _
		[-11917, -18111, 'Skale Place'], _
		[-13425, -16930, 'Skale Boss'], _
		[-15218, -17460, 'Skale Group'], _
		[-16084, -14159, 'Skale Group'], _
		[-17395, -12851, 'Skale Place'], _
		[-18157, -9785, 'Skale On the Way'], _
		[-18222, -6263, 'Finish Skale'], _
		[-17239, -1933, 'Moving'], _
		[-17509, 202, 'Moving'], _
		[-13853, -2427, 'Charr Seeker'], _
		[-9313, -3786, 'Charr Seeker'], _
		[-13228, 2083, 'Charr Seeker'], _
		[-13622, 5476, 'Moving'], _
		[-17705, 3079, 'Mantid on the way'], _
		[-16565, 2528, 'More Charr'], _
		[-12909, 6403, 'Mantid on the way'], _
		[-10699, 5105, 'Mantid Group'], _
		[-9016, 6958, 'Mantid Group'], _
		[-8889, 9446, 'Mantid Group'], _
		[-6869, 4604, 'Mantid Monk Boss'], _
		[-8190, 6872, 'Mantid'], _
		[-6181, 1837, 'Mantid Group'], _
		[-4125, 2789, 'Mantid Group'], _
		[-2875, 985, 'Moving'], _
		[-769, 2047, 'Charr Group'], _
		[1114, 1765, 'Mantid and Charr'], _
		[6550, 7549, 'Looking for Mantids'], _
		[8246, 8104, 'Looking for Mantids'], _
		[1960, 4969, 'Looking for Mantids'], _
		[621, 8056, 'Looking for Mantids'], _
		[-4039, 8928, 'Looking for Mantids'], _
		[-3299, 606, 'Looking for Mantids'], _
		[5219, -5017, 'Charr Patrol'], _
		[7289, -9484, 'Charr Patrol'], _
		[5219, -7017, 'Charr Patrol'], _
		[1342, -9068, 'Charr Patrol'], _
		[1606, 22, 'Charr Patrol'], _
		[-276, -2566, 'Going to Molotov'], _
		[-3337, -4323, 'Molotov'], _
		[-4700, -4943, 'Molotov'], _
		[-5561, -5483, 'Molotov'] _
	]

	GoToNPC(GetNearestNPCToCoords(-14939, 11018))
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 1, 10) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(5816, 11687))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 11, 27) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(8565, -3974))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 28, 41) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(14891, -18146))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 42, 47) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-4014, -11504))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 48, 61) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-17546, 341))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 62, 84) == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-2659, 464))
	Sleep(1000)

	If MoveAggroAndKillGroups($foes, 85, 93) == $FAIL Then Return $FAIL

	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	Else
		Info('Map has been fully vanquished.')
		Return $SUCCESS
	EndIf
EndFunc