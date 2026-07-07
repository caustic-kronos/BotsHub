#CS ===========================================================================
; Author: caustic-kronos (aka Kronos, Night, Svarog)
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
#include '../../lib/GWA2_ID_Maps.au3'
#include '../../lib/GWA2_ID.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils-Agents.au3'
#include '../../lib/Utils-Console.au3'
#include '../../lib/Utils-Storage.au3'
#include '../../lib/Utils.au3'

; Improvements:


; ==== Constants ====
Global Const $SKALE_FINS_FARMER_SKILLBAR = 'OgeikysMdXuddgh7QBJG2cJdBA'
Global Const $SKALE_FINS_FARM_INFORMATIONS = 'For best results, have :' & @CRLF _
	& '- 16 in Mysticism' & @CRLF _
	& '- 12 in Scythe Mastery' & @CRLF _
	& '- A max damage scythe'
Global Const $SKALE_FINS_FARM_DURATION = 3 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($SKALE_FINS_DWARVEN_STABILITY) is better than UseSkillEx(1))
Global Const $SKALE_FINS_DWARVEN_STABILITY				= 1
Global Const $SKALE_FINS_PIOUS_RENEWAL					= 2
Global Const $SKALE_FINS_PIOUS_HASTE					= 3
Global Const $SKALE_FINS_DEATHS_CHARGE					= 4
Global Const $SKALE_FINS_DARK_PRISON					= 5
Global Const $SKALE_FINS_PIOUS_FURY						= 6
Global Const $SKALE_FINS_EREMITES_ATTACK				= 7
Global Const $SKALE_FINS_PIOUS_ASSAULT					= 8

Global $skale_fins_farm_setup = False

;~ Main method to farm Skale Fins
Func SkaleFinsFarm()
	If Not $skale_fins_farm_setup And SetupSkaleFinsFarm() == $FAIL Then Return $PAUSE

	LeaveToZehlonReach()
	Local $result = SkaleFinsFarmLoop()
	ResignAndReturnToOutpost($ID_JOKANUR_DIGGINGS)
	Return $result
EndFunc


;~ Skale Fins farm setup
Func SetupSkaleFinsFarm()
	Info('Setting up farm')
	If TravelToOutpost($ID_JOKANUR_DIGGINGS, $district_name) == $FAIL Then Return $FAIL
	SwitchMode($ID_NORMAL_MODE)
	LeaveParty()
	;~ If SetupPlayerSkaleFinsFarm() == $FAIL Then Return $FAIL
	LeaveToZehlonReach()
	UseSkillEx($SKALE_FINS_PIOUS_RENEWAL)
	PingSleep(100)
	UseSkillEx($SKALE_FINS_PIOUS_HASTE)
	MoveTo(-19800, -20150)
	Move(-20000, -20150)
	RandomSleep(1000)
	WaitMapLoading($ID_JOKANUR_DIGGINGS, 10000, 1000)
	$skale_fins_farm_setup = True
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Setting up character with proper attributes and skills
Func SetupPlayerSkaleFinsFarm()
	Info('Setting up player build skill bar')
	If DllStructGetData(GetMyAgent(), 'Primary') == $ID_DERVISH Then
		LoadSkillTemplate($SKALE_FINS_FARMER_SKILLBAR)
		RandomSleep(250)
	Else
		Warn('Should run this farm as dervish')
		Return $FAIL
	EndIf
	Return $SUCCESS
EndFunc


;~ Move out of outpost into the Flood Plains of Mahnkelon
Func LeaveToZehlonReach()
	TravelToOutpost($ID_JOKANUR_DIGGINGS, $district_name)
	While GetMapID() <> $ID_ZEHLON_REACH
		Info('Moving to Zehlon Reach')
		MoveTo(4300, 4500)
		Move(4700, 4500)
		RandomSleep(1000)
		WaitMapLoading($ID_ZEHLON_REACH, 10000, 1000)
	WEnd
EndFunc


;~ Farm loop
Func SkaleFinsFarmLoop()
	If GetMapID() <> $ID_ZEHLON_REACH Then Return $FAIL

	Local $nodes[][] = [ _
		[-18200,	-17800,	'Moving'			], _
		[-20000,	-16000,	'Moving'			], _
		[-18500,	-13000,	'Group 1'			], _
		[-18000,	-9500,	'Group 2'			], _
		[-16500,	-10000,	'Moving'			], _
		[-13500,	-9000,	'Group 3'			], _
		[-9000,		-12000,	'Group 4'			], _
		[-9500,		-9000, 	'Moving'			], _
		[-6000,		-8000, 	'Boss Group'		], _
		[-6000,		-7000, 	'Boss Group - end'	] _
	]
	For $i = 0 To UBound($nodes) - 1
		Info($nodes[$i][2])
		Local $me = GetMyAgent()
		Local $foe
		While GetDistanceToPoint($me, $nodes[$i][0], $nodes[$i][1]) > $RANGE_NEARBY
			; Fight management
			$foe = GetNearestEnemyToAgent($me, $RANGE_SPELLCAST)
			If $foe <> Null Then
				SkaleFinsFight()
			Else
				; Movement management
				SkaleFinsSpeedUp()
				FindAndOpenChests($RANGE_COMPASS, SkaleFinsSpeedUp, SkaleFinsUnblock)
				Move($nodes[$i][0], $nodes[$i][1])
				RandomSleep(1000)
			EndIf
			$me = GetMyAgent()
			If IsPlayerDead() Then Return $FAIL
		WEnd
	Next
	Return $SUCCESS
