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

#include-once
#RequireAdmin
#NoTrayIcon

#include '../lib/GWA2_Headers.au3'
#include '../lib/GWA2.au3'
#include '../lib/Utils.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $SoOFarmerSkillbar = ''
Global Const $SoOFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'Testing was done with a ROJ monk and an adapted mesmerway (1esurge replaced by a ROJ, inept replaced by blinding surge)' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded rooms' & @CRLF _
	& '45mn average in NM' & @CRLF _
	& '60mn average in HM with cons (automatically used if HM is on)'

Global Const $ID_SoO_Quest_Lost_Souls = 0x324
Global Const $ID_SoO_Torch = 22342

Global $SOO_FARM_SETUP = False
Global $SoODeathsCount = 0


;~ Main method to farm SoO
Func SoOFarm($STATUS)
	If Not $SOO_FARM_SETUP Then
		SetupSoOFarm()
		$SOO_FARM_SETUP = True
	EndIf

	If $STATUS <> 'RUNNING' Then Return 2

	Return SoOFarmLoop()
EndFunc


;~ SoO farm setup
Func SetupSoOFarm()
	Info('Setting up farm')
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Vloxs_Fall Then DistrictTravel($ID_Vloxs_Fall, $DISTRICT_NAME)

	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
	RunToShardsOfOrrDungeon()
	Info('Preparations complete')
EndFunc


;~ Run to Shards of Orr through Arbor Bay
Func RunToShardsOfOrrDungeon()
	$SoODeathsCount = 0
	Info('Making way to portal')
	MoveTo(16448, 14830)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(15827, 13368)
		Move(15450, 12680)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Arbor_Bay)
	WEnd

	AdlibRegister('SoOGroupIsAlive', 10000)

	Local $aggroRange = $RANGE_SPELLCAST + 100
	Info('Making way to Shards of Orr')
	MoveTo(16327, 11607)
	GoToNPC(GetNearestNPCToCoords(16362, 11627))
	RndSleep(250)
	Dialog(0x84)
	RndSleep(500)

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 11156, -17802, 1250)
		MoveAggroAndKill(13122, 10437, '1', $aggroRange)
		MoveAggroAndKill(10668, 6530, '2', $aggroRange)
		MoveAggroAndKill(9028, -1613, '3', $aggroRange)
		MoveAggroAndKill(8803, -5104, '4', $aggroRange)
		MoveAggroAndKill(8125, -8247, '5', $aggroRange)
		If SoOIsFailure() Then Return 1
		MoveAggroAndKill(8634, -11529, '6', $aggroRange)
		MoveAggroAndKill(9559, -13494, '7', $aggroRange)
		MoveAggroAndKill(10314, -16111, '8', $aggroRange)
		MoveAggroAndKill(11156, -17802, '9', $aggroRange)
		If SoOIsFailure() Then Return 1
	WEnd
	AdlibUnRegister('SoOGroupIsAlive')
EndFunc


;~ Farm loop
Func SoOFarmLoop()
	$SoODeathsCount = 0

	AdlibRegister('SoOGroupIsAlive', 10000)

	GetRewardRefreshAndTakeQuest()
	ClearSoOFloor1()
	ClearSoOFloor2()
	ClearSoOFloor3()

	AdlibUnRegister('SoOGroupIsAlive')
	Info('Waiting for timer end')
	Sleep(190000)
	While Not WaitMapLoading($ID_Arbor_Bay)
		Sleep(500)
	WEnd

	Info('Finished Run')
	Return 0
EndFunc


;~ Take quest rewards, refresh quest by entering dungeon and exiting it, then take quest again and reenter dungeon
Func GetRewardRefreshAndTakeQuest()
	Info('Get quest reward')
	MoveTo(11996, -17846)
	; Doubled to secure
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12056, -17882))
		RndSleep(250)
		Dialog(0x832407)
		RndSleep(500)
	Next

	Info('Get in dungeon to reset quest')
	MoveTo(11177, -17683)
	MoveTo(10218, -18864)
	Local $mapLoaded = False
	While Not $mapLoaded
		MoveTo(9519, -19968)
		Move(9250, -20200)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Shards_of_Orr_Floor_1)
	WEnd

	Info('Get out of dungeon to reset quest')
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(-15000, 8600)
		Move(-15650, 8900)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Arbor_Bay)
	WEnd

	Info('Get quest')
	MoveTo(10218, -18864)
	MoveTo(11177, -17683)
	MoveTo(11996, -17846)

	; Doubled to secure
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12056, -17882))
		RndSleep(250)
		Dialog(0x832401)
		RndSleep(500)
	Next

	Info('Talk to Shandra again if already had quest')
	; Doubled to secure
	For $i = 1 To 2
		GoToNPC(GetNearestNPCToCoords(12056, -17882))
		RndSleep(250)
		Dialog(0x832405)
		RndSleep(500)
	Next

	Info('Get back in')
	MoveTo(11177, -17683)
	MoveTo(10218, -18864)
	$mapLoaded = False
	While Not $mapLoaded
		MoveTo(9519, -19968)
		Move(9250, -20200)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Shards_of_Orr_Floor_1)
	WEnd
