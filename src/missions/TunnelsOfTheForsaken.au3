#CS ===========================================================================
; Author: TDawg
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

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $TUNNELS_OF_THE_FORSAKEN_FARM_INFORMATIONS = 'For best results, do not cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1 E-surge replaced by a ROJ, ineptitude replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '32mn average in NM' & @CRLF _
	& '41mn average in HM with consets (automatically used if HM is on)'

Global Const $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE = $RANGE_SPELLCAST + 100
Global Const $ID_TUNNELS_ELEMENTAL_KEYSTONE = 38301
Global Const $TUNNELS_OF_THE_FORSAKEN_FARM_DURATION = 40 * 60 * 1000
Global Const $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION = 60 * 60 * 1000

Global $tunnels_of_the_forsaken_farm_setup = False

;~ Main method to farm TunnelsOfTheForsaken
Func TunnelsOfTheForsakenFarm()
	If Not $tunnels_of_the_forsaken_farm_setup Then SetupTunnelsOfTheForsakenFarm()

	If RunToTunnels() == $FAIL Then Return $FAIL
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = TunnelsOfTheForsakenFarmLoop()
	AdlibUnregister('TrackPartyStatus')
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	Return $result	
EndFunc


;~ TunnelsOfTheForsaken farm setup
Func SetupTunnelsOfTheForsakenFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	SwitchToHardModeIfEnabled()
	AbandonQuest($ID_QUEST_THE_DREAMER_AND_THE_ZEALOT)
	Info('Preparations complete')
	$tunnels_of_the_forsaken_farm_setup = True
	Return $SUCCESS
EndFunc


