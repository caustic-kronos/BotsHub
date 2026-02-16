#CS ===========================================================================
; Author: ian
; Contributor: ---
; Copyright 2026 caustic-kronos
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
Global Const $KURZICK_FACTION_DRAZACH_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot does not load hero builds - please use your own teambuild' & @CRLF _
	& 'An Alternative Farm to Ferndale. This Bot will farm Drazach Thicket'

Global Const $KURZICKS_FARM_DRAZACH_DURATION = 25 * 60 * 1000

Global $kurzick_farm_drazach_setup = False

; Shrine state (matches the GW3 script pattern)
Global $RezShrine = 0


; =====================================================================
; Local wrappers / compatibility
; The GWA2 hub tracks party/run state in Utils-Agents.au3:
;   - IsPlayerDead(), IsPlayerAlive(), IsPlayerAndPartyWiped()
;   - IsRunFailed(), TrackPartyStatus(), ResetFailuresCounter(), ...
; There is no GetPartyDead()/GetPartyDefeated() in this codebase, but the
; shrine-phase logic we want reads better with them, so we provide wrappers
; locally *in this file only*.
; =====================================================================

Func GetPartyDead()
	Return IsPlayerDead()
EndFunc

Func GetPartyDefeated()
	; Run is considered defeated/failed when the global wipe counter exceeds
	; the limit (handled by TrackPartyStatus/IsRunFailed).
	Return IsRunFailed()
EndFunc


; =====================================================================
; Public entry
; =====================================================================
Func KurzickFactionFarmDrazach()
	ManageFactionPointsKurzickFarm()
	If Not $kurzick_farm_drazach_setup Then KurzickFarmDrazachSetup()

	GetGoldForShrineBenediction()
	ResetFailuresCounter()

	AdlibRegister('TrackPartyStatus', 10000)
	Local $result = KurzickFactionFarmDrazachLoop()
	AdlibUnRegister('TrackPartyStatus')

	Return $result
EndFunc


; =====================================================================
; Setup once
; =====================================================================
Func KurzickFarmDrazachSetup()
	Info('Setting up Drazach farm')
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	SwitchMode($ID_HARD_MODE)
	$kurzick_farm_drazach_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


; =====================================================================
; “Loop” container for a single run (SoO style)
; =====================================================================
Func KurzickFactionFarmDrazachLoop()
	If GoToDrazach() = $FAIL Then
		$kurzick_farm_drazach_setup = False
		Return $FAIL
	EndIf

	Local $ok = FarmDrazachThicket()
	If Not $ok Then
		$kurzick_farm_drazach_setup = False
		Return $FAIL
	EndIf

	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	EndIf

	Info('Map has been fully vanquished.')
	Return $SUCCESS
EndFunc


; =====================================================================
; Move out of outpost into Drazach
; =====================================================================
Func GoToDrazach()
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	While GetMapID() <> $ID_DRAZACH_THICKET
		Info('Moving to Drazach')
		MoveTo(-5928.21, 14269.09)
		Move(-6550, 14550)
		RandomSleep(1000)
		WaitMapLoading($ID_DRAZACH_THICKET, 10000, 2000)
	WEnd
	If GetMapID() <> $ID_DRAZACH_THICKET Then Return $FAIL
	Return $SUCCESS
EndFunc


; =====================================================================
; Blessing (same as before)
; =====================================================================
Func GetBlessingDrazach()
	Info('Taking blessing')
	MoveTo(-4927.36, -16385.35)
	GoNearestNPCToCoords(-5621.25, -16367.59)

	If GetLuxonFaction() > GetKurzickFaction() Then
		Dialog(0x81)
		Sleep(1000)
		Dialog(0x2)
		Sleep(1000)
		Dialog(0x84)
		Sleep(1000)
		Dialog(0x86)
		RandomSleep(1000)
	Else
		Dialog(0x85)
		RandomSleep(1000)
		Dialog(0x86)
		RandomSleep(1000)
	EndIf

	Return $SUCCESS
EndFunc


