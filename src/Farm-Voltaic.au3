; Author: caustic-kronos (aka Kronos, Night, Svarog)
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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2.au3'
#include '../lib/GWA2_ID.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $VoltaicFarmerSkillbar = ''
Global Const $VoltaicFarmInformations = 'For best results, have :' & @CRLF _
	& '- completed EotN story once' & @CRLF _
	& '- a full and efficient 7-hero-team' & @CRLF _
	& '- a hero with Frozen Soil' & @CRLF _
	& '- a build that can be run from skill 1 to 8 (no complex combos or conditional skills)' & @CRLF _
	& 'In NM, bot takes 13min (with cons), 15min (without cons) on average' & @CRLF _
	& 'Not tested in HM.'
Global Const $VOLTAIC_FARM_DURATION = 16 * 60 * 1000

Global $VOLTAIC_FARM_SETUP = False
Global $voltaicDeathsCount = 0

;~ Main method to farm Voltaic
Func VoltaicFarm($STATUS)
	If Not $VOLTAIC_FARM_SETUP Then
		SetupVoltaicFarm()
		$VOLTAIC_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return VoltaicFarmLoop()
EndFunc


;~ Voltaic farm setup
Func SetupVoltaicFarm()
	Info('Setting up farm')
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func VoltaicFarmLoop()
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Umbral_Grotto Then DistrictTravel($ID_Umbral_Grotto, $DISTRICT_NAME)

	$voltaicDeathsCount = 0
	Info('Making way to portal')
	MoveTo(-22846, 9056)
	Move(-22735, 6339)
	WaitMapLoading($ID_Verdant_Cascades)

	AdlibRegister('VoltaicGroupIsAlive', 10000)

	Local $timer = TimerInit()
	Local $aggroRange = $RANGE_SPELLCAST + 200
	MoveAggroAndKill(-19887, 6074, '1', $aggroRange)
	Info('Making way to Slavers')
	MoveAggroAndKill(-10273, 3251, '2', $aggroRange)
	MoveAggroAndKill(-6878, -329, '3', $aggroRange)
	MoveAggroAndKill(-3041, -3446, '4', $aggroRange)
	MoveAggroAndKill(3571, -9501, '5', $aggroRange)
	MoveAggroAndKill(10764, -6448, '6', $aggroRange)
	MoveAggroAndKill(13063, -4396, '7', $aggroRange)
	If IsFailure() Then Return 1
	Info('At the Troll Bridge - TROLL TOLL')
	MoveAggroAndKill(18054, -3275, '8', $aggroRange)
	MoveAggroAndKill(20966, -6476, '9', $aggroRange)
	MoveAggroAndKill(25298, -9456, '10', $aggroRange)
	If IsFailure() Then Return 1
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
	RndSleep(250)
	Dialog(132)
	RndSleep(500)

	If IsHardmodeEnabled() Then UseCons()

	Sleep(1000)
	While $voltaicDeathsCount < 6 And Not IsInRange (-18500, -8000, 1250)
		; Waiting to be alive before retrying
		While Not IsGroupAlive()
			Sleep(2000)
		WEnd
		UseSummon()
		SafeMoveAggroAndKill(-13500, -15750, 'In front of the door', $aggroRange)
		SafeMoveAggroAndKill(-12500, -15000, 'Before the bridge', $aggroRange)
		SafeMoveAggroAndKill(-10400, -14800, 'After the bridge', $aggroRange)
		SafeMoveAggroAndKill(-11500, -13300, 'First group', $aggroRange)
		SafeMoveAggroAndKill(-13400, -11500, 'Second group', $aggroRange)
		SafeMoveAggroAndKill(-13700, -9550, 'Third group', $aggroRange)
		SafeMoveAggroAndKill(-14100, -8600, 'Fourth group', $aggroRange)
		SafeMoveAggroAndKill(-15000, -7500, 'Fourth group, again', $aggroRange)
		SafeMoveAggroAndKill(-16500, -8000, 'Fifth group', $aggroRange)
		SafeMoveAggroAndKill(-18500, -8000, 'To the shrine', $aggroRange)
		If IsFailure() Then Return 1
	WEnd
	While $voltaicDeathsCount < 6 And Not IsInRange (-17500, -14250, 1250)
		; Waiting to be alive before retrying
		While Not IsGroupAlive()
			Sleep(2000)
		WEnd
		UseSummon()
		SafeMoveAggroAndKill(-18500, -11500, 'Pre-Boss group', $aggroRange)
		SafeMoveAggroAndKill(-17700, -12500, 'Boss group', $aggroRange)
		SafeMoveAggroAndKill(-17500, -14250, 'Final group', $aggroRange)
		If IsFailure() Then Return 1
	WEnd
	; Chest
	Move(-17500, -14250)
	Info('Opening chest')
	Sleep(5000)
	TargetNearestItem()
	ActionInteract()
	Sleep(2500)
	PickUpItems()
	Info('Finished Run')
	Return 0
EndFunc


;~ Use all consumables
Func UseCons()
	UseConsumable($ID_Armor_of_Salvation)
	UseConsumable($ID_Essence_of_Celerity)
	UseConsumable($ID_Grail_of_Might)
EndFunc


;~ Use the legionnaire summoning crystal if available
Func UseSummon()
	UseConsumable($ID_Legionnaire_Summoning_Crystal, True)
EndFunc


;~ Did run fail ?
Func IsFailure()
	If ($voltaicDeathsCount > 5) Then
		AdlibUnregister('VoltaicGroupIsAlive')
		Notice('Group wiped.')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the voltaicDeathsCount variable, this function is run on a fixed timer
Func VoltaicGroupIsAlive()
	$voltaicDeathsCount += IsGroupAlive() ? 0 : 1
EndFunc


;~ Is in range of coordinates
Func IsInRange($X, $Y, $range)
	Local $myX = DllStructGetData(GetMyAgent(), 'X')
	Local $myY = DllStructGetData(GetMyAgent(), 'Y')

	If ($myX < $X + $range) And ($myX > $X - $range) And ($myY < $Y + $range) And ($myY > $Y - $range) Then
		Return True
	EndIf
	Return False
EndFunc