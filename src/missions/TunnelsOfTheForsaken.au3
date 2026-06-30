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

Global Const $ID_TUNNELS_ELEMENTAL_KEYSTONE = 38301
Global Const $TUNNELS_OF_THE_FORSAKEN_FARM_DURATION = 35 * 60 * 1000
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
	Info('Preparations complete')
	$tunnels_of_the_forsaken_farm_setup = True
	Return $SUCCESS
EndFunc


Func RunToTunnels()
	TravelToOutpost($ID_PIKEN_SQUARE, $district_name)
	AbandonQuest($ID_QUEST_THE_DREAMER_AND_THE_ZEALOT)
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
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 17982, 641, $RANGE_LONGBOW)
		WaitUntilPartyAlive()
		UseSummoningStone()
		MoveAggroAndKillInRange(21264, 3562, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(17982, 641, '2', $PLAYER_AGGRO_RANGE)
	WEnd
	AdlibUnRegister('TrackPartyStatus')

	$mapLoaded = False
	Info('Going through door')
	While Not $mapLoaded
		MoveTo(17300, -400)
		Move(17400, -800)
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

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -8684, 4580, $RANGE_AREA)
		WaitUntilPartyAlive()
		If CheckStuck('TunnelsOfTheForsaken Floor 1 - First loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		;~ Move next line to avoid aggro of the Storm Riders
		MoveTo(-15247, -5785)
		MoveAggroAndKillInRange(-13102, -6841, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11660, -7585, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7836, -9115, '3', $PLAYER_AGGRO_RANGE)

		Local $questNPC = GetNearestNPCToCoords(-7400, -9462)
		TakeQuest($questNPC, $ID_QUEST_THE_DREAMER_AND_THE_ZEALOT, 0x85B501)

		MoveAggroAndKillInRange(-9672, -3286, '4', $PLAYER_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-11186, -1788, '5', $PLAYER_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-10727, -304, '6', $PLAYER_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-8618, 3132, '7', $PLAYER_AGGRO_RANGE)
		PickUpElementalKeystone()
		MoveAggroAndKillInRange(-8684, 4580, '8', $PLAYER_AGGRO_RANGE)
		PickUpElementalKeystone()
	WEnd
	If IsRunFailed() Then Return $FAIL

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		If CheckStuck('TunnelsOfTheForsaken Floor 1 - Getting through portal', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		MoveTo(-8684, 4580)
		Move(-8687, 4700)
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

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -16748, 5350, $RANGE_LONGBOW)
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - First loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		MoveAggroAndKillInRange(-2196, 12191, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(1228, 16292, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-764, 17454, '3', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-643, 20296, '4', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-2584, 21152, '5', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3558, 21554, '6', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-3788, 21873, '7', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6974, 20808, '8', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9017, 21345, '9', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10769, 20331, '10', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12465, 20092, '11', $RANGE_NEARBY)
		MoveAggroAndKillInRange(-14464, 19742, '12', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16238, 17982, '13', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16724, 15846, '14', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13865, 17135, '15', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12848, 18506, '16', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10956, 19044, '17', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-9889, 18907, '18', $RANGE_NEARBY)
        MoveAggroAndKillInRange(-8953, 18720, '18', $RANGE_NEARBY)
        MoveAggroAndKillInRange(-7921, 18913, '18', $RANGE_NEARBY)
        MoveAggroAndKillInRange(-7456, 18718, '18', $RANGE_NEARBY)
		MoveAggroAndKillInRange(-6272, 17188, '19', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-5910, 14892, '20', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-7177, 13320, '21', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10482, 14259, '22', $PLAYER_AGGRO_RANGE)
		RandomSleep(5000)
		MoveAggroAndKillInRange(-10816, 15686, '23', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12402, 15310, '24', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-14553, 12670, '25', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16047, 10162, '26', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16759, 7708, '27', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16748, 5350, '28', $PLAYER_AGGRO_RANGE)
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

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -10264, -4463, $RANGE_LONGBOW)
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - First loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		MoveAggroAndKillInRange(-11162, 3309, '1', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10127, 2505, '2', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17353, -952, '3', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16397, -3496, '4', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-15176, -3768, '5', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13875, -4543, '6', $PLAYER_AGGRO_RANGE)
		; Spawning the grawls prevents killing the God-touched Grawl too close to Althea, which risks leaving Varny alive and therefore the chest won't appear.
		; Put ; in front of the next three lines to skip this step.
		MoveAggroAndKillInRange(-14111, -6232, '7', $PLAYER_AGGRO_RANGE)
		Sleep(2000)
		MoveAggroAndKillInRange(-13875, -4543, '8', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12599, -5454, '9', $PLAYER_AGGRO_RANGE)
		Sleep(4000)
		PickUpItems()
		MoveAggroAndKillInRange(-10724, -3552, '10', $PLAYER_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -15949, -8561, $RANGE_LONGBOW)
		If CheckStuck('TunnelsOfTheForsaken Floor 2 - Second loop', $MAX_TUNNELS_OF_THE_FORSAKEN_FARM_DURATION) == $FAIL Then Return $FAIL
		WaitUntilPartyAlive()
		UseMoraleConsumableIfNeeded()
		UseSummoningStone()
		MoveAggroAndKillInRange(-9820, -2108, '11', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8166, 1081, '12', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-5090, -78, '13', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6212, -2777, '14', $PLAYER_AGGRO_RANGE)
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
		MoveAggroAndKillInRange(-7771, -6279, '15', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11025, -7480, '16', $PLAYER_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12939, -8238, '17', $PLAYER_AGGRO_RANGE)
		; TODO: replace those sleep with chest detection and a loop
		RandomSleep(2000)
		MoveAggroAndKillInRange(-13836, -8918, '18', $PLAYER_AGGRO_RANGE)
		RandomSleep(2000)
		MoveAggroAndKillInRange(-16021, -8601, '19', $PLAYER_AGGRO_RANGE)
		RandomSleep(2000)
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
