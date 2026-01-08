#CS ===========================================================================
; Author: Coaxx
; Contributor: caustic-kronos, n1kn4x
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

Opt('MustDeclareVars', True)

; ==== Constants ====
Global Const $LDOAInformations = 'The bot will:' & @CRLF _
	& '- Go right off the bat, on a new character after the cutscene.' & @CRLF _
	& '- In the beginning it tries to do the elementalist quest to get some initial skill.' & @CRLF _
	& '- If you are not an elementalist, then it is advised to get some initial skills yourself.' & @CRLF _
	& '- If you are already level 2, it wont setup your bar or weapons, you can choose.' & @CRLF _
	& '- It will get you LDOA, this is not a farming bot.'
; Average duration ~ 1m
Global Const $LDOA_FARM_DURATION = 1 * 60 * 1000

Global Const $ID_Dialog_Accept_Quest_War_Preparations = 0x80DB01
Global Const $ID_Dialog_Finish_Quest_War_Preparations = 0x80DB07
Global Const $ID_Dialog_Accept_Quest_Elementalist_Test = 0x805301
Global Const $ID_Dialog_Finish_Quest_Elementalist_Test = 0x805307
Global Const $ID_Dialog_Select_Quest_A_Mesmers_Burden = 0x804703
Global Const $ID_Dialog_Accept_Quest_A_Mesmers_Burden = 0x804701
Global Const $ID_Dialog_Accept_Quest_Charr_At_The_Gate = 0x802E01
Global Const $ID_Dialog_Accept_Quest_Farmer_Hamnet = 0x84A101

Global Const $ID_Quest_CharrAtTheGate = 0x2E
Global Const $ID_Quest_FarmerHamnet = 0x4A1

Global Const $ID_Luminescent_Scepter = 6508
Global Const $ID_Serrated_Shield = 6514

; Variables used for Survivor async checking (Low Health Monitor)
Global Const $LOW_HEALTH_THRESHOLD = 0.33
Global Const $LOW_HEALTH_CHECK_INTERVAL = 100

Global $LDOA_FARM_SETUP = False


;~ Main method to get LDOA title
Func LDOATitleFarm($STATUS)
	If Not $LDOA_FARM_SETUP And SetupLDOATitleFarm() == $FAIL Then
		Info('LDOA farm setup failed, stopping farm.')
		Return $PAUSE
	EndIf
	; Difference between this bot and ALL the others : this bot can't go to Eye of the North or other towns for inventory management
	If (CountSlots(1, _Min($BAGS_COUNT, 4)) <= 5) Then
		PresearingInventoryManagement()
	EndIf
	If (CountSlots(1, $BAGS_COUNT) <= 0) Then
		Notice('Inventory has 0 slots left, pausing.')
		Return $PAUSE
	EndIf

	AdlibRegister('LowHealthMonitor', $LOW_HEALTH_CHECK_INTERVAL)
	Local $result = LDOATitleFarmLoop()
	AdlibUnRegister('LowHealthMonitor')
	Return $result
EndFunc


;~ LDOA Title farm setup
Func SetupLDOATitleFarm()
	Info('Setting up farm')
	LeaveParty()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	If $level == 1 Then
		Info('LDOA 1-2')
		InitialSetupLDOA()
	ElseIf $level >= 2 And $level < 10 Then
		Info('LDOA 2-10')
		SetupCharrAtTheGateQuest()
	Else
		Info('LDOA 10-20')
		If SetupHamnetQuest() == $FAIL Then Return $FAIL
		Info('Checking if Foibles Fair is available...')
		If TryTravel($ID_Foibles_Fair) == $FAIL Then RunToFoible()
	EndIf
	Info('Preparations complete')
	$LDOA_FARM_SETUP = True
EndFunc


;~ Initial setup for LDOA title farm if new char, this is done only once
Func InitialSetupLDOA()
	DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	SendChat('bonus', '/') ; Get Igneous summoning stone for low level characters
	Sleep(GetPing() + 750)
	GetWeapons()
	; First Sir Tydus quest to get some skills
	MoveTo(10399, 318)
	MoveTo(11004, 1409)
	MoveTo(11683, 3447)
	GoToNPC(GetNearestNPCToCoords(11683, 3447))
	Sleep(GetPing() + 750)
	Dialog($ID_Dialog_Accept_Quest_War_Preparations)
	Sleep(GetPing() + 750)

	MoveTo(7607, 5552)
	Move(7175, 5229)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveTo(6116, 3995)
	GoToNPC(GetNearestNPCToCoords(6187, 4085))
	Sleep(GetPing() + 750)
	Dialog($ID_Dialog_Finish_Quest_War_Preparations)
	Sleep(250)
	Dialog($ID_Dialog_Accept_Quest_Elementalist_Test)
	Sleep(GetPing() + 750)
	MoveTo(4187, -948)
	MoveAggroAndKillInRange(4207, -2892, '', 2500)
	MoveTo(3771, -1729)
	MoveTo(6069, 3865)
	GoToNPC(GetNearestNPCToCoords(6187, 4085))
	Sleep(GetPing() + 750)
	Dialog($ID_Dialog_Finish_Quest_Elementalist_Test)
	Sleep(GetPing() + 750)
	MoveTo(2785, 7736)
	GoToNPC(GetNearestNPCToCoords(2785, 7736))
	Sleep(GetPing() + 750)
	Dialog($ID_Dialog_Select_Quest_A_Mesmers_Burden)
	Sleep(250)
	Dialog($ID_Dialog_Accept_Quest_A_Mesmers_Burden)

	DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
	If TryTravel($ID_Ashford_Abbey) == $FAIL Then RunToAshford()