EndFunc


;~ Clear SoO floor 1
Func ClearSoOFloor1()
	Info('------------------------------------')
	Info('First floor')
	
	If IsHardmodeEnabled() Then UseConset()
	Local $aggroRange = $RANGE_SPELLCAST + 100

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 9232, 11483, 1250)
		UseMoraleConsumableIfNeeded()
		Info('Getting blessing')
		GoToNPC(GetNearestNPCToCoords(-11657, 10465))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(500)

		MoveTo(-11750, 9925)
		SafeMoveAggroAndKill(-10486, 9587, '1', $aggroRange)
		SafeMoveAggroAndKill(-6196, 10260, '2', $aggroRange)
		SafeMoveAggroAndKill(-4000, 12000, '3', $aggroRange)
		; Poison trap between 3 and 4
		SafeMoveAggroAndKill(-2200, 13000, '4', $aggroRange)
		SafeMoveAggroAndKill(2650, 16200, '5', $aggroRange)
		; too close to walls
		SafeMoveAggroAndKill(3350, 15400, '6', $aggroRange)
		; Poison trap between 6 and 7
		; too close to walls
		SafeMoveAggroAndKill(4200, 14325, '7', $aggroRange)
		; Poison trap between 7 and 8
		; too close to walls
		SafeMoveAggroAndKill(7600, 12500, '8', $aggroRange)
		SafeMoveAggroAndKill(9200, 12000, 'Triggering beacon 2', $aggroRange)
	WEnd

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 16134, 11781, 1250)
		UseMoraleConsumableIfNeeded()
		; too close to walls
		SafeMoveAggroAndKill(7300, 12200, '', $aggroRange)
		SafeMoveAggroAndKill(6300, 10400, 'Killing boss for key', $aggroRange)
		PickUpItems()
		SafeMoveAggroAndKill(11200, 13900, '1', $aggroRange)
		; Poison trap between 1 and 2
		FanFlagHeroes()
		MoveTo(12500, 14250)
		MoveTo(11200, 13900)
		RndSleep(2000)
		; too close to walls
		SafeMoveAggroAndKill(12500, 14250, '2', $aggroRange)
		SafeMoveAggroAndKill(13750, 15900, '3', $aggroRange)
		SafeMoveAggroAndKill(16000, 17000, '4', $aggroRange)
		SafeMoveAggroAndKill(16000, 12000, 'Triggering beacon 3', $aggroRange)
	WEnd

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 14750, 5250, 1250)
		UseMoraleConsumableIfNeeded()
		; Poison trap between 1, 2 and 3
		SafeMoveAggroAndKill(14000, 7400, '1', $aggroRange)
		SafeMoveAggroAndKill(14400, 6000, '2', $aggroRange)
		SafeMoveAggroAndKill(15000, 5300, '3', $aggroRange)
	WEnd

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		Info('Open dungeon door')
		ClearTarget()
		; Doubled to secure
		For $i = 1 To 2
			MoveTo(15041, 5475)
			RndSleep(500)
			ActionInteract()
			ActionInteract()
			RndSleep(500)
		Next

		SafeMoveAggroAndKill(18000, 1900, '1', $aggroRange)
		SafeMoveAggroAndKill(19700, 700, '2', $aggroRange)

		MoveTo(20000, 900)
		Move(20400, 1300)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Shards_of_Orr_Floor_2)
	WEnd
EndFunc


