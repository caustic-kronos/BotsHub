#CS ===========================================================================
; Author: TDawg
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

#include '../../lib/GWA2_Headers.au3'
#include '../../lib/GWA2.au3'
#include '../../lib/Utils.au3'

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $SOO_FARM_INFORMATIONS = 'For best results, don''t cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1esurge replaced by a ROJ, inept replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '45mn average in NM' & @CRLF _
	& '60mn average in HM with cons (automatically used if HM is on)'

Global Const $ID_SOO_TORCH = 22342
Global Const $SOO_AGGRO_RANGE = $RANGE_SPELLCAST + 100

Global Const $MAX_SOO_FARM_DURATION = 80 * 60 * 1000

Global $soo_farm_setup = False


;~ Main method to farm SoO
Func SoOFarm()
	If Not $soo_farm_setup Then SetupSoOFarm()
	Return SoOFarmLoop()
EndFunc


;~ SoO farm setup
Func SetupSoOFarm()
	Info('Setting up farm')
	TravelToOutpost($ID_VLOXS_FALLS, $district_name)
	SwitchToHardModeIfEnabled()
	While Not $soo_farm_setup
		If RunToShardsOfOrrDungeon() == $FAIL Then ContinueLoop
		$soo_farm_setup = True
	WEnd
	Info('Preparations complete')
	Return $SUCCESS
EndFunc


;~ Run to Shards of Orr through Arbor Bay
Func RunToShardsOfOrrDungeon()
	TravelToOutpost($ID_VLOXS_FALLS, $district_name)
	ResetFailuresCounter()

	Info('Making way to portal')
	MoveTo(16448, 14830)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(15827, 13368)
		Move(15450, 12680)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_ARBOR_BAY)
	WEnd

	AdlibRegister('TrackPartyStatus', 10000)

	Info('Making way to Shards of Orr')
	MoveTo(16327, 11607)
	GoToNPC(GetNearestNPCToCoords(16362, 11627))
	RandomSleep(250)
	Dialog(0x84)
	RandomSleep(500)

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 11156, -17802, 1250)
		MoveAggroAndKillInRange(13122, 10437, '1', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(10668, 6530, '2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(11891, -224, '3', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(8803, -5104, '4', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(8125, -8247, '5', $SOO_AGGRO_RANGE)
		; Can't return here - we need to deregister adlib first
		If IsRunFailed() Then ExitLoop
		MoveAggroAndKillInRange(8634, -11529, '6', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(9559, -13494, '7', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(10314, -16111, '8', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(11156, -17802, '9', $SOO_AGGRO_RANGE)
	WEnd

	AdlibUnRegister('TrackPartyStatus')
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Farm loop
Func SoOFarmLoop()
	GetRewardRefreshAndTakeSoOQuest()
	ResetFailuresCounter()
	AdlibRegister('TrackPartyStatus', 10000)
	; Failure return delayed after adlib function deregistered
	If (ClearSoOFloor1() == $FAIL Or ClearSoOFloor2() == $FAIL Or ClearSoOFloor3() == $FAIL) Then $soo_farm_setup = False
	AdlibUnRegister('TrackPartyStatus')
	If Not $soo_farm_setup Then Return $FAIL

	Info('Waiting for timer end')
	Sleep(190000)
	While Not WaitMapLoading($ID_ARBOR_BAY)
		Sleep(500)
	WEnd

	Info('Finished Run')
	Return $SUCCESS
EndFunc


;~ Take quest rewards, refresh quest by entering dungeon and exiting it, then take quest again and reenter dungeon
Func GetRewardRefreshAndTakeSoOQuest()
	Info('Get quest reward')
	MoveTo(11996, -17846)
	; Doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12056, -17882))
		RandomSleep(250)
		Dialog(0x832407)
		RandomSleep(500)
	Next

	Info('Get in dungeon to reset quest')
	MoveTo(11177, -17683)
	MoveTo(10218, -18864)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(9519, -19968)
		Move(9250, -20200)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SHARDS_OF_ORR_LVL_1)
	WEnd

	Info('Get out of dungeon to reset quest')
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(-15000, 8600)
		Move(-15650, 8900)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_ARBOR_BAY)
	WEnd

	Info('Get quest')
	MoveTo(10218, -18864)
	MoveTo(11177, -17683)
	MoveTo(11996, -17846)

	; Doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12056, -17882))
		RandomSleep(250)
		Dialog(0x832401)
		RandomSleep(500)
	Next

	Info('Talk to Shandra again if already had quest')
	; Doubled to secure bot
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12056, -17882))
		RandomSleep(250)
		Dialog(0x832405)
		RandomSleep(500)
	Next

	Info('Get back in')
	MoveTo(11177, -17683)
	MoveTo(10218, -18864)
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(9519, -19968)
		Move(9250, -20200)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SHARDS_OF_ORR_LVL_1)
	WEnd