EndFunc


;~ Get weapons for LDOA title farm
Func GetWeapons()
	Local $luminescentScepter = FindInInventory($ID_Luminescent_Scepter)
	Local $serratedShield = FindInInventory($ID_Serrated_Shield)

	If $luminescentScepter[0] <> 0 And $serratedShield[0] <> 0 Then
		Info('Equipping Luminescent Scepter and Serrated Shield')
		UseItemBySlot($luminescentScepter[0], $luminescentScepter[1])
		UseItemBySlot($serratedShield[0], $serratedShield[1])
	EndIf
EndFunc


;~ Setup Charr at the gate quest
Func SetupCharrAtTheGateQuest()
	Info('Setting up Charr at the gate quest...')
	DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)

	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_CharrAtTheGate), 'Logstate')
	If $questStatus == 0 Or $questStatus == 3 Then
		Sleep(GetPing() + 750)
		AbandonQuest($ID_Quest_CharrAtTheGate)
		Sleep(GetPing() + 750)
		MoveTo(7974, 6142)
		MoveTo(5668, 10667)
		GoToNPC(GetNearestNPCToCoords(5668, 10667))
		Sleep(GetPing() + 750)
		Dialog($ID_Dialog_Accept_Quest_Charr_At_The_Gate)
		Sleep(GetPing() + 750)
	ElseIf $questStatus == 1 Then
		Info('Good to go!')
	EndIf
EndFunc


;~ Setup Hamnet quest
Func SetupHamnetQuest()
	Info('Setting up Hamnet quest...')
	DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)

	Local $questStatus = DllStructGetData(GetQuestByID($ID_Quest_FarmerHamnet), 'Logstate')
	If $questStatus == 0 Then
		Info('Quest not found, setting up...')
		Sleep(GetPing() + 750)
		MoveTo(9516, 7668)
		MoveTo(9815, 7809)
		MoveTo(10280, 7895)
		MoveTo(10564, 7832)
		GoToNPC(GetNearestNPCToCoords(10564, 7832))
		Sleep(GetPing() + 750)
		Dialog($ID_Dialog_Accept_Quest_Farmer_Hamnet)
		Sleep(GetPing() + 750)
		$questStatus = DllStructGetData(GetQuestByID($ID_Quest_FarmerHamnet), 'Logstate')
		If $questStatus == 0 Then Return $FAIL
	EndIf
	Info('Quest found, Good to go!')
	Return $SUCCESS
EndFunc


;~ LDOA Title farm loop
Func LDOATitleFarmLoop()
	Local $level = DllStructGetData(GetMyAgent(), 'Level')
	Local $result
	Info('Current level: ' & $level)
	If $level < 2 Then
		$result = LDOATitleFarmUnder2()
	ElseIf $level < 10 Then
		$result = LDOATitleFarmUnder10()
	ElseIf $level < 20 Then
		$result = LDOATitleFarmAfter10()
	Else
		Info('Reached level 20, LDOA title farm complete.')
		Return $PAUSE
	EndIf
	; If we leveled to 2 or 10, we reset the setup so that the bot starts on the 2-10 or the 10-20 part
	Local $newLevel = DllStructGetData(GetMyAgent(), 'Level')
	If ($level == 1 Or $level == 9) And $newLevel > $level Then $LDOA_FARM_SETUP = False
	Return $result
EndFunc


;~ Kill some worms, level 2 needed for CharrAtGate
Func LDOATitleFarmUnder2()
	Info('Here wormy, wormy!')
	DistrictTravel($ID_Ashford_Abbey)
	MoveTo(-11455, -6238)
	Move(-11037, -6240)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveTo(-10433, -6021)
	MoveAggroAndKill(-9551, -5499)
	MoveAggroAndKill(-9545, -4205)
	MoveAggroAndKill(-9551, -2929)
	MoveAggroAndKill(-9559, -1324)
	MoveAggroAndKill(-9451, -301)
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Farm to do to level to level 10
Func LDOATitleFarmUnder10()
	DistrictTravel($ID_Ascalon_City_Presearing)
	Info('Entering explorable')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RandomSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	MoveTo(6220, 4470, 30)
	Sleep(3000)
	Info('Going to the gate')
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveTo(3180, 6468, 30)
	MoveTo(360, 6575, 30)
	MoveTo(-3140, 9610, 30)
	Sleep(6000)
	MoveTo(-3640, 10930, 30)
	Sleep(2000)
	MoveTo(-3440, 10010, 30)
	MoveAggroAndKillInRange(-3753, 11131, '', 3000)
	If IsPlayerDead() Then Return $FAIL
	Return $SUCCESS