; =====================================================================
; Core behavioral fix:
; - NEVER continue executing waypoints if player is dead
; - Wait for rez, then return to let outer Do..Until rerun the phase
; =====================================================================
Func _HandleDeathAndReturn($restartMsg)
	; If the run is already considered failed, stop.
	If GetPartyDefeated() Then Return $FAIL

	; Stop phase immediately if player is dead (regardless of whether a hero might rez).
	; This is the key behaviour: prevent burning through waypoints while dead.
	If IsPlayerDead() Then
		If IsPlayerAndPartyWiped() Then
			Warn($restartMsg & ' (wipe detected)')
		Else
			Warn($restartMsg & ' (player dead)')
		EndIf

		; Wait until player is alive again (rez shrine or hero rez).
		Local $t = TimerInit()
		While IsPlayerDead()
			Sleep(250)
			If GetPartyDefeated() Then Return $FAIL
			; Safety cap so we don't hang forever if rez never happens.
			If TimerDiff($t) > 180000 Then ; 3 minutes
				Error('Rez wait timed out - run failed')
				Return $FAIL
			EndIf
		WEnd

		; After rez, caller should stop current phase and let outer loop rerun it.
		Return $FAIL
	EndIf

	Return $SUCCESS
EndFunc


Func _Step($x, $y, $msg, $aggroRange = 0)
	; Hard stop if run is considered failed
	If GetPartyDefeated() Then Return $FAIL

	; If dead, do NOT attempt steps
	If _HandleDeathAndReturn('Party wiped — restarting from shrine ' & $RezShrine) = $FAIL Then Return $FAIL

	; Run the actual move/aggro/kill step
	If $aggroRange > 0 Then
		If MoveAggroAndKillInRange($x, $y, $msg, $aggroRange) = $FAIL Then Return $FAIL
	Else
		If MoveAggroAndKillInRange($x, $y, $msg) = $FAIL Then Return $FAIL
	EndIf

	; After the step, check again for death/wipe
	If _HandleDeathAndReturn('Party wiped — restarting from shrine ' & $RezShrine) = $FAIL Then Return $FAIL

	Return $SUCCESS
EndFunc


; =====================================================================
; Farm controller (matches the GW3 farm pattern exactly)
; =====================================================================
Func FarmDrazachThicket()
	If GetPartyDead() Then Return False

	GetBlessingDrazach()
	$RezShrine = 1

	Info("Now let's Farm some Kurzick Points")

	If GetPartyDefeated() Then Return False
	Do
		If GetPartyDefeated() Then ExitLoop
		FarmToSecondShrine()
	Until $RezShrine = 2 Or GetPartyDefeated()

	If GetPartyDefeated() Then Return False
	Do
		If GetPartyDefeated() Then ExitLoop
		FarmToThirdShrine()
	Until $RezShrine = 3 Or GetPartyDefeated()

	If GetPartyDefeated() Then Return False
	Do
		If GetPartyDefeated() Then ExitLoop
		FarmToFourthShrine()
	Until $RezShrine = 4 Or GetPartyDefeated()

	If GetPartyDefeated() Then Return False
	Do
		If GetPartyDefeated() Then ExitLoop
		FarmToFifthShrine()
	Until $RezShrine = 5 Or GetPartyDefeated()

	If GetPartyDefeated() Then Return False
	Do
		If GetPartyDefeated() Then ExitLoop
		FarmToEnd()
	Until $RezShrine = 0 Or GetPartyDefeated()

	Return (Not GetPartyDefeated())
EndFunc


