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
Global Const $VanguardTitleFarmInformations = 'Vanguard title farm'
; Average duration ~ 45m
Global Const $VANGUARD_TITLE_FARM_DURATION = 45 * 60 * 1000


;~ Main loop for the vanguard faction farm
Func VanguardTitleFarm($STATUS)
	VanguardFarmSetup()
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


Func VanguardFarmSetup()
	Info('Setting up farm')
	TravelToOutpost($ID_Doomlore_Shrine, $DISTRICT_NAME)
	SetDisplayedTitle($ID_Ebon_Vanguard_Title)
	SwitchMode($ID_HARD_MODE)
	; Assuming that team has been set up correctly manually
	;SetupTeamVanguardFarm()
	Info('Preparations complete')
EndFunc


Func SetupTeamVanguardFarm()
	Info('Setting up team')
	Sleep(500)
	LeaveParty()
	RandomSleep(500)
	AddHero($ID_Norgu)
	RandomSleep(500)
	AddHero($ID_Gwen)
	RandomSleep(500)
	AddHero($ID_Razah)
	RandomSleep(500)
	AddHero($ID_Master_Of_Whispers)
	RandomSleep(500)
	AddHero($ID_Livia)
	RandomSleep(500)
	AddHero($ID_Olias)
	RandomSleep(500)
	AddHero($ID_Xandra)
	Sleep(1000)
	If GetPartySize() <> 8 Then
    	Warn("Could not set up party correctly. Team size different than 8")
	EndIf
EndFunc


;~ Move out of outpost into Dalada Uplands
Func GoToDaladaUplands()
	If GetMapID() <> $ID_Doomlore_Shrine Then TravelToOutpost($ID_Doomlore_Shrine, $DISTRICT_NAME)
	Info('Moving to Dalada Uplands')
	While GetMapID() <> $ID_Dalada_Uplands
		MoveTo(-15231, 13608)
		RandomSleep(1000)
		WaitMapLoading($ID_Dalada_Uplands, 10000, 2000)
	WEnd
EndFunc


