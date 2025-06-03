; Author: Kronos ?
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
Global Const $FoWFarmerSkillbar = ''
Global Const $FoWFarmInformations = 'For best results, dont cheap out on heroes' & @CRLF _
	& 'I recommend using a range build to avoid pulling extra groups in crowded areas' & @CRLF _
	& 'XXmn average in NM' & @CRLF _
	& 'YYmn  average in HM with consets (automatically used if HM is on)'

Global $FOW_FARM_SETUP = False
Global $FoWDeathsCount = 0
Global Const $ID_FoW_Quest = 0x000


;~ Main method to farm FoW
Func FoWFarm($STATUS)
	If Not $FOW_FARM_SETUP Then
		SetupFoWFarm()
		$FOW_FARM_SETUP = True
	EndIf

	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Temple_of_the_Ages Then DistrictTravel($ID_Temple_of_the_Ages, $DISTRICT_NAME)
	Info('Making way to Balthazar statue')
	MoveTo(-2500, 18700)
	SendChat('/kneel', '')
	RndSleep(3000)
	GoToNPC(GetNearestNPCToCoords(-2500, 18700))
	RndSleep(250)
	Dialog(0x85)
	RndSleep(500)
	Dialog(0x86)
	RndSleep(500)
	WaitMapLoading($ID_Fissure_of_Woe)

	If $STATUS <> 'RUNNING' Then Return 2

	Return FoWFarmLoop()
EndFunc


;~ FoW farm setup
Func SetupFoWFarm()
	Info('Setting up farm')
	; Make group
	If IsHardmodeEnabled() Then
		SwitchMode($ID_HARD_MODE)
	Else
		SwitchMode($ID_NORMAL_MODE)
	EndIf
	Info('Preparations complete')
EndFunc


;~ Farm loop
Func FoWFarmLoop()
	AdlibRegister('FoWGroupIsAlive', 10000)
	Local $aggroRange = $RANGE_SPELLCAST + 100
	$FoWDeathsCount = 0
	If IsHardmodeEnabled() Then UseConset()

	; What order is the best ?
	If TowerOfCourage() Then Return 1
	If TheWailingLord() Then Return 1
	If AGiftOfGriffons() Then Return 1
	If TheEternalForgemaster() Then Return 1
	If DefendTheTempleOfWar() Then Return 1
	If RestoreTheTempleOfWar() Then Return 1
	If KhobayTheBetrayer() Then Return 1
	If TowerOfStrength() Then Return 1
	If ArmyOfDarkness() Then Return 1
	If SlavesOfMenzies() Then Return 1
	If TheHunt() Then Return 1

	
	; Chest
	MoveTo(15086, -19132)
	Info('Opening chest')
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()
	; Doubled to secure the looting
	MoveTo(15590, -18853)
	MoveTo(15027, -19102)
	RndSleep(5000)
	TargetNearestItem()
	ActionInteract()
	RndSleep(2500)
	PickUpItems()

	AdlibUnRegister('FoWGroupIsAlive')
	Info('Chest looted')
	Return 0
EndFunc


Func TowerOfCourage()
EndFunc

Func TheWailingLord()
EndFunc

Func AGiftOfGriffons()
EndFunc

Func TheEternalForgemaster()
EndFunc

Func DefendTheTempleOfWar()
EndFunc

Func RestoreTheTempleOfWar()
EndFunc

Func KhobayTheBetrayer()
EndFunc

Func TowerOfStrength()
EndFunc

Func ArmyOfDarkness()
EndFunc

Func SlavesOfMenzies()
EndFunc

Func TheHunt()
EndFunc


;~ Did run fail ?
Func FoWIsFailure()
	If ($FoWDeathsCount > 5) Then
		AdlibUnregister('FoWGroupIsAlive')
		Return True
	EndIf
	Return False
EndFunc


;~ Updates the groupIsAlive variable, this function is run on a fixed timer
Func FoWGroupIsAlive()
	$FoWDeathsCount += IsGroupAlive() ? 0 : 1
EndFunc



;~ Function present only to store useful tidbits to use in other places
Func UselessFunction()
	; TIDBIT get a quest
	Info('Get quest')
	MoveTo(, )
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x0)
	RndSleep(500)
	; Quest validation doubled to secure bot
	GoToNPC(GetNearestNPCToCoords(12500, 22648))
	RndSleep(250)
	Dialog(0x0)
	RndSleep(500)



	; TIDBIT move and kill stuff
	While $FoWDeathsCount < 6 And Not IsAgentInRange(GetMyAgent(), 6078, 4483, 1250)
		UseMoraleConsumableIfNeeded()
		SafeMoveAggroAndKill(17619, 2687, 'Moving near duo', $aggroRange)
		SafeMoveAggroAndKill(18168, 4788, 'Killing one from duo', $aggroRange)
		SafeMoveAggroAndKill(18880, 7749, 'Triggering beacon 1', $aggroRange)
		SafeMoveAggroAndKill(13080, 7822, 'Moving towards nettles cave', $aggroRange)
		SafeMoveAggroAndKill(9946, 6963, 'Nettles cave', $aggroRange)
		SafeMoveAggroAndKill(6078, 4483, 'Nettles cave exit group', $aggroRange)
	WEnd



	; TIDBIT interact with items on the floor
	RndSleep(500)
	PickUpItems()
	Info('Open dungeon door')
	ClearTarget()
	Sleep(GetPing() + 500)
	Moveto(17888, -6243)
	ActionInteract()
	Sleep(GetPing() + 500)



	; TIDBIT waiting on a quest to terminate
	Local $questState = 1
	While $FoWDeathsCount < 6 And $questState <> 3
		$questState = DllStructGetData(GetQuestByID($ID_FoW_Quest), 'LogState')
		Sleep(1000)
	WEnd
	If FoWIsFailure() Then Return 1
EndFunc