; =====================================================================
; Phase 1 -> Shrine 2
; =====================================================================
Func FarmToSecondShrine()
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the first Shrine')
		Return
	EndIf

	_Step(-6506, -16099, 'Start')
	If GetPartyDead() Then Return
	_Step(-8581, -15354, 'Approach')
	If GetPartyDead() Then Return
	_Step(-8627, -13151, 'Clear first big batch')
	If GetPartyDead() Then Return
	_Step(-6128.70, -11242.96, 'Path')
	If GetPartyDead() Then Return
	_Step(-5173.57, -10858.66, 'Path')
	If GetPartyDead() Then Return
	_Step(-6368.70, -9313.60, 'Kill Mesmer Boss')
	If GetPartyDead() Then Return
	_Step(-7827.89, -9681.69, 'Kill Mesmer Boss')
	If GetPartyDead() Then Return
	_Step(-6021, -8358, 'Clear smaller groups')
	If GetPartyDead() Then Return
	_Step(-5184, -6307, 'Clear smaller groups')
	If GetPartyDead() Then Return
	_Step(-4643, -5336, 'Clear smaller groups')
	If GetPartyDead() Then Return
	_Step(-7368, -6043, 'Clear smaller groups')
	If GetPartyDead() Then Return
	_Step(-9514, -6539, 'Clear smaller groups')
	If GetPartyDead() Then Return
	_Step(-10988, -8177, 'Kill Necro Boss')
	If GetPartyDead() Then Return
	_Step(-11388, -7827, 'Kill Necro Boss')
	If GetPartyDead() Then Return
	_Step(-11291, -5987, 'Small groups north')
	If GetPartyDead() Then Return
	_Step(-11380, -3787, 'Small groups north')
	If GetPartyDead() Then Return
	_Step(-10641, -1714, 'Small groups north')
	If GetPartyDead() Then Return
	_Step(-8659.20, -2268.30, 'Oni spawn point')
	If GetPartyDead() Then Return
	_Step(-7019.81, -976.18, 'Undergrowth group')
	If GetPartyDead() Then Return
	_Step(-4464.77, 780.87, 'Undergrowth group')
	If GetPartyDead() Then Return

	_Step(-1355.74, -914.94, 'Move to Shrine 2')
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the first Shrine')
		Return
	EndIf

	$RezShrine = 2
EndFunc


