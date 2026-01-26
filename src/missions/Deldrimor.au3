#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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
Global Const $DELDRIMOR_FARM_INFORMATIONS = 'For best results, do not cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& 'Recommend two healer heroes. Tested with BIP + SOS Healer.' & @CRLF _
	& '10-15mn average in NM' & @CRLF _
	& '15-20mn average in HM with cons (automatically used if HM is on)' & @CRLF _
	& 'You must have already completed the 4 map pieces and at least one' & @CRLF _
	& 'Manual run of the Dungeon Prior to running this script'
	
Global Const $SNOWMAN_QUEST_ID = 0x382
Global Const $SNOWMAN_QUEST_ACCEPT_ID = 0x838201
Global Const $SNOWMAN_READY_ID = 0x84

Global $snowman_farm_setup = False

Func DeldrimorFarm()
	If Not $snowman_farm_setup And SetupDeldrimorTitleFarm() == $FAIL Then
		Info('Snowman farm setup failed, stopping farm.')
		Return $PAUSE
	EndIf
	MoveToLairSnowman()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result =FarmLairSnowman()
	AdlibUnRegister('TrackPartyStatus')
	;DistrictTravel($ID_UMBRAL_GROTTO, $district_name)
	Return $result
EndFunc

Func SetupDeldrimorTitleFarm()
	DistrictTravel($ID_UMBRAL_GROTTO, $district_name)
	;SwitchMode($ID_HARD_MODE)
	If IsQuestNotFound($SNOWMAN_QUEST_ID) Or IsQuestReward($SNOWMAN_QUEST_ID) Then
		Info('Setting up Snowman Lair')
		RandomSleep(750)
		AbandonQuest($SNOWMAN_QUEST_ID)
		RandomSleep(750)
		MoveTo(-23886.06, 13881.35)
		Local $questNPC = GetNearestNPCToCoords(-23886.06, 13881.35)
		TakeQuest($questNPC, $SNOWMAN_QUEST_ID, $SNOWMAN_QUEST_ACCEPT_ID)
	EndIf
	
	If IsQuestActive($SNOWMAN_QUEST_ID) Then
		$snowman_farm_setup = True
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc

Func MoveToLairSnowman()
	Info('Moving to Lair')
	GoToNPC(GetNearestNPCToCoords(-23886.06, 13881.35))
	RandomSleep(250)
	Dialog(0x84)
	
	WaitMapLoading($ID_SNOWMEN_LAIR, 10000, 2000)
EndFunc

Func FarmLairSnowman()
	If GetMapID() <> $ID_SNOWMEN_LAIR Then Return $FAIL
	Info('Getting Blessing')
	GoToNPC(GetNearestNPCToCoords(-14131.44, 15437.75))
	RandomSleep(250)
	Dialog(0x84)
	
	FlagMoveAggroAndKillInRange(-14610.22, 12352.80, 'First Snowmen Block')
	FlagMoveAggroAndKillInRange(-16585.22, 8741.05, 'Second Snowmen Block')
	Info('Time to avoid Snowballs')
	MoveTo(-17949.62, 6797.99)
	RandomSleep(10000)
	
	MoveAggroAndKillInRange(-19169.78, 5355.52, 'Lonely Snowmen 1')
	MoveAggroAndKillInRange(-17196.19, 1934.53, 'Lots of Snowmen')
	
	MoveAggroAndKillInRange(-15396.72, 2887.34, 'Bridge of Snowmen')
	MoveAggroAndKillInRange(-14392.77, 3759.07, 'Over The Bridge of Snowmen')
	
	Info('Get New Blessing')
	GoToNPC(GetNearestNPCToCoords(-12482.00, 3924.00))
	Info('Moving to Snowman Channel')
	MoveTo(-14413.26, 2483.14)
	
	MoveAggroAndKillInRange(-13464.57, -687.09, 'Channel of Snowmen')
	
	Info('Wait to Heal after Ice Spouts')
	RandomSleep(5000)
	
	MoveAggroAndKillInRange(-12989.46, -731.47, 'Lonely Snowman 2')
	MoveAggroAndKillInRange(-12802.18, -4446.38, 'Remainder of Snowmen')
	
	Info('Wait to Heal after Ice Spouts')
	RandomSleep(5000)
	Info('Beware of Avalanches')
	
	FlagMoveAggroAndKillInRange(-13176.58, -6779.26, 'Third Snowmen Block')
	FlagMoveAggroAndKillInRange(-13676.65, -9799.06, 'Fourth Snowmen Block')
	
	Info('Time To Get a Key')
	
	MoveAggroAndKillInRange(-9646.23, -10924.95, 'Key of Snowmen')
	PickUpItems()
	
	Info('Time to open the door')
	MoveAggroAndKillInRange(-15641.55, -11961.42, 'Door of Snowmen')
	Info('Open dungeon door')
	ClearTarget()
	; Doubled to secure bot
	For $i = 1 To 2
		MoveTo(-15483.29, -12236.64)
		TargetNearestItem()
		RandomSleep(500)
		ActionInteract()
		ActionInteract()
		RandomSleep(500)
	Next
	
	MoveAggroAndKillInRange(-17345.07, -13797.14, 'Circle of Snowmen')
	
	Info('Time for Freezie')
	
	FlagMoveAggroAndKillInRange(-14303.93, -17111.98, 'Fourth Snowmen Block')
	
	Info('Pickup Key')
	PickUpItems()
	
	; Doubled to secure bot
	For $i = 1 To 2
		MoveTo(-11274.85, -17984.23)
		TargetNearestItem()
		RandomSleep(500)
		ActionInteract()
		ActionInteract()
		RandomSleep(500)
	Next
	
	Info('Having a cry about beer')
	MoveTo(-7767.71, -18739.19)
	
	; Doubled to try securing the looting
	For $i = 1 To 2
		MoveTo(-15800, 16950)
		Info('Opening Wintersday chest')
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next
	
	Return $SUCCESS

EndFunc