EndFunc


;~ Farm to do to level to level 20
Func LDOATitleFarmAfter10()
	Info('Starting Hamnet farm...')
	Info('Heading to Foibles Fair!')
	DistrictTravel($ID_Foibles_Fair)
	MoveTo(-183, 9002)
	MoveTo(356, 7834)
	Info('Entering Wizards Folly!')
	Move(500, 7300)
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveAggroAndKillInRange(2541, 4504, '', 2000)
	If IsPlayerDead() Then Return $FAIL
	Info('Returning to Foibles Fair')
	ResignAndReturnToOutpost()
	WaitMapLoading($ID_Foibles_Fair, 10000, 1000)
	Return $SUCCESS
EndFunc


;~ Outpost checker
Func TryTravel($mapID)
	Local $startTime = TimerInit()
	DistrictTravel($mapID)
	While TimerDiff($startTime) < 10000
		If GetMapID() == $mapID Then
			Info('Travel successful.')
			Return $SUCCESS
		EndIf
		Sleep(200)
	WEnd
	Info('Travel failed.')
	Return $FAIL
EndFunc


;~ Run to Ashford Abbey
Func RunToAshford()
	; This function is used to run to Ashford Abbey
	Info('Starting run to Ashford Abbey from Ascalon..')
	MoveTo(7500, 5500)
	Move(7000, 5000)
	RandomSleep(1000)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveTo(2560, -2331)
	MoveTo(-1247, -6084)
	MoveTo(-5310, -6951)
	MoveTo(-11026, -6238)
	Move(-11444, -6237)
	If IsPlayerDead() Then Return $FAIL
	WaitMapLoading($ID_Ashford_Abbey, 10000, 2000)
	Info('Made it to Ashford Abbey')
	Return $SUCCESS
EndFunc


;~ Run to Foibles Fair
Func RunToFoible()
	Info('Starting run to Foibles Fair from Ashford Abbey..')
	DistrictTravel($ID_Ashford_Abbey)
	Info('Entering Lakeside County!')
	MoveTo(-11455, -6238)
	Move(-11037, -6240)
	WaitMapLoading($ID_Lakeside_County, 10000, 2000)
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveTo(-11809, -12198)
	MoveTo(-12893, -16093)
	MoveTo(-11566, -18712)
	MoveTo(-11246, -19376)
	MoveTo(-13738, -20079)
	Info('Entering Wizards Folly!')
	Move(-14000, -19900)
	If IsPlayerDead() Then Return $FAIL
	WaitMapLoading($ID_Wizards_Folly, 10000, 2000)
	UseConsumable($ID_Igneous_Summoning_Stone)
	MoveTo(8648, 17730)
	MoveTo(7497, 15763)
	MoveTo(2840, 10383)
	MoveTo(1648, 7527)
	MoveTo(536, 7315)
	Move(320, 7950)
	If IsPlayerDead() Then Return $FAIL
	WaitMapLoading($ID_Foibles_Fair, 10000, 2000)
	Info('Made it to Foibles Fair')
	Return $SUCCESS
EndFunc


;~ Resign and return to Ascalon
Func BackToAscalon()
	Info('Porting to Ascalon')
	ResignAndReturnToOutpost()
	WaitMapLoading($ID_Ascalon_City_Presearing, 10000, 1000)
EndFunc


;~ Start/stop background low-health monitor
;~ Return to Ascalon if health is dangerously low
Func LowHealthMonitor()
	If IsLowHealth() Then
		Notice('Health below threshold, returning to Ascalon and restarting the run.')
		DistrictTravel($ID_Ascalon_City_Presearing, $DISTRICT_NAME)
		Return $SUCCESS ; restarting the title farm run
	EndIf
EndFunc


Func IsLowHealth()
	Local $me = GetMyAgent()
	Local $healthRatio = DllStructGetData($me, 'HealthPercent')
	If $healthRatio > 0 And $healthRatio < $LOW_HEALTH_THRESHOLD Then Return True
	Return False
EndFunc


;~ Function to deal with inventory after farm, in presearing
Func PresearingInventoryManagement()
	; Operations order :
	; 1-Sort items
	; 2-Identify items
	; 3-Salvage
	; 4-Store items
	If GUICtrlRead($GUI_Checkbox_SortItems) == $GUI_CHECKED Then SortInventory()
	If $IDENTIFY_ITEMS And HasUnidentifiedItems() Then IdentifyAllItems(False)
	If $SALVAGE_ANY_ITEM And HasChosenItemsToSalvage() Then
		SalvageAllItems(False)
		If $BAGS_COUNT == 5 Then
			If MoveItemsOutOfEquipmentBag() > 0 Then SalvageAllItems(False)
		EndIf
	EndIf
	If GUICtrlRead($GUI_Checkbox_StoreTheRest) == $GUI_CHECKED Then StoreEverythingInXunlaiStorage()
EndFunc