EndFunc


;~ Clear SoO floor 1
Func ClearSoOFloor1()
	Info('------------------------------------')
	Info('First floor')

	If IsHardmodeEnabled() Then UseConset()
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 9232, 11483, 1250)
		If CheckStuck('SoO Floor 1 - First loop', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		Info('Getting blessing')
		GoToNPC(GetNearestNPCToCoords(-11657, 10465))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(500)

		MoveTo(-11750, 9925)
		MoveAggroAndKillInRange(-10486, 9587, '1', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6196, 10260, '2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-4000, 12000, '3', $SOO_AGGRO_RANGE)
		; Poison trap between 3 and 4
		MoveAggroAndKillInRange(-2200, 13000, '4', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(2650, 16200, '5', $SOO_AGGRO_RANGE)
		; too close to walls
		MoveAggroAndKillInRange(3350, 15400, '6', $SOO_AGGRO_RANGE)
		; Poison trap between 6 and 7
		; too close to walls
		MoveAggroAndKillInRange(4200, 14325, '7', $SOO_AGGRO_RANGE)
		; Poison trap between 7 and 8
		; too close to walls
		MoveAggroAndKillInRange(7600, 12500, '8', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(9200, 12000, 'Triggering beacon 2', $SOO_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 16134, 11781, 1250)
		If CheckStuck('SoO Floor 1 - Second loop', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		; too close to walls
		MoveAggroAndKillInRange(7300, 12200, '', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(6300, 10400, 'Killing boss for key', $SOO_AGGRO_RANGE)
		PickUpItems()
		MoveAggroAndKillInRange(11200, 13900, '1', $SOO_AGGRO_RANGE)
		; Poison trap between 1 and 2
		FanFlagHeroes()
		MoveTo(12500, 14250)
		MoveTo(11200, 13900)
		RandomSleep(2000)
		CancelAllHeroes()
		; too close to walls
		MoveAggroAndKillInRange(12500, 14250, '2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(13750, 15900, '3', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(16000, 17000, '4', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(16000, 12000, 'Triggering beacon 3', $SOO_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 14750, 5250, 1250)
		If CheckStuck('SoO Floor 1 - Third loop', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		; Poison trap between 1, 2 and 3
		MoveAggroAndKillInRange(14000, 7400, '1', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(14400, 6000, '2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(15000, 5300, '3', $SOO_AGGRO_RANGE)
	WEnd

	Info('Going through portal')
	Local $mapLoaded = False
	While Not IsRunFailed() And Not $mapLoaded
		If CheckStuck('SoO Floor 1 - Opening door', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		Info('Open dungeon door')
		ClearTarget()
		; Doubled to secure bot
		For $i = 1 To 2
			MoveTo(15041, 5475)
			TargetNearestItem()
			RandomSleep(500)
			ActionInteract()
			ActionInteract()
			RandomSleep(500)
		Next

		FlagMoveAggroAndKillInRange(18000, 1900, '1', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(19700, 700, '2', $SOO_AGGRO_RANGE)

		MoveTo(20000, 900)
		Move(20400, 1300)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SHARDS_OF_ORR_LVL_2)
	WEnd
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Clear SoO floor 2
Func ClearSoOFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()

	Local $firstRoomfirstTime = True
	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -11000, -6000, 1250)
		If CheckStuck('SoO Floor 2 - First Room', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		Info('Getting blessing')
		GoToNPC(GetNearestNPCToCoords(-14076, -19457))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(500)

		If Not $firstRoomfirstTime Then
			MoveTo(-10033, -12701)
			RandomSleep(500)
			MoveTo(-9600, -16600)
			RandomSleep(500)
			MoveTo(-9300, -17300)
			RandomSleep(500)
			MoveTo(-14076, -19457)
			RandomSleep(500)
		EndIf

		MoveAggroAndKillInRange(-14600, -16650, '1', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16600, -16500, '2', $SOO_AGGRO_RANGE)

		Info('Open torch chest')
		ClearTarget()
		Sleep(500)

		; Doubled to secure bot
		For $i = 1 To 2
			MoveTo(-14709, -16548)
			TargetNearestItem()
			RandomSleep(1500)
			ActionInteract()
			RandomSleep(500)
			ActionInteract()
			RandomSleep(500)
		Next

		Info('Pick up torch')
		PickUpTorch()

		MoveAggroAndKillInRange(-9300, -17300, '3', $SOO_AGGRO_RANGE)
		; Pick up again in case of death
		PickUpTorch()
		MoveAggroAndKillInRange(-9600, -16600, '4', $SOO_AGGRO_RANGE)
		; Pick up again in case of death
		PickUpTorch()
		InteractWithTorchOrBrazierAt(-11242, -14612, 'Light up torch')

		Info('Get in torch room')
		MoveTo(-10033, -12701)
		InteractWithTorchOrBrazierAt(-11019, -11550, 'Lighting brazier 1')
		InteractWithTorchOrBrazierAt(-9028, -9021, 'Lighting brazier 2')
		InteractWithTorchOrBrazierAt(-6805, -11511, 'Lighting brazier 3')
		InteractWithTorchOrBrazierAt(-8984, -13842, 'Lighting brazier 4')

		Info('Drop torch')
		DropBundle()
		RandomSleep(500)
		Info('Kill group')
		FlagMoveAggroAndKillInRange(-9358, -12411, '5', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(-10143, -11136, '6', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(-8871, -9951, '7', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(-7722, -11522, '8', $SOO_AGGRO_RANGE)

		MoveTo(-8912, -13586)
		Sleep(500)
		Info('Pick up torch')
		PickUpTorch()

		MoveAggroAndKillInRange(-10500, -9600, '9', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11000, -7800, '10', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11000, -6000, '11', $SOO_AGGRO_RANGE)
		; Pick up again in case of death
		PickUpTorch()
	WEnd

	Local $secondRoomfirstTime = True
	Local $mapLoaded = False
	While Not IsRunFailed() And Not $mapLoaded
		If CheckStuck('SoO Floor 2 - Second Room', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		While Not IsPartyCurrentlyAlive()
			Sleep(2000)
		WEnd
		UseMoraleConsumableIfNeeded()

		If IsAgentInRange(GetMyAgent(), -14076, -19457, 1250) Then
			Info('Group wiped, moving from shrine to torch room 1 exit')
			MoveTo(-9300, -17300)
			RandomSleep(500)
			MoveTo(-9600, -16600)
			RandomSleep(500)
			MoveTo(-10033, -12701)
			RandomSleep(500)
			MoveTo(-10500, -9600)
			RandomSleep(500)
			MoveTo(-11000, -6000)
			RandomSleep(500)
			PickUpTorch()
		EndIf

		If Not $secondRoomfirstTime Then
			MoveAggroAndKillInRange(-17500, -9500, 'If not first loop, run back from end of floor to torch room 1', $SOO_AGGRO_RANGE)
			MoveTo(-16000, -8700)
			RandomSleep(500)
			MoveTo(-11500, -8400)
			RandomSleep(500)
			MoveTo(-11204, -4331)
			RandomSleep(500)
			MoveTo(-10500, -9600)
			RandomSleep(500)
			MoveTo(-8912, -13586)
			RandomSleep(500)
			Info('Pick up torch')
			PickUpTorch()
			MoveTo(-10500, -9600)
			RandomSleep(500)
			MoveTo(-11000, -6000)
			RandomSleep(500)
			PickUpTorch()
		EndIf

		; Poison trap between 12 and 13
		MoveAggroAndKillInRange(-6900, -4200, '12', $SOO_AGGRO_RANGE)
		; Pick up again in case of death
		PickUpTorch()
		MoveAggroAndKillInRange(-5000, -3500, '13', $SOO_AGGRO_RANGE)
		; Pick up again in case of death
		PickUpTorch()
		MoveAggroAndKillInRange(-4000, -4000, '14', $SOO_AGGRO_RANGE)
		PickUpTorch()
		MoveAggroAndKillInRange(-3900, -4163, '15', $SOO_AGGRO_RANGE)
		PickUpTorch()

		InteractWithTorchOrBrazierAt(-3717, -4254, 'Light up torch')
		InteractWithTorchOrBrazierAt(-8251, -3240, 'Light up brazier 1')
		InteractWithTorchOrBrazierAt(-8278, -1670, 'Light up brazier 2')

		Info('Drop torch')
		DropBundle()
		RandomSleep(500)

		FlagMoveAggroAndKillInRange(-6553, -2347, '16', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(-7733, -2487, '17', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(-6481, -2668, '18', $SOO_AGGRO_RANGE)
		PickUpItems()
		MoveAggroAndKillInRange(-9000, -4350, '19', $SOO_AGGRO_RANGE)
		; Poison trap between 19 and 20
		MoveAggroAndKillInRange(-11204, -4331, '20', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11500, -8400, '21', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-16000, -8700, '22', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-17500, -9500, '23', $SOO_AGGRO_RANGE)

		$secondRoomfirstTime = False
		Info('Going through portal')
		If CheckStuck('SoO Floor 2 - Opening door', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		Info('Open dungeon door')
		ClearTarget()
		; Tripled to secure bot
		For $i = 1 To 3
			MoveTo(-18725, -9171)
			TargetNearestItem()
			ActionInteract()
			RandomSleep(500)
			ActionInteract()
			RandomSleep(500)
		Next
		MoveTo(-18725, -9171)
		Move(-19300, -8200)
		RandomSleep(2000)
		$mapLoaded = WaitMapLoading($ID_SHARDS_OF_ORR_LVL_3)
	WEnd
	Return IsRunFailed() ? $FAIL : $SUCCESS
EndFunc


;~ Clear SoO floor 3
Func ClearSoOFloor3()
	Info('------------------------------------')
	Info('Third floor')
	If IsHardmodeEnabled() Then UseConset()

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), 1100, 7100, 1250)
		If CheckStuck('SoO Floor 3 - First loop', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		Info('Getting blessing')
		GoToNPC(GetNearestNPCToCoords(17544, 18810))
		RandomSleep(250)
		Dialog(0x84)
		RandomSleep(500)

		FlagMoveAggroAndKillInRange(16337, 16366, '1', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(16313, 17997, '2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(16000, 18400, '3', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(10000, 19425, '4', $SOO_AGGRO_RANGE)
		; Poison trap between 4 and 5
		MoveAggroAndKillInRange(9600, 18700, '5', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(9100, 18000, '6', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(9000, 17000, '7', $SOO_AGGRO_RANGE)
		FlagMoveAggroAndKillInRange(8000, 15000, '8', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(4000, 9200, '9', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(1800, 7500, '10', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(2300, 8000, '11', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(1100, 7100, '12', $SOO_AGGRO_RANGE)
	WEnd

	While Not IsRunFailed() And Not IsAgentInRange(GetMyAgent(), -8650, 9200, 1250)
		If CheckStuck('SoO Floor 3 - Second loop', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL
		UseMoraleConsumableIfNeeded()
		MoveAggroAndKillInRange(-2300, 8000, 'Triggering beacon 2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-4500, 6500, '1', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-6523, 5533, '2', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10000, 3400, '3', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-11500, 3500, '4', $SOO_AGGRO_RANGE)

		Info('Run time, fun time')
		MoveAggroAndKillInRange(-4723, 6703, '5', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-1337, 7825, '6', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(2913, 8190, '7', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(5846, 11037, '8', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(9796, 18960, '9', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(14068, 19549, '10', $SOO_AGGRO_RANGE)

		Info('Open torch chest')
		ClearTarget()
		; Doubled to secure bot
		For $i = 1 To 2
			RandomSleep(500)
			MoveTo(16134, 17590)
			TargetNearestItem()
			RandomSleep(1500)
			ActionInteract()
			RandomSleep(500)
			ActionInteract()
			RandomSleep(1000)
		Next
		Info('Pick up torch')
		PickUpTorch()

		InteractWithTorchOrBrazierAt(15692, 17111, 'Light up torch')
		InteractWithTorchOrBrazierAt(12969, 19842, 'Light up brazier 1')
		MoveTo(9657, 18783)
		InteractWithTorchOrBrazierAt(8236, 16950, 'Light up brazier 2')
		MoveTo(8000, 14708)
		MoveTo(6102, 12590)
		InteractWithTorchOrBrazierAt(5549, 9920, 'Light up brazier 3')
		InteractWithTorchOrBrazierAt(-536, 6109, 'Light up brazier 4')
		MoveTo(-2346, 7961)
		MoveTo(-4329, 6606)
		InteractWithTorchOrBrazierAt(-3814, 5599, 'Light up brazier 5')
		InteractWithTorchOrBrazierAt(-4959, 7558, 'Light up brazier 6')
		InteractWithTorchOrBrazierAt(-7532, 4536, 'Light up brazier 7')
		InteractWithTorchOrBrazierAt(-8814, 3727, 'Light up brazier 8')
		InteractWithTorchOrBrazierAt(-11044, 482, 'Light up brazier 9')
		InteractWithTorchOrBrazierAt(-12686, 2945, 'Light up brazier 10')

		Info('Drop torch')
		DropBundle()
		RandomSleep(500)

		Info('Keyboss')
		MoveAggroAndKillInRange(-11600, 2400, '14', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-10000, 3000, '15', $SOO_AGGRO_RANGE)

		PickUpItems()

		MoveAggroAndKillInRange(-9200, 6000, '16', $SOO_AGGRO_RANGE)

		Info('Open dungeon door')
		ClearTarget()

		; Doubled to secure bot
		For $i = 1 To 2
			RandomSleep(500)
			MoveTo(-9214, 6323)
			TargetNearestItem()
			Sleep(1500)
			ActionInteract()
			RandomSleep(500)
			ActionInteract()
		Next

		MoveAggroAndKillInRange(-9850, 7600, 'Added extra move to force going past door before endloop 1', $SOO_AGGRO_RANGE)
		MoveAggroAndKillInRange(-8650, 9200, 'Added extra move to force going past door before endloop 2', $SOO_AGGRO_RANGE)
	WEnd

	Local $largerSoOAggroRange = $RANGE_SPELLCAST + 300
	Local $questState = 999
	While Not IsRunFailed() And $questState <> 3
		If CheckStuck('SoO Floor 3 - Third loop', $MAX_SOO_FARM_DURATION) == $FAIL Then Return $FAIL

		MoveAggroAndKillInRange(-9850, 7600, 'Going back to secure door opening in case run failed 1', $largerSoOAggroRange)
		MoveAggroAndKillInRange(-9200, 6000, 'Going back to secure door opening in case run failed 2', $largerSoOAggroRange)

		Info('Boss room')
		UseMoraleConsumableIfNeeded()
		; Poison trap between 1 2 and 3
		MoveAggroAndKillInRange(-9850, 7600, '1', $largerSoOAggroRange)
		MoveAggroAndKillInRange(-8650, 9200, '2', $largerSoOAggroRange)
		MoveAggroAndKillInRange(-9150, 10250, '3', $largerSoOAggroRange)
		MoveAggroAndKillInRange(-9450, 10550, '4', $largerSoOAggroRange)
		MoveTo(-10000, 11150)
		MoveAggroAndKillInRange(-13300, 13550, '5', $largerSoOAggroRange)
		MoveTo(13900, 13500)
		; Fire traps between 5 6 and 7
		FlagMoveAggroAndKillInRange(-15250, 15900, '6', $largerSoOAggroRange)
		Info('Boss fight, go in and move around to make sure its aggroed')
		FlagMoveAggroAndKillInRange(-16300, 16600, '7', $largerSoOAggroRange)
		FlagMoveAggroAndKillInRange(-15850, 17500, '8', $largerSoOAggroRange)

		$questState = DllStructGetData(GetQuestByID($ID_QUEST_LOST_SOULS), 'LogState')
		Info('Quest state end of boss loop : ' & $questState)
		Sleep(1000)
	WEnd
	If IsRunFailed() Then Return $FAIL

	; Doubled to try securing the looting
	For $i = 1 To 2
		MoveTo(-15800, 16950)
		Info('Opening Fendis chest')
		TargetNearestItem()
		ActionInteract()
		RandomSleep(2500)
		PickUpItems()
	Next
	MoveTo(-15700, 17150)
	Return $SUCCESS
EndFunc


;~ Function to interact with torches and braziers
Func InteractWithTorchOrBrazierAt($X, $Y, $message)
	Info($message)
	MoveTo($X, $Y)
	TargetNearestItem()
	Sleep(250)
	ActionInteract()
	RandomSleep(1000)
	ActionInteract()
	RandomSleep(1000)
	ActionInteract()
	Sleep(250)
EndFunc


;~ Pick up the torch
Func PickUpTorch()
	Local $agents = GetAgentArray($ID_AGENT_TYPE_ITEM)
	Local $deadlock
	For $agent In $agents
		Local $agentID = DllStructGetData($agent, 'ID')
		Local $item = GetItemByAgentID($agentID)
		If (DllStructGetData(($item), 'ModelID') == $ID_SOO_TORCH) Then
			Info('Torch: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			$deadlock = TimerInit()
			While GetAgentExists($agentID)
				RandomSleep(500)
				If IsPlayerDead() Then Return False
				If TimerDiff($deadlock) > 20000 Then
					Error('Could not get torch at (' & DllStructGetData($agent, 'X') & ', ' & DllStructGetData($agent, 'Y') & ')')
					Return False
				EndIf
			WEnd
			Return True
		EndIf
	Next
	Return False
EndFunc