;~ Cleaning Dalada Uplands function
Func VanquishDaladaUplands()
	If GetMapID() <> $ID_Dalada_Uplands Then Return $FAIL

	GoToNPC(GetNearestNPCToCoords(-14939, 11018))
	Sleep(1000)
	Dialog(0x84)
	Sleep(1000)
	If MoveAggroAndKill(-12373, 12899, 'Move To Start') == $FAIL Or _
		MoveAggroAndKill(-9464, 15937, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(-9130, 13535, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-5532, 11281, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-3979, 9184, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(-355, 9296, 'Again mantid Group') == $FAIL Or _
		MoveAggroAndKill(836, 12171, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(884, 15641, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(2956, 10496, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(5160, 11032, 'Moving') == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(5816, 11687))
	Sleep(1000)

	If MoveAggroAndKill(5848, 11086, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(7639, 11839, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(6494, 15729, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(5704, 17469, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(8572, 12365, 'Moving Back') == $FAIL Or _
		MoveAggroAndKill(13960, 13432, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(15385, 9899, 'Going Charr') == $FAIL Or _
		MoveAggroAndKill(17089, 6922, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(16363, 3809, 'Moving Gain') == $FAIL Or _
		MoveAggroAndKill(15635, 710, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(12754, 2740, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(10068, 2580, 'Skale') == $FAIL Or _
		MoveAggroAndKill(7663, 3236, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(6152, 1706, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(5086, -2187, 'Charr on the way') == $FAIL Or _
		MoveAggroAndKill(3449, -3693, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(7170, -4037, 'Moving') == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(8565, -3974))
	Sleep(1000)

	If MoveAggroAndKill(8903, -1801, 'Second Skale') == $FAIL Or _
		MoveAggroAndKill(6790, -6124, 'Moving') == $FAIL Or _
		MoveAggroAndKill(3696, -9324, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(8031, -10361, 'Charr on the way') == $FAIL Or _
		MoveAggroAndKill(9282, -12837, 'Moving') == $FAIL Or _
		MoveAggroAndKill(8817, -16314, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(13337, -14025, 'Charr Patrol 2') == $FAIL Or _
		MoveAggroAndKill(13675, -5513, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(14760, -2224, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(13378, -2577, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(17500, -11685, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(15290, -13688, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(15932, -14104, 'Moving Back') == $FAIL Or _
		MoveAggroAndKill(14934, -17261, 'Moving') == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(14891, -18146))
	Sleep(1000)

	If MoveAggroAndKill(11509, -17586, 'Moving') == $FAIL Or _
		MoveAggroAndKill(6031, -17582, 'Moving') == $FAIL Or _
		MoveAggroAndKill(2846, -17340, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(-586, -16529, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(-4099, -14897, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-4217, -12620, 'Moving') == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-4014, -11504))
	Sleep(1000)

	If MoveAggroAndKill(-8023, -13970, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(-7326, -8852, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(-8023, -13970, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(-9808, -15103, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-10902, -16356, 'Skale Place') == $FAIL Or _
		MoveAggroAndKill(-11917, -18111, 'Skale Place') == $FAIL Or _
		MoveAggroAndKill(-13425, -16930, 'Skale Boss') == $FAIL Or _
		MoveAggroAndKill(-15218, -17460, 'Skale Group') == $FAIL Or _
		MoveAggroAndKill(-16084, -14159, 'Skale Group') == $FAIL Or _
		MoveAggroAndKill(-17395, -12851, 'Skale Place') == $FAIL Or _
		MoveAggroAndKill(-18157, -9785, 'Skale On the Way') == $FAIL Or _
		MoveAggroAndKill(-18222, -6263, 'Finish Skale') == $FAIL Or _
		MoveAggroAndKill(-17239, -1933, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-17509, 202, 'Moving') == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-17546, 341))
	Sleep(1000)

	If MoveAggroAndKill(-13853, -2427, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(-9313, -3786, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(-13228, 2083, 'Charr Seeker') == $FAIL Or _
		MoveAggroAndKill(-13622, 5476, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-17705, 3079, 'Mantid on the way') == $FAIL Or _
		MoveAggroAndKill(-16565, 2528, 'More Charr') == $FAIL Or _
		MoveAggroAndKill(-12909, 6403, 'Mantid on the way') == $FAIL Or _
		MoveAggroAndKill(-10699, 5105, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(-9016, 6958, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(-8889, 9446, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(-6869, 4604, 'Mantid Monk Boss') == $FAIL Or _
		MoveAggroAndKill(-8190, 6872, 'Mantid') == $FAIL Or _
		MoveAggroAndKill(-6181, 1837, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(-4125, 2789, 'Mantid Group') == $FAIL Or _
		MoveAggroAndKill(-2875, 985, 'Moving') == $FAIL Or _
		MoveAggroAndKill(-769, 2047, 'Charr Group') == $FAIL Or _
		MoveAggroAndKill(1114, 1765, 'Mantid and Charr') == $FAIL Or _
		MoveAggroAndKill(6550, 7549, 'Looking for Mantids') == $FAIL Or _
		MoveAggroAndKill(8246, 8104, 'Looking for Mantids') == $FAIL Or _
		MoveAggroAndKill(1960, 4969, 'Looking for Mantids') == $FAIL Or _
		MoveAggroAndKill(621, 8056, 'Looking for Mantids') == $FAIL Or _
		MoveAggroAndKill(-4039, 8928, 'Looking for Mantids') == $FAIL Or _
		MoveAggroAndKill(-3299, 606, 'Looking for Mantids') == $FAIL Then Return $FAIL

	Info('Taking Blessing')
	GoToNPC(GetNearestNPCToCoords(-2659, 464))
	Sleep(1000)

	If MoveAggroAndKill(5219, -5017, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(7289, -9484, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(5219, -7017, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(1342, -9068, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(1606, 22, 'Charr Patrol') == $FAIL Or _
		MoveAggroAndKill(-276, -2566, 'Going to Molotov') == $FAIL Or _
		MoveAggroAndKill(-3337, -4323, 'Molotov') == $FAIL Or _
		MoveAggroAndKill(-4700, -4943, 'Molotov') == $FAIL Or _
		MoveAggroAndKill(-5561, -5483, 'Molotov') == $FAIL Then Return $FAIL

	Return $SUCCESS
EndFunc