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
Global Const $VOLTAIC_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- completed EotN story once' & @CRLF _
	& '- a full and efficient 7-hero-team' & @CRLF _
	& '- a hero with Frozen Soil' & @CRLF _
	& '- a build that can be run from skill 1 to 8 (no complex combos or conditional skills)' & @CRLF _
	& 'In NM, bot takes 13min (with cons), 15min (without cons) on average' & @CRLF _
	& 'Not tested in HM.'
Global Const $VOLTAIC_FARM_DURATION = 16 * 60 * 1000
Global Const $VS_AGGRO_RANGE = $RANGE_SPELLCAST + 200

Global $voltaic_farm_setup = False

;~ Main method to farm Voltaic
Func VoltaicFarm()
	If Not $voltaic_farm_setup Then SetupVoltaicFarm()

	GoToVerdantCascades()
	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = VoltaicFarmLoop()
	AdlibUnregister('TrackPartyStatus')
	TravelToOutpost($ID_UMBRAL_GROTTO, $district_name)
	Return $result
EndFunc


;~ Voltaic farm setup
Func SetupVoltaicFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_UMBRAL_GROTTO, $district_name)
	SwitchToHardModeIfEnabled()
	SetDisplayedTitle($ID_ASURA_TITLE)
	$voltaic_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Move out of outpost into Verdant Cascades
Func GoToVerdantCascades()
	TravelToOutpost($ID_UMBRAL_GROTTO, $district_name)
	While GetMapID() <> $ID_VERDANT_CASCADES
		Info('Moving to Verdant Cascades')
		MoveTo(-23200, 7100)
		Move(-22735, 6339)
		RandomSleep(1000)
		WaitMapLoading($ID_VERDANT_CASCADES, 10000, 2000)
	WEnd
EndFunc


;~ Farm loop
Func VoltaicFarmLoop()
	If GetMapID() <> $ID_VERDANT_CASCADES Then Return $FAIL
	ResetFailuresCounter()

	MoveAggroAndKillInRange(-19887, 6074, '1', $VS_AGGRO_RANGE)
	Info('Making way to Slavers')
	MoveAggroAndKillInRange(-10273, 3251, '2', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(-6878, -329, '3', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(-3041, -3446, '4', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(3571, -9501, '5', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(10764, -6448, '6', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(13063, -4396, '7', $VS_AGGRO_RANGE)
	If IsRunFailed() Then Return $FAIL

	Info('At the Troll Bridge - TROLL TOLL')
	MoveAggroAndKillInRange(18054, -3275, '8', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(20966, -6476, '9', $VS_AGGRO_RANGE)
	MoveAggroAndKillInRange(25298, -9456, '10', $VS_AGGRO_RANGE)
	If IsRunFailed() Then Return $FAIL

	Move(25729, -9360)
	Info('Entering Slavers')
	While Not WaitMapLoading($ID_SLAVERS_EXILE)
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
		UseConsumable($ID_LEGIONNAIRE_SUMMONING_CRYSTAL, False)
		MoveAggroAndKillInRange(-13500, -15750, 'In front of the door', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-12500, -15000, 'Before the bridge', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10400, -14800, 'After the bridge', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11500, -13300, 'First group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13400, -11500, 'Second group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-13700, -9550, 'Third group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-14100, -8600, 'Fourth group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-15000, -7500, 'Fourth group, again', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16500, -8000, 'Fifth group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-18800, -7850, 'To the shrine', $VS_AGGRO_RANGE)
	WEnd
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -17500, -14250, 1250)
		; Waiting to be alive before retrying
		While Not IsPartyCurrentlyAlive()
			Sleep(2000)
		WEnd
		UseMoraleConsumableIfNeeded()
		UseConsumable($ID_LEGIONNAIRE_SUMMONING_CRYSTAL, False)
		MoveAggroAndKillInRange(-18500, -11500, 'Pre-Boss group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17700, -12500, 'Boss group', $VS_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17500, -14250, 'Final group', $VS_AGGRO_RANGE)
	WEnd
	If IsRunFailed() Then Return $FAIL
	Info('Opening chest')
	; Tripled to secure looting of chest
	For $i = 0 To 2
		Move(-17500, -14250, 600)
		Sleep(5000)
		TargetNearestItem()
		ActionInteract()
		Sleep(2500)
		PickUpItems()
	Next
	Info('Finished Run')
	Return $SUCCESS
EndFunc