;~ Clear SoO floor 2
Func ClearSoOFloor2()
	Info('------------------------------------')
	Info('Second floor')
	If IsHardmodeEnabled() Then UseConset()
	Local $aggroRange = $RANGE_SPELLCAST + 100

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), -18725, -9171, 1250)
		UseMoraleConsumableIfNeeded()
		Info('Getting blessing')
		GoToNPC(GetNearestNPCToCoords(-14076, -19457))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(500)

		SafeMoveAggroAndKill(-14600, -16650, '1', $aggroRange)
		SafeMoveAggroAndKill(-16600, -16500, '2', $aggroRange)

		Info('Open torch chest')
		ClearTarget()
		Sleep(GetPing() + 500)

		For $i = 1 To 2
			MoveTo(-14709, -16548)
			Sleep(1500)
			ActionInteract()
			Sleep(GetPing() + 500)
			ActionInteract()
			Sleep(GetPing() + 500)
		Next

		Info('Pick up torch')
		PickUpTorch()

		SafeMoveAggroAndKill(-9300, -17300, '3', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		SafeMoveAggroAndKill(-9600, -16600, '4', $aggroRange)
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
		RndSleep(500)
		Info('Kill group')
		SafeMoveAggroAndKill(-9358, -12411, '5', $aggroRange)
		SafeMoveAggroAndKill(-10143, -11136, '6', $aggroRange)
		SafeMoveAggroAndKill(-8871, -9951, '7', $aggroRange)
		SafeMoveAggroAndKill(-7722, -11522, '8', $aggroRange)

		MoveTo(-8912, -13586)
		Sleep(500)
		Info('Pick up torch')
		PickUpTorch()

		SafeMoveAggroAndKill(-10500, -9600, '9', $aggroRange)
		SafeMoveAggroAndKill(-11000, -7800, '10', $aggroRange)
		SafeMoveAggroAndKill(-11000, -6000, '11', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		; Poison trap between 12 and 13
		SafeMoveAggroAndKill(-6900, -4200, '12', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		SafeMoveAggroAndKill(-5000, -3500, '13', $aggroRange)
		; Pick up again in case of death
		PickUpTorch()
		SafeMoveAggroAndKill(-4000, -4000, '14', $aggroRange)
		PickUpTorch()
		SafeMoveAggroAndKill(-3900, -4163, '15', $aggroRange)
		PickUpTorch()

		InteractWithTorchOrBrazierAt(-3717, -4254, 'Light up torch')
		InteractWithTorchOrBrazierAt(-8251, -3240, 'Light up brazier 1')
		InteractWithTorchOrBrazierAt(-8278, -1670, 'Light up brazier 2')

		Info('Drop torch')
		DropBundle()
		RndSleep(500)

		SafeMoveAggroAndKill(-6553, -2347, '16', $aggroRange)
		SafeMoveAggroAndKill(-7733, -2487, '17', $aggroRange)
		SafeMoveAggroAndKill(-6481, -2668, '18', $aggroRange)
		PickUpItems()
		SafeMoveAggroAndKill(-9000, -4350, '19', $aggroRange)
		; Poison trap between 19 and 20
		SafeMoveAggroAndKill(-11204, -4331, '20', $aggroRange)
		SafeMoveAggroAndKill(-11500, -8400, '21', $aggroRange)
		SafeMoveAggroAndKill(-16000, -8700, '22', $aggroRange)
		SafeMoveAggroAndKill(-17500, -9500, '23', $aggroRange)
	WEnd

	Info('Going through portal')
	Local $mapLoaded = False
	While Not $mapLoaded
		Info('Open dungeon door')
		ClearTarget()
		For $i = 1 To 3
			Sleep(GetPing() + 500)
			MoveTo(-18725, -9171)
			ActionInteract()
			Sleep(GetPing() + 500)
			ActionInteract()
		Next
		MoveTo(-18725, -9171)
		Move(-19300, -8200)
		RndSleep(2000)
		$mapLoaded = WaitMapLoading($ID_Shards_of_Orr_Floor_3)
	WEnd
EndFunc


;~ Clear SoO floor 3
Func ClearSoOFloor3()
	Info('------------------------------------')
	Info('Third floor')
	If IsHardmodeEnabled() Then UseConset()
	Local $aggroRange = $RANGE_SPELLCAST + 100

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 1100, 7100, 1250)
		UseMoraleConsumableIfNeeded()
		Info('Getting blessing')
		GoToNPC(GetNearestNPCToCoords(17544, 18810))
		RndSleep(250)
		Dialog(0x84)
		RndSleep(500)

		SafeMoveAggroAndKill(16000, 18400, '1', $aggroRange)
		SafeMoveAggroAndKill(10000, 19425, '2', $aggroRange)
		; Poison trap between 2 and 3
		SafeMoveAggroAndKill(9600, 18700, '3', $aggroRange)
		SafeMoveAggroAndKill(9100, 18000, '4', $aggroRange)
		SafeMoveAggroAndKill(9000, 17000, '5', $aggroRange)
		SafeMoveAggroAndKill(8000, 15000, '6', $aggroRange)
		SafeMoveAggroAndKill(4000, 9200, '7', $aggroRange)
		SafeMoveAggroAndKill(1800, 7500, '8', $aggroRange)
		SafeMoveAggroAndKill(2300, 8000, '9', $aggroRange)
		SafeMoveAggroAndKill(1100, 7100, '10', $aggroRange)
	WEnd

	While $SoODeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), -9202, 6165, 1250)
		UseMoraleConsumableIfNeeded()
		SafeMoveAggroAndKill(-2300, 8000, 'Triggering beacon 2', $aggroRange)
		SafeMoveAggroAndKill(-4500, 6500, '1', $aggroRange)
		SafeMoveAggroAndKill(-6523, 5533, '2', $aggroRange)
		SafeMoveAggroAndKill(-10000, 3400, '3', $aggroRange)
		SafeMoveAggroAndKill(-11500, 3500, '4', $aggroRange)

		Info('Run time, fun time')
		SafeMoveAggroAndKill(-4723, 6703, '5', $aggroRange)
		SafeMoveAggroAndKill(-1337, 7825, '6', $aggroRange)
		SafeMoveAggroAndKill(2913, 8190, '7', $aggroRange)
		SafeMoveAggroAndKill(5846, 11037, '8', $aggroRange)
		SafeMoveAggroAndKill(9796, 18960, '9', $aggroRange)
		SafeMoveAggroAndKill(14068, 19549, '10', $aggroRange)

		Info('Open torch chest')
		ClearTarget()
		For $i = 1 To 2
			Sleep(GetPing() + 500)
			MoveTo(16134, 17590)
			Sleep(1500)
			ActionInteract()
			Sleep(GetPing() + 500)
			ActionInteract()
			Sleep(GetPing() + 1000)
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
		RndSleep(500)

		Info('Keyboss')
		SafeMoveAggroAndKill(-11600, 2400, '14', $aggroRange)
		SafeMoveAggroAndKill(-10000, 3000, '15', $aggroRange)

		PickUpItems()

		SafeMoveAggroAndKill(-9200, 6000, '16', $aggroRange)
	WEnd

	$aggroRange = $RANGE_SPELLCAST + 300

	Local $questState = 1
	While $SoODeathsCount < 6 And $questState <> 3
		Info('Open dungeon door')
		ClearTarget()

		For $i = 1 To 2
			Sleep(GetPing() + 500)
			MoveTo(-9214, 6323)
			Sleep(1500)
			ActionInteract()
			Sleep(GetPing() + 500)
			ActionInteract()
		Next

		Info('Boss room')
		UseMoraleConsumableIfNeeded()
		; Poison trap between 1 2 and 3
		SafeMoveAggroAndKill(-9850, 7600, '1', $aggroRange)
		SafeMoveAggroAndKill(-8650, 9200, '2', $aggroRange)
		SafeMoveAggroAndKill(-9150, 10250, '3', $aggroRange)
		SafeMoveAggroAndKill(-9450, 10550, '4', $aggroRange)
		MoveTo(-10000, 11150)
		SafeMoveAggroAndKill(-13300, 13550, '5', $aggroRange)
		MoveTo(13900, 13500)
		; Fire traps between 5 6 and 7
		SafeMoveAggroAndKill(-15250, 15900, '6', $aggroRange)
		Info('Boss fight, go in and move around to make sure its aggroed')
		SafeMoveAggroAndKill(-16300, 16600, '7', $aggroRange)
		SafeMoveAggroAndKill(-15850, 17500, '8', $aggroRange)
		$questState = DllStructGetData(GetQuestByID($ID_SoO_Quest_Lost_Souls), 'LogState')
		Sleep(1000)
	WEnd

	; Doubled to try securing the looting
	For $i = 1 To 2
		MoveTo(-15800, 16950)
		Info('Opening Fendis chest')
		TargetNearestItem()
		ActionInteract()
		RndSleep(2500)
		PickUpItems()
	Next
	MoveTo(-15700, 17150)
