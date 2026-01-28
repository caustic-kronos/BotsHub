#CS ===========================================================================
; Author: Ian
; Contributor: ----
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

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'
#include '../../lib/Utils-Agents.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $KILROY_FARM_INFORMATIONS = 'This bot loops the Kilroy Stonekins' & @CRLF _
	& 'Punch Out Extravanganza Quest' & @CRLF _
	& 'Check the Maintain Survivor under Options to keep Survivor going.' & @CRLF _
	& 'Ensure your Brass Knuckcles are in Weapon Slot 1 and you have 9 in Dagger Mastery' & @CRLF _
	& 'Complete all of Kilroys other quests first to get the best Daggers.'
Global Const $KILROY_FARM_DURATION = 10000 ;sample time for now
Global Const $KILROY_ACCEPT_REWARD = 000
Global Const $KILROY_START_QUEST = 0x835803 
Global Const $KILRAY_ACCEPT_QUEST = 0x835801

; Variables used for Survivor async checking (Low Health Monitor)
Global Const $LOW_HEALTH_THRESHOLD_KILROY = 0
Global Const $LOW_HEALTH_CHECK_INTERVAL_KILROY = 100

Global $kilroy_farm_setup = False

Func KilroyFarm()
	If Not $kilroy_farm_setup And SetupKilroyFarm() == $FAIL Then
		Info('Kilroy farm setup failed, stopping farm.')
		Return $PAUSE
	EndIf
	MoveToPunchOut()
	Local $result =FarmPunchOut()
	DistrictTravel($ID_GUNNARS_HOLD, $district_name)
	Return $result
EndFunc

Func SetupKilroyFarm()
	Info('Setting Up Farm')
	Info('Traveling to Gunnars')
	DistrictTravel($ID_GUNNARS_HOLD, $district_name)
	SwitchToHardModeIfEnabled()
	
	If IsQuestReward($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Quest Reward Found! Gathering Quest Reward')
		MoveTo(17281.19, -4850.08)
		Local $questNPC = GetNearestNPCToCoords((17281.19, -4850.08))
		RandomSleep(750)
		TakeQuestReward($questNPC, $ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA, $KILROY_ACCEPT_REWARD)
		RandomSleep(750)
		Info('Zoning to Olafsted to Refresh Quest')
		DistrictTravel($ID_OLAFSTEAD, $district_name)
		Sleep(750)
		Info('Zoning back to Gunnars')
		DistrictTravel($ID_GUNNARS_HOLD, $district_name)
		RandomSleep(1000)
	EndIf
	
	If IsQuestNotFound($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		Info('Setting up Kilroy Quest')
		RandomSleep(750)
		MoveTo(17281.19, -4850.08)
		Local $questNPC = GetNearestNPCToCoords(17281.19, -4850.08)
		TakeQuest($questNPC, $ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA, $KILRAY_ACCEPT_QUEST, $KILROY_START_QUEST)
	EndIf
	
	If IsQuestActive($ID_QUEST_KILROYS_PUNCH_OUT_EXTRAVAGANZA) Then
		$kilroy_farm_setup = True
		Info('Quest in the logbook. Good to go!')
		Return $SUCCESS
	Else
		Return $FAIL
	EndIf
EndFunc

Func MoveToPunchOut()
	Info('Moving to Punchout')
	GoToNPC(GetNearestNPCToCoords(17281.19, -4850.08))
	RandomSleep(250)
	Dialog(0x85)
	WaitMapLoading($ID_FRONIS_IRONTOES_LAIR, 10000, 2000)
	If GetMapID() <> $ID_FRONIS_IRONTOES_LAIR Then Return $FAIL
EndFunc

Func FarmPunchOut()
EndFunc

;TODO - Health Monitor for Standup
;Func LowHealthMonitor()
;	If IsLowHealth() Then
;		
;		Return $SUCCESS
;	EndIf
;EndFunc
;
;
;Func IsLowHealth()
;	Local $me = GetMyAgent()
;	Local $healthRatio = DllStructGetData($me, 'HealthPercent')
;	If $healthRatio = 0 Then Return True
;	Return False
;EndFunc