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

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

; Possible improvements :

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $EdenIrisFarmInformations = 'Only thing needed for this farm is a character in Eden and Ashford Abbey unlocked.'
; Average duration ~ 35s
Global Const $IRIS_FARM_DURATION = 35 * 1000

Global $IRIS_FARM_SETUP = False

;~ Main method to farm Red Iris Flowers in Eden
Func EdenIrisFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $IRIS_FARM_SETUP Then SetupEdenIrisFarm()

	GoToLakesideCounty()
	Local $result = EdenIrisFarmLoop()
	ReturnBackToOutpost($ID_Ashford_Abbey)
	Return $result
EndFunc


;~ Iris farm short setup
Func SetupEdenIrisFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Ashford_Abbey, $DISTRICT_NAME)
	GoToLakesideCounty()
	MoveTo(-11000, -6250)
	Move(-11600, -6250)
	RandomSleep(1000)
	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
	$IRIS_FARM_SETUP = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Lakeside County
Func GoToLakesideCounty()
	TravelToOutpost($ID_Ashford_Abbey, $DISTRICT_NAME)
	While GetMapID() <> $ID_Lakeside_County
		Info('Moving to Lakeside County')
		MoveTo(-11600, -6250)
		Move(-11000, -6250)
		RandomSleep(1000)
		WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func EdenIrisFarmLoop()
	If GetMapID() <> $ID_Lakeside_County Then Return $FAIL
	If PickUpIris() Then Return $SUCCESS
	Moveto(-11000, -7850)
	If PickUpIris() Then Return $SUCCESS
	Moveto(-11200, -10500)
	If PickUpIris() Then Return $SUCCESS
	Moveto(-10500, -13000)
	If PickUpIris() Then Return $SUCCESS
	Return $FAIL
EndFunc


;~ Loot only iris, return True if collected, False otherwise
Func PickUpIris()
	Local $agent
	Local $item
	Local $deadlock
	Local $agents = GetAgentArray($ID_Agent_Type_Item)
	For $agent In $agents
		Local $agentID = DllStructGetData($agent, 'ID')
		$item = GetItemByAgentID($agentID)
		If (DllStructGetData($item, 'ModelID') == $ID_Red_Iris_Flower) Then
			Info('Iris: (' & Round(DllStructGetData($agent, 'X')) & ',' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			$deadlock = TimerInit()
			While GetAgentExists($agentID)
				RandomSleep(500)
				If IsPlayerDead() Then Return False
				If TimerDiff($deadlock) > 20000 Then
					Info('Could not get iris at (' & DllStructGetData($agent, 'X') & ',' & DllStructGetData($agent, 'Y') & ')')
					Return False
				EndIf
			WEnd
			Return True
		EndIf
	Next
	Return False
EndFunc