#CS ===========================================================================
; Author: Northbound
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

; Shrine phase state (1..5, 0 = done)
Global $rez_shrine = 0

; Rez handling flags (no hungarian)
Global $just_rezzed = False
Global $last_rez_shrine = 0


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
; Single-run container
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
; Blessing
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
; Death / rez handling
; =====================================================================
Func HandleDeathAndReturn($restart_msg)
	If IsRunFailed() Then Return $FAIL

	If IsPlayerDead() Then
		If IsPlayerAndPartyWiped() Then
			Warn($restart_msg & ' (wipe detected)')
		Else
			Warn($restart_msg & ' (player dead)')
		EndIf

		; Wait until alive again (rez shrine or hero rez)
		Local $t = TimerInit()
		While IsPlayerDead()
			Sleep(250)
			If IsRunFailed() Then Return $FAIL
			If TimerDiff($t) > 180000 Then
				Error('Rez wait timed out - run failed')
				Return $FAIL
			EndIf
		WEnd

		; Mark rez so next phase attempt can reposition from shrine
		$just_rezzed = True
		$last_rez_shrine = $rez_shrine

		; Critical: abort current phase attempt
		Return $FAIL
	EndIf

	Return $SUCCESS
EndFunc


; One movement/combat step wrapper.
; IMPORTANT: caller MUST check return value and Return on $FAIL.
Func StepTo($x, $y, $msg, $aggro_range = 0)
	If IsRunFailed() Then Return $FAIL
	If HandleDeathAndReturn('Party wiped — restarting from shrine ' & $rez_shrine) = $FAIL Then Return $FAIL

	If $aggro_range > 0 Then
		If MoveAggroAndKillInRange($x, $y, $msg, $aggro_range) = $FAIL Then Return $FAIL
	Else
		If MoveAggroAndKillInRange($x, $y, $msg) = $FAIL Then Return $FAIL
	EndIf

	If HandleDeathAndReturn('Party wiped — restarting from shrine ' & $rez_shrine) = $FAIL Then Return $FAIL
	Return $SUCCESS
EndFunc


; After rez, move from the shrine back onto the path start for the CURRENT phase.
; This prevents "continue from death spot" and reduces wall-running.
Func RepositionAfterRez()
	If Not $just_rezzed Then Return $SUCCESS
	If IsRunFailed() Then Return $FAIL
	If IsPlayerDead() Then Return $FAIL

	Info('Repositioning after rez (shrine ' & $last_rez_shrine & ')')
	Sleep(1500)

	Switch $last_rez_shrine
		Case 1
			; Phase 1 start
			MoveTo(-6000, -15800)
			MoveTo(-6506, -16099)

		Case 2
			; Phase 2 start
			MoveTo(-2400, -500)
			MoveTo(-3500, 200)
			MoveTo(-4464.77, 780.87)

		Case 3
			; Phase 3 start
			MoveTo(-7000, 17200)
			MoveTo(-6100, 16650)
			MoveTo(-5701.15, 16202.36)

		Case 4
			; Phase 4 start
			MoveTo(15400, 8400)
			MoveTo(15000, 7600)
			MoveTo(14685.91, 7077.44)

		Case 5
			; Phase 5 start
			MoveTo(-1600, -2500)
			MoveTo(-2200, -3600)
			MoveTo(-2693.82, -4748.93)
	EndSwitch

	Sleep(1000)
	$just_rezzed = False
	Return $SUCCESS
EndFunc


; =====================================================================
; Farm controller
; =====================================================================
Func FarmDrazachThicket()
	If IsPlayerDead() Then Return False

	GetBlessingDrazach()
	$rez_shrine = 1

	Info("Now let's Farm some Kurzick Points")
	If IsRunFailed() Then Return False

	Do
		If IsRunFailed() Then ExitLoop
		FarmToSecondShrine()
	Until $rez_shrine = 2 Or IsRunFailed()

	Do
		If IsRunFailed() Then ExitLoop
		FarmToThirdShrine()
	Until $rez_shrine = 3 Or IsRunFailed()

	Do
		If IsRunFailed() Then ExitLoop
		FarmToFourthShrine()
	Until $rez_shrine = 4 Or IsRunFailed()

	Do
		If IsRunFailed() Then ExitLoop
		FarmToFifthShrine()
	Until $rez_shrine = 5 Or IsRunFailed()

	Do
		If IsRunFailed() Then ExitLoop
		FarmToEnd()
	Until $rez_shrine = 0 Or IsRunFailed()

	Return (Not IsRunFailed())
EndFunc


