#CS ===========================================================================
; Author: Coaxx
; Contributor: caustic-kronos
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
#include '../lib/Utils-Storage-Bot.au3'

Opt('MustDeclareVars', 1)

; ==== Constants ====
Global Const $LDOASkillbar = 'Any build will do, providing it has a heal and damage.'
Global Const $LDOAInformations = 'The bot will:' & @CRLF _
	& '- Go right off the bat, on a new character after the cutscene.' & @CRLF _
	& '- If you are already level 2, it wont setup your bar or weapons, you can choose.' & @CRLF _
	& '- It will get you LDOA, this is not a farming bot.'
; Average duration ~ 10m
Global Const $LDOA_FARM_DURATION = 10 * 60 * 1000

; Skill numbers declared to make the code WAY more readable (UseSkillEx($LDOA_Skill1) is better than UseSkillEx(1))
Global Const $LDOA_Skill1 = 1
Global Const $LDOA_Skill2 = 2
Global Const $LDOA_Skill3 = 3
Global Const $LDOA_Skill4 = 4
Global Const $LDOA_Skill5 = 5
Global Const $LDOA_Skill6 = 6
Global Const $LDOA_Skill7 = 7
Global Const $LDOA_Skill8 = 8

Global Const $ID_Quest_CharrAtTheGate = 0x2E
Global Const $ID_Quest_FarmerHamnet = 0x4A1

Global Const $ID_Luminescent_Scepter = 6508
Global Const $ID_Serrated_Shield = 6514

Global Const $ID_Ascalon_City_Presearing = 148
Global Const $ID_Foibles_Fair = 165
Global Const $ID_Wizards_Folly = 149
Global Const $ID_Fort_Ranik_Presearing = 166
Global Const $ID_Barradin_Estate = 167
Global Const $ID_Regent_Valley = 116
Global Const $ID_Green_Hills_County = 147

Global $LDOA_FARM_SETUP = False
Global $LDOA_OUTPOST_CHECK = False
Global $LDOA_HAMNET_UNAVAILABLE = False

;~ Main method to get LDOA title
Func LDOATitleFarm($STATUS)
	; Need to be done here in case bot comes back from inventory management
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	If Not $LDOA_FARM_SETUP Then SetupLDOATitleFarm()

	; Here we check if the quest is available, if not, we stop the farm
	If $LDOA_HAMNET_UNAVAILABLE Then
		Info('Quest not available, wait for rotation.')
		$LDOA_FARM_SETUP = False
		Return $PAUSE
	EndIf

	; Difference between this bot and ALL the others : this bot can't go to Eye of the North for inventory management
	If (CountSlots(1, _Min($BAGS_COUNT, 4)) <= 5) Then
		PresearingInventoryManagement()
		$LDOA_FARM_SETUP = False
	EndIf
	If (CountSlots(1, $BAGS_COUNT) <= 5) Then
		Notice('Inventory full, pausing.')
		$LDOA_FARM_SETUP = False
		Return $PAUSE
	EndIf

	If $STATUS <> 'RUNNING' Then Return $PAUSE

	Return LDOATitleFarmLoop($STATUS)
EndFunc


;~ LDOA Title farm setup
Func SetupLDOATitleFarm()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')

	Info('Setting up farm')
	$LDOA_HAMNET_UNAVAILABLE = False

	LeaveParty()

	If $level == 1 Then
		Info('LDOA 1-2')
		SendChat('bonus', '/')
		RandomSleep(GetPing() + 750)
		GetWeapons()
		InitialSetupLDOA()
	ElseIf $level >= 2 And $level <= 10 Then
		Info('LDOA 2-10')
		SetupCharrAtTheGateQuest()
	Else
		If Not $LDOA_OUTPOST_CHECK Then
			Info('Checking for outposts...')
			OutpostRun()
			$LDOA_OUTPOST_CHECK = True
		EndIf

		RandomSleep(GetPing() + 750)
		Info('LDOA 11-20')
		SetupHamnetQuest()
	EndIf
	Info('Preparations complete')
	$LDOA_FARM_SETUP = True
EndFunc


