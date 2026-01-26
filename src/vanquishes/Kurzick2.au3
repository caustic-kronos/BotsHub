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

; Possible improvements :
; - noticed some scenarios where map is not cleared - check whether this can be fixed by adding a few additional locations

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $KURZICK_FACTION2_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- a full hero team that can clear HM content easily' & @CRLF _
	& '- a build that can be played from skill 1 to 8 easily (no combos or complicated builds)' & @CRLF _
	& 'This bot doesnt load hero builds - please use your own teambuild' & @CRLF _
	& 'An Alternative Farm to Ferndale. This Bot will farm Drazach Thicket'
; Average duration ~ 40m
Global Const $KURZICKS_FARM2_DURATION = 41 * 60 * 1000

Global $kurzick_farm_setup = False

;~ Main loop for the kurzick faction farm
Func KurzickFactionFarm2()
	ManageFactionPointsKurzickFarm2()
	If Not $kurzick_farm_setup Then KurzickFarmSetup2()
	CheckGoldKurzickFarm2()
	GoToDrazach()
	Local $result = VanquishDrazach()
	AdlibUnRegister('TrackPartyStatus')
	
	Return $result
EndFunc

;~ Setup for kurzick farm
Func KurzickFarmSetup2()
	Info('Setting up farm')
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	SwitchMode($ID_HARD_MODE)

	$kurzick_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc

Func ManageFactionPointsKurzickFarm2()
	Local $cur = GetKurzickFaction()
	Local $max = GetMaxKurzickFaction()
	Info("KurzickFaction cur=" & $cur & " max=" & $max & " threshold=" & ($max - 25000))
	If GetKurzickFaction() > (GetMaxKurzickFaction() - 25000) Then
		TravelToOutpost($ID_HOUSE_ZU_HELTZER, $district_name)
		RandomSleep(200)
		GoNearestNPCToCoords(5390, 1524)

		Local $donatePoints = (GUICtrlRead($GUI_RadioButton_DonatePoints) == $GUI_CHECKED)
		Local $buyResources = (GUICtrlRead($GUI_RadioButton_BuyFactionResources) == $GUI_CHECKED)
		Local $buyScrolls = (GUICtrlRead($GUI_RadioButton_BuyFactionScrolls) == $GUI_CHECKED)
		If $donatePoints Then
			Info('Donating Kurzick faction points')
			While GetKurzickFaction() >= 5000
				DonateFaction('kurzick')
				RandomSleep(500)
			WEnd
		ElseIf $buyResources Then
			Info('Converting Kurzick faction points into Amber Chunks')
			Dialog(0x83)
			RandomSleep(550)
			Local $numberOfChunks = Floor(GetKurzickFaction() / 5000)
			; number of chunks = bits from 9th position (binary, not hex), e.g. 0x800101 = 1 chunk, 0x800201 = 2 chunks
			Local $dialogID = 0x800001 + (0x100 * $numberOfChunks)
			Dialog($dialogID)
			RandomSleep(550)
		ElseIf $buyScrolls Then
			Info('Converting Kurzick faction points into Urgoz Warren Passage Scrolls')
			Dialog(0x83)
			RandomSleep(550)
			Local $numberOfScrolls = Floor(GetKurzickFaction() / 1000)
			; number of scrolls = bits from 9th position (binary, not hex), e.g. 0x800102 = 1 scroll, 0x800202 = 2 scrolls, 0x800A02 = 10 scrolls
			Local $dialogID = 0x800002 + (0x100 * $numberOfScrolls)
			Dialog($dialogID)
			RandomSleep(550)
		EndIf
		RandomSleep(500)
	EndIf
EndFunc

Func CheckGoldKurzickFarm2()
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	If GetGoldCharacter() < 100 AND GetGoldStorage() > 100 Then
		Info('Withdrawing gold for shrines benediction')
		RandomSleep(250)
		WithdrawGold(100)
		RandomSleep(250)
	EndIf
EndFunc

