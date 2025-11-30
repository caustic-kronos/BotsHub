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

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $VoltaicFarmInformations = 'For best results, have :' & @CRLF _
	& '- completed EotN story once' & @CRLF _
	& '- a full and efficient 7-hero-team' & @CRLF _
	& '- a hero with Frozen Soil' & @CRLF _
	& '- a build that can be run from skill 1 to 8 (no complex combos or conditional skills)' & @CRLF _
	& 'In NM, bot takes 13min (with cons), 15min (without cons) on average' & @CRLF _
	& 'Not tested in HM.'
Global Const $VOLTAIC_FARM_DURATION = 16 * 60 * 1000
Global Const $VSAggroRange = $RANGE_SPELLCAST + 200

Global $VOLTAIC_FARM_SETUP = False

;~ Main method to farm Voltaic
Func VoltaicFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If Not $VOLTAIC_FARM_SETUP Then SetupVoltaicFarm()
	If $STATUS <> 'RUNNING' Then Return $PAUSE

	GoToVerdantCascades()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VoltaicFarmLoop()
	; Local $timer = TimerInit()
	AdlibUnregister('TrackPartyStatus')
	TravelToOutpost($ID_Umbral_Grotto, $DISTRICT_NAME)
	Return $result
EndFunc


;~ Voltaic farm setup
Func SetupVoltaicFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_Umbral_Grotto, $DISTRICT_NAME)
	; Assuming that team has been set up correctly manually
	SwitchToHardModeIfEnabled()
	$VOLTAIC_FARM_SETUP = True
	Info('Preparations complete')
EndFunc


;~ Move out of outpost into Verdant Cascades
Func GoToVerdantCascades()
	If GetMapID() <> $ID_Umbral_Grotto Then TravelToOutpost($ID_Umbral_Grotto, $DISTRICT_NAME)
	While GetMapID() <> $ID_Verdant_Cascades
		Info('Moving to Verdant Cascades')
		MoveTo(-23200, 7100)
		Move(-22735, 6339)
		RandomSleep(1000)
		WaitMapLoading($ID_Verdant_Cascades, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func VoltaicFarmLoop()
	If GetMapID() <> $ID_Verdant_Cascades Then Return $FAIL
	ResetFailuresCounter()

	MoveAggroAndKillInRange(-19887, 6074, '1', $VSAggroRange)
	Info('Making way to Slavers')
	MoveAggroAndKillInRange(-10273, 3251, '2', $VSAggroRange)
	MoveAggroAndKillInRange(-6878, -329, '3', $VSAggroRange)
	MoveAggroAndKillInRange(-3041, -3446, '4', $VSAggroRange)
	MoveAggroAndKillInRange(3571, -9501, '5', $VSAggroRange)
	MoveAggroAndKillInRange(10764, -6448, '6', $VSAggroRange)
	MoveAggroAndKillInRange(13063, -4396, '7', $VSAggroRange)
	If IsRunFailed() Then Return $FAIL

	Info('At the Troll Bridge - TROLL TOLL')
	MoveAggroAndKillInRange(18054, -3275, '8', $VSAggroRange)
	MoveAggroAndKillInRange(20966, -6476, '9', $VSAggroRange)
	MoveAggroAndKillInRange(25298, -9456, '10', $VSAggroRange)
	If IsRunFailed() Then Return $FAIL

	Move(25729, -9360)
	Info('Entering Slavers')
	While Not WaitMapLoading($ID_Slavers_Exile)
		Sleep(50)
	WEnd
	MoveTo(-16797, 9251)
	MoveTo(-17835, 12524)
	Move(-18300, 12527)
	; The map has the same ID as slavers
	While Not WaitMapLoading()
		Sleep(50)
	WEnd
	Info('Now in Justicar')
	Sleep(500)
	GoToNPC(GetNearestNPCToCoords(-12135, -18210))
	RandomSleep(250)
	Dialog(0x84)
	RandomSleep(500)

	If IsHardmodeEnabled() Then UseConset()

	Sleep(1000)
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -18500, -8000, 1250)
		; Waiting to be alive before retrying
		While Not IsPartyCurrentlyAlive()
			Sleep(2000)
		WEnd
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_Legionnaire_Summoning_Crystal, False)
		MoveAggroAndKillInRange(-13500, -15750, 'In front of the door', $VSAggroRange)
		MoveAggroAndKillInRange(-12500, -15000, 'Before the bridge', $VSAggroRange)
		MoveAggroAndKillInRange(-10400, -14800, 'After the bridge', $VSAggroRange)
		MoveAggroAndKillInRange(-11500, -13300, 'First group', $VSAggroRange)
		MoveAggroAndKillInRange(-13400, -11500, 'Second group', $VSAggroRange)
		MoveAggroAndKillInRange(-13700, -9550, 'Third group', $VSAggroRange)
		MoveAggroAndKillInRange(-14100, -8600, 'Fourth group', $VSAggroRange)
		MoveAggroAndKillInRange(-15000, -7500, 'Fourth group, again', $VSAggroRange)
		MoveAggroAndKillInRange(-16500, -8000, 'Fifth group', $VSAggroRange)
		MoveAggroAndKillInRange(-18800, -7850, 'To the shrine', $VSAggroRange)
	WEnd
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -17500, -14250, 1250)
		; Waiting to be alive before retrying
		While Not IsPartyCurrentlyAlive()
			Sleep(2000)
		WEnd
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_Legionnaire_Summoning_Crystal, False)
		MoveAggroAndKillInRange(-18500, -11500, 'Pre-Boss group', $VSAggroRange)
		MoveAggroAndKillInRange(-17700, -12500, 'Boss group', $VSAggroRange)
		MoveAggroAndKillInRange(-17500, -14250, 'Final group', $VSAggroRange)
	WEnd
	If IsRunFailed() Then Return $FAIL
	; Chest
	Move(-17500, -14250)
	Info('Opening chest')
	Sleep(5000)
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	Info('Finished Run')
	Return $SUCCESS
EndFunc