;~ Get weapons for LDOA title farm
Func GetWeapons()
	Local $lumS = FindInInventory($ID_Luminescent_Scepter)
	Local $serS = FindInInventory($ID_Serrated_Shield)

	If $lumS[0] <> 0 And $serS[0] <> 0 Then
		Info('Equipping Luminescent Scepter and Serrated Shield')
		UseItemBySlot($lumS[0], $lumS[1])
		UseItemBySlot($serS[0], $serS[1])
	EndIf
EndFunc


;~ Initial setup for LDOA title farm if new char, this is done only once
Func InitialSetupLDOA()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	Info('Current level: ' & $level)
	; First Sir Tydus quest to get some skills
	MoveTo(10399, 318)
	MoveTo(11004, 1409)
	MoveTo(11691, 3435)
	GoToNPC(GetNearestNPCToCoords(11691, 3435))
	RandomSleep(GetPing() + 750)
	Dialog(0x80DD01)
	RandomSleep(GetPing() + 750)

	MoveTo(7607, 5552)
	Move(7175, 5229)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(6116, 3995)
	GoToNPC(GetNearestNPCToCoords(6116, 3995))
	RandomSleep(GetPing() + 750)
	Dialog(0x80DD07)
	RandomSleep(250)
	Dialog(0x805501)
	RandomSleep(GetPing() + 750)
	MoveTo(4187, -948)
	MoveAggroAndKill(4207, -2892, '', 2500, Null)
	MoveTo(3771, -1729)
	MoveTo(6069, 3865)
	GoToNPC(GetNearestNPCToCoords(6069, 3865))
	RandomSleep(GetPing() + 750)
	Dialog(0x805507)
	RandomSleep(GetPing() + 750)
	MoveTo(2785, 7736)
	GoToNPC(GetNearestNPCToCoords(2785, 7736))
	RandomSleep(GetPing() + 750)
	Dialog(0x804703)
	RandomSleep(250)
	Dialog(0x804701)

	Ashford()
	KillWorms()
EndFunc


;~ Kill some worms, level 2 needed for CharrAtGate
Func KillWorms()
	Local $level = 1
	Info('Here wormy, wormy!')

	While $level < 2
		If GetMapID() <> $ID_Ashford_Abbey Then RandomDistrictTravel($ID_Ashford_Abbey)

		MoveTo(-11455, -6238)
		Move(-11037, -6240)
		WaitMapLoading($ID_Lakeside_County, 10000, 2000)
		UseSS($ID_Lakeside_County)

		MoveTo(-10433, -6021)
		MoveAggroAndKill(-9551, -5499, '', 3000, Null)
		MoveAggroAndKill(-9545, -4205, '', 3000, Null)
		MoveAggroAndKill(-9551, -2929, '', 3000, Null)
		MoveAggroAndKill(-9559, -1324, '', 3000, Null)
		MoveAggroAndKill(-9451, -301, '', 3000, Null)

		If GetIsDead() Then Return KillWorms()

		Sleep(500)
		$level = DllStructGetData(GetMyAgent(), 'Level')
		Info('Current level: ' & $level)
	WEnd
EndFunc


;~ LDOA Title farm loop
Func LDOATitleFarmLoop($STATUS)
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	Info('Current level: ' & $level)

	If $STATUS <> 'RUNNING' Then Return $PAUSE

	If $level < 10 Then
		LDOATitleFarmUnder10()
	Else
		LDOATitleFarmAfter10()
	EndIf
	; If we level to 11, we reset the setup so that the bot starts on the 11-20 part
	Local $newLevel = DllStructGetData(GetMyAgent(), 'Level')
	If $level == 10 And $newLevel > $level Then $LDOA_FARM_SETUP = False
	Return $SUCCESS
EndFunc


;~ Setup Charr at the gate quest
Func SetupCharrAtTheGateQuest()
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	Info('Setting up Charr at the gate quest...')

	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_CharrAtTheGate), 'Logstate')

	If $questStatus == 0 Or $questStatus == 3 Then
		RandomSleep(GetPing() + 750)
		AbandonQuest($ID_Quest_CharrAtTheGate)
		RandomSleep(GetPing() + 750)
		MoveTo(7974, 6142)
		MoveTo(5668, 10667)
		GoToNPC(GetNearestNPCToCoords(5668, 10667))
		RandomSleep(GetPing() + 750)
		Dialog(0x802E01)
		RandomSleep(GetPing() + 750)
	ElseIf $questStatus == 1 Then
		Info('Good to go!')
	EndIf