EndFunc


;~ Dervish speed up to zoom through the map
Func SkaleFinsSpeedUp()
	Local Static $piousHasteTimer = Null
	If $piousHasteTimer == Null Or TimerDiff($piousHasteTimer) > 12000 Then
		If IsRecharged($SKALE_FINS_DWARVEN_STABILITY) Then UseSkillEx($SKALE_FINS_DWARVEN_STABILITY)
		UseSkillEx($SKALE_FINS_PIOUS_RENEWAL)
		PingSleep(100)
		UseSkillEx($SKALE_FINS_PIOUS_HASTE)
		$piousHasteTimer = TimerInit()
	EndIf
EndFunc


;~ Kill a group of Skales
Func SkaleFinsFight()
	; Targetting a Frigid Skale first (if present) since they stay at range
	Local $me = GetMyAgent()
	Local $target = GetNearestAgentToAgent($me, $ID_AGENT_TYPE_NPC, $RANGE_SPIRIT, IsFrigidSkale)
	If $target == Null Then $target = GetNearestEnemyToAgent($me, $RANGE_SPELLCAST)

	While $target <> Null
		If IsFrigidSkale($target) Then
			If IsRecharged($SKALE_FINS_DEATHS_CHARGE) Then
				; Force casting Deaths Charge on target
				While IsRecharged($SKALE_FINS_DEATHS_CHARGE)
					UseSkillEx($SKALE_FINS_DEATHS_CHARGE, $target)
					If IsPlayerDead() Then Return $FAIL
				WEnd
			ElseIf IsRecharged($SKALE_FINS_DARK_PRISON) Then
				; Force casting Dark Prison on target
				While IsRecharged($SKALE_FINS_DARK_PRISON)
					UseSkillEx($SKALE_FINS_DARK_PRISON, $target)
					If IsPlayerDead() Then Return $FAIL
				WEnd
			EndIf
		EndIf
		KillSkale($target)
		$target = GetNearestEnemyToAgent($me, $RANGE_SPELLCAST)
	WEnd

	; Loooooooooot
	Info('Picking up loot')
	RandomSleep(1000)
	PickUpItems()
	Return $SUCCESS
EndFunc


;~ Focus on killing a Skale
Func KillSkale($target)
	Local $targetID = DllStructGetData($target, 'ID')
	While $target <> Null And Not GetIsDead($target) And DllStructGetData($target, 'HealthPercent') > 0 And DllStructGetData($target, 'ID') <> 0
		If IsRecharged($SKALE_FINS_PIOUS_FURY) Then
			UseSkillEx($SKALE_FINS_PIOUS_RENEWAL)
			PingSleep(100)
			UseSkillEx($SKALE_FINS_PIOUS_FURY)
			PingSleep(100)
		ElseIf IsRecharged($SKALE_FINS_EREMITES_ATTACK) Then
			UseSkillEx($SKALE_FINS_PIOUS_RENEWAL)
			PingSleep(100)
			UseSkillEx($SKALE_FINS_EREMITES_ATTACK, $target)
		ElseIf IsRecharged($SKALE_FINS_PIOUS_ASSAULT) Then
			UseSkillEx($SKALE_FINS_PIOUS_RENEWAL)
			PingSleep(100)
			UseSkillEx($SKALE_FINS_PIOUS_ASSAULT, $target)
		Else
			Attack($target)
			Sleep(500)
		EndIf
		Sleep(250)
		$target = GetAgentByID($targetID)
		If IsPlayerDead() Then Return $FAIL
	WEnd
	Return $SUCCESS
EndFunc


;~ Return True if agent is a Frigid Skale
Func IsFrigidSkale($agent)
	If DllStructGetData($agent, 'Allegiance') <> $ID_ALLEGIANCE_FOE Then Return False
	If IsNearlyEqual(DllStructGetData($agent, 'HealthPercent'), 0) Then Return False
	If GetIsDead($agent) Then Return False
	If DllStructGetData($agent, 'TypeMap') == $ID_TYPEMAP_IDLE_MINION Then Return False
	Return DllStructGetData($agent, 'ModelID') == 4422
EndFunc


;~ Function to unblocked when opening chests
Func SkaleFinsUnblock()
	If IsRecharged($SKALE_FINS_DEATHS_CHARGE) Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($SKALE_FINS_DEATHS_CHARGE, $target)
	ElseIf IsRecharged($SKALE_FINS_DARK_PRISON) Then
		Local $target = GetFurthestNPCInRangeOfCoords($ID_ALLEGIANCE_FOE, Null, Null, $RANGE_SPELLCAST)
		If $target <> Null Then UseSkillEx($SKALE_FINS_DARK_PRISON, $target)
	EndIf
EndFunc