; =====================================================================
; Phase 1 -> Shrine 2
; NOTE: Every StepTo(...) MUST be checked for $FAIL and Return immediately.
; This is the bug that caused your "continue after wipe" behaviour.
; =====================================================================
Func FarmToSecondShrine()
	If HandleDeathAndReturn('Restart from the first Shrine') = $FAIL Then Return
	If RepositionAfterRez() = $FAIL Then Return

	If StepTo(-6506, -16099, 'Start') = $FAIL Then Return
	If StepTo(-8581, -15354, 'Approach') = $FAIL Then Return
	If StepTo(-8627, -13151, 'Clear first big batch') = $FAIL Then Return
	If StepTo(-6128.70, -11242.96, 'Path') = $FAIL Then Return
	If StepTo(-5173.57, -10858.66, 'Path') = $FAIL Then Return
	If StepTo(-6368.70, -9313.60, 'Kill Mesmer Boss') = $FAIL Then Return
	If StepTo(-7827.89, -9681.69, 'Kill Mesmer Boss') = $FAIL Then Return
	If StepTo(-6021, -8358, 'Clear smaller groups') = $FAIL Then Return
	If StepTo(-5184, -6307, 'Clear smaller groups') = $FAIL Then Return
	If StepTo(-4643, -5336, 'Clear smaller groups') = $FAIL Then Return
	If StepTo(-7368, -6043, 'Clear smaller groups') = $FAIL Then Return
	If StepTo(-9514, -6539, 'Clear smaller groups') = $FAIL Then Return
	If StepTo(-10988, -8177, 'Kill Necro Boss') = $FAIL Then Return
	If StepTo(-11388, -7827, 'Kill Necro Boss') = $FAIL Then Return
	If StepTo(-11291, -5987, 'Small groups north') = $FAIL Then Return
	If StepTo(-11380, -3787, 'Small groups north') = $FAIL Then Return
	If StepTo(-10641, -1714, 'Small groups north') = $FAIL Then Return
	If StepTo(-8659.20, -2268.30, 'Oni spawn point') = $FAIL Then Return
	If StepTo(-7019.81, -976.18, 'Undergrowth group') = $FAIL Then Return
	If StepTo(-4464.77, 780.87, 'Undergrowth group') = $FAIL Then Return
	If StepTo(-1355.74, -914.94, 'Move to Shrine 2') = $FAIL Then Return

	$rez_shrine = 2
EndFunc


; =====================================================================
; Phase 2 -> Shrine 3
; =====================================================================
Func FarmToThirdShrine()
	If HandleDeathAndReturn('Restart from the second Shrine') = $FAIL Then Return
	If RepositionAfterRez() = $FAIL Then Return

	If StepTo(-4464.77, 780.87, 'Back NW') = $FAIL Then Return
	If StepTo(-7019.81, -976.18, 'Back NW') = $FAIL Then Return
	If StepTo(-10575, 489, 'Back NW') = $FAIL Then Return
	If StepTo(-11266, 2581, 'Back NW') = $FAIL Then Return
	If StepTo(-10444, 4234, 'Back NW') = $FAIL Then Return
	If StepTo(-12820, 4153, 'Back NW') = $FAIL Then Return
	If StepTo(-12804, 6357, 'Oni spawn point') = $FAIL Then Return
	If StepTo(-12074, 8448, 'Kill Mantis') = $FAIL Then Return
	If StepTo(-10212.96, 10309.16, 'Kill Mantis') = $FAIL Then Return
	If StepTo(-8211.33, 11407.54, 'Kill Mantis') = $FAIL Then Return
	If StepTo(-7754.69, 9436.11, 'Oni spawn point') = $FAIL Then Return
	If StepTo(-6167.01, 9447.13, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-4815.21, 10528.07, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-5479.61, 7343.60, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-5289.82, 4998.54, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-2484.76, 7233.19, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-3367.10, 9928.76, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-3394.30, 11746.05, 'Kill Ranger Boss') = $FAIL Then Return
	If StepTo(-4869.57, 12948.64, 'Kill Ranger Boss') = $FAIL Then Return
	If StepTo(-5932.44, 13806.47, 'Kill Ranger Boss') = $FAIL Then Return
	If StepTo(-4848.12, 15585.97, 'Wardens + Dragon Moss') = $FAIL Then Return
	If StepTo(-8019.13, 18330.92, 'Move to Shrine 3') = $FAIL Then Return

	$rez_shrine = 3
EndFunc