EndFunc


;~ Farm to do to level to level 10
Func LDOATitleFarmUnder10()
	Local $me = GetMyAgent()

	Info('Entering explorable')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RandomSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(6220, 4470, 30)
	Info('Going to the gate')
	MoveTo(3180, 6468, 30)
	MoveTo(360, 6575, 30)
	MoveTo(-3140, 9610, 30)
	MoveTo(-3640, 10930, 30)
	MoveTo(-4165, 10655, 30)

	If GetIsDead() Then BackToAscalon()

	While 1
		If CountFoesInRangeOfAgent($me, 2000) >= 2 Then
			Sleep(100)
		Else
			BackToAscalon()
			ExitLoop
		EndIf
	WEnd

	Return $SUCCESS
EndFunc


;~ Setup Hamnet quest
Func SetupHamnetQuest()
	Info('I think Ill just call it There and Back Again, a Hobbit''s Holiday.')
	RandomDistrictTravel($ID_Ashford_Abbey)

	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	Info('Setting up Hamnet quest...')
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)

	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_FarmerHamnet), 'Logstate')

	; Get quest if not already obtained
	If $questStatus == 0 Then
		Info('Quest not found, setting up...')
		RandomSleep(GetPing() + 750)
		MoveTo(9516, 7668)
		MoveTo(9815, 7809)
		MoveTo(10280, 7895)
		MoveTo(10564, 7832)
		GoToNPC(GetNearestNPCToCoords(10564, 7832))
		RandomSleep(GetPing() + 750)
		RandomSleep(GetPing() + 750)
		$questStatus = DllStructGetData(GetQuestByID($ID_Quest_FarmerHamnet), 'Logstate')
		If $questStatus == 0 Then
			$LDOA_HAMNET_UNAVAILABLE = True
			Return
		EndIf
	EndIf
	If $questStatus == 1 Then
		Info('Quest found, Good to go!')
	EndIf
EndFunc


;~ Farm to do to level to level 20
Func LDOATitleFarmAfter10()
	Info('Starting Hamnet farm...')

	While 1
		Local $level = DllStructGetData(GetMyAgent(), 'Level')
		If $level < 20 Then
			RandomSleep(500)
			Info('Current level: ' & $level)
			Hamnet()
		Else
			Info('Current level: ' & $level & ', stopping farm.')
			BackToAscalon()
			ExitLoop
		EndIf
	WEnd

	Return $SUCCESS
EndFunc


;~ Farmer Hamnet farm
Func Hamnet()
	Info('Heading to Foibles Fair!')
	RandomDistrictTravel($ID_Foibles_Fair)

	RandomSleep(GetPing() + 750)

	MoveTo(-183, 9002)
	MoveTo(356, 7834)
	Info('Entering Wizards Folly!')
	Move(390, 7800)
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)
	UseSS($ID_Wizards_Folly)

	MoveAggroAndKill(2418, 5437, '', 2000, Null)

	If GetIsDead() Then Return Hamnet()

	ReturnToOutpost()
	Info('Returning to Foibles Fair')
	WaitMapLoading($ID_Foibles_Fair, 10000, 2000)
EndFunc


;~ Run to every outpost in pre
Func OutpostRun()
	If GetMapID() <> $ID_Ascalon_City_Presearing Then DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)

	RandomSleep(2000)
	Info('Starting outpost run...')
	TravelWithTimeout($ID_Ashford_Abbey, 'Ashford')
	Sleep(500)
	TravelWithTimeout($ID_Foibles_Fair, 'Foible')
	Sleep(500)
	TravelWithTimeout($ID_Fort_Ranik_Presearing, 'Ranik')
	Sleep(500)
	TravelWithTimeout($ID_Barradin_Estate, 'Barradin')
	Sleep(500)
EndFunc