;~ Move out of outpost into Drazach
Func GoToDrazach()
	TravelToOutpost($ID_THE_ETERNAL_GROVE, $district_name)
	While GetMapID() <> $ID_DRAZACH_THICKET
		Info('Moving to Drazach')
		MoveTo(-5928.21, 14269.09)
		MoveTo(-6550, 14550)
		RandomSleep(1000)
		WaitMapLoading($ID_DRAZACH_THICKET, 10000, 2000)
	WEnd
EndFunc

Func VanquishDrazach()
	
	If GetMapID() <> $ID_DRAZACH_THICKET Then Return $FAIL
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
	
	Local Static $foes[81][4] = [ _
		[-6506, -16099, 'Start', $AGGRO_RANGE], _
		[-8581, -15354, 'Approach', $AGGRO_RANGE], _
		[-8627, -13151, 'Clear first big batch', $AGGRO_RANGE], _
		[-6128.70, -11242.96, 'Path', $AGGRO_RANGE], _
		[-5173.57, -10858.66, 'Path', $AGGRO_RANGE], _
		[-6368.70, -9313.60, 'Kill Mesmer Boss', $AGGRO_RANGE], _
		[-7827.89, -9681.69, 'Kill Mesmer Boss', $AGGRO_RANGE], _
		[-6021, -8358, 'Clear smaller groups', $AGGRO_RANGE], _
		[-5184, -6307, 'Clear smaller groups', $AGGRO_RANGE], _
		[-4643, -5336, 'Clear smaller groups', $AGGRO_RANGE], _
		[-7368, -6043, 'Clear smaller groups', $AGGRO_RANGE], _
		[-9514, -6539, 'Clear smaller groups', $AGGRO_RANGE], _
		[-10988, -8177, 'Kill Necro Boss', $AGGRO_RANGE], _
		[-11388, -7827, 'Kill Necro Boss', $AGGRO_RANGE], _
		[-11291, -5987, 'Small groups north', $AGGRO_RANGE], _
		[-11380, -3787, 'Small groups north', $AGGRO_RANGE], _
		[-10641, -1714, 'Small groups north', $AGGRO_RANGE], _
		[-8659.20, -2268.30, 'Oni spawn point', $AGGRO_RANGE], _
		[-7019.81, -976.18, 'Undergrowth group', $AGGRO_RANGE], _
		[-4464.77, 780.87, 'Undergrowth group', $AGGRO_RANGE], _
		[-4464.77, 780.87, 'Back NW', $AGGRO_RANGE], _
		[-7019.81, -976.18, 'Back NW', $AGGRO_RANGE], _
		[-10575, 489, 'Back NW', $AGGRO_RANGE], _
		[-11266, 2581, 'Back NW', $AGGRO_RANGE], _
		[-10444, 4234, 'Back NW', $AGGRO_RANGE], _
		[-12820, 4153, 'Back NW', $AGGRO_RANGE], _
		[-12804, 6357, 'Oni spawn point', $AGGRO_RANGE], _
		[-12074, 8448, 'Kill Mantis', $AGGRO_RANGE], _
		[-10212.96, 10309.16, 'Kill Mantis', $AGGRO_RANGE], _
		[-8211.33, 11407.54, 'Kill Mantis', $AGGRO_RANGE], _
		[-7754.69, 9436.11, 'Oni spawn point', $AGGRO_RANGE], _
		[-6167.01, 9447.13, 'Kill Wardens', $AGGRO_RANGE], _
		[-4815.21, 10528.07, 'Kill Wardens', $AGGRO_RANGE], _
		[-5479.61, 7343.60, 'Kill Wardens', $AGGRO_RANGE], _
		[-5289.82, 4998.54, 'Kill Wardens', $AGGRO_RANGE], _
		[-2484.76, 7233.19, 'Kill Wardens', $AGGRO_RANGE], _
		[-3367.10, 9928.76, 'Kill Wardens', $AGGRO_RANGE], _
		[-3394.30, 11746.05, 'Kill Ranger Boss', $AGGRO_RANGE], _
		[-4869.57, 12948.64, 'Kill Ranger Boss', $AGGRO_RANGE], _
		[-5932.44, 13806.47, 'Kill Ranger Boss', $AGGRO_RANGE], _
		[-4848.12, 15585.97, 'Wardens + Dragon Moss', $AGGRO_RANGE], _
		[-5701.15, 16202.36, 'Back', $AGGRO_RANGE], _
		[-3141.18, 16025.75, 'Back', $AGGRO_RANGE], _
		[-787.45, 15014.48, 'Back', $AGGRO_RANGE], _
		[1462.83, 15520.20, 'Back', $AGGRO_RANGE], _
		[4282.75, 14447.79, 'Oni spawn point', $AGGRO_RANGE], _
		[4605.17, 12623.42, 'Kill Wardens', $AGGRO_RANGE], _
		[2966.67, 11883.08, 'Kill Wardens', $AGGRO_RANGE], _
		[1147.05, 9904.27, 'Kill Wardens', $AGGRO_RANGE], _
		[-1241.19, 8426.36, 'Kill Wardens', $AGGRO_RANGE], _
		[1612.73, 10091.67, 'Kill Wardens', $AGGRO_RANGE], _
		[3292.36, 10628.14, 'Kill Wardens', $AGGRO_RANGE], _
		[4957.04, 8302.28, 'Kill Wardens', $AGGRO_RANGE], _
		[7123.86, 5813.80, 'Kill Wardens', $AGGRO_RANGE], _
		[8363.76, 9446.83, 'Kill Wardens', $AGGRO_RANGE], _
		[8723.25, 11237.47, 'Kill Wardens', $AGGRO_RANGE], _
		[7363.71, 13697.35, 'Kill Wardens', $AGGRO_RANGE], _
		[10668.76, 11515.62, 'Kill Wardens', $AGGRO_RANGE], _
		[13930.39, 10779.55, 'Kill Wardens', $AGGRO_RANGE], _
		[14685.91, 7077.44, 'To Wardens', $AGGRO_RANGE], _
		[11869.74, 5679.88, 'To Wardens', $AGGRO_RANGE], _
		[8744.54, 4192.64, 'To Wardens', $AGGRO_RANGE], _
		[6187.57, 6313.87, 'To Wardens', $AGGRO_RANGE], _
		[9159.87, 3654.00, 'To Wardens', $AGGRO_RANGE], _
		[11257.36, 338.60, 'To Wardens', $AGGRO_RANGE], _
		[8844.41, 303.82, 'Undergrowth groups', $AGGRO_RANGE], _
		[5613.70, 296.42, 'Undergrowth groups', $AGGRO_RANGE], _
		[2832.80, 3850.74, 'Undergrowth groups', $AGGRO_RANGE], _
		[4588.24, 5461.12, 'More Wardens', $AGGRO_RANGE], _
		[-599.41, 3401.40, 'More Wardens', $AGGRO_RANGE], _
		[-1528.55, 5116.05, 'Path', $AGGRO_RANGE], _
		[-1292.70, 2307.54, 'Path', $AGGRO_RANGE], _
		[-2693.82, -4748.93, 'Last enemies', $AGGRO_RANGE], _
		[-454.99, -4876.88, 'Last enemies', $AGGRO_RANGE], _
		[1888.65, -4833.90, 'Last enemies', $AGGRO_RANGE], _
		[4022.13, -5717.67, 'Last enemies', $AGGRO_RANGE], _
		[3528.05, -7154.28, 'Last enemies', $AGGRO_RANGE], _
		[1103.53, -6744.78, 'Last enemies', $AGGRO_RANGE], _
		[455.56, -9067.87, 'Last enemies', $AGGRO_RANGE], _
		[2772.91, -9397.36, 'Ritualist bosses', $AGGRO_RANGE] _
	]
	
	For $i = 0 To UBound($foes) - 1
		If MoveAggroAndKillInRange($foes[$i][0], $foes[$i][1], $foes[$i][2], $foes[$i][3]) == $FAIL Then Return $FAIL
	Next
	If Not GetAreaVanquished() Then
		Error('The map has not been completely vanquished.')
		Return $FAIL
	Else
		Info('Map has been fully vanquished.')
		Return $SUCCESS
	EndIf
EndFunc