; =====================================================================
; Phase 2 -> Shrine 3
; =====================================================================
Func FarmToThirdShrine()
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the second Shrine')
		Return
	EndIf

	_Step(-4464.77, 780.87, 'Back NW')
	If GetPartyDead() Then Return
	_Step(-7019.81, -976.18, 'Back NW')
	If GetPartyDead() Then Return
	_Step(-10575, 489, 'Back NW')
	If GetPartyDead() Then Return
	_Step(-11266, 2581, 'Back NW')
	If GetPartyDead() Then Return
	_Step(-10444, 4234, 'Back NW')
	If GetPartyDead() Then Return
	_Step(-12820, 4153, 'Back NW')
	If GetPartyDead() Then Return

	_Step(-12804, 6357, 'Oni spawn point')
	If GetPartyDead() Then Return

	_Step(-12074, 8448, 'Kill Mantis')
	If GetPartyDead() Then Return
	_Step(-10212.96, 10309.16, 'Kill Mantis')
	If GetPartyDead() Then Return
	_Step(-8211.33, 11407.54, 'Kill Mantis')
	If GetPartyDead() Then Return

	_Step(-7754.69, 9436.11, 'Oni spawn point')
	If GetPartyDead() Then Return

	_Step(-6167.01, 9447.13, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(-4815.21, 10528.07, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(-5479.61, 7343.60, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(-5289.82, 4998.54, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(-2484.76, 7233.19, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(-3367.10, 9928.76, 'Kill Wardens')
	If GetPartyDead() Then Return

	_Step(-3394.30, 11746.05, 'Kill Ranger Boss')
	If GetPartyDead() Then Return
	_Step(-4869.57, 12948.64, 'Kill Ranger Boss')
	If GetPartyDead() Then Return
	_Step(-5932.44, 13806.47, 'Kill Ranger Boss')
	If GetPartyDead() Then Return

	_Step(-4848.12, 15585.97, 'Wardens + Dragon Moss')
	If GetPartyDead() Then Return

	_Step(-8019.13, 18330.92, 'Move to Shrine 3')
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the second Shrine')
		Return
	EndIf

	$RezShrine = 3
EndFunc


; =====================================================================
; Phase 3 -> Shrine 4
; =====================================================================
Func FarmToFourthShrine()
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the third Shrine')
		Return
	EndIf

	_Step(-5701.15, 16202.36, 'Back')
	If GetPartyDead() Then Return
	_Step(-3141.18, 16025.75, 'Back')
	If GetPartyDead() Then Return
	_Step(-787.45, 15014.48, 'Back')
	If GetPartyDead() Then Return
	_Step(1462.83, 15520.20, 'Back')
	If GetPartyDead() Then Return

	_Step(4282.75, 14447.79, 'Oni spawn point')
	If GetPartyDead() Then Return

	_Step(4605.17, 12623.42, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(2966.67, 11883.08, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(1147.05, 9904.27, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(-1241.19, 8426.36, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(1612.73, 10091.67, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(3292.36, 10628.14, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(4957.04, 8302.28, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(7123.86, 5813.80, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(8363.76, 9446.83, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(8723.25, 11237.47, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(7363.71, 13697.35, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(10668.76, 11515.62, 'Kill Wardens')
	If GetPartyDead() Then Return
	_Step(13930.39, 10779.55, 'Kill Wardens')
	If GetPartyDead() Then Return

	_Step(15884.81, 9224.07, 'Move to Shrine 4')
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the third Shrine')
		Return
	EndIf

	$RezShrine = 4
EndFunc


; =====================================================================
; Phase 4 -> Shrine 5
; =====================================================================
Func FarmToFifthShrine()
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the fourth Shrine')
		Return
	EndIf

	_Step(14685.91, 7077.44, 'To Wardens')
	If GetPartyDead() Then Return
	_Step(11869.74, 5679.88, 'To Wardens')
	If GetPartyDead() Then Return
	_Step(8744.54, 4192.64, 'To Wardens')
	If GetPartyDead() Then Return
	_Step(6187.57, 6313.87, 'To Wardens')
	If GetPartyDead() Then Return
	_Step(9159.87, 3654.00, 'To Wardens')
	If GetPartyDead() Then Return
	_Step(11257.36, 338.60, 'To Wardens')
	If GetPartyDead() Then Return

	_Step(8844.41, 303.82, 'Undergrowth groups')
	If GetPartyDead() Then Return
	_Step(5613.70, 296.42, 'Undergrowth groups')
	If GetPartyDead() Then Return
	_Step(2832.80, 3850.74, 'Undergrowth groups')
	If GetPartyDead() Then Return

	_Step(4588.24, 5461.12, 'More Wardens')
	If GetPartyDead() Then Return
	_Step(-599.41, 3401.40, 'More Wardens')
	If GetPartyDead() Then Return

	_Step(-1528.55, 5116.05, 'Path')
	If GetPartyDead() Then Return
	_Step(-1292.70, 2307.54, 'Path')
	If GetPartyDead() Then Return

	_Step(-1257.87, -1004.89, 'Move to Shrine 5')
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the fourth Shrine')
		Return
	EndIf

	$RezShrine = 5
EndFunc


; =====================================================================
; Phase 5 -> End
; =====================================================================
Func FarmToEnd()
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the fifth Shrine')
		Return
	EndIf

	_Step(-2693.82, -4748.93, 'Last enemies')
	If GetPartyDead() Then Return
	_Step(-454.99, -4876.88, 'Last enemies')
	If GetPartyDead() Then Return
	_Step(1888.65, -4833.90, 'Last enemies')
	If GetPartyDead() Then Return
	_Step(4022.13, -5717.67, 'Last enemies')
	If GetPartyDead() Then Return
	_Step(3528.05, -7154.28, 'Last enemies')
	If GetPartyDead() Then Return
	_Step(1103.53, -6744.78, 'Last enemies')
	If GetPartyDead() Then Return
	_Step(455.56, -9067.87, 'Last enemies')
	If GetPartyDead() Then Return

	_Step(2772.91, -9397.36, 'Ritualist bosses')
	If GetPartyDead() Then
		_HandleDeathAndReturn('Restart from the fifth Shrine')
		Return
	EndIf

	$RezShrine = 0
EndFunc