;~ Outpost checker
Func TravelWithTimeout($mapID, $onFailFunc)
	Local $startTime = TimerInit()

	RandomDistrictTravel($mapID)

	While TimerDiff($startTime) < 15000
		If GetMapID() == $mapID Then
			Info('Travel successful.')
			Return
		EndIf
		Sleep(1000)
	WEnd
	Info('Travel failed.')
	Call($onFailFunc)
EndFunc


;~ Run to Ashford Abbey
Func Ashford()
	; This function is used to run to Ashford Abbey
	Info('Starting run to Ashford Abbey..')
	Info('Entering Lakeside County!')

	RandomSleep(GetPing() + 750)

	MoveTo(7500, 5500)
	Move(7000, 5000)
	RandomSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(2560, -2331) ; 1
	MoveTo(-1247, -6084) ; 2
	MoveTo(-5310, -6951) ; 3
	MoveTo(-11026, -6238) ; 4
	Move(-11444, -6237) ; 5

	; If we are dead, we will try again
	If GetIsDead() Then Return Ashford()

	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
	Info('Made it to Ashford Abbey')
EndFunc


;~ Run to Foibles Fair
Func Foible()
	Info('Starting run to Foibles Fair..')
	RandomDistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')

	RandomSleep(GetPing() + 750)

	MoveTo(-11455, -6238) ; 1
	Move(-11037, -6240) ; 2
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(-11809, -12198) ; 3
	MoveTo(-12893, -16093) ; 4
	MoveTo(-11566, -18712) ; 5
	MoveTo(-11246, -19376) ; 6
	MoveTo(-13738, -20079) ; 7
	Info('Entering Wizards Folly!')
	Move(9875, 19853) ; 8
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)
	UseSS($ID_Wizards_Folly)
	MoveTo(8648, 17730) ; 9
	MoveTo(7497, 15763) ; 10
	MoveTo(2840, 10383) ; 11
	MoveTo(1648, 7527) ; 12
	MoveTo(536, 7315) ; 13
	Move(337, 7924) ; 14

	; If we are dead, we will try again
	If GetIsDead() Then Return Foible()

	WaitMapLoading($ID_Foibles_Fair, 10000, 2000)
	Info('Made it to Foibles Fair')
EndFunc


;~ Run to Fort Ranik
Func Ranik()
	Info('Starting run to Fort Ranik..')
	RandomDistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')

	RandomSleep(GetPing() + 750)

	MoveTo(-11465, -6221) ; 1
	Move(-11045, -6234) ; 2
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(-6996, -6842) ; 3
	MoveTo(-4559, -12343) ; 4
	MoveTo(-3589, -13032) ; 5
	MoveTo(737, -16091) ; 6
	MoveTo(2205, -18452) ; 7
	MoveTo(4100, -19770) ; 8
	Info('Entering Regent Valley!')
	Move(-15504, 16947) ; 9
	WaitMapLoading($ID_Regent_Valley, 10000, 2000)
	UseSS($ID_Regent_Valley)
	MoveAvoidingBodyBlock(-13479, 14598, 20000) ; 10
	MoveAvoidingBodyBlock(-11850, 14655, 20000) ; 11
	MoveAvoidingBodyBlock(-8092, 11137, 20000) ; 12
	MoveAvoidingBodyBlock(-3485, 8705, 20000) ; 13
	MoveAvoidingBodyBlock(497, 6267, 20000) ; 14
	MoveAvoidingBodyBlock(6250, 5387, 20000) ; 15
	MoveAvoidingBodyBlock(7605, 4062, 20000) ; 16
	MoveAvoidingBodyBlock(9897, 2728, 20000) ; 17
	MoveAvoidingBodyBlock(13312, 2072, 20000) ; 18
	MoveAvoidingBodyBlock(14977, 1361, 20000) ; 19
	MoveAvoidingBodyBlock(18820, 1496, 20000) ; 20
	MoveAvoidingBodyBlock(19241, 2153, 20000) ; 21
	MoveAvoidingBodyBlock(22297, 4014, 20000) ; 22
	MoveAvoidingBodyBlock(22554, 6949, 20000) ; 23
	Move(22540, 7575) ; 24

	; If we are dead, we will try again
	If GetIsDead() Then Return Ranik()

	WaitMapLoading($ID_Fort_Ranik_Presearing, 10000, 2000)
	Info('Made it to Fort Ranik!')