Func RunToTunnels()
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	ResetFailuresCounter()
	Info('Making way to portal')
	MoveTo(21030, 9015)
	MoveTo(20255, 8712)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(20248, 7855)
		Move(20180, 7500)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_THE_BREACH)
	WEnd
	Info('Making way to entrance')
	AdlibRegister('TrackPartyStatus', 10000)
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 18004, -1686, 1250)
		WaitUntilPartyAlive()
		UseConsumable($ID_CRACKED_ASCALONIAN_WAR_HORN)
		MoveAggroAndKillInRange(21264., 3562, '1', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(18837, -919, '2', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(19213, -4201, '3', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(18004, -1686, '4', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
	WEnd
	;MoveAggroAndKillInRange(17750, -1500, '5', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
	AdlibUnRegister('TrackPartyStatus')
	
	$mapLoaded = False
	Info('Going through door')
	While Not $mapLoaded
		MoveTo(17771, -1416)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_TUNNELS_OF_THE_FORSAKEN_LVL_1)
	WEnd
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Farm loop
Func TunnelsOfTheForsakenFarmLoop()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	; Failure return delayed after adlib function deregistered
	If (ClearTunnelsOfTheForsakenFloor1() == $FAIL Or ClearTunnelsOfTheForsakenFloor2() == $FAIL Or ClearTunnelsOfTheForsakenFloor3() == $FAIL) Then $tunnels_of_the_forsaken_farm_setup = False
	AdlibUnRegister('TrackPartyStatus')
	If Not $tunnels_of_the_forsaken_farm_setup Then Return $FAIL

	Info('Finished Run')
	Return $SUCCESS
EndFunc


;~ Clear TunnelsOfTheForsaken floor 1
Func ClearTunnelsOfTheForsakenFloor1()
	Info('------------------------------------')
	Info('First floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -8618, 3132, 1250)
		WaitUntilPartyAlive()
		If CheckStuck('TunnelsOfTheForsaken Floor 1 - First loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_CRACKED_ASCALONIAN_WAR_HORN)
		MoveAggroAndKillInRange(-17442, -4638, '1', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12710, -6983, '2', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7836, -9115, '3', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		
		Local $questNPC = GetNearestNPCToCoords(-7400, -9462)
		TakeQuest($questNPC, $ID_QUEST_THE_DREAMER_AND_THE_ZEALOT, 0x85B501)		
		
		MoveAggroAndKillInRange(-9672, -3286, '4', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-11186, -1788, '5', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-10727, -304, '6', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-8618, 3132, '7', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('TunnelsOfTheForsaken Floor 1 - Getting through portal', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(-8684, 4580)
		MoveTo(-8687, 4700)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_TUNNELS_OF_THE_FORSAKEN_LVL_2)
	WEnd
	Return $SUCCESS
EndFunc


;~ Clear TunnelsOfTheForsaken floor 2
Func ClearTunnelsOfTheForsakenFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -16748, 5350, 1250)
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - First loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_CRACKED_ASCALONIAN_WAR_HORN)
		MoveAggroAndKillInRange(-991, 10963, '1', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(2007, 15561, '2', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-764, 17454, '3', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-643, 20296, '4', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8922, 21419, '5', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17622, 19010, '6', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-18139, 17292, '7', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16466, 15466, '8', $RANGE_NEARBY)
		MoveAggroAndKillInRange(-7110, 18292, '9', $RANGE_NEARBY)
		MoveAggroAndKillInRange(-6065, 14829, '10', $RANGE_NEARBY)
		MoveAggroAndKillInRange(-10273, 14406, '11', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11164., 16520, '12', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16715, 9618, '13', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16748, 5350, '14', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL
	
	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - Getting through portal', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(-16780, 4324)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_TUNNELS_OF_THE_FORSAKEN_LVL_3)
	WEnd
	Return $SUCCESS
EndFunc

;~ Clear TunnelsOfTheForsaken floor 3
Func ClearTunnelsOfTheForsakenFloor3()
	Info('------------------------------------')
	Info('Third floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -10264, -4463, 1250)
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - First loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_CRACKED_ASCALONIAN_WAR_HORN)
		MoveAggroAndKillInRange(-11162, 3309, '1', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10127, 2505, '2', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17353, -952, '3', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16644, -3499, '4', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13208, -4395, '5', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12436, -5865, '6', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		PickUpItems()
		MoveAggroAndKillInRange(-13244, -2246, '7', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10537, -1300, '8', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		Info('Triggering beacon')
		MoveAggroAndKillInRange(-10264, -4463, '9', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
	WEnd
	
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -15949, -8561, 1250)
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - Second loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_CRACKED_ASCALONIAN_WAR_HORN)
		MoveAggroAndKillInRange(-9819, -1276, '10', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7260, 1425, '11', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3990, -940, '12', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6418, -4303, '13', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		
		Info('Open dungeon door')
		ClearTarget()

		; Doubled to secure bot
		For $i = 1 To 2
			RandomSleep(500)
			MoveTo(-6442, -4281)
			TargetNearestItem()
			Sleep(1500)
			ActionInteract()
			RandomSleep(500)
			ActionInteract()
		Next
		
		MoveAggroAndKillInRange(-10642, -8052, '14', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13186, -8718, '15', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
		MoveAggroAndKillInRange(-15949, -8561, '16', $TUNNELS_OF_THE_FORSAKEN_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL
	
	; Taking reward 
	Local $questrewardNPC = GetNearestNPCToCoords(-16098, -8626)
	TakeQuestReward($questrewardNPC, $ID_QUEST_THE_DREAMER_AND_THE_ZEALOT, 0x85B507)

	MoveTo(-15776, -8484)
	MoveTo(-16066, -8370)
	; Doubled to try securing the looting
	For $i = 1 To 2
		Info('Opening chest')
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next
EndFunc


;~ Pick up the Elemental Keystone
Func PickUpElementalKeystone()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_ITEM)
	For $agent In $agents
		Local $agentID = DllStructGetData($agent, 'ID')
		Local $item = GetItemByAgentID($agentID)
		If (DllStructGetData($item, 'ModelID') == $ID_TUNNELS_ELEMENTAL_KEYSTONE) Then
			Info('Elemental Keystone: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			Local $attemptPlaces[] = [2300, 14700, 1800, 16500, 4400, 15800, 1900, 13800]
			For $attempt = 0 To 4
				PickUpItem($item)
				Local $waitCycles = 0
				While $waitCycles < 10
					RandomSleep(1000)
					$waitCycles += 1
					If Not IsPlayerOrPartyAlive() Then Return False
					If Not GetAgentExists($agentID) Then Return True
				WEnd
				Error('Attempt ' & $attempt & ' - could not get Elemental Keystone at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
				If $attempt < 4 Then MoveTo($attemptPlaces[2 * $attempt], $attemptPlaces[2 * $attempt + 1])
			Next
			Error('All attempts failed, skipping Elemental Keystone quest')
			Return False
		EndIf
	Next
	Error('Could not find Elemental Keystone on the ground')
	Return False
EndFunc