; =====================================================================
; Phase 3 -> Shrine 4
; =====================================================================
Func FarmToFourthShrine()
	If HandleDeathAndReturn('Restart from the third Shrine') = $FAIL Then Return
	If RepositionAfterRez() = $FAIL Then Return

	If StepTo(-5701.15, 16202.36, 'Back') = $FAIL Then Return
	If StepTo(-3141.18, 16025.75, 'Back') = $FAIL Then Return
	If StepTo(-787.45, 15014.48, 'Back') = $FAIL Then Return
	If StepTo(1462.83, 15520.20, 'Back') = $FAIL Then Return
	If StepTo(4282.75, 14447.79, 'Oni spawn point') = $FAIL Then Return
	If StepTo(4605.17, 12623.42, 'Kill Wardens') = $FAIL Then Return
	If StepTo(2966.67, 11883.08, 'Kill Wardens') = $FAIL Then Return
	If StepTo(1147.05, 9904.27, 'Kill Wardens') = $FAIL Then Return
	If StepTo(-1241.19, 8426.36, 'Kill Wardens') = $FAIL Then Return
	If StepTo(1612.73, 10091.67, 'Kill Wardens') = $FAIL Then Return
	If StepTo(3292.36, 10628.14, 'Kill Wardens') = $FAIL Then Return
	If StepTo(4957.04, 8302.28, 'Kill Wardens') = $FAIL Then Return
	If StepTo(7123.86, 5813.80, 'Kill Wardens') = $FAIL Then Return
	If StepTo(8363.76, 9446.83, 'Kill Wardens') = $FAIL Then Return
	If StepTo(8723.25, 11237.47, 'Kill Wardens') = $FAIL Then Return
	If StepTo(7363.71, 13697.35, 'Kill Wardens') = $FAIL Then Return
	If StepTo(10668.76, 11515.62, 'Kill Wardens') = $FAIL Then Return
	If StepTo(13930.39, 10779.55, 'Kill Wardens') = $FAIL Then Return
	If StepTo(15884.81, 9224.07, 'Move to Shrine 4') = $FAIL Then Return

	$rez_shrine = 4
EndFunc


; =====================================================================
; Phase 4 -> Shrine 5
; =====================================================================
Func FarmToFifthShrine()
	If HandleDeathAndReturn('Restart from the fourth Shrine') = $FAIL Then Return
	If RepositionAfterRez() = $FAIL Then Return

	If StepTo(14685.91, 7077.44, 'To Wardens') = $FAIL Then Return
	If StepTo(11869.74, 5679.88, 'To Wardens') = $FAIL Then Return
	If StepTo(8744.54, 4192.64, 'To Wardens') = $FAIL Then Return
	If StepTo(6187.57, 6313.87, 'To Wardens') = $FAIL Then Return
	If StepTo(9159.87, 3654.00, 'To Wardens') = $FAIL Then Return
	If StepTo(11257.36, 338.60, 'To Wardens') = $FAIL Then Return
	If StepTo(8844.41, 303.82, 'Undergrowth groups') = $FAIL Then Return
	If StepTo(5613.70, 296.42, 'Undergrowth groups') = $FAIL Then Return
	If StepTo(2832.80, 3850.74, 'Undergrowth groups') = $FAIL Then Return
	If StepTo(4588.24, 5461.12, 'More Wardens') = $FAIL Then Return
	If StepTo(-599.41, 3401.40, 'More Wardens') = $FAIL Then Return
	If StepTo(-1528.55, 5116.05, 'Path') = $FAIL Then Return
	If StepTo(-1292.70, 2307.54, 'Path') = $FAIL Then Return
	If StepTo(-1257.87, -1004.89, 'Move to Shrine 5') = $FAIL Then Return

	$rez_shrine = 5
EndFunc


; =====================================================================
; Phase 5 -> End
; =====================================================================
Func FarmToEnd()
	If HandleDeathAndReturn('Restart from the fifth Shrine') = $FAIL Then Return
	If RepositionAfterRez() = $FAIL Then Return

	If StepTo(-2693.82, -4748.93, 'Last enemies') = $FAIL Then Return
	If StepTo(-454.99, -4876.88, 'Last enemies') = $FAIL Then Return
	If StepTo(1888.65, -4833.90, 'Last enemies') = $FAIL Then Return
	If StepTo(4022.13, -5717.67, 'Last enemies') = $FAIL Then Return
	If StepTo(3528.05, -7154.28, 'Last enemies') = $FAIL Then Return
	If StepTo(1103.53, -6744.78, 'Last enemies') = $FAIL Then Return
	If StepTo(455.56, -9067.87, 'Last enemies') = $FAIL Then Return
	If StepTo(2772.91, -9397.36, 'Ritualist bosses') = $FAIL Then Return

	$rez_shrine = 0
EndFunc