EndFunc


;~ Func to interact with torches and braziers
Func InteractWithTorchOrBrazierAt($X, $Y, $message)
	Info($message)
	MoveTo($X, $Y)
	Sleep(250)
	ActionInteract()
	Sleep(GetPing() + 1000)
	ActionInteract()
	Sleep(GetPing() + 1000)
	ActionInteract()
	Sleep(250)
EndFunc


;~ Did run fail ?
Func SoOIsFailure()
	If ($SoODeathsCount > 5) Then
		AdlibUnregister('SoOGroupIsAlive')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the groupIsAlive variable, this function is run on a fixed timer
Func SoOGroupIsAlive()
	$SoODeathsCount += IsGroupAlive() ? 0 : 1
EndFunc


;~ Pick up the torch
Func PickUpTorch()
	Local $agent
	Local $item
	Local $deadlock
	For $i = 1 To GetMaxAgents()
		$agent = GetAgentByID($i)
		If (DllStructGetData($agent, 'Type') <> 0x400) Then ContinueLoop
		$item = GetItemByAgentID($i)
		If (DllStructGetData(($item), 'ModelID') == $ID_SoO_Torch) Then
			Info('Torch: (' & Round(DllStructGetData($agent, 'X')) & ', ' & Round(DllStructGetData($agent, 'Y')) & ')')
			PickUpItem($item)
			$deadlock = TimerInit()
			While GetAgentExists($i)
				RndSleep(500)
				If GetIsDead() Then Return
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