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
	MoveToLair()
EndFunc

Func SetupDeldrimorTitleFarm()
	DistrictTravel($ID_UMBRAL_GROTTO, $district_name)
	SwitchMode($ID_HARD_MODE)
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
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc

Func MoveToLair()
	GoToNPC(GetNearestNPCToCoords(-23886.06, 13881.35))
	RandomSleep(250)
	Dialog(0x84)
EndFunc