EndFunc


;~ Run to Barradin Estate
Func Barradin()
	Info('Starting run to The Barradin Estate..')
	RandomDistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')

	RandomSleep(GetPing() + 750)

	MoveTo(-11445, -6228) ; 1
	Move(-11023, -6232) ; 2
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseSS($ID_Lakeside_County)
	MoveTo(-11280, 1103) ; 3
	MoveTo(-11601, 3398) ; 4
	MoveTo(-10132, 6921) ; 5
	MoveTo(-14363, 10094) ; 6
	Info('Entering Green Hills County!')
	Move(21918, 13053) ; 7
	WaitMapLoading($ID_Green_Hills_County, 10000, 2000)
	UseSS($ID_Green_Hills_County)
	MoveAvoidingBodyBlock(20577, 12039, 20000) ; 8
	MoveAvoidingBodyBlock(18023, 12529, 20000) ; 9
	MoveAvoidingBodyBlock(13583, 5991, 20000) ; 10
	MoveAvoidingBodyBlock(12076, 3308, 20000) ; 11
	MoveAvoidingBodyBlock(10281, 1164, 20000) ; 12
	MoveAvoidingBodyBlock(11603, -523, 20000) ; 13
	MoveAvoidingBodyBlock(10870, -2085, 20000) ; 14
	MoveAvoidingBodyBlock(6763, -3873, 20000) ; 15
	MoveAvoidingBodyBlock(1843, -2556, 20000) ; 16
	MoveAvoidingBodyBlock(-987, -2137, 20000) ; 17
	MoveAvoidingBodyBlock(-1813, -2055, 20000) ; 18
	MoveAvoidingBodyBlock(-4040, -478, 20000) ; 19
	MoveAvoidingBodyBlock(-6625, -189, 20000) ; 20
	MoveAvoidingBodyBlock(-7552, -121, 20000) ; 21
	MoveAvoidingBodyBlock(-7902, 510, 20000) ; 22
	MoveAvoidingBodyBlock(-7827, 1420, 20000) ; 23
	MoveAvoidingBodyBlock(-7444, 1423, 20000) ; 24
	Move(-7158, 1430) ; 25

	; If we are dead, we will try again
	If GetIsDead() Then Return Barradin()

	WaitMapLoading($ID_Barradin_Estate, 10000, 2000)
	Info('Made it to Barradin Estate!')
EndFunc


;~ Resign and return to Ascalon
Func BackToAscalon()
	Info('Porting to Ascalon')
	Resign()
	RandomSleep(3500)
	ReturnToOutpost()
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 2000)
EndFunc


;~ Function to deal with inventory after farm, in presearing
Func PresearingInventoryManagement()
	; Operations order :
	; 1-Sort items
	; 2-Identify items
	; 3-Salvage
	; 4-Store items
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	If GUICtrlRead($GUI_Checkbox_IdentifyAllItems) == $GUI_CHECKED And HasUnidentifiedItems() Then IdentifyAllItems(False)
	If GUICtrlRead($GUI_Checkbox_SalvageItems) == $GUI_CHECKED Then
		SalvageAllItems(False)
		If $BAGS_COUNT == 5 Then
			If MoveItemsOutOfEquipmentBag() > 0 Then SalvageAllItems(False)
		EndIf
	EndIf
	If GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED Then StoreEverythingInXunlaiStorage()
EndFunc


;~ Use Igneous Summoning Stone
Func UseSS($mapID)
	Local $invSS = FindInInventory($ID_Igneous_Summoning_Stone)

	While 1
		If GetMapID() == $mapID Then
			If $invSS[0] <> 0 Then
				UseConsumable($ID_Igneous_Summoning_Stone)
				Info('Using Igneous Summoning Stone')
				ExitLoop
			Else
				Info('Igneous Summoning Stone not found in inventory.')
				ExitLoop
			EndIf
		Else
			Sleep(100)
		EndIf
	WEnd